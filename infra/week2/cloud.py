#!/usr/bin/env python3
"""Disposable week2 AWS lab. Reuse week1 logic without modifying its state.
Secrets stay in .local/; fresh DB/private ALB, SSM control and VPC-local load.
"""
import base64
import importlib.util
import json
import os
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
LOCAL = HERE / '.local'
LOCAL.mkdir(mode=0o700, exist_ok=True)
spec = importlib.util.spec_from_file_location('infra1_reusable', HERE.parent / 'week1/manage.py')
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)
lab.LOCAL = LOCAL
lab.STATE_FILE = LOCAL / 'state.json'
lab.state = json.loads(lab.STATE_FILE.read_text()) if lab.STATE_FILE.exists() else {}
lab.PREFIX = 'movielog-infra2'
lab.TAGS = [{'Key': 'Project', 'Value': lab.PREFIX}, {'Key': 'Purpose', 'Value': 'UMC-Infra-week2-disposable'}]
lab.state.setdefault('probe_cidr', '127.0.0.1/32')  # Bootstrap never opens direct application ingress.
raw_aws = lab.aws

def aws(service, operation, data=None, **kwargs):
    data = json.loads(json.dumps(data)) if data is not None else None
    if service == 'ecr' and operation == 'create-repository':
        data['repositoryName'] = lab.PREFIX + '-app'
    if service == 'iam' and operation == 'put-role-policy':
        data['PolicyDocument'] = data['PolicyDocument'].replace('repository/movielog-infra-app', 'repository/' + lab.PREFIX + '-app')
    if service == 'ec2' and operation == 'authorize-security-group-ingress':
        for permission in data['IpPermissions']:
            if permission.get('FromPort') == 3000 and 'IpRanges' in permission:
                return {}  # No direct app port on bootstrap or ASG nodes.
            if permission.get('FromPort') == 80:
                permission.pop('IpRanges', None)
                permission['UserIdGroupPairs'] = [{'GroupId': lab.state['app_sg']}]
    if service == 'elbv2' and operation == 'create-load-balancer':
        data['Scheme'] = 'internal'
    if service == 'elbv2' and operation == 'create-rule':
        data['Conditions'] = [{'Field': 'path-pattern', 'PathPatternConfig': {'Values': [
            '/health', '/members', '/auth/login', '/movie-records'
        ]}}]
    return raw_aws(service, operation, data, **kwargs)

lab.aws = aws

def user_data(start_app=True):
    swap = (HERE.parent / 'week1/swap.sh').read_text()
    swap = swap.replace('CORS_DISABLED=true\\n', 'CORS_DISABLED=true\\nMETRICS_ENABLED=true\\n')
    script = '''#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/movielog-boot.log) 2>&1
dnf install -y docker
systemctl enable --now docker
mkdir -p /opt/umc /opt/alloy
chmod 700 /opt/umc /opt/alloy
'''
    script += "printf 'AWS_REGION=" + lab.REGION + "\\n' > /opt/umc/region.env\n"
    script += 'echo ' + base64.b64encode(swap.encode()).decode() + ' | base64 -d > /opt/umc/swap.sh\nchmod 700 /opt/umc/swap.sh\n'
    if start_app:
        script += '''ready=false
for attempt in $(seq 1 10); do
  if /opt/umc/swap.sh; then ready=true; break; fi
  sleep 10
done
$ready || exit 1
'''
        for name, dest in [('config.alloy', '/opt/alloy/config.alloy'), ('install-alloy.sh', '/opt/umc/install-alloy.sh')]:
            script += 'echo ' + base64.b64encode((HERE / name).read_bytes()).decode() + ' | base64 -d > ' + dest + '\n'
        script += 'export AWS_REGION=' + lab.REGION + '\nbash /opt/umc/install-alloy.sh\n'
    return base64.b64encode(script.encode()).decode()

lab.user_data = user_data

def inspect():
    lab.inspect()
    # Read names/types only. Never fetch or print any existing parameter's value.
    params = aws('ssm', 'describe-parameters', {'ParameterFilters': [
        {'Key': 'Name', 'Option': 'BeginsWith', 'Values': ['/umc/app/']}
    ]})['Parameters']
    print(json.dumps({'existingAppParameters': [{'name': p['Name'], 'type': p['Type']} for p in params]}))

def status():
    reservations = aws('ec2', 'describe-instances', {'Filters': [
        {'Name': 'tag:Project', 'Values': [lab.PREFIX]}]})['Reservations']
    instances = [{'id': i['InstanceId'], 'state': i['State']['Name']} for r in reservations for i in r['Instances']]
    dbs = aws('rds', 'describe-db-instances')['DBInstances']
    database = next((d['DBInstanceStatus'] for d in dbs if d['DBInstanceIdentifier'] == lab.state.get('db_id')), 'absent')
    print(json.dumps({'rds': database, 'instances': instances, 'cleanupComplete': lab.state.get('cleanup_complete', False)}, indent=2))

def foundation():
    if lab.state.get('cleanup_complete'):
        raise RuntimeError('State was cleaned; do not reuse recorded deleted resource IDs.')
    if 'repo' not in lab.state:
        params = aws('ssm', 'describe-parameters', {'ParameterFilters': [
            {'Key': 'Name', 'Option': 'BeginsWith', 'Values': ['/umc/app/']}
        ]})['Parameters']
        if params:
            raise RuntimeError('Existing /umc/app parameters found; refusing overwrite without ownership review.')
    lab.foundation()

def settings():
    config = json.loads((LOCAL / 'grafana.json').read_text())
    required = ['gc-fleet-url', 'gc-fleet-user', 'gc-prom-url', 'gc-prom-user', 'gc-token']
    for key in required:
        if not isinstance(config.get(key), str) or not config[key].strip():
            raise RuntimeError('Missing local Grafana setting: ' + key)
    for key in ['gc-fleet-url', 'gc-prom-url']:
        from urllib.parse import urlparse
        value = urlparse(config[key])
        if value.scheme != 'https' or not value.hostname or not value.hostname.endswith('.grafana.net'):
            raise RuntimeError('Only HTTPS *.grafana.net endpoint allowed: ' + key)
    for key in required:
        lab.parameter(key, config[key], key == 'gc-token')
    print('Grafana settings stored; token is SecureString and was not printed.')

def exporter():
    # Bootstrap DB admin parameter is restored briefly only for this explicit operation.
    # The exact random exporter password is stored only locally and as SecureString.
    import secrets
    lab.state.setdefault('exporter_password', secrets.token_hex(24))
    lab.save()
    lab.parameter('bootstrap', lab.state['master_password'], True)
    lab.parameter('exporter-password', lab.state['exporter_password'], True)
    script = """const mysql=require('mysql2/promise');
(async()=>{
const db=await mysql.createConnection({host:process.env.DB_HOST,user:'labadmin',password:process.env.MASTER_PASSWORD});
await db.query("CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY ?",[process.env.EXPORTER_PASSWORD]);
await db.query("GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'%'");
await db.end();
})().catch(()=>{console.error('Exporter setup failed');process.exit(1)});
"""
    builder = """import os,subprocess,json
os.umask(0o077)
def p(k):
 return json.loads(subprocess.check_output(['aws','ssm','get-parameter','--region','REGION','--name','/umc/app/'+k,'--with-decryption']))['Parameter']['Value']
with open('/opt/umc/exporter.env','w') as f:
 for k,v in [('DB_HOST',p('db-host')),('MASTER_PASSWORD',p('bootstrap')),('EXPORTER_PASSWORD',p('exporter-password'))]:
  f.write(k+'='+v+'\\n')
""".replace('REGION', lab.REGION)
    import shlex
    commands = ["set -euo pipefail", "trap 'rm -f /opt/umc/exporter.env' EXIT",
        'echo ' + base64.b64encode(builder.encode()).decode() + ' | base64 -d | python3',
        'IMAGE=$(aws ssm get-parameter --region ' + lab.REGION + ' --name /umc/app/image --query Parameter.Value --output text)',
        'docker run --rm --env-file /opt/umc/exporter.env --entrypoint node "$IMAGE" -e ' + shlex.quote(script)]
    try:
        lab.remote(lab.state['baseline'], ['bash -c ' + shlex.quote('\n'.join(commands))])
        lab.parameter('mysql-dsn', 'exporter:' + lab.state['exporter_password'] + '@tcp(' + lab.state['db_host'] + ':3306)/', True)
    finally:
        aws('ssm', 'delete-parameters', {'Names': ['/umc/app/bootstrap', '/umc/app/exporter-password']})
    print('Disposable exporter created; only lab database contains synthetic data.')

def tunnel():
    group = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [lab.state['asg']]})['AutoScalingGroups'][0]
    target = next(i['InstanceId'] for i in group['Instances'] if i['LifecycleState'] == 'InService')
    import subprocess
    subprocess.run(['aws', 'ssm', 'start-session', '--profile', lab.PROFILE, '--region', lab.REGION,
        '--target', target, '--document-name', 'AWS-StartPortForwardingSessionToRemoteHost',
        '--parameters', json.dumps({'host': [lab.state['alb_dns']], 'portNumber': ['80'], 'localPortNumber': ['9377']})], check=True)

def cleanup_start():
    if aws('sts', 'get-caller-identity')['Account'] != lab.state['account'] or lab.REGION != lab.state['region']:
        raise RuntimeError('Refusing cleanup in a different account or region')
    if lab.state.get('loadgen'):
        aws('ec2', 'terminate-instances', {'InstanceIds': [lab.state['loadgen']]})
    if lab.state.get('loadgen_sg'):
        try:
            raw_aws('ec2', 'revoke-security-group-ingress', {'GroupId': lab.state['alb_sg'], 'IpPermissions': [
                {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'UserIdGroupPairs': [{'GroupId': lab.state['loadgen_sg']}]}]})
        except RuntimeError as error:
            if not any(code in str(error) for code in ['InvalidPermission.NotFound', 'InvalidGroup.NotFound']): raise
    lab.cleanup_start()
    aws('ssm', 'delete-parameters', {'Names': ['/umc/app/' + k for k in [
        'gc-fleet-url', 'gc-fleet-user', 'gc-prom-url', 'gc-prom-user', 'gc-token', 'mysql-dsn', 'exporter-password'
    ]]})

def cleanup_finish():
    previous_root = lab.ROOT
    lab.ROOT = HERE
    try:
        if lab.state.get('account') and (aws('sts', 'get-caller-identity')['Account'] != lab.state['account'] or lab.REGION != lab.state['region']):
            raise RuntimeError('Refusing cleanup in a different account or region')
        # Private ALB ingress references app SG while app ingress references ALB:
        # remove this owned reverse reference before deleting either group.
        if lab.state.get('cleanup_requested') and lab.state.get('app_sg') and lab.state.get('alb_sg'):
            try:
                raw_aws('ec2', 'revoke-security-group-ingress', {'GroupId': lab.state['alb_sg'], 'IpPermissions': [
                    {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'UserIdGroupPairs': [{'GroupId': lab.state['app_sg']}]}]})
            except RuntimeError as error:
                if not any(code in str(error) for code in ['InvalidPermission.NotFound', 'InvalidGroup.NotFound']): raise
        lab.cleanup_finish()
        if lab.state.get('cleanup_complete'):
            def remove(service, operation, data):
                try: aws(service, operation, data)
                except RuntimeError as error:
                    if not any(code in str(error) for code in ['NoSuchEntity', 'InvalidGroup.NotFound']): raise
            if lab.state.get('loadgen_role'):
                name = lab.state['loadgen_role']
                remove('iam', 'remove-role-from-instance-profile', {'InstanceProfileName': name, 'RoleName': name})
                remove('iam', 'delete-instance-profile', {'InstanceProfileName': name})
                remove('iam', 'detach-role-policy', {'RoleName': name, 'PolicyArn': 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'})
                remove('iam', 'delete-role', {'RoleName': name})
            if lab.state.get('loadgen_sg'):
                remove('ec2', 'delete-security-group', {'GroupId': lab.state['loadgen_sg']})
            lab.state.pop('exporter_password', None)
            lab.save()
    finally:
        lab.ROOT = previous_root

if __name__ == '__main__':
    actions = {'inspect': inspect, 'foundation': foundation, 'settings': settings, 'exporter': exporter,
        'tunnel': tunnel, 'cleanup-start': cleanup_start, 'cleanup-finish': cleanup_finish}
    for name, function in [('status', lab.status), ('push-image', lab.push_image), ('baseline', lab.baseline),
        ('init-db', lab.init_db), ('end-baseline', lab.end_baseline), ('cluster', lab.cluster),
        ('targets', lab.targets), ('wait-cluster', lab.wait_cluster)]:
        actions[name] = function
    actions['status'] = status
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        raise SystemExit('Usage: cloud.py ' + '|'.join(actions))
    actions[sys.argv[1]]()
