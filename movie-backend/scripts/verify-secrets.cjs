const { execFileSync } = require("node:child_process");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "../..");
const files = execFileSync(
  "git",
  ["ls-files", "--cached", "--others", "--exclude-standard", "-z"],
  { cwd: root },
)
  .toString()
  .split("\0")
  .filter(Boolean);
const secrets = [process.env.TMDB_ACCESS_TOKEN, process.env.DB_PASSWORD].filter(
  (value) => value && value.length >= 6,
);
if (secrets.length < 2)
  throw new Error(
    "로컬 TMDB·DB 환경 변수를 먼저 로드해야 합니다. 값은 출력하지 않습니다.",
  );
let count = 0;
const leaked = [];
for (const file of new Set(files)) {
  if (
    !/\.(?:ts|cjs|mjs|json|dart|md|txt|html|svg|sql|yaml|yml|xml|rb|properties|kts|gradle)$/.test(
      file,
    )
  )
    continue;
  const text = readFileSync(path.join(root, file), "utf8");
  count++;
  if (secrets.some((secret) => text.includes(secret))) leaked.push(file);
}
if (leaked.length) {
  console.error("비밀값 발견 파일: " + leaked.join(", "));
  process.exitCode = 1;
} else
  console.log(
    `소스·문서 ${count}개 검사: TMDB 토큰과 DB 비밀번호 원문 노출 없음 (.env 제외, 비밀값 출력 없음)`,
  );
