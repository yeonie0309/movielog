"""Validate week 8 artifacts without printing authentication credentials."""
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence/week8-frontend'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip().splitlines()

results = {name: json.loads((OUT / f'result-{name}.json').read_text()) for name in ['live', 'restore', 'errors', 'invalid']}
assert all(result['passed'] for result in results.values())
assert results['live']['ratingCleaned'] and results['live']['secureStorageRead']
assert all(results['restore'][key] for key in ['restoredAfterProcessRestart','logoutTokenDeleted','protectedRedirect','invalidToken401'])
assert all(results['errors'][key] for key in ['injected503RetainsToken','injected403RetainsSession','injectedExpired401ClearsSession'])
requests = [r for name in ['live','restore','invalid'] for r in results[name]['requests'] if 'method' in r]
assert len(requests) == 17
assert {200, 201, 401, 403, 409}.issubset({r['status'] for r in requests})
created = next(r for r in requests if r['method']=='POST' and r['path']=='/v7/ratings')
assert created['bearerAttached'] and 'memberId' not in created['body']
assert created['body']['movieId'] == created['response']['result']['movieId'] == 155
assert any(r['method']=='DELETE' and r['status']==200 and r['response']['result'] is None for r in requests)
assert '+94: All tests passed!' in (OUT/'flutter-test.txt').read_text()
analyze = (OUT/'flutter-analyze.txt').read_text()
assert 'error •' not in analyze and 'warning •' not in analyze
assert '2 issues found' in analyze
for phase in ['live','restore','errors','invalid']:
    assert 'All tests passed!' in (OUT/f'android-{phase}.txt').read_text()
pngs = list(OUT.glob('*.png'))
assert len(pngs) == 18
for photo in pngs:
    assert photo.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
for name in ['19-flutter-checks.jpg','20-safe-network.jpg']:
    assert (OUT/name).read_bytes().startswith(b'\xff\xd8')
for name in ['01-login-profile-crud.mp4','02-restart-logout-invalid.mp4']:
    assert (OUT/name).stat().st_size > 10000

changed = set(git('diff','--name-only','origin/feature/week-7-backend'))
for name in git('ls-files','--others','--exclude-standard'):
    if name.startswith(('lib/','evidence/week8-frontend/')) or name in {
        'test/week8_auth_test.dart','integration_test/week8_evidence_test.dart',
        'scripts/capture_week8.py','scripts/check_week8.py','WEEK8_FRONTEND_SUBMISSION_GUIDE.md'}:
        changed.add(name)
secrets = []
for name in ['.env','movie-backend/.env','backend/.env']:
    file = ROOT/name
    if not file.exists():
        continue
    for line in file.read_text().splitlines():
        if '=' not in line or line.lstrip().startswith('#'):
            continue
        key,value=line.split('=',1)
        value=value.strip().strip('\"\'')
        if any(word in key.upper() for word in ['TOKEN','SECRET','PASSWORD']) and len(value)>=8:
            secrets.append(value)
for name in changed:
    file=ROOT/name
    if file.suffix not in {'.dart','.md','.txt','.json','.py','.yaml','.lock'} or not file.is_file():
        continue
    text=file.read_text()
    assert not any(secret in text for secret in secrets), f'Credential match in {name}'
    assert not re.search(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',text), f'JWT in {name}'
assert not any(name.endswith('/.env') or name=='.env' for name in git('ls-files'))
subprocess.run(['git','diff','--check'],cwd=ROOT,check=True)
changed.update({'evidence/week8-frontend/changed-files.txt','evidence/week8-frontend/verification-summary.json'})
(OUT/'changed-files.txt').write_text('\n'.join(sorted(changed))+'\n')
summary={'flutterTests':94,'androidScenarios':4,'actualV7Requests':len(requests),'analyzeExitCode':0,
         'existingWeek0Infos':2,'nativePlatform':'Android Pixel 7 emulator','pngScreenshots':len(pngs),
         'videos':2,'tokenValuesAbsentFromChangedText':True,'envUntracked':True,
         'finalFixtureMemberIds':[52,53],'finalRatingId':36,'finalRatingDeleted':True,
         'earlierInterruptedRatingRemaining':{'memberId':50,'ratingId':35},
         'fixtureAccountsCreatedAcrossAttempts':14,'manualUserCheckPending':True,
         'expiry4014':'injected','invalid4013':'actualAPI','iOSVerified':False}
(OUT/'verification-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print('PASS: Flutter 94, Android 4, actual API 17, secure storage restore/delete, artifacts, credential scan, ignored env, diff check')
