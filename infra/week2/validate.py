#!/usr/bin/env python3
"""Actual offline validation via official containers; never creates cloud resources."""
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parent
results=[]
alloy='grafana/alloy:v1.20.1'
for name in ['config.alloy','pipelines/01-host-metrics.alloy','pipelines/02-mysql-metrics.alloy','pipelines/03-app-metrics.alloy']:
    command=['docker','run','--rm','--network','none','-v',str(ROOT)+':/config:ro',
        '-e','GC_FLEET_URL=https://example.invalid','-e','GC_FLEET_USER=placeholder',
        '-e','GC_PROM_URL=https://example.invalid/api/prom/push','-e','GC_PROM_USER=placeholder',
        '-e','GC_TOKEN=placeholder-not-real','-e','MYSQL_DSN=exporter:placeholder@tcp(127.0.0.1:3306)/',
        alloy,'validate','/config/'+name]
    run=subprocess.run(command,text=True,capture_output=True)
    results.append({'file':name,'image':alloy,'exitCode':run.returncode,'output':run.stdout+run.stderr,'network':'none'})
command=['docker','run','--rm','--network','none','--entrypoint','/bin/promtool','-v',str(ROOT)+':/config:ro',
    '-w','/config','prom/prometheus:v3.5.0','test','rules','alerts.test.yaml']
run=subprocess.run(command,text=True,capture_output=True)
results.append({'file':'alerts.test.yaml','image':'prom/prometheus:v3.5.0','exitCode':run.returncode,'output':run.stdout+run.stderr,'network':'none'})
(ROOT/'evidence/config-validation.json').write_text(json.dumps({'checks':results,'passed':all(r['exitCode']==0 for r in results)},indent=2)+'\n')
for r in results: print(r['file']+': '+('PASS' if r['exitCode']==0 else 'FAIL'))
raise SystemExit(0 if all(r['exitCode']==0 for r in results) else 1)
