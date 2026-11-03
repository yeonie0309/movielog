const { spawnSync, execFileSync } = require('node:child_process');
const { mkdirSync, writeFileSync, readFileSync } = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const evidence = path.join(root, 'evidence/week6-frontend');
mkdirSync(evidence, { recursive: true });
for (const [file, command, args] of [
  ['flutter-analyze.txt', 'flutter', ['analyze', '--no-fatal-infos']],
  ['flutter-test.txt', 'flutter', ['test', '--reporter', 'expanded']],
  ['git-diff-check.txt', 'git', ['diff', '--check']],
]) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8' });
  const log = `$ ${command} ${args.join(' ')}\n${result.stdout || ''}${result.stderr || ''}\nExit code: ${result.status}\n`;
  writeFileSync(path.join(evidence, file), log.replace(/[ \t]+$/gm, ''));
  process.stdout.write(log);
  if (result.status !== 0) process.exit(result.status ?? 1);
}
const env = readFileSync(path.join(root, '.env'), 'utf8');
const token = env.match(/^TMDB_ACCESS_TOKEN\s*=\s*(.+)$/m)?.[1]?.trim().replace(/^['"]|['"]$/g, '');
if (!token || token.length < 30) throw new Error('TMDB token missing (value not printed)');
const files = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard'], { cwd: root, encoding: 'utf8' })
  .trim().split('\n').filter(file => /^(lib\/|test\/|integration_test\/|tool\/|evidence\/week6-frontend\/|WEEK6_FRONTEND_)/.test(file));
for (const file of new Set(files)) {
  if (readFileSync(path.join(root, file)).includes(Buffer.from(token))) {
    throw new Error('Secret scan failed (value and location withheld)');
  }
}
const ignored = spawnSync('git', ['check-ignore', '.env'], { cwd: root, encoding: 'utf8' });
const tracked = execFileSync('git', ['ls-files', '.env'], { cwd: root, encoding: 'utf8' }).trim();
if (ignored.status !== 0 || tracked) throw new Error('.env must be ignored and untracked');
const security = 'PASS: .env ignored and untracked.\nPASS: actual TMDB token absent from current frontend code, tests, tools and week6 evidence.\nScope: current files only; no claim about all historical commits.\nWorkbook requests are GET only and use a separate Dio without Authorization.\n';
writeFileSync(path.join(evidence, 'security-check.txt'), security);
process.stdout.write(security);
