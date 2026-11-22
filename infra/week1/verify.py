#!/usr/bin/env python3
"""Run relevant checks and retain their actual stdout, with no secret values."""
import json
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[1]
OUT = HERE / 'evidence'
OUT.mkdir(exist_ok=True)
checks = [
    ('backend-tests', ['npm', 'test'], REPO / 'movie-backend'),
    ('backend-types', ['npm', 'run', 'lint'], REPO / 'movie-backend'),
    ('rolling-safety-tests', ['python3', '-m', 'unittest', 'discover', '-s', 'infra/week1', '-p', 'test_*.py', '-v'], REPO),
    ('diff-check', ['git', 'diff', '--check'], REPO),
]
result = {}
for name, command, cwd in checks:
    process = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    (OUT / (name + '.txt')).write_text('$ ' + ' '.join(command) + '\n' + process.stdout + process.stderr)
    result[name] = {'exitCode': process.returncode}
    print(name, 'PASS' if process.returncode == 0 else 'FAIL', flush=True)
    if process.returncode:
        print(process.stdout[-3000:] + process.stderr[-3000:])
        sys.exit(process.returncode)

# Compare actual generated secret values against every publishable file. Print
# only pass/fail and paths; never print the sensitive value itself.
state_file = HERE / '.local/state.json'
state = json.loads(state_file.read_text()) if state_file.exists() else {}
secrets = [state[k].encode() for k in ['master_password', 'app_password', 'jwt_secret'] if k in state]
candidates = [p for p in HERE.rglob('*') if p.is_file() and '.local' not in p.parts and '__pycache__' not in p.parts]
candidates += [REPO / 'movie-backend/Dockerfile', REPO / 'movie-backend/.dockerignore',
               REPO / 'movie-backend/src/controller/health.controller.ts']
hits = [str(p.relative_to(REPO)) for p in candidates if any(secret in p.read_bytes() for secret in secrets)]
ignored = subprocess.run(['git', 'check-ignore', '-q', str(HERE / '.local/state.json')], cwd=REPO).returncode == 0
result['secret-scan'] = {'generatedSecretsChecked': len(secrets), 'matchingFiles': hits, 'stateIgnoredByGit': ignored}
(OUT / 'verification.json').write_text(json.dumps(result, indent=2))
if hits or not ignored:
    raise RuntimeError('Secret isolation check failed; see file paths in verification.json')
print(('Generated secrets absent from publishable files' if secrets else 'No live secrets available for comparison')
      + '; local state ignored by Git.', flush=True)
