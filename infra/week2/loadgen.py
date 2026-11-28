#!/usr/bin/env python3
"""One approved, disposable load-only EC2. No public ingress; max 30 minutes."""
import base64
import contextlib
import gzip
import importlib.util
import io
import json
from pathlib import Path
import shlex
import sys
import tarfile
import time

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('infra2_cloud', HERE / 'cloud.py')
cloud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cloud)
aws, state = cloud.aws, cloud.lab.state

def create():
    if state.get('cleanup_requested') or state.get('cleanup_complete'):
        raise RuntimeError('Lab cleanup started; refusing to reuse deleted resource IDs')
    if state.get('loadgen'):
        reservations = aws('ec2','describe-instances',{'Filters':[{'Name':'instance-id','Values':[state['loadgen']]}]})['Reservations']
        existing = [i for r in reservations for i in r['Instances']]
        if any(i['State']['Name'] != 'terminated' for i in existing):
            raise RuntimeError('Load generator is still present; refusing a concurrent duplicate')
        state.setdefault('previous_loadgens',[]).append(state.pop('loadgen'))
        cloud.lab.save()
    name = cloud.lab.PREFIX + '-loadgen'
    if not state.get('loadgen_role'):
        aws('iam','create-role',{'RoleName':name,'AssumeRolePolicyDocument':json.dumps({'Version':'2012-10-17','Statement':[{'Effect':'Allow','Principal':{'Service':'ec2.amazonaws.com'},'Action':'sts:AssumeRole'}]}),'Tags':cloud.lab.TAGS})
        aws('iam','attach-role-policy',{'RoleName':name,'PolicyArn':'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'})
        aws('iam','create-instance-profile',{'InstanceProfileName':name,'Tags':cloud.lab.TAGS})
        aws('iam','add-role-to-instance-profile',{'InstanceProfileName':name,'RoleName':name})
        state['loadgen_role'] = name; cloud.lab.save()
    if not state.get('loadgen_sg'):
        state['loadgen_sg'] = aws('ec2','create-security-group',{'GroupName':name,'Description':'No inbound load generator','VpcId':state['vpc'],'TagSpecifications':[{'ResourceType':'security-group','Tags':cloud.lab.TAGS}]})['GroupId']
        cloud.lab.save()
    # Dedicated source SG can reach only the internal ALB; no DB/app ingress added.
    try:
        cloud.raw_aws('ec2','authorize-security-group-ingress',{'GroupId':state['alb_sg'],'IpPermissions':[{'IpProtocol':'tcp','FromPort':80,'ToPort':80,'UserIdGroupPairs':[{'GroupId':state['loadgen_sg']}]}]})
    except RuntimeError as error:
        if 'InvalidPermission.Duplicate' not in str(error): raise
    script = '#!/bin/bash\nset -eu\nexec > /var/log/infra2-loadgen-boot.log 2>&1\nshutdown -h +29\ndnf install -y nodejs22\nmkdir -p /opt/infra2/results\nnode --version || node-22 --version\n'
    for attempt in range(8):
        try:
            response = aws('ec2','run-instances',{'ImageId':state['ami'],'InstanceType':'t4g.micro','MinCount':1,'MaxCount':1,'IamInstanceProfile':{'Name':name},'UserData':base64.b64encode(script.encode()).decode(),
                'NetworkInterfaces':[{'DeviceIndex':0,'AssociatePublicIpAddress':True,'SubnetId':state['subnets'][0]['id'],'Groups':[state['loadgen_sg']]}],
                'MetadataOptions':{'HttpTokens':'required'},'InstanceInitiatedShutdownBehavior':'terminate','CreditSpecification':{'CpuCredits':'standard'},
                'BlockDeviceMappings':[{'DeviceName':'/dev/xvda','Ebs':{'VolumeSize':8,'VolumeType':'gp3','Encrypted':True,'DeleteOnTermination':True}}],
                'TagSpecifications':[{'ResourceType':r,'Tags':cloud.lab.TAGS+[{'Key':'Name','Value':name}]} for r in ['instance','volume']]})
            state['loadgen'] = response['Instances'][0]['InstanceId']; cloud.lab.save()
            print('Dedicated no-inbound load generator created:',state['loadgen']); return
        except RuntimeError as error:
            if 'Invalid IAM Instance Profile' not in str(error) or attempt==7: raise
            time.sleep(5)

def install():
    reference = Path('/private/tmp/umc-infra2-reference')
    archive = io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w:gz') as tar:
        tar.add(reference/'src',arcname='src')
        tar.add(reference/'package.json',arcname='package.json')
        tar.add(HERE/'remote-runner.mjs',arcname='remote-runner.mjs')
    encoded = base64.b64encode(archive.getvalue()).decode()
    if len(encoded)>55000: raise RuntimeError('Payload too large')
    cloud.lab.remote(state['loadgen'],['set -eu','test -d /opt/infra2/results','node --version || node-22 --version',
        'echo '+encoded+' | base64 -d | tar xz -C /opt/infra2','echo "Official engine installed; no credentials copied."'])

def run(rps,duration=40,label='load'):
    if rps not in [200,400,600,800] or duration>120 or label not in ['load','alert']:
        raise ValueError('Unsupported stage')
    command = 'cd /opt/infra2 && node remote-runner.mjs '+shlex.quote('http://'+state['alb_dns'])+f' {rps} {duration} {label}'
    # Persist a redacted export immediately, even if the VM later auto-terminates.
    with contextlib.redirect_stdout(io.StringIO()):
        command_id = cloud.lab.remote(state['loadgen'],['set -eu',command])
    invocation = aws('ssm','get-command-invocation',{'CommandId':command_id,'InstanceId':state['loadgen']})
    line = next(line for line in invocation['StandardOutputContent'].splitlines() if line.startswith('SAFE_EXPORT='))
    value = json.loads(gzip.decompress(base64.b64decode(line.split('=',1)[1],validate=True)))
    if value['scenario']['target']['headers']['Authorization'] != '[REDACTED]':raise RuntimeError('Unsafe export')
    (HERE/'evidence'/f'vpc-{label}-{rps}.json').write_text(json.dumps(value,indent=2)+'\n')
    summary = {k:v for k,v in value['summary'].items() if k!='outages'}
    print(json.dumps({'commandId':command_id,'summary':summary,'generator':value['generator']}))

def collect(rps,label='load'):
    path = f'/opt/infra2/results/{label}-{rps}.json'
    cmd = "node -e " + shlex.quote("process.stdout.write(require('node:zlib').gzipSync(require('node:fs').readFileSync("+json.dumps(path)+")).toString('base64'))")
    result = aws('ssm','send-command',{'InstanceIds':[state['loadgen']],'DocumentName':'AWS-RunShellScript','Parameters':{'commands':[cmd]}})['Command']['CommandId']
    for _ in range(30):
        try: data=aws('ssm','get-command-invocation',{'CommandId':result,'InstanceId':state['loadgen']})
        except RuntimeError:
            time.sleep(2);continue
        if data['Status']=='Success':
            import gzip
            raw=gzip.decompress(base64.b64decode(data['StandardOutputContent'].strip(),validate=True))
            value=json.loads(raw)
            if value['scenario']['target']['headers']['Authorization']!='[REDACTED]':raise RuntimeError('Unsafe export')
            (HERE/'evidence'/f'vpc-{label}-{rps}.json').write_bytes(raw)
            print('Redacted VPC result saved:',rps,label);return
        if data['Status'] not in ['Pending','InProgress','Delayed']:raise RuntimeError('Result collection failed: '+data['Status'])
        time.sleep(2)
    raise TimeoutError('Result collection timeout')

if __name__=='__main__':
    action=sys.argv[1]
    if action=='create':create()
    elif action=='install':install()
    elif action=='run':run(int(sys.argv[2]),int(sys.argv[3]) if len(sys.argv)>3 else 40,sys.argv[4] if len(sys.argv)>4 else 'load')
    elif action=='collect':collect(int(sys.argv[2]),sys.argv[3] if len(sys.argv)>3 else 'load')
    else:raise SystemExit('create|install|run RPS [duration label]|collect RPS [label]')
