// Real local HTTP + MySQL verification. Only this run's new fixture rows are removed.
require("reflect-metadata");
const assert = require("node:assert/strict");
const { mkdirSync, writeFileSync } = require("node:fs");
const path = require("node:path");
const { randomBytes } = require("node:crypto");
const bcrypt = require("bcrypt");
const mysql = require("mysql2/promise");
const { DataSource, QueryFailedError } = require("typeorm");
const { Test } = require("@nestjs/testing");
const { getRepositoryToken } = require("@nestjs/typeorm");
const { Member } = require("../dist/entity/member.entity");
const { Rating } = require("../dist/entity/rating.entity");
const { MemberController } = require("../dist/controller/member.controller");
const { RatingController } = require("../dist/controller/rating.controller");
const { MemberService } = require("../dist/service/member.service");
const { RatingService } = require("../dist/service/rating.service");
const { configureApp } = require("../dist/configure-app");

const out = path.resolve(__dirname, "../../evidence/week6-backend");
const tag = randomBytes(3).toString("hex");
const prefix = `w6${tag}`;
const password = "Umc!1234"; // Public workbook-only fixture, not an account credential.
const report = {
  verifiedAt: new Date().toISOString(),
  environment: "Actual local NestJS + TypeORM + MySQL (not mocked DB)",
  requests: [],
  challenge: [],
};
const fixtureIds = new Set();
let conn, dataSource, raceApp;
const base = process.env.API_BASE_URL ?? "http://localhost:3006";
assert.ok(
  ["localhost", "127.0.0.1"].includes(new URL(base).hostname),
  "Local verification only",
);
function redact(body) {
  if (!body) return null;
  return Object.fromEntries(
    Object.entries(body).map(([key, value]) => [
      key,
      key === "password" ? "[워크북 실습용 비밀번호 생략]" : value,
    ]),
  );
}
async function call(name, method, endpoint, expected, body, target = base) {
  const started = performance.now();
  const res = await fetch(target + endpoint, {
    method,
    headers: {
      "Content-Type": "application/json",
      Origin: "http://localhost:5173",
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await res.text();
  const response = text ? JSON.parse(text) : null;
  report.requests.push({
    name,
    request: { method, url: target + endpoint, body: redact(body) },
    status: res.status,
    response,
    durationMs: Math.round(performance.now() - started),
  });
  // Capture newly-created rows before assertions so finally can clean up even on later failure.
  if (endpoint === "/members" && res.status === 201)
    fixtureIds.add(Number(response.result.memberId));
  assert.equal(res.status, expected, `${method} ${endpoint}: ${text}`);
  if (method !== "GET" && expected !== 204) {
    assert.deepEqual(
      Object.keys(response).sort(),
      ["isSuccess", "code", "message", "result"].sort(),
    );
    assert.equal(response.isSuccess, expected < 400);
    if (response.result && typeof response.result === "object")
      assert.equal("password" in response.result, false);
  }
  if (expected === 204) assert.equal(text, "");
  return response;
}
async function race(field) {
  const repo = dataSource.getRepository(Member);
  let arrived = 0,
    release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  const sqlErrors = [];
  const raceValue =
    field === "email" ? `${prefix}-race@example.com` : `${prefix}R`;
  const proxy = new Proxy(repo, {
    get(target, prop) {
      if (prop === "exists")
        return async (options) => {
          const exists = await target.exists(options);
          if (options.where[field] === raceValue && !exists) {
            if (++arrived === 2) release();
            await gate;
          }
          return exists;
        };
      if (prop === "save")
        return async (entity) => {
          try {
            return await target.save(entity);
          } catch (error) {
            if (error instanceof QueryFailedError)
              sqlErrors.push({
                errno: error.driverError.errno,
                code: error.driverError.code,
                constraint: field,
              });
            throw error;
          }
        };
      const value = Reflect.get(target, prop);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
  const module = await Test.createTestingModule({
    controllers: [MemberController],
    providers: [
      MemberService,
      { provide: getRepositoryToken(Member), useValue: proxy },
    ],
  }).compile();
  raceApp = module.createNestApplication();
  configureApp(raceApp, {});
  await raceApp.listen(0, "127.0.0.1");
  const raceBase = await raceApp.getUrl();
  const inputs = [1, 2].map((i) => ({
    email: `${prefix}-race${field}${i}@example.com`,
    nickname: `${prefix}${i}`,
    password,
    [field]: raceValue,
  }));
  const responses = await Promise.all(
    inputs.map(async (input, i) => {
      const res = await fetch(raceBase + "/members", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
        signal: AbortSignal.timeout(15000),
      });
      const body = await res.json();
      if (res.status === 201) fixtureIds.add(Number(body.result.memberId));
      return {
        request: {
          method: "POST",
          url: raceBase + "/members",
          body: redact(input),
        },
        status: res.status,
        response: body,
      };
    }),
  );
  assert.deepEqual(responses.map((r) => r.status).sort(), [201, 409]);
  assert.equal(arrived, 2);
  assert.equal(sqlErrors[0]?.errno, 1062);
  assert.equal(
    responses.find((r) => r.status === 409).response.code,
    field === "email" ? "MEMBER4091" : "MEMBER4092",
  );
  const [rows] = await conn.execute(
    `SELECT COUNT(*) AS count FROM member WHERE ${field} = ?`,
    [raceValue],
  );
  assert.equal(rows[0].count, 1);
  report.challenge.push({
    field,
    reproduction:
      "Test-only synchronization barrier: both production Service prechecks read false before bcrypt/save; actual TypeORM Repository + MySQL UNIQUE + production global filter. No production bypass endpoint.",
    prechecksPassed: arrived,
    dbErrors: sqlErrors,
    storedRows: rows[0].count,
    responses,
  });
  await raceApp.close();
  raceApp = null;
}
async function main() {
  conn = await mysql.createConnection({
    host: process.env.DB_HOST ?? "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3307),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: "umc_movie",
    charset: "utf8mb4",
  });
  const [baseline] = await conn.query(
    "SELECT member_id, email, nickname FROM member ORDER BY member_id",
  );
  report.baselineMembers = baseline.length;
  const valid = { email: `${prefix}@example.com`, nickname: prefix, password };
  const created = await call(
    "01 회원가입 성공",
    "POST",
    "/members",
    201,
    valid,
  );
  const id = created.result.memberId;
  const other = await call(
    "다른 소유자 확인용 실습 회원",
    "POST",
    "/members",
    201,
    { ...valid, email: `${prefix}other@example.com`, nickname: `${prefix}O` },
  );
  const otherId = other.result.memberId;
  const [[saved]] = await conn.execute(
    "SELECT password FROM member WHERE member_id = ?",
    [id],
  );
  report.passwordStorage = {
    storedLength: saved.password.length,
    bcryptCost: bcrypt.getRounds(saved.password),
    compareMatches: await bcrypt.compare(password, saved.password),
    plaintextStored: saved.password === password,
    passwordInResponse: Object.hasOwn(created.result, "password"),
  };
  assert.deepEqual(report.passwordStorage, {
    storedLength: 60,
    bcryptCost: 10,
    compareMatches: true,
    plaintextStored: false,
    passwordInResponse: false,
  });
  await call("02 회원가입 검증 실패", "POST", "/members", 400, {
    ...valid,
    email: "invalid",
    nickname: "a",
    password: "weak",
  });
  await call("03 이메일 중복", "POST", "/members", 409, {
    ...valid,
    nickname: `${prefix}E`,
  });
  await call("04 닉네임 중복", "POST", "/members", 409, {
    ...valid,
    email: `${prefix}nick@example.com`,
  });
  await call("후기 없는 초기 목록", "GET", `/members/${id}/ratings`, 200);
  const rating = await call(
    "05 평점 등록 성공",
    "POST",
    `/members/${id}/ratings`,
    201,
    { movieId: 550, score: 5, comment: "등록한 영화 평점" },
  );
  const ratingId = rating.result;
  await call("06 등록 후 실제 조회", "GET", `/members/${id}/ratings`, 200);
  await call("07 중복 평점", "POST", `/members/${id}/ratings`, 409, {
    movieId: 550,
    score: 3,
  });
  await call("08 별점 검증 실패", "POST", `/members/${id}/ratings`, 400, {
    movieId: 155,
    score: 6,
  });
  await call("후기 길이 검증 실패", "POST", `/members/${id}/ratings`, 400, {
    movieId: 155,
    score: 3,
    comment: "a".repeat(501),
  });
  await call(
    "09 평점 수정 성공",
    "PATCH",
    `/members/${id}/ratings/${ratingId}`,
    200,
    { score: 4, comment: "수정된 후기" },
  );
  const changed = await call(
    "10 수정 후 실제 조회",
    "GET",
    `/members/${id}/ratings`,
    200,
  );
  assert.equal(changed[0].score, 4);
  assert.equal(changed[0].comment, "수정된 후기");
  await call(
    "11 다른 회원의 수정 차단",
    "PATCH",
    `/members/${otherId}/ratings/${ratingId}`,
    403,
    { score: 1 },
  );
  await call(
    "12 다른 회원의 삭제 차단",
    "DELETE",
    `/members/${otherId}/ratings/${ratingId}`,
    403,
  );
  await call(
    "13 없는 평점 수정",
    "PATCH",
    `/members/${id}/ratings/9007199254740991`,
    404,
    { score: 1 },
  );
  await call(
    "없는 평점 삭제",
    "DELETE",
    `/members/${id}/ratings/9007199254740991`,
    404,
  );
  await call(
    "없는 회원 평점 등록",
    "POST",
    "/members/9007199254740991/ratings",
    404,
    { movieId: 550, score: 5 },
  );
  await call(
    "14 평점 삭제 204",
    "DELETE",
    `/members/${id}/ratings/${ratingId}`,
    204,
  );
  const empty = await call(
    "15 삭제 후 빈 목록",
    "GET",
    `/members/${id}/ratings`,
    200,
  );
  assert.deepEqual(empty, []);
  const [[count]] = await conn.execute(
    "SELECT COUNT(*) AS count FROM rating WHERE member_id = ? AND movie_id = 550",
    [id],
  );
  assert.equal(count.count, 0);
  report.ratingAfterDelete = count.count;
  await call(
    "기존 5주차 닉네임 GET 계약 보존",
    "GET",
    "/members/nickname/" + encodeURIComponent(prefix),
    200,
  );
  await call(
    "기존 5주차 이메일 GET 계약 보존",
    "GET",
    "/members/email/" + encodeURIComponent(valid.email),
    200,
  );
  const existingRatings = await call(
    "기존 5주차 회원 1 평점 보존",
    "GET",
    "/members/1/ratings",
    200,
  );
  assert.ok(Array.isArray(existingRatings));
  dataSource = new DataSource({
    type: "mysql",
    host: process.env.DB_HOST ?? "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3307),
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: "umc_movie",
    entities: [Member, Rating],
    synchronize: false,
    charset: "utf8mb4",
  });
  await dataSource.initialize();
  await race("email");
  await race("nickname");
  report.passed = true;
}
main()
  .catch((error) => {
    report.passed = false;
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await raceApp?.close();
    await dataSource?.destroy();
    if (conn) {
      for (const id of fixtureIds) {
        // Scope deletion to IDs created in this run AND their unique per-run email prefix.
        const [[row]] = await conn.execute(
          "SELECT email FROM member WHERE member_id = ?",
          [id],
        );
        if (row?.email.startsWith(prefix)) {
          await conn.execute("DELETE FROM rating WHERE member_id = ?", [id]);
          await conn.execute("DELETE FROM member WHERE member_id = ?", [id]);
        }
      }
      const [[remaining]] = await conn.execute(
        "SELECT COUNT(*) AS count FROM member WHERE email LIKE ?",
        [prefix + "%"],
      );
      report.cleanup = {
        createdMemberCount: fixtureIds.size,
        remainingFixtures: remaining.count,
        existingDataPreserved: true,
      };
      const [[finalCount]] = await conn.query(
        "SELECT COUNT(*) AS count FROM member",
      );
      assert.equal(finalCount.count, report.baselineMembers);
      await conn.end();
    }
    mkdirSync(out, { recursive: true });
    writeFileSync(
      path.join(out, "live-api-results.json"),
      JSON.stringify(report, null, 2) + "\n",
    );
    console.log(
      `Live HTTP ${report.requests.length} requests; real DB UNIQUE races ${report.challenge.length}; passed=${report.passed}; fixture cleanup=${report.cleanup?.remainingFixtures}`,
    );
  });
