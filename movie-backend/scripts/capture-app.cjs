const { spawn, execFileSync } = require("node:child_process");
const { writeFileSync, mkdirSync } = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "../..");
const evidence = path.join(root, "evidence/week5-backend");
mkdirSync(evidence, { recursive: true });
const seen = new Set();
const child = spawn(
  "flutter",
  [
    "test",
    "integration_test/week5_backend_live_test.dart",
    "-d",
    "emulator-5554",
    "--reporter",
    "expanded",
  ],
  { cwd: root, stdio: ["ignore", "pipe", "pipe"] },
);
let log = "";
function output(data) {
  const text = data.toString();
  log += text;
  process.stdout.write(text);
  for (const match of log.matchAll(/WEEK5_BACKEND_CAPTURE=([\w-]+)/g)) {
    if (seen.has(match[1])) continue;
    seen.add(match[1]);
    const png = execFileSync(
      "/Users/yeonie/Library/Android/sdk/platform-tools/adb",
      ["-s", "emulator-5554", "exec-out", "screencap", "-p"],
    );
    writeFileSync(path.join(evidence, match[1] + ".png"), png);
  }
}
child.stdout.on("data", output);
child.stderr.on("data", output);
child.on("exit", (code) => {
  writeFileSync(path.join(evidence, "flutter-live-test.txt"), log);
  process.exitCode = code ?? 1;
});
