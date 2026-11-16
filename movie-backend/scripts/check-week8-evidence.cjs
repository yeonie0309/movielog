const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const out = path.join(root, 'evidence/week8-backend');
const read = name => fs.readFileSync(path.join(out, name), 'utf8');
const report = JSON.parse(read('live-api-results.json'));
assert.equal(report.passed, true);
assert.equal(report.requests.length, 37);
assert.equal(report.rollback.ratingObservedBeforeFailure, true);
assert.equal(report.rollback.ratingRowsAfterRollback, 0);
assert.equal(report.rollback.favoriteRowsAfterRollback, 0);
assert.equal(report.forcedUniqueRace.rowCount, 1);
assert.ok(report.cleanup.includes('preexisting rows unchanged'));
assert.equal(JSON.parse(read('postman-fixture-cleanup.json')).passed, true);
assert.match(read('backend-tests-final.txt'), /pass 70/);
assert.match(read('backend-tests-final.txt'), /fail 0/);
assert.match(read('flutter-tests.txt'), /\+94: All tests passed/);
assert.match(read('flutter-analyze.txt'), /2 issues found/);
assert.ok(!read('backend-lint.txt').includes('error TS'));
const captures = JSON.parse(read('postman-live-captures.json')).captures;
assert.equal(captures.length, 11);
for (const capture of captures) assert.ok(fs.statSync(path.join(out, capture.file)).size > 10000);
for (const photo of ['11-swagger-overview.jpg', '12-swagger-record-examples.jpg', '13-transaction-code.jpg', '14-mysql-rollback-unique.jpg', '15-checks.jpg']) assert.ok(fs.statSync(path.join(out, photo)).size > 10000);
const changed = execFileSync('git', ['diff', '--name-only', 'origin/feature/week-7-backend'], { cwd: root, encoding: 'utf8' }).trim().split('\n');
const untracked = execFileSync('git', ['ls-files', '--others', '--exclude-standard', 'movie-backend', 'evidence/week8-backend', 'WEEK8_BACKEND_SUBMISSION_GUIDE.md'], { cwd: root, encoding: 'utf8' }).trim().split('\n');
const files = [...new Set([...changed, ...untracked])].filter(Boolean).sort();
const secrets = [];
for (const envPath of ['.env', 'backend/.env', 'movie-backend/.env']) {
  const full = path.join(root, envPath);
  if (!fs.existsSync(full)) continue;
  for (const line of fs.readFileSync(full, 'utf8').split('\n')) {
    const match = /^\s*([A-Z_]*(?:TOKEN|SECRET|PASSWORD)[A-Z_]*)\s*=\s*(.+)/.exec(line);
    if (match && match[2].length >= 12) secrets.push(match[2].replace(/^['"]|['"]$/g, ''));
  }
}
for (const file of files) {
  if (/\.(png|jpg|mp4)$/.test(file)) continue;
  const full = path.join(root, file);
  if (!fs.existsSync(full)) continue;
  const text = fs.readFileSync(full, 'utf8');
  assert.ok(!/eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/.test(text), 'JWT found in ' + file);
  assert.ok(!secrets.some(secret => text.includes(secret)), 'Local credential found in ' + file);
}
for (const file of ['.env', 'backend/.env', 'movie-backend/.env']) assert.equal(execFileSync('git', ['ls-files', '--', file], { cwd: root, encoding: 'utf8' }).trim(), '');
execFileSync('git', ['diff', '--check'], { cwd: root });
fs.writeFileSync(path.join(out, 'changed-files.txt'), files.join('\n') + '\n');
fs.writeFileSync(path.join(out, 'verification-summary.json'), JSON.stringify({ backendTests: 70, flutterTests: 94, automatedActualHttpRequests: 37, postmanLiveScreenshots: 11, realMysqlRollback: report.rollback, uniqueRace: report.forcedUniqueRace, automaticFixtureCleaned: true, postmanFixtureCleaned: true, existingFlutterInfos: 2, changedTextCredentialScanPassed: true }, null, 2) + '\n');
console.log('PASS: backend70, Flutter94, actual HTTP37, Postman11, real MySQL rollback/UNIQUE, cleanup, secret scan, artifacts');
