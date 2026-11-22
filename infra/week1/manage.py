#!/usr/bin/env python3
"""MovieLog disposable AWS lab. State/secrets stay in ignored .local (0600).

All AWS requests use the explicitly selected profile and region. No local DB
contents or existing passwords are uploaded. Never print request bodies.
"""
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import secrets
import base64
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
LOCAL = ROOT / '.local'
LOCAL.mkdir(mode=0o700, exist_ok=True)
STATE_FILE = LOCAL / 'state.json'
PROFILE = os.environ.get('MOVIELOG_AWS_PROFILE', 'umc-infra')
REGION = os.environ.get('MOVIELOG_AWS_REGION', 'ap-southeast-2')
state = json.loads(STATE_FILE.read_text()) if STATE_FILE.exists() else {}
PREFIX = 'movielog-infra1'
TAGS = [{'Key': 'Project', 'Value': PREFIX}, {'Key': 'Purpose', 'Value': 'UMC-Infra-week1-disposable'}]


def save():
    with os.fdopen(os.open(STATE_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), 'w') as f:
        json.dump(state, f, indent=2)


def aws(service, operation, data=None, **kwargs):
    if service == 'autoscaling' and operation == 'describe-auto-scaling-groups':
        data = {'IncludeInstances': True, 'IncludeManagedResources': True, **(data or {})}
    if service == 'autoscaling' and operation == 'describe-scaling-activities':
        data = {'IncludeManagedResources': True, **(data or {})}
    command = ['aws', service, operation, '--profile', PROFILE, '--region', REGION,
               '--output', 'json', '--no-cli-pager', '--cli-connect-timeout', '15', '--cli-read-timeout', '60']
    path = None
    try:
        if data is not None:
            with tempfile.NamedTemporaryFile(mode='w', dir=LOCAL, delete=False) as f:
                json.dump(data, f)
                path = f.name
            command += ['--cli-input-json', 'file://' + path]
        result = subprocess.run(command, capture_output=True, text=True, **kwargs)
        if result.returncode:
            raise RuntimeError(f'{service} {operation}: {result.stderr.strip()}')
        return json.loads(result.stdout) if result.stdout.strip() else {}
    finally:
        if path:
            pathlib.Path(path).unlink(missing_ok=True)


def inspect():
    identity = aws('sts', 'get-caller-identity')
    state['account'] = identity['Account']
    state['region'] = REGION
    vpcs = aws('ec2', 'describe-vpcs', {'Filters': [{'Name': 'isDefault', 'Values': ['true']}]})['Vpcs']
    if len(vpcs) != 1:
        raise RuntimeError('Expected exactly one default VPC')
    state['vpc'] = vpcs[0]['VpcId']
    subnets = aws('ec2', 'describe-subnets', {'Filters': [{'Name': 'vpc-id', 'Values': [state['vpc']]}]})['Subnets']
    state['subnets'] = [{'id': x['SubnetId'], 'az': x['AvailabilityZone']} for x in subnets if x['State'] == 'available']
    ami = aws('ssm', 'get-parameter', {'Name': '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64'})
    state['ami'] = ami['Parameter']['Value']
    versions = aws('rds', 'describe-db-engine-versions', {'Engine': 'mysql', 'DefaultOnly': True})['DBEngineVersions']
    state['db_engine'] = versions[0]['EngineVersion']
    options = aws('rds', 'describe-orderable-db-instance-options', {
        'Engine': 'mysql', 'EngineVersion': state['db_engine'], 'DBInstanceClass': 'db.t4g.micro'})['OrderableDBInstanceOptions']
    state['rds_option_count'] = len(options)
    save()
    print(json.dumps({k: state[k] for k in ['account', 'region', 'vpc', 'subnets', 'ami', 'db_engine', 'rds_option_count']}, indent=2))


def parameter(name, value, secret=False):
    aws('ssm', 'put-parameter', {'Name': '/umc/app/' + name,
        'Type': 'SecureString' if secret else 'String', 'Value': value, 'Overwrite': True})


def foundation():
    if aws('sts', 'get-caller-identity')['Account'] != state['account']:
        raise RuntimeError('Account changed; refusing to create resources')
    for key, suffix in [('alb_sg', 'alb'), ('app_sg', 'app'), ('db_sg', 'db')]:
        if key not in state:
            state[key] = aws('ec2', 'create-security-group', {
                'GroupName': PREFIX + '-' + suffix, 'Description': 'Disposable MovieLog Infra lab ' + suffix,
                'VpcId': state['vpc'], 'TagSpecifications': [{'ResourceType': 'security-group', 'Tags': TAGS}]})['GroupId']
            save()
    for key, port, source in [('alb_sg', 80, {'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'HTTP health probe only'}]}),
                              ('app_sg', 3000, {'UserIdGroupPairs': [{'GroupId': state['alb_sg']}]}),
                              ('db_sg', 3306, {'UserIdGroupPairs': [{'GroupId': state['app_sg']}]})]:
        try:
            aws('ec2', 'authorize-security-group-ingress', {'GroupId': state[key], 'IpPermissions': [
                {'IpProtocol': 'tcp', 'FromPort': port, 'ToPort': port, **source}]})
        except RuntimeError as e:
            if 'InvalidPermission.Duplicate' not in str(e):
                raise
    if 'repo' not in state:
        state['repo'] = aws('ecr', 'create-repository', {'repositoryName': 'movielog-infra-app',
            'imageTagMutability': 'IMMUTABLE', 'encryptionConfiguration': {'encryptionType': 'AES256'},
            'tags': TAGS})['repository']['repositoryUri']
        save()
    state.setdefault('master_password', secrets.token_urlsafe(30))
    state.setdefault('app_password', secrets.token_urlsafe(30))
    state.setdefault('jwt_secret', secrets.token_urlsafe(48))
    save()
    if 'db_subnet' not in state:
        state['db_subnet'] = aws('rds', 'create-db-subnet-group', {
            'DBSubnetGroupName': PREFIX, 'DBSubnetGroupDescription': 'Disposable private RDS',
            'SubnetIds': [s['id'] for s in state['subnets']], 'Tags': TAGS})['DBSubnetGroup']['DBSubnetGroupName']
        save()
    if 'db_id' not in state:
        result = aws('rds', 'create-db-instance', {'DBInstanceIdentifier': PREFIX,
            'DBInstanceClass': 'db.t4g.micro', 'Engine': 'mysql', 'EngineVersion': state['db_engine'],
            'EngineLifecycleSupport': 'open-source-rds-extended-support-disabled',
            'AllocatedStorage': 20, 'StorageType': 'gp3', 'StorageEncrypted': True,
            'DBName': 'umc_movie', 'MasterUsername': 'labadmin', 'MasterUserPassword': state['master_password'],
            'VpcSecurityGroupIds': [state['db_sg']], 'DBSubnetGroupName': state['db_subnet'],
            'PubliclyAccessible': False, 'MultiAZ': False, 'BackupRetentionPeriod': 0,
            'DeletionProtection': False, 'AutoMinorVersionUpgrade': True, 'Tags': TAGS})
        state['db_id'] = result['DBInstance']['DBInstanceIdentifier']
        save()
        print('RDS creation requested (private, encrypted, Single-AZ).', flush=True)
    if 'role' not in state:
        trust = {'Version': '2012-10-17', 'Statement': [{'Effect': 'Allow',
                 'Principal': {'Service': 'ec2.amazonaws.com'}, 'Action': 'sts:AssumeRole'}]}
        state['role'] = aws('iam', 'create-role', {'RoleName': PREFIX, 'AssumeRolePolicyDocument': json.dumps(trust), 'Tags': TAGS})['Role']['RoleName']
        save()
    aws('iam', 'attach-role-policy', {'RoleName': state['role'],
        'PolicyArn': 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'})
    account = state['account']
    policy = {'Version': '2012-10-17', 'Statement': [
        {'Effect': 'Allow', 'Action': ['ecr:GetAuthorizationToken'], 'Resource': '*'},
        {'Effect': 'Allow', 'Action': ['ecr:BatchGetImage', 'ecr:GetDownloadUrlForLayer', 'ecr:BatchCheckLayerAvailability'],
         'Resource': f'arn:aws:ecr:{REGION}:{account}:repository/movielog-infra-app'},
        {'Effect': 'Allow', 'Action': ['ssm:GetParameter', 'ssm:GetParameters'],
         'Resource': f'arn:aws:ssm:{REGION}:{account}:parameter/umc/app/*'},
        # The SSM agent managed policy also grants GetParameter on '*'. An
        # explicit deny keeps that managed grant inside our approved prefix.
        {'Effect': 'Deny', 'Action': ['ssm:GetParameter', 'ssm:GetParameters'],
         'NotResource': f'arn:aws:ssm:{REGION}:{account}:parameter/umc/app/*'},
        {'Effect': 'Allow', 'Action': ['kms:Decrypt'], 'Resource': '*', 'Condition': {
            'StringEquals': {'kms:ViaService': f'ssm.{REGION}.amazonaws.com'},
            'StringLike': {'kms:EncryptionContext:PARAMETER_ARN': f'arn:aws:ssm:{REGION}:{account}:parameter/umc/app/*'}}},
    ]}
    aws('iam', 'put-role-policy', {'RoleName': state['role'], 'PolicyName': 'MovieLogLabReadOnly', 'PolicyDocument': json.dumps(policy)})
    if 'instance_profile' not in state:
        state['instance_profile'] = aws('iam', 'create-instance-profile', {'InstanceProfileName': PREFIX, 'Tags': TAGS})['InstanceProfile']['InstanceProfileName']
        save()
        aws('iam', 'add-role-to-instance-profile', {'InstanceProfileName': PREFIX, 'RoleName': state['role']})
    parameter('db-user', 'movielog_app')
    parameter('db-name', 'umc_movie')
    parameter('db-password', state['app_password'], True)
    parameter('jwt-secret', state['jwt_secret'], True)
    print('Foundation requested; IAM permissions scoped to this lab and parameter prefix.', flush=True)


def status():
    result = {}
    if 'db_id' in state:
        db = aws('rds', 'describe-db-instances', {'DBInstanceIdentifier': state['db_id']})['DBInstances'][0]
        result['rds'] = db['DBInstanceStatus']
        if 'Endpoint' in db:
            state['db_host'] = db['Endpoint']['Address']
            save()
    if 'baseline' in state:
        inst = aws('ec2', 'describe-instances', {'InstanceIds': [state['baseline']]})['Reservations'][0]['Instances'][0]
        result['baseline'] = {'id': inst['InstanceId'], 'state': inst['State']['Name'], 'publicIp': inst.get('PublicIpAddress')}
        state['baseline_ip'] = inst.get('PublicIpAddress')
        save()
    print(json.dumps(result, indent=2), flush=True)


def push_image():
    tag = os.environ.get('MOVIELOG_IMAGE_TAG', 'v0.1.0-26-11-22-1')
    image = state['repo'] + ':' + tag
    auth = aws('ecr', 'get-authorization-token')['authorizationData'][0]
    username, password = base64.b64decode(auth['authorizationToken']).decode().split(':', 1)
    login = subprocess.run(['docker', 'login', '--username', username, '--password-stdin', state['repo'].split('/')[0]],
        input=password, text=True, capture_output=True)
    if login.returncode:
        raise RuntimeError('ECR Docker login failed')
    subprocess.run(['docker', 'tag', 'movielog-infra:' + tag, image], check=True)
    subprocess.run(['docker', 'push', image], check=True)
    key = 'fault_image' if os.environ.get('MOVIELOG_IMAGE_KIND') == 'fault' else 'good_image'
    state[key] = image
    save()
    if key == 'good_image':
        parameter('image', image)
    print('Versioned image pushed; no env files were included.', flush=True)


def end_baseline():
    instance = aws('ec2', 'describe-instances', {'InstanceIds': [state['baseline']]})['Reservations'][0]['Instances'][0]
    if not any(t['Key'] == 'Project' and t['Value'] == PREFIX for t in instance.get('Tags', [])):
        raise RuntimeError('Refusing to terminate an instance without our lab tag')
    if instance['State']['Name'] not in ('terminated', 'shutting-down'):
        aws('ec2', 'terminate-instances', {'InstanceIds': [state['baseline']]})
    if 'probe_cidr' in state:
        try:
            aws('ec2', 'revoke-security-group-ingress', {'GroupId': state['app_sg'], 'IpPermissions': [
                {'IpProtocol': 'tcp', 'FromPort': 3000, 'ToPort': 3000, 'IpRanges': [{'CidrIp': state['probe_cidr']}]}]})
        except RuntimeError as e:
            if 'InvalidPermission.NotFound' not in str(e):
                raise
    print('Before-measurement instance termination requested; direct ingress revoked.', flush=True)


def cluster():
    for attempt in range(48):
        inst = aws('ec2', 'describe-instances', {'InstanceIds': [state['baseline']]})['Reservations'][0]['Instances'][0]
        if inst['State']['Name'] == 'terminated':
            break
        if attempt == 47:
            raise TimeoutError('Baseline termination did not finish; refusing extra instances')
        time.sleep(5)
    if 'tg' not in state:
        tg = aws('elbv2', 'create-target-group', {'Name': PREFIX + '-tg', 'Protocol': 'HTTP', 'Port': 3000,
            'VpcId': state['vpc'], 'TargetType': 'instance', 'HealthCheckProtocol': 'HTTP',
            'HealthCheckPort': 'traffic-port', 'HealthCheckPath': '/health', 'HealthCheckIntervalSeconds': 5,
            'HealthCheckTimeoutSeconds': 3, 'HealthyThresholdCount': 2, 'UnhealthyThresholdCount': 2,
            'Matcher': {'HttpCode': '200'}, 'Tags': TAGS})['TargetGroups'][0]
        state['tg'] = tg['TargetGroupArn']
        save()
    aws('elbv2', 'modify-target-group-attributes', {'TargetGroupArn': state['tg'],
        'Attributes': [{'Key': 'deregistration_delay.timeout_seconds', 'Value': '30'}]})
    if 'alb' not in state:
        alb = aws('elbv2', 'create-load-balancer', {'Name': PREFIX + '-alb', 'Subnets': [s['id'] for s in state['subnets']],
            'SecurityGroups': [state['alb_sg']], 'Scheme': 'internet-facing', 'Type': 'application',
            'IpAddressType': 'ipv4', 'Tags': TAGS})['LoadBalancers'][0]
        state['alb'] = alb['LoadBalancerArn']
        state['alb_dns'] = alb['DNSName']
        save()
    if 'listener' not in state:
        state['listener'] = aws('elbv2', 'create-listener', {'LoadBalancerArn': state['alb'], 'Protocol': 'HTTP', 'Port': 80,
            'DefaultActions': [{'Type': 'fixed-response', 'FixedResponseConfig': {'StatusCode': '404', 'ContentType': 'text/plain', 'MessageBody': 'Health probe endpoint only'}}]})['Listeners'][0]['ListenerArn']
        save()
    if 'rule' not in state:
        state['rule'] = aws('elbv2', 'create-rule', {'ListenerArn': state['listener'], 'Priority': 10,
            'Conditions': [{'Field': 'path-pattern', 'PathPatternConfig': {'Values': ['/health']}}],
            'Actions': [{'Type': 'forward', 'TargetGroupArn': state['tg']}]})['Rules'][0]['RuleArn']
        save()
    if 'lt' not in state:
        state['lt'] = aws('ec2', 'create-launch-template', {'LaunchTemplateName': PREFIX + '-lt',
            'VersionDescription': 'AL2023 ARM64, SSM bootstrap, no embedded secrets',
            'LaunchTemplateData': {'ImageId': state['ami'], 'InstanceType': 't4g.micro',
                'IamInstanceProfile': {'Name': state['instance_profile']}, 'UserData': user_data(),
                'NetworkInterfaces': [{'DeviceIndex': 0, 'AssociatePublicIpAddress': True, 'Groups': [state['app_sg']]}],
                'MetadataOptions': {'HttpTokens': 'required', 'HttpPutResponseHopLimit': 1},
                'CreditSpecification': {'CpuCredits': 'standard'},
                'BlockDeviceMappings': [{'DeviceName': '/dev/xvda', 'Ebs': {'VolumeSize': 8, 'VolumeType': 'gp3', 'Encrypted': True, 'DeleteOnTermination': True}}],
                'TagSpecifications': [{'ResourceType': 'instance', 'Tags': TAGS}, {'ResourceType': 'volume', 'Tags': TAGS}]},
            'TagSpecifications': [{'ResourceType': 'launch-template', 'Tags': TAGS}]})['LaunchTemplate']['LaunchTemplateId']
        save()
    if 'asg' not in state:
        aws('autoscaling', 'create-auto-scaling-group', {'AutoScalingGroupName': PREFIX + '-asg',
            'LaunchTemplate': {'LaunchTemplateId': state['lt'], 'Version': '$Latest'},
            'MinSize': 2, 'MaxSize': 4, 'DesiredCapacity': 2,
            'VPCZoneIdentifier': ','.join(s['id'] for s in state['subnets']), 'TargetGroupARNs': [state['tg']],
            'HealthCheckType': 'EC2', 'HealthCheckGracePeriod': 180,
            'Tags': [{**t, 'PropagateAtLaunch': True} for t in TAGS]})
        state['asg'] = PREFIX + '-asg'
        save()
    print('ALB /health-only listener and two-node ASG requested.', flush=True)


def targets():
    result = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg']})['TargetHealthDescriptions']
    print(json.dumps([{'instance': x['Target']['Id'], 'state': x['TargetHealth']['State'], 'reason': x['TargetHealth'].get('Reason')} for x in result], indent=2), flush=True)
    return result


def cluster_status():
    group = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [state['asg']]})['AutoScalingGroups'][0]
    print(json.dumps(group, indent=2))
    activities = aws('autoscaling', 'describe-scaling-activities', {'AutoScalingGroupName': state['asg'], 'MaxRecords': 5})['Activities']
    print(json.dumps([{k: a.get(k) for k in ['StatusCode', 'Description', 'StatusMessage']} for a in activities], indent=2))
    targets()


def reconcile_cluster():
    role = aws('iam', 'get-role', {'RoleName': 'AWSServiceRoleForAutoScaling'})['Role']
    print('Auto Scaling service-linked role exists:', role['RoleName'], flush=True)
    aws('autoscaling', 'set-desired-capacity', {'AutoScalingGroupName': state['asg'], 'DesiredCapacity': 2, 'HonorCooldown': False})
    print('Reasserted desired capacity 2 without increasing the approved size.', flush=True)


def network_inventory():
    addresses = aws('ec2', 'describe-addresses')['Addresses']
    nats = aws('ec2', 'describe-nat-gateways', {'Filter': [{'Name': 'vpc-id', 'Values': [state['vpc']]}]})['NatGateways']
    print(json.dumps({'addresses': addresses, 'natGateways': nats}, indent=2, default=str))


def cluster_boot_log():
    group = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [state['asg']]})['AutoScalingGroups'][0]
    for item in group['Instances']:
        remote(item['InstanceId'], ['cloud-init status --long || true', 'tail -35 /var/log/movielog-boot.log || true',
            "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Image}}' || true"])


def wait_target(instance_id, wanted, deadline=300):
    end = time.monotonic() + deadline
    while time.monotonic() < end:
        result = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg'], 'Targets': [{'Id': instance_id}]})['TargetHealthDescriptions']
        current = result[0]['TargetHealth'] if result else {'State': 'unused'}
        if wanted == 'drained' and (current['State'] == 'unused' or current.get('Reason') == 'Target.NotRegistered'):
            return
        if current['State'] == wanted:
            return
        time.sleep(5)
    raise TimeoutError(f'Target {instance_id} did not become {wanted}')


def wait_cluster():
    for attempt in range(90):
        health = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg']})['TargetHealthDescriptions']
        if len(health) == 2 and all(x['TargetHealth']['State'] == 'healthy' for x in health):
            print('Both AWS targets are healthy. Measurement may begin.', flush=True)
            targets()
            return
        if attempt % 6 == 0:
            print('Waiting for initial readiness:', [(x['Target']['Id'], x['TargetHealth']['State']) for x in health], flush=True)
        time.sleep(10)
    raise TimeoutError('Two-node initial readiness timed out; do not start a measurement')


def deploy():
    image = os.environ.get('MOVIELOG_DEPLOY_IMAGE', state['good_image'])
    if not image.startswith(state['repo'] + ':'):
        raise RuntimeError('Only this lab repository may be deployed')
    previous = aws('ssm', 'get-parameter', {'Name': '/umc/app/image'})['Parameter']['Value']
    group = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [state['asg']]})['AutoScalingGroups'][0]
    ids = [x['InstanceId'] for x in group['Instances'] if x['LifecycleState'] == 'InService']
    if len(ids) < 2:
        raise RuntimeError('Rolling deploy requires at least two InService instances')
    initial_health = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg']})['TargetHealthDescriptions']
    healthy_ids = {x['Target']['Id'] for x in initial_health if x['TargetHealth']['State'] == 'healthy'}
    # Recover an out-of-service node before touching its one remaining peer.
    ids.sort(key=lambda instance_id: (instance_id in healthy_ids, instance_id))
    state['cluster_ids'] = ids
    save()
    parameter('image', image)
    try:
        for instance_id in ids:
            health = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg']})['TargetHealthDescriptions']
            if not any(x['Target']['Id'] != instance_id and x['TargetHealth']['State'] == 'healthy' for x in health):
                raise RuntimeError('No healthy peer; refusing to take this instance out')
            print('DRAIN ' + instance_id, flush=True)
            aws('elbv2', 'deregister-targets', {'TargetGroupArn': state['tg'], 'Targets': [{'Id': instance_id}]})
            wait_target(instance_id, 'drained')
            print('SWAP ' + instance_id, flush=True)
            remote(instance_id, ['bash /opt/umc/swap.sh'])
            aws('elbv2', 'register-targets', {'TargetGroupArn': state['tg'], 'Targets': [{'Id': instance_id}]})
            wait_target(instance_id, 'healthy')
            print('HEALTHY ' + instance_id, flush=True)
    except Exception:
        parameter('image', previous)
        print('STOPPED: next instance was not touched; launch image pointer restored. Explicit rollback is required for the failed node.', flush=True)
        raise
    print('ROLLING COMPLETE ' + image, flush=True)


def user_data(start_app=True):
    swap = base64.b64encode((ROOT / 'swap.sh').read_bytes()).decode()
    script = f'''#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/movielog-boot.log) 2>&1
dnf install -y docker
command -v aws
systemctl enable --now docker
mkdir -p /opt/umc
printf 'AWS_REGION={REGION}\\n' > /opt/umc/region.env
echo {swap} | base64 -d > /opt/umc/swap.sh
chmod 700 /opt/umc/swap.sh
for attempt in $(seq 1 10); do
  if /opt/umc/swap.sh; then exit 0; fi
  sleep 10
done
exit 1
'''
    if not start_app:
        script = script[:script.index('for attempt in $(seq 1 10)')]
    return base64.b64encode(script.encode()).decode()


def baseline():
    db = aws('rds', 'describe-db-instances', {'DBInstanceIdentifier': state['db_id']})['DBInstances'][0]
    if db['DBInstanceStatus'] != 'available':
        print('RDS is still ' + db['DBInstanceStatus'] + '; retry baseline after it becomes available.')
        return
    state['db_host'] = db['Endpoint']['Address']
    save()
    parameter('db-host', state['db_host'])
    parameter('bootstrap', state['master_password'], True)
    if 'probe_cidr' not in state:
        import ipaddress
        ip = urllib.request.urlopen('https://checkip.amazonaws.com', timeout=15).read().decode().strip()
        ipaddress.IPv4Address(ip)
        state['probe_cidr'] = ip + '/32'
        save()
    try:
        aws('ec2', 'authorize-security-group-ingress', {'GroupId': state['app_sg'], 'IpPermissions': [
            {'IpProtocol': 'tcp', 'FromPort': 3000, 'ToPort': 3000,
             'IpRanges': [{'CidrIp': state['probe_cidr'], 'Description': 'Temporary before measurement probe'}]}]})
    except RuntimeError as e:
        if 'InvalidPermission.Duplicate' not in str(e):
            raise
    if 'baseline' not in state:
        result = aws('ec2', 'run-instances', {'ImageId': state['ami'], 'InstanceType': 't4g.micro',
            'MinCount': 1, 'MaxCount': 1, 'ClientToken': PREFIX + '-baseline',
            'IamInstanceProfile': {'Name': state['instance_profile']},
            'NetworkInterfaces': [{'DeviceIndex': 0, 'SubnetId': state['subnets'][0]['id'],
                'AssociatePublicIpAddress': True, 'Groups': [state['app_sg']]}],
            'MetadataOptions': {'HttpTokens': 'required', 'HttpPutResponseHopLimit': 1},
            'BlockDeviceMappings': [{'DeviceName': '/dev/xvda', 'Ebs': {'VolumeSize': 8, 'VolumeType': 'gp3', 'Encrypted': True, 'DeleteOnTermination': True}}],
            'CreditSpecification': {'CpuCredits': 'standard'}, 'UserData': user_data(False),
            'TagSpecifications': [{'ResourceType': 'instance', 'Tags': TAGS + [{'Key': 'Name', 'Value': PREFIX + '-baseline'}]},
                {'ResourceType': 'volume', 'Tags': TAGS}]})
        state['baseline'] = result['Instances'][0]['InstanceId']
        save()
    print('Baseline EC2 requested; DB schema initialization follows via SSM.', flush=True)


def remote(instance_id, commands, wait=True):
    result = aws('ssm', 'send-command', {'InstanceIds': [instance_id], 'DocumentName': 'AWS-RunShellScript',
        'Parameters': {'commands': commands, 'executionTimeout': ['900']}, 'TimeoutSeconds': 120,
        'Comment': 'MovieLog disposable Infra week1'})
    command_id = result['Command']['CommandId']
    state['last_command'] = {'id': command_id, 'instance': instance_id}
    save()
    print('SSM command ' + command_id + ' on ' + instance_id, flush=True)
    if not wait:
        return command_id
    for _ in range(100):
        inv = aws('ssm', 'list-command-invocations', {'CommandId': command_id, 'Details': True})['CommandInvocations']
        if inv:
            status = inv[0]['Status']
            if status == 'Success':
                output = inv[0]['CommandPlugins'][0].get('Output', '')
                print(output[-5000:], flush=True)
                return command_id
            if status not in ('Pending', 'InProgress', 'Delayed'):
                raise RuntimeError('SSM command failed: ' + status + '; inspect command ' + command_id)
        time.sleep(5)
    raise TimeoutError('SSM command deadline exceeded; command ' + command_id)


def diagnose():
    data = {'CommandId': state['last_command']['id']} if 'last_command' in state else {'InstanceId': state['baseline']}
    result = aws('ssm', 'list-command-invocations', {**data, 'Details': True})['CommandInvocations']
    for inv in result[:3]:
        print(inv['CommandId'], inv['Status'])
        for plugin in inv.get('CommandPlugins', []):
            print(plugin.get('Output', '')[-10000:])


def boot_log():
    remote(state['baseline'], ['cloud-init status --long || true', 'tail -60 /var/log/movielog-boot.log || true', 'command -v aws || true'])


def repair_boot():
    script = base64.b64encode(base64.b64decode(user_data(False))).decode()
    remote(state['baseline'], ['echo ' + script + ' | base64 -d > /tmp/movielog-repair.sh', 'bash /tmp/movielog-repair.sh'])


def audit():
    evidence = ROOT / 'evidence'
    evidence.mkdir(exist_ok=True)
    result = {'region': REGION, 'observedAt': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()}
    db = aws('rds', 'describe-db-instances', {'DBInstanceIdentifier': state['db_id']})['DBInstances'][0]
    result['database'] = {k: db.get(k) for k in ['DBInstanceIdentifier', 'Engine', 'EngineVersion', 'DBInstanceStatus',
        'DBInstanceClass', 'AllocatedStorage', 'MultiAZ', 'PubliclyAccessible', 'StorageEncrypted', 'BackupRetentionPeriod', 'MonitoringInterval']}
    result['securityGroups'] = aws('ec2', 'describe-security-groups', {'GroupIds': [state['alb_sg'], state['app_sg'], state['db_sg']]})['SecurityGroups']
    interfaces = aws('ec2', 'describe-network-interfaces', {'Filters': [{'Name': 'group-id', 'Values': [state['alb_sg']]}]})['NetworkInterfaces']
    interface_ids = {x['NetworkInterfaceId'] for x in interfaces}
    state['alb_address_ids'] = [a['AllocationId'] for a in aws('ec2', 'describe-addresses')['Addresses']
        if a.get('NetworkInterfaceId') in interface_ids]
    save()
    result['parameters'] = [{'name': p['Name'], 'type': p['Type']} for p in aws('ssm', 'describe-parameters', {
        'ParameterFilters': [{'Key': 'Name', 'Option': 'BeginsWith', 'Values': ['/umc/app/']}]})['Parameters']]
    if 'asg' in state:
        group = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [state['asg']]})['AutoScalingGroups'][0]
        result['autoScaling'] = {k: group[k] for k in ['AutoScalingGroupName', 'MinSize', 'MaxSize', 'DesiredCapacity', 'HealthCheckType', 'Instances']}
        result['targets'] = aws('elbv2', 'describe-target-health', {'TargetGroupArn': state['tg']})['TargetHealthDescriptions']
        result['targetAttributes'] = aws('elbv2', 'describe-target-group-attributes', {'TargetGroupArn': state['tg']})['Attributes']
        result['instanceChecks'] = []
        for instance in group['Instances']:
            command_id = remote(instance['InstanceId'], ["docker inspect --format 'Image={{.Config.Image}} Status={{.State.Status}} Health={{.State.Health.Status}} User={{.Config.User}}' app",
                "curl --silent --max-time 5 -w '\\nHTTP %{http_code}\\n' http://127.0.0.1:3000/health",
                "cloud-init status --long || true",
                'aws sts get-caller-identity --region ' + REGION + ' --query Arn --output text',
                'aws ssm get-parameter --region ' + REGION + ' --name /umc/app/image --query Parameter.Name --output text',
                'if aws ssm get-parameter --region ' + REGION + ' --name /outside-lab/permission-probe --query Parameter.Name --output text >/tmp/movielog-permission-out 2>/tmp/movielog-permission-error; then echo "Unexpected outside-prefix access"; exit 1; else grep -q AccessDenied /tmp/movielog-permission-error || exit 1; echo "Outside-prefix access: DENIED"; fi'])
            invocation = aws('ssm', 'list-command-invocations', {'CommandId': command_id, 'Details': True})['CommandInvocations'][0]
            result['instanceChecks'].append({'instance': instance['InstanceId'], 'commandId': command_id,
                'status': invocation['Status'], 'output': invocation['CommandPlugins'][0].get('Output', '')})
    scope = f'arn:aws:ssm:{REGION}:{state["account"]}:parameter'
    simulation = aws('iam', 'simulate-principal-policy', {
        'PolicySourceArn': f'arn:aws:iam::{state["account"]}:role/{state["role"]}',
        'ActionNames': ['ssm:GetParameter'], 'ResourceArns': [scope + '/umc/app/image', scope + '/outside-lab/example']})
    result['parameterScopeSimulation'] = [{'resource': x['EvalResourceName'], 'decision': x['EvalDecision']} for x in simulation['EvaluationResults']]
    result['parameterScopeEvidenceNote'] = 'Runtime EC2 role checks in instanceChecks are authoritative; simulator may return ARN placeholders.'
    (evidence / 'aws-configuration.json').write_text(json.dumps(result, indent=2))
    print('Saved non-secret AWS configuration evidence.', flush=True)


def cleanup_start():
    # Only IDs recorded by this lab are removed. The default VPC/subnets and
    # pre-existing local/remote databases are never deletion candidates.
    if aws('sts', 'get-caller-identity')['Account'] != state['account'] or REGION != state['region']:
        raise RuntimeError('Refusing cleanup in a different account or region')
    if state.get('asg'):
        groups = aws('autoscaling', 'describe-auto-scaling-groups', {'AutoScalingGroupNames': [state['asg']]})['AutoScalingGroups']
        if groups:
            aws('autoscaling', 'update-auto-scaling-group', {'AutoScalingGroupName': state['asg'], 'MinSize': 0, 'DesiredCapacity': 0})
            aws('autoscaling', 'delete-auto-scaling-group', {'AutoScalingGroupName': state['asg'], 'ForceDelete': True})
    if state.get('baseline'):
        try:
            aws('ec2', 'terminate-instances', {'InstanceIds': [state['baseline']]})
        except RuntimeError as e:
            if 'InvalidInstanceID.NotFound' not in str(e):
                raise
    if state.get('alb'):
        aws('elbv2', 'delete-load-balancer', {'LoadBalancerArn': state['alb']})
    if state.get('db_id'):
        db = aws('rds', 'describe-db-instances', {'DBInstanceIdentifier': state['db_id']})['DBInstances'][0]
        if db['DBInstanceStatus'] != 'deleting':
            aws('rds', 'delete-db-instance', {'DBInstanceIdentifier': state['db_id'], 'SkipFinalSnapshot': True, 'DeleteAutomatedBackups': True})
    names = ['/umc/app/' + n for n in ['image', 'db-host', 'db-user', 'db-name', 'db-password', 'jwt-secret', 'bootstrap']]
    aws('ssm', 'delete-parameters', {'Names': names})
    if state.get('repo'):
        aws('ecr', 'delete-repository', {'repositoryName': state['repo'].split('/', 1)[1], 'force': True})
    if state.get('lt'):
        aws('ec2', 'delete-launch-template', {'LaunchTemplateId': state['lt']})
    state['cleanup_requested'] = True
    save()
    print('Billable resource deletion requested. Final cleanup must verify completion.', flush=True)


def cleanup_finish():
    if aws('sts', 'get-caller-identity')['Account'] != state['account'] or REGION != state['region']:
        raise RuntimeError('Refusing cleanup in a different account or region')
    instances = aws('ec2', 'describe-instances', {'Filters': [{'Name': 'tag:Project', 'Values': [PREFIX]},
        {'Name': 'instance-state-name', 'Values': ['pending', 'running', 'stopping', 'stopped', 'shutting-down']}]})['Reservations']
    dbs = aws('rds', 'describe-db-instances')['DBInstances']
    lbs = aws('elbv2', 'describe-load-balancers')['LoadBalancers']
    volumes = aws('ec2', 'describe-volumes', {'Filters': [{'Name': 'tag:Project', 'Values': [PREFIX]}]})['Volumes']
    addresses = aws('ec2', 'describe-addresses')['Addresses']
    leftover_addresses = [x for x in addresses if x['AllocationId'] in state.get('alb_address_ids', [])]
    if instances or volumes or leftover_addresses or any(x['DBInstanceIdentifier'] == state.get('db_id') for x in dbs) or any(x['LoadBalancerArn'] == state.get('alb') for x in lbs):
        print('Deletion is still in progress. Retry cleanup-finish later.', flush=True)
        return
    def remove(service, operation, data, missing):
        try:
            aws(service, operation, data)
        except RuntimeError as e:
            if not any(x in str(e) for x in missing):
                raise
    if state.get('tg'):
        remove('elbv2', 'delete-target-group', {'TargetGroupArn': state['tg']}, ['TargetGroupNotFound'])
    if state.get('db_subnet'):
        remove('rds', 'delete-db-subnet-group', {'DBSubnetGroupName': state['db_subnet']}, ['DBSubnetGroupNotFoundFault'])
    if state.get('instance_profile'):
        remove('iam', 'remove-role-from-instance-profile', {'InstanceProfileName': state['instance_profile'], 'RoleName': state['role']}, ['NoSuchEntity'])
        remove('iam', 'delete-instance-profile', {'InstanceProfileName': state['instance_profile']}, ['NoSuchEntity'])
    if state.get('role'):
        remove('iam', 'detach-role-policy', {'RoleName': state['role'], 'PolicyArn': 'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'}, ['NoSuchEntity'])
        remove('iam', 'delete-role-policy', {'RoleName': state['role'], 'PolicyName': 'MovieLogLabReadOnly'}, ['NoSuchEntity'])
        remove('iam', 'delete-role', {'RoleName': state['role']}, ['NoSuchEntity'])
    # Drop references before deleting groups, so the DB -> app -> ALB relation
    # does not keep an otherwise unused group alive.
    for key in ['db_sg', 'app_sg', 'alb_sg']:
        if state.get(key):
            remove('ec2', 'delete-security-group', {'GroupId': state[key]}, ['InvalidGroup.NotFound'])
    for key in ['master_password', 'app_password', 'jwt_secret']:
        state.pop(key, None)
    state['cleanup_complete'] = True
    save()
    report = {'checkedAt': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat(),
        'region': REGION, 'activeLabEC2': 0, 'labRDS': 0, 'labALB': 0,
        'labEBSVolumes': 0, 'labALBPublicIPs': 0,
        'temporarySecretsRemovedFromLocalState': True, 'defaultVpcAndSubnetsPreserved': True}
    (ROOT / 'evidence/cleanup.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2), flush=True)


def init_db():
    for attempt in range(48):
        info = aws('ssm', 'describe-instance-information', {'Filters': [{'Key': 'InstanceIds', 'Values': [state['baseline']]}]})['InstanceInformationList']
        if info and info[0]['PingStatus'] == 'Online':
            break
        if attempt == 47:
            raise TimeoutError('Baseline instance did not become SSM Online')
        time.sleep(5)
    schema = (ROOT.parents[1] / 'movie-backend/sql/01_schema.sql').read_text()
    # DDL is public repository content. Secrets are fetched on the instance and
    # passed through a root-only environment file, never through command history.
    node_script = '''const fs=require('fs'); const mysql=require('mysql2/promise');
(async()=>{const db=await mysql.createConnection({host:process.env.DB_HOST,user:'labadmin',password:process.env.MASTER_PASSWORD,multipleStatements:true});
await db.query(Buffer.from(process.env.SCHEMA_B64,'base64').toString());
await db.query("CREATE USER IF NOT EXISTS 'movielog_app'@'%' IDENTIFIED BY ?",[process.env.APP_PASSWORD]);
await db.query("GRANT SELECT,INSERT,UPDATE,DELETE ON umc_movie.* TO 'movielog_app'@'%'");
const [tables]=await db.query('SHOW TABLES FROM umc_movie');console.log('Initialized tables:',tables.length);await db.end();
})().catch(()=>{console.error('DB initialization failed');process.exit(1)});
'''
    env_builder = '''import json,subprocess,os
os.umask(0o077)
def p(k):
 return json.loads(subprocess.check_output(['aws','ssm','get-parameter','--region','REGION','--name','/umc/app/'+k,'--with-decryption']))['Parameter']['Value']
with open('/opt/umc/init.env','w') as f:
 for k,v in [('DB_HOST',p('db-host')),('MASTER_PASSWORD',p('bootstrap')),('APP_PASSWORD',p('db-password'))]: f.write(k+'='+v+'\\n')
'''.replace('REGION', REGION)
    commands = ['set -euo pipefail', 'cloud-init status --wait || test -x /opt/umc/swap.sh', 'mkdir -p /opt/umc',
        'echo ' + base64.b64encode(env_builder.encode()).decode() + ' | base64 -d | python3',
        'echo SCHEMA_B64=' + base64.b64encode(schema.encode()).decode() + ' >> /opt/umc/init.env',
        'IMAGE=$(aws ssm get-parameter --region ' + REGION + ' --name /umc/app/image --query Parameter.Value --output text)',
        'aws ecr get-login-password --region ' + REGION + ' | docker login --username AWS --password-stdin "${IMAGE%%/*}" >/dev/null',
        'docker pull "$IMAGE" >/dev/null',
        "docker run --rm --env-file /opt/umc/init.env --entrypoint node \"$IMAGE\" -e " + __import__('shlex').quote(node_script),
        'rm -f /opt/umc/init.env', '/opt/umc/swap.sh']
    remote(state['baseline'], ['bash -c ' + __import__('shlex').quote('\n'.join(commands))])
    aws('ssm', 'delete-parameter', {'Name': '/umc/app/bootstrap'})
    print('Bootstrap master parameter removed. Application uses DML-only DB user.', flush=True)


if __name__ == '__main__':
    {'inspect': inspect, 'foundation': foundation, 'status': status, 'push-image': push_image,
     'baseline': baseline, 'init-db': init_db, 'end-baseline': end_baseline,
     'cluster': cluster, 'targets': targets, 'deploy': deploy, 'diagnose': diagnose,
     'boot-log': boot_log, 'repair-boot': repair_boot, 'audit': audit,
     'cluster-status': cluster_status, 'reconcile-cluster': reconcile_cluster,
     'network-inventory': network_inventory,
     'cluster-boot-log': cluster_boot_log,
     'wait-cluster': wait_cluster,
     'cleanup-start': cleanup_start, 'cleanup-finish': cleanup_finish}[sys.argv[1]]()
