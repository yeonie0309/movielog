const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const root = path.resolve(__dirname, "../..");
const out = path.join(root, "evidence/week7-backend");
const report = JSON.parse(
  fs.readFileSync(path.join(out, "live-api-results.json")),
);
assert.equal(report.passed, true);
assert.equal(report.requests.length, 25);
assert.equal(report.newman.stats.requests.total, 12);
assert.equal(report.newman.stats.assertions.total, 41);
assert.equal(report.newman.failures.length, 0);
assert.equal(report.tokensExpiredBeforeSaving, true);
assert.equal(report.cleanup.fixtureMembersRemoved, 2);
assert.ok(
  report.cleanup.existingMembersUnchanged &&
    report.cleanup.existingRatingsUnchanged,
);
assert.equal(report.payload.exp - report.payload.iat, 60);
for (const code of [
  "AUTH401_1",
  "AUTH401_2",
  "AUTH401_3",
  "AUTH401_4",
  "RATING403_1",
  "RATING404_1",
  "RATING409_1",
  "MEMBER409_1",
]) {
  assert.ok(
    report.requests.some((r) => r.response.code === code),
    code,
  );
}
assert.match(fs.readFileSync(path.join(out, "test.txt"), "utf8"), /pass 60/);
assert.match(fs.readFileSync(path.join(out, "test.txt"), "utf8"), /fail 0/);
assert.match(
  fs.readFileSync(path.join(out, "flutter-test.txt"), "utf8"),
  /\+79: All tests passed!/,
);
const pictures = fs.readdirSync(out).filter((name) => name.endsWith(".jpg"));
assert.ok(pictures.length >= 12);
for (const name of pictures) {
  const bytes = fs.readFileSync(path.join(out, name));
  assert.equal(bytes.subarray(0, 2).toString("hex"), "ffd8", name);
}
const diff = execFileSync(
  "git",
  ["diff", "--name-only", "origin/feature/week-7-frontend"],
  { cwd: root, encoding: "utf8" },
)
  .trim()
  .split("\n");
const untracked = execFileSync(
  "git",
  ["ls-files", "--others", "--exclude-standard"],
  { cwd: root, encoding: "utf8" },
)
  .trim()
  .split("\n");
const files = [...new Set([...diff, ...untracked])]
  .filter(
    (file) =>
      file.startsWith("movie-backend/") ||
      file.startsWith("evidence/week7-backend/") ||
      file === "WEEK7_BACKEND_SUBMISSION_GUIDE.md",
  )
  .sort();
const secrets = [];
for (const env of [".env", "backend/.env", "movie-backend/.env"]) {
  const filename = path.join(root, env);
  if (!fs.existsSync(filename)) continue;
  for (const line of fs.readFileSync(filename, "utf8").split("\n")) {
    const match = line.match(/^([^#=]+)=(.*)$/);
    if (match && /TOKEN|SECRET|PASSWORD|API_KEY/.test(match[1])) {
      const value = match[2].trim().replace(/^(['"])(.*)\1$/, "$2");
      if (value.length >= 8) secrets.push(value);
    }
  }
}
for (const file of files.filter((file) => !file.endsWith(".jpg"))) {
  if (!fs.existsSync(path.join(root, file))) continue;
  const text = fs.readFileSync(path.join(root, file), "utf8");
  for (const secret of secrets)
    assert.ok(!text.includes(secret), "Secret value found in " + file);
}
const tracked = execFileSync("git", ["ls-files"], {
  cwd: root,
  encoding: "utf8",
}).split("\n");
assert.ok(!tracked.some((file) => file === ".env" || file.endsWith("/.env")));
execFileSync("git", ["diff", "--check"], { cwd: root });
fs.writeFileSync(path.join(out, "changed-files.txt"), files.join("\n") + "\n");
const summary = {
  backendTests: 60,
  flutterTests: 79,
  postmanRequests: 12,
  postmanAssertions: 41,
  realRequests: 25,
  expirySeconds: 60,
  cleanup: report.cleanup,
  images: pictures,
  secretsAbsent: true,
  files,
};
fs.writeFileSync(
  path.join(out, "verification-summary.json"),
  JSON.stringify(summary, null, 2) + "\n",
);
console.log(
  "PASS: 60 backend tests, 79 Flutter tests, Postman 12/41, live HTTP 25, 60-second expiry, cleanup, images, secret values absent, ignored .env, diff check.",
);
