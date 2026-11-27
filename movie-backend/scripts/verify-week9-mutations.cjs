// Temporary compiled-code mutations only. Source is untouched; finally restores bytes.
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const { createHash } = require("node:crypto");
const root = path.resolve(__dirname, "..");
const out = path.resolve(root, "../evidence/week9-backend");
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
const results = [];
function mutation(name, file, transform, pattern, tests, expectedFailures) {
  const target = path.join(root, "dist/service", file);
  const original = fs.readFileSync(target);
  const mutated = transform(original.toString());
  assert.notEqual(
    mutated,
    original.toString(),
    "Mutation must change compiled production logic",
  );
  try {
    fs.writeFileSync(target, mutated);
    const run = spawnSync(
      process.execPath,
      [
        "--test",
        "--test-reporter=spec",
        "--test-name-pattern=" + pattern,
        ...tests,
      ],
      { cwd: root, encoding: "utf8" },
    );
    const log = (run.stdout ?? "") + (run.stderr ?? "");
    fs.writeFileSync(path.join(out, name + ".txt"), log);
    assert.notEqual(run.status, 0, "Mutant must fail");
    assert.match(log, new RegExp("fail " + expectedFailures + "(?:\\s|$)"));
    for (const expected of name === "duplicate-removed"
      ? ["Missing expected rejection", "expected 409"]
      : ["ROLLBACK_REQUIRED"])
      assert.ok(
        log.includes(expected),
        "Failure must be about intended behavior: " + expected,
      );
    results.push({
      name,
      exitCode: run.status,
      expectedFailures,
      originalSha256: hash(original),
    });
  } finally {
    fs.writeFileSync(target, original);
    assert.equal(hash(fs.readFileSync(target)), hash(original));
  }
}
mutation(
  "duplicate-removed",
  "favorite.service.js",
  (source) =>
    source.replace(
      /        if \(await this\.favorites\.exists\(\{[\s\S]*?\n        \}\n(?=        \/\/ The UNIQUE)/,
      "        // week9 mutation: duplicate guard removed\n",
    ),
  "favorite unit: 중복|favorite integration 3",
  ["test/week9-unit.test.cjs", "test/week9-memory.e2e.test.cjs"],
  2,
);
mutation(
  "transaction-removed",
  "movie-record.service.js",
  (source) =>
    source
      .replace(
        "this.dataSource.transaction(async (manager) => {",
        "(async (manager) => {",
      )
      .replace(
        "        });\n    }\n",
        "        })(this.dataSource.manager);\n    }\n",
      ),
  "transaction rollback:",
  ["test/week9-memory.e2e.test.cjs"],
  1,
);
const restore = spawnSync(
  process.execPath,
  ["--test", "test/week9-unit.test.cjs", "test/week9-memory.e2e.test.cjs"],
  { cwd: root, encoding: "utf8" },
);
fs.writeFileSync(
  path.join(out, "restored-tests.txt"),
  restore.stdout + restore.stderr,
);
assert.equal(restore.status, 0, "Restored code must pass again");
fs.writeFileSync(
  path.join(out, "mutation-results.json"),
  JSON.stringify(
    {
      mutations: results,
      restored: true,
      restoredTestExit: restore.status,
      sourceEdited: false,
    },
    null,
    2,
  ),
);
console.log(
  JSON.stringify(
    {
      mutations: results.map((x) => ({
        name: x.name,
        expectedFailures: x.expectedFailures,
      })),
      restored: true,
    },
    null,
    2,
  ),
);
