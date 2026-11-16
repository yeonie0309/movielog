// Executes the real Postman collection, then verifies extra flows against MySQL.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { randomBytes } = require("node:crypto");
const { spawn } = require("node:child_process");
const mysql = require("mysql2/promise");
const out = path.resolve(__dirname, "../../evidence/week7-backend");
fs.mkdirSync(out, { recursive: true });
const temporary = fs.mkdtempSync("/private/tmp/movielog-week7-");
const baseUrl = "http://localhost:3007";
const prefix = "w7" + randomBytes(3).toString("hex");
const values = {
  baseUrl,
  emailA: prefix + "a@example.com",
  emailB: prefix + "b@example.com",
  nicknameA: prefix + "A",
  nicknameB: prefix + "B",
  password: "Aa9!" + randomBytes(16).toString("hex"),
};
const privateEnv = path.join(temporary, "environment.json");
const exportedEnv = path.join(temporary, "exported.json");
const rawReport = path.join(temporary, "newman.json");
fs.writeFileSync(
  privateEnv,
  JSON.stringify({
    values: Object.entries(values).map(([key, value]) => ({
      key,
      value,
      enabled: true,
    })),
  }),
  { mode: 0o600 },
);
const report = {
  verifiedAt: new Date().toISOString(),
  environment:
    "Actual local NestJS + TypeORM + MySQL; Postman collection executed by Newman",
  requests: [],
  passed: false,
};
let connection,
  baseline,
  credentials,
  tokenExpiresAt = 0;
const redact = (body) =>
  body && typeof body === "object"
    ? Object.fromEntries(
        Object.entries(body).map(([key, value]) => [
          key,
          key === "password" ? "[비밀번호 생략]" : value,
        ]),
      )
    : body;
function decode(token) {
  return JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString());
}
function loadEnvironment() {
  if (!fs.existsSync(exportedEnv)) return {};
  return Object.fromEntries(
    JSON.parse(fs.readFileSync(exportedEnv)).values.map(({ key, value }) => [
      key,
      value,
    ]),
  );
}
async function call(
  name,
  method,
  endpoint,
  expected,
  body,
  token,
  expectedCode,
) {
  const response = await fetch(baseUrl + endpoint, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: "Bearer " + token } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(10000),
  });
  const result = await response.json();
  report.requests.push({
    name,
    request: {
      method,
      url: baseUrl + endpoint,
      body: redact(body),
      authentication: token ? "Bearer (실습 토큰)" : "없음",
    },
    status: response.status,
    response: result,
  });
  assert.equal(response.status, expected, name);
  if (expectedCode) assert.equal(result.code, expectedCode, name);
  return result;
}
async function main() {
  connection = await mysql.createConnection({
    host: process.env.DB_HOST ?? "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3307),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: "umc_movie",
    charset: "utf8mb4",
  });
  const [existingMembers] = await connection.query(
    "SELECT * FROM member ORDER BY member_id",
  );
  const [existingRatings] = await connection.query(
    "SELECT * FROM rating ORDER BY rating_id",
  );
  baseline = { members: existingMembers, ratings: existingRatings };
  const [[missing]] = await connection.query(
    "SELECT COUNT(*) AS count FROM rating WHERE rating_id = 9007199254740991",
  );
  assert.equal(missing.count, 0);
  await new Promise((resolve, reject) => {
    const child = spawn(
      "npm",
      [
        "exec",
        "--yes",
        "--package=newman",
        "--",
        "newman",
        "run",
        path.resolve(
          __dirname,
          "../postman/MovieLog-week7.postman_collection.json",
        ),
        "-e",
        privateEnv,
        "--export-environment",
        exportedEnv,
        "--reporters",
        "cli,json",
        "--reporter-json-export",
        rawReport,
      ],
      { cwd: path.resolve(__dirname, ".."), stdio: ["ignore", "pipe", "pipe"] },
    );
    let log = "";
    for (const stream of [child.stdout, child.stderr])
      stream.on("data", (data) => {
        log += data;
        process.stdout.write(data);
      });
    child.on("error", reject);
    child.on("close", (code) => {
      fs.writeFileSync(path.join(out, "newman.txt"), log);
      code === 0 ? resolve() : reject(new Error("Postman collection failed"));
    });
  });
  credentials = loadEnvironment();
  const raw = JSON.parse(fs.readFileSync(rawReport));
  report.newman = {
    stats: raw.run.stats,
    failures: raw.run.failures.map((f) => f.error.message),
  };
  for (const execution of raw.run.executions) {
    const response = JSON.parse(
      Buffer.from(execution.response.stream.data).toString(),
    );
    const request = execution.request;
    report.requests.push({
      name: execution.item.name,
      request: {
        method: request.method,
        url: baseUrl + "/" + request.url.path.join("/"),
        body: request.body ? redact(JSON.parse(request.body.raw)) : null,
        authentication:
          request.auth?.type === "bearer" ? "Bearer (실습 토큰)" : "없음",
      },
      status: execution.response.code,
      response,
    });
  }
  const token = credentials.tokenA;
  tokenExpiresAt = decode(token).exp * 1000;
  report.payload = decode(token);
  assert.equal(report.payload.exp - report.payload.iat, 60);
  assert.equal(report.payload.sub, String(credentials.memberA));
  const info = await call(
    "내 정보 조회 / LoginMember 데코레이터",
    "GET",
    "/members/me",
    200,
    null,
    token,
    "COMMON200",
  );
  assert.equal(info.result.email, values.emailA);
  assert.deepEqual(Object.keys(info.result).sort(), [
    "createdAt",
    "email",
    "nickname",
  ]);
  await call(
    "자기 닉네임 유지",
    "PATCH",
    "/members/me",
    200,
    { nickname: values.nicknameA },
    token,
    "COMMON200",
  );
  await call(
    "닉네임 수정",
    "PATCH",
    "/members/me",
    200,
    { nickname: prefix + "C" },
    token,
    "COMMON200",
  );
  assert.equal(
    (await call("닉네임 수정 후 조회", "GET", "/members/me", 200, null, token))
      .result.nickname,
    prefix + "C",
  );
  await call(
    "다른 회원 닉네임 중복",
    "PATCH",
    "/members/me",
    409,
    { nickname: values.nicknameB },
    token,
    "MEMBER409_1",
  );
  const failedLogin = await call(
    "틀린 비밀번호",
    "POST",
    "/auth/login",
    401,
    { email: values.emailA, password: "incorrect" },
    null,
    "AUTH401_1",
  );
  assert.deepEqual(
    await call(
      "미가입 이메일",
      "POST",
      "/auth/login",
      401,
      { email: prefix + "missing@example.com", password: "incorrect" },
      null,
      "AUTH401_1",
    ),
    failedLogin,
  );
  const parts = token.split(".");
  const middle = Math.floor(parts[1].length / 2);
  parts[1] =
    parts[1].slice(0, middle) +
    (parts[1][middle] === "a" ? "b" : "a") +
    parts[1].slice(middle + 1);
  await call(
    "payload 한 글자 교체",
    "GET",
    "/members/me",
    401,
    null,
    parts.join("."),
    "AUTH401_3",
  );
  await call(
    "작성자 body 주입 거절",
    "POST",
    "/ratings",
    400,
    { movieId: 155, score: 4, memberId: Number(credentials.memberB) },
    token,
    "COMMON400",
  );
  await call(
    "기존 memberId 쓰기 경로 제거",
    "POST",
    `/members/${credentials.memberA}/ratings`,
    404,
    { movieId: 155, score: 4 },
    token,
    "COMMON404",
  );
  assert.deepEqual(
    await call(
      "본인 삭제 후 공개 빈 목록",
      "GET",
      `/members/${credentials.memberA}/ratings`,
      200,
    ),
    [],
  );
  await call(
    "만료 전 /members/me 성공",
    "GET",
    "/members/me",
    200,
    null,
    token,
    "COMMON200",
  );
  console.log("60초 만료 대기 중 — 실제 시계로 만료를 확인합니다.");
  await new Promise((resolve) =>
    setTimeout(resolve, Math.max(0, tokenExpiresAt - Date.now() + 1200)),
  );
  await call(
    "60초 만료 후 AUTH401_4",
    "GET",
    "/members/me",
    401,
    null,
    token,
    "AUTH401_4",
  );
  report.passed = true;
}
main()
  .catch((error) => {
    report.failure = error.message;
    process.exitCode = 1;
    console.error("Verification failed:", error.message);
  })
  .finally(async () => {
    credentials ??= loadEnvironment();
    // Even if a later assertion fails, only the two unique emails generated here are eligible for cleanup.
    if (connection && baseline) {
      const [rows] = await connection.execute(
        "SELECT member_id FROM member WHERE email IN (?, ?)",
        [values.emailA, values.emailB],
      );
      for (const row of rows) {
        await connection.execute("DELETE FROM rating WHERE member_id = ?", [
          row.member_id,
        ]);
        await connection.execute(
          "DELETE FROM member WHERE member_id = ? AND email IN (?, ?)",
          [row.member_id, values.emailA, values.emailB],
        );
      }
      const [members] = await connection.query(
        "SELECT * FROM member ORDER BY member_id",
      );
      const [ratings] = await connection.query(
        "SELECT * FROM rating ORDER BY rating_id",
      );
      report.cleanup = {
        fixtureMembersRemoved: rows.length,
        existingMembersUnchanged:
          JSON.stringify(members) === JSON.stringify(baseline.members),
        existingRatingsUnchanged:
          JSON.stringify(ratings) === JSON.stringify(baseline.ratings),
      };
      assert.ok(
        report.cleanup.existingMembersUnchanged &&
          report.cleanup.existingRatingsUnchanged,
      );
      await connection.end();
    }
    // Captures intentionally show only expired, disposable localhost tokens.
    const expirations = [credentials.tokenA, credentials.tokenB]
      .filter(Boolean)
      .map((t) => decode(t).exp * 1000);
    await new Promise((resolve) =>
      setTimeout(
        resolve,
        Math.max(0, ...expirations.map((exp) => exp - Date.now() + 1000)),
      ),
    );
    report.tokensExpiredBeforeSaving = expirations.every(
      (exp) => exp < Date.now(),
    );
    fs.writeFileSync(
      path.join(out, "live-api-results.json"),
      JSON.stringify(report, null, 2) + "\n",
    );
    fs.rmSync(temporary, { recursive: true, force: true });
    console.log(
      JSON.stringify({
        passed: report.passed,
        requests: report.requests.length,
        tokensExpired: report.tokensExpiredBeforeSaving,
        cleanup: report.cleanup,
      }),
    );
  });
