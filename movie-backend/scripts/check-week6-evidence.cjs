const assert = require("node:assert/strict");
const { readFileSync, writeFileSync } = require("node:fs");
const { execFileSync } = require("node:child_process");
const path = require("node:path");
const root = path.resolve(__dirname, "../..");
const dir = path.join(root, "evidence/week6-backend");
const expected = [
  "01-signup-201.jpg",
  "02-signup-validation-400.jpg",
  "03-rating-create-201.jpg",
  "04-rating-update-200.jpg",
  "05-rating-after-update.jpg",
  "06-duplicate-email-409.jpg",
  "07-duplicate-nickname-409.jpg",
  "08-duplicate-rating-409.jpg",
  "09-score-validation-400.jpg",
  "10-owner-403.jpg",
  "11-rating-not-found-404.jpg",
  "12-rating-delete-204.jpg",
  "13-rating-after-delete.jpg",
  "14-db-email-unique-race.jpg",
  "15-db-nickname-unique-race.jpg",
  "16-bcrypt-and-cleanup.jpg",
];
const images = expected.map((file) => {
  const jpeg = readFileSync(path.join(dir, file));
  assert.equal(jpeg.readUInt16BE(0), 0xffd8);
  let width = 0,
    height = 0;
  for (let offset = 2; offset < jpeg.length - 8;) {
    const marker = jpeg[offset + 1];
    if (marker === 0xc0 || marker === 0xc2) {
      height = jpeg.readUInt16BE(offset + 5);
      width = jpeg.readUInt16BE(offset + 7);
      break;
    }
    offset += jpeg.readUInt16BE(offset + 2) + 2;
  }
  assert.ok(width >= 1000 && height >= 600);
  return { file, width, height };
});
const report = JSON.parse(
  readFileSync(path.join(dir, "live-api-results.json")),
);
assert.equal(report.passed, true);
assert.equal(report.cleanup.remainingFixtures, 0);
assert.equal(report.requests.length, 23);
assert.equal(report.challenge.length, 2);
const ui = JSON.parse(readFileSync(path.join(dir, "ui-request-results.json")));
assert.deepEqual(
  ui.map((r) => Number(r.status.split(" ")[1])),
  [201, 400, 201, 200, 200, 409, 409, 409, 400, 403, 404, 204, 200],
);
for (const file of [
  "npm-lint.txt",
  "npm-test.txt",
  "flutter-analyze.txt",
  "flutter-test.txt",
  "security-check.txt",
])
  assert.ok(readFileSync(path.join(dir, file)).length > 0);
assert.equal(
  JSON.parse(readFileSync(path.join(dir, "npm-audit.json"))).metadata
    .vulnerabilities.total,
  0,
);
assert.match(readFileSync(path.join(dir, "npm-test.txt"), "utf8"), /pass 47/);
assert.match(
  readFileSync(path.join(dir, "flutter-test.txt"), "utf8"),
  /49: All tests passed/,
);
const diff = execFileSync("git", ["diff", "--check", "HEAD"], { cwd: root }).toString();
writeFileSync(
  path.join(dir, "git-diff-check.txt"),
  "git diff --check HEAD (staged + unstaged tracked changes)\nExit code: 0\n" + diff,
);
const summary = {
  verifiedAt: new Date().toISOString(),
  images,
  standardMission: true,
  challengeMission: true,
  backendHttpTests: 47,
  flutterTests: 49,
  liveHttpRequests: 23,
  realDbConcurrencyPairs: 2,
  browserRequests: 13,
  npmAuditVulnerabilities: 0,
  gitDiffCheck: "passed",
  notionWriteback: "awaiting approval; not performed",
  submission: "not performed",
};
writeFileSync(
  path.join(dir, "verification-summary.json"),
  JSON.stringify(summary, null, 2) + "\n",
);
console.log(
  "Evidence verified: 16 JPEGs, required 3 screenshots, 13 browser requests, 23 live HTTP requests, 2 DB races, 47 + 49 tests, audit 0, git diff clean.",
);
