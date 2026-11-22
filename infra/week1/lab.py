#!/usr/bin/env python3
"""Drive the workbook's official zero-downtime-lab and export real results."""
import json
import pathlib
import sys
import time
import urllib.request
import manage

EVIDENCE = pathlib.Path(__file__).resolve().parent / 'evidence'
EVIDENCE.mkdir(exist_ok=True)
API = 'http://127.0.0.1:9376/api'


def request(path, data=None):
    req = urllib.request.Request(API + path,
        data=json.dumps(data).encode() if data is not None else None,
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=15) as response:
        return json.load(response)


class Tee:
    def __init__(self, output, logfile):
        self.output, self.logfile = output, logfile

    def write(self, text):
        self.output.write(text)
        self.logfile.write(text)
        self.flush()

    def flush(self):
        self.output.flush()
        self.logfile.flush()


def run(kind):
    if kind == 'before':
        url = 'http://' + manage.state['baseline_ip'] + ':3000/health'
        duration = 120
    else:
        url = 'http://' + manage.state['alb_dns'] + '/health'
        duration = 480 if kind == 'fault-rollback' else 240
    # GET /health exercises both the app and its DB without creating test users
    # or sending login credentials over the workbook's HTTP endpoint.
    with urllib.request.urlopen(url, timeout=5) as response:
        initial = json.load(response)
    scenario = {'name': 'MovieLog ' + kind, 'target': {'url': url, 'method': 'GET', 'headers': {}, 'body': '', 'timeoutMs': 5000},
        'success': {'statusCodes': [200]}, 'load': {'rps': 10, 'durationSec': duration},
        'analysis': {'slowThresholdMs': 1000, 'baselineSec': 15, 'minConsecutiveFailures': 3}}
    run_id = request('/runs', scenario)['runId']
    (manage.LOCAL / (kind + '-run-id.txt')).write_text(run_id)
    (EVIDENCE / (kind + '-initial-health.json')).write_text(json.dumps(initial, indent=2))
    print(f'{kind}: official monitor started {run_id}; 10 RPS; {duration}s; initial={initial}', flush=True)
    time.sleep(20)
    baseline = request('/runs/' + run_id)['baseline']
    if not baseline['complete'] or baseline['failureRate'] != 0:
        request('/runs/' + run_id + '/stop', {})
        raise RuntimeError('Clean baseline was not established; deployment not started')
    if kind == 'before':
        manage.remote(manage.state['baseline'], ['bash /opt/umc/swap.sh'])
    elif kind == 'after':
        manage.deploy()
    elif kind == 'fault-rollback':
        import os
        os.environ['MOVIELOG_DEPLOY_IMAGE'] = manage.state['fault_image']
        try:
            manage.deploy()
            raise AssertionError('Fault image unexpectedly passed readiness')
        except RuntimeError as error:
            print('EXPECTED deployment failure:', error, flush=True)
        finally:
            os.environ.pop('MOVIELOG_DEPLOY_IMAGE', None)
        # Probe the quarantined node through SSM, not the public listener.
        health = manage.targets()
        bad = [i for i in manage.state['cluster_ids'] if not any(
            x['Target']['Id'] == i and x['TargetHealth']['State'] == 'healthy' for x in health)]
        if len(bad) != 1:
            raise AssertionError('Expected exactly one quarantined node')
        manage.remote(bad[0], [
            "STATUS=$(curl --silent --max-time 5 -o /tmp/movielog-health-response -w '%{http_code}' http://127.0.0.1:3000/health)",
            'cat /tmp/movielog-health-response', 'echo "HTTP $STATUS"', 'test "$STATUS" = 500',
            "docker inspect --format '{{.Config.Image}}' app"])
        with urllib.request.urlopen(url, timeout=5) as response:
            print('Public service stayed available:', response.status, response.read().decode(), flush=True)
        print('ROLLBACK to known-good image', flush=True)
        manage.deploy()
        print('Observing 30 seconds of recovered service before ending the optional run.', flush=True)
        time.sleep(30)
        request('/runs/' + run_id + '/stop', {})
    else:
        raise ValueError(kind)
    while True:
        summary = request('/runs/' + run_id)
        if summary['status'] != 'running':
            break
        time.sleep(5)
    result = request('/runs/' + run_id + '/export.json')
    (EVIDENCE / (kind + '.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps(result['summary'], ensure_ascii=False, indent=2), flush=True)
    if result['summary']['warnings']:
        raise RuntimeError('Measurement has warnings; investigate before claiming success')
    if kind != 'before' and result['summary']['totals']['failure']:
        raise RuntimeError('AWS measurement had failures; investigate before claiming zero downtime')


if __name__ == '__main__':
    kind = sys.argv[1]
    if kind in ('archive-preflight', 'archive-deploy-failure'):
        run_id = (manage.LOCAL / 'before-run-id.txt').read_text().strip()
        if request('/runs/' + run_id)['status'] == 'running':
            request('/runs/' + run_id + '/stop', {})
            time.sleep(2)
        result = request('/runs/' + run_id + '/export.json')
        name = 'preflight-timeout-2s.json' if kind == 'archive-preflight' else 'preflight-docker-stop-flag.json'
        (EVIDENCE / name).write_text(json.dumps(result, ensure_ascii=False, indent=2))
        print('Preserved the incomplete attempt; do not use it as successful deployment evidence.')
    else:
        original = sys.stdout
        with (EVIDENCE / (kind + '-deployment.txt')).open('w') as logfile:
            try:
                sys.stdout = Tee(original, logfile)
                run(kind)
            finally:
                sys.stdout = original
