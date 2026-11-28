#!/usr/bin/env python3
"""Collect non-secret, synthetic-lab CPU/DB samples through SSM."""
import base64
import gzip
import importlib.util
import json
from pathlib import Path
import shlex
import sys
import time

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('infra2_cloud', HERE / 'cloud.py')
cloud = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cloud)

def start():
    group = cloud.aws('autoscaling','describe-auto-scaling-groups',{'AutoScalingGroupNames':[cloud.lab.state['asg']]})['AutoScalingGroups'][0]
    encoded = base64.b64encode((HERE/'sample.cjs').read_bytes()).decode()
    js="const fs=require('fs');for(const p of fs.readdirSync('/proc').filter(x=>/^\\d+$/.test(x))){try{if(fs.readFileSync('/proc/'+p+'/cmdline','utf8').split('\\0')[1]==='/tmp/infra2-sample.cjs')process.kill(Number(p),'SIGTERM')}catch{}}"
    for instance in group['Instances']:
        cloud.lab.remote(instance['InstanceId'],[
            'docker exec app node -e '+shlex.quote(js),
            'echo '+encoded+' | base64 -d | docker exec -i app sh -c "cat > /tmp/infra2-sample.cjs"',
            'docker exec -d app node /tmp/infra2-sample.cjs',
        ])

def collect():
    group = cloud.aws('autoscaling', 'describe-auto-scaling-groups', {
        'AutoScalingGroupNames': [cloud.lab.state['asg']],
    })['AutoScalingGroups'][0]
    for instance in group['Instances']:
        instance_id = instance['InstanceId']
        js = "process.stdout.write(require('node:zlib').gzipSync(require('node:fs').readFileSync('/tmp/infra2-samples.jsonl')).toString('base64'))"
        command = cloud.aws('ssm', 'send-command', {
            'InstanceIds': [instance_id], 'DocumentName': 'AWS-RunShellScript',
            'Parameters': {'commands': ['docker exec app node -e ' + shlex.quote(js)]},
            'Comment': 'Collect non-secret Infra2 load observations',
        })['Command']['CommandId']
        for _ in range(30):
            try:
                result = cloud.aws('ssm', 'get-command-invocation', {'CommandId': command, 'InstanceId': instance_id})
            except RuntimeError:
                time.sleep(2)
                continue
            if result['Status'] == 'Success':
                raw = gzip.decompress(base64.b64decode(result['StandardOutputContent'].strip(), validate=True))
                rows = [json.loads(line) for line in raw.splitlines()]
                (HERE / 'evidence' / f'samples-{instance_id}.json').write_text(json.dumps(rows, indent=2) + '\n')
                print(instance_id, len(rows), 'non-secret samples saved')
                break
            if result['Status'] not in ['Pending', 'InProgress', 'Delayed']:
                raise RuntimeError('Observation collection failed: ' + result['Status'])
            time.sleep(2)
        else:
            raise TimeoutError('Observation collection timed out')

if __name__ == '__main__':
    start() if len(sys.argv)>1 and sys.argv[1]=='start' else collect()
