#!/usr/bin/env python3
"""Run ONE workbook stage through an explicit local SSM tunnel.
Raw tokens/scenarios remain .local. Public exports are recursively redacted.
"""
import json
import os
from pathlib import Path
import secrets
import sys
import time
import urllib.error
import urllib.request

HERE = Path(__file__).resolve().parent
LOCAL = HERE / '.local'
LOCAL.mkdir(mode=0o700, exist_ok=True)
API = 'http://127.0.0.1:9376/api'
TARGET = 'http://127.0.0.1:9377'

def save_private(path, value):
    with os.fdopen(os.open(path, os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600),'w') as f:
        json.dump(value,f)

def call(url, body=None, token=None):
    req=urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None,
        headers={'Content-Type':'application/json', **({'Authorization':'Bearer '+token} if token else {})})
    with urllib.request.urlopen(req,timeout=15) as res:
        return res.status,json.load(res)

def redact(value, secret_values=()):
    if isinstance(value,dict):
        return {k: '[REDACTED]' if k.lower() in ['authorization','password','accesstoken','token'] else redact(v,secret_values) for k,v in value.items()}
    if isinstance(value,list): return [redact(v,secret_values) for v in value]
    if isinstance(value,str):
        for secret in secret_values:
            if secret: value=value.replace(secret,'[REDACTED]')
    return value

def prepare(rps):
    if rps not in [200,400,600,800]:
        raise ValueError('Only workbook stages 200/400/600/800 are allowed.')
    path=LOCAL/f'stage-{rps}.json'
    if path.exists(): raise RuntimeError('Stage already prepared. Never reuse its member/counter; archive state first.')
    prefix='i2'+secrets.token_hex(4)
    password='Aa9!'+secrets.token_hex(16)
    email=prefix+'@example.com'
    status,member=call(TARGET+'/members',{'email':email,'nickname':prefix,'password':password})
    assert status==201
    _,login=call(TARGET+'/auth/login',{'email':email,'password':password})
    token=login['result']['accessToken']
    state={'rps':rps,'email':email,'memberId':member['result']['memberId'],'accessToken':token}
    save_private(path,state)
    # Probe uses a disjoint ID; the official counter restarts at1 on each run.
    status,_=call(TARGET+'/movie-records',{'movieId':1000000000000,'score':5,'comment':'preflight','addToFavorites':True},token)
    assert status==201
    print(f'Stage {rps}: fresh synthetic member; disjoint probe201; credentials not printed.')

def run(rps):
    path=LOCAL/f'stage-{rps}.json'
    state=json.loads(path.read_text())
    if state.get('runId'): raise RuntimeError('Already started. Use collect; never restart the same member counter.')
    scenario={'name':f'Infra2 {rps}RPS',
        'target':{'url':TARGET+'/movie-records','method':'POST',
            'headers':{'Content-Type':'application/json','Authorization':'Bearer '+state['accessToken']},
            'body':'{"movieId": {{counter}}, "score": 5, "comment": "lab", "addToFavorites": true}','timeoutMs':5000},
        'success':{'statusCodes':[201]},'load':{'rps':rps,'durationSec':40},
        'analysis':{'slowThresholdMs':1000,'baselineSec':8,'minConsecutiveFailures':3}}
    state['startedAt']=time.time()
    _,value=call(API+'/runs',scenario)
    state['runId']=value['runId'];save_private(path,state)
    print(f'Stage {rps} started for40s; run ID recorded privately.')

def collect(rps):
    path=LOCAL/f'stage-{rps}.json'
    state=json.loads(path.read_text())
    _,run=call(API+'/runs/'+state['runId'])
    if run['status']=='running':
        print('Still running; collect again after completion.');return
    _,result=call(API+'/runs/'+state['runId']+'/export.json')
    safe=redact(result,[state['accessToken']])
    (HERE/'evidence'/f'load-{rps}.json').write_text(json.dumps(safe,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'rps':rps,'status':run['status'],'summary':safe.get('summary')},ensure_ascii=False,indent=2))

if __name__=='__main__':
    if len(sys.argv)!=3 or sys.argv[1] not in ['prepare','run','collect']:
        raise SystemExit('load.py prepare|run|collect 200|400|600|800')
    globals()[sys.argv[1]](int(sys.argv[2]))
