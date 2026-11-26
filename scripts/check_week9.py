"""Verify week 9 using real command output, artifacts, and a non-disclosing scan."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/week9-frontend'


def command(args, name):
    result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (OUT / name).write_text(result.stdout)
    if result.returncode:
        print(result.stdout[-5000:])
        raise SystemExit(result.returncode)


parser = argparse.ArgumentParser()
parser.add_argument('--run-checks', action='store_true')
args = parser.parse_args()
OUT.mkdir(parents=True, exist_ok=True)
if args.run_checks:
    command(['flutter', 'analyze', '--no-pub', '--no-fatal-infos'], 'flutter-analyze.txt')
    command(['flutter', 'test', '--no-pub', '--reporter', 'expanded'], 'flutter-test.txt')
    print('PASS: analyze and complete Flutter test suite')
    raise SystemExit(0)

analyze = (OUT / 'flutter-analyze.txt').read_text()
assert 'error •' not in analyze and 'warning •' not in analyze
assert '2 issues found' in analyze
tests = (OUT / 'flutter-test.txt').read_text()
assert 'All tests passed!' in tests
count = int(re.findall(r'\+(\d+): All tests passed!', tests)[-1])
results = {phase: json.loads((OUT / f'result-{phase}.json').read_text()) for phase in ['live', 'states']}
assert all(r['passed'] for r in results.values())
assert results['live']['fixtureFavoritesAndRatingsRemoved']
assert results['states']['emptyErrorPartialRetry']
assert results['states']['conflict409404Reconciled']
for phase in results:
    assert 'All tests passed!' in (OUT / f'android-{phase}.txt').read_text()
trace = results['live']['requests']
assert any(r['path'] == '/v8/movie-records' and r['status'] == 201 and r['body']['addToFavorites'] is True for r in trace)
assert any(r['path'].startswith('/v8/favorites/') and r['method'] == 'DELETE' and r['status'] == 200 and r['response']['result'] is None for r in trace)
assert any(r['path'] == '/search/movie' and r['response']['count'] == 0 for r in trace)
assert {1, 2, 3}.issubset({r['query']['page'] for r in trace if r['path'] == '/discover/movie' and r['status'] == 200})
assert any(r['status'] == 401 and r['response']['code'] == 'AUTH401_3' for r in results['states']['requests'])
pngs = list(OUT.glob('*.png'))
assert len(pngs) >= 24
for photo in pngs:
    assert photo.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
videos = list(OUT.glob('*.mp4'))
assert len(videos) >= 5
assert all(v.stat().st_size > 10000 for v in videos)

changed = set(subprocess.check_output(['git', 'diff', '--name-only', 'feature/week-8-backend'], cwd=ROOT, text=True).splitlines())
untracked = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard'], cwd=ROOT, text=True).splitlines()
for name in untracked:
    if name.startswith(('lib/', 'evidence/week9-frontend/')) or name in {
        'test/week9_frontend_test.dart', 'integration_test/week9_evidence_test.dart',
        'scripts/capture_week9.py', 'scripts/check_week9.py', 'scripts/report_week9.py',
        'WEEK9_FRONTEND_SUBMISSION_GUIDE.md'}:
        changed.add(name)
secrets = []
for env in ['.env', 'backend/.env', 'movie-backend/.env']:
    p = ROOT / env
    if not p.exists():
        continue
    for line in p.read_text().splitlines():
        if '=' not in line or line.lstrip().startswith('#'):
            continue
        key, value = line.split('=', 1)
        value = value.strip().strip('\"\'')
        if any(w in key.upper() for w in ['TOKEN', 'SECRET', 'PASSWORD']) and len(value) >= 8:
            secrets.append(value)
for name in changed:
    p = ROOT / name
    if not p.is_file() or p.suffix not in {'.dart', '.md', '.txt', '.json', '.py', '.html'}:
        continue
    text = p.read_text()
    assert not any(secret in text for secret in secrets), f'Credential match: {name}'
    assert not re.search(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', text), f'JWT: {name}'
tracked = subprocess.check_output(['git', 'ls-files'], cwd=ROOT, text=True).splitlines()
assert not any(p == '.env' or p.endswith('/.env') for p in tracked)
subprocess.run(['git', 'diff', '--check'], cwd=ROOT, check=True)
changed.update({'evidence/week9-frontend/changed-files.txt', 'evidence/week9-frontend/verification-summary.json'})
(OUT / 'changed-files.txt').write_text('\n'.join(sorted(changed)) + '\n')
fixture_ids = set(results['live']['fixtureMemberIds'])
for attempt in (OUT / 'interrupted-attempts').glob('*.json'):
    fixture_ids.update(json.loads(attempt.read_text())['fixtureMemberIds'])
summary = {'flutterTests': count, 'week9Tests': 15, 'androidScenarios': 2,
           'actualLiveRequests': len(trace), 'actualApiRequests': len(trace) + len(results['states']['requests']),
           'pngScreenshots': len(pngs), 'videos': len(videos), 'analyzeErrors': 0, 'analyzeWarnings': 0,
           'existingWeek0Infos': 2, 'fixtureMemberIds': results['live']['fixtureMemberIds'],
           'fixtureAccountsCreatedAcrossAttempts': len(fixture_ids),
           'finalFavoritesAndRatingsRemoved': True, 'tokensAbsentFromChangedText': True, 'envUntracked': True,
           'manualUserCheckPending': True, 'iOSVerified': False,
           'controlledFailures': ['next-page transport', 'search transport', 'favorites list', 'one movie', '409/404 conflict'],
           'actualAuth401': 'AUTH401_3', 'originalNotionEdited': False, 'umcSubmitted': False}
(OUT / 'verification-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(summary, ensure_ascii=False))
