const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { randomBytes } = require("node:crypto");
const mysql = require("mysql2/promise");
const { DataSource } = require("typeorm");
const { FavoriteService } = require("../dist/service/favorite.service");
const { MovieRecordService } = require("../dist/service/movie-record.service");
const { Member } = require("../dist/entity/member.entity");
const { Rating } = require("../dist/entity/rating.entity");
const { Favorite } = require("../dist/entity/favorite.entity");
const out = path.resolve(__dirname, "../../evidence/week8-backend");
const baseUrl = "http://localhost:3008";
const prefix = "w8" + randomBytes(4).toString("hex");
const password = "Aa9!" + randomBytes(15).toString("hex");
const emails = [prefix + "a@example.com", prefix + "b@example.com"];
const report = {
  verifiedAt: new Date().toISOString(),
  environment: "Real local NestJS + TypeORM + MySQL",
  requests: [],
  passed: false,
};
const options = {
  host: process.env.DB_HOST || "127.0.0.1",
  port: Number(process.env.DB_PORT || 3307),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: "umc_movie",
};
let db,
  source,
  baseline,
  memberIds = [];
async function snapshot() {
  const result = {};
  for (const table of ["member", "rating", "favorite"]) {
    const [rows] = await db.query(
      `SELECT * FROM ${table} ORDER BY ${table}_id`,
    );
    result[table] = rows;
  }
  return result;
}
async function call(name, method, endpoint, status, body, token, code) {
  const response = await fetch(baseUrl + endpoint, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: "Bearer " + token } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(15000),
  });
  const value = await response.json();
  const safeBody = body ? { ...body } : undefined;
  if (safeBody?.password) safeBody.password = "[비밀번호 생략]";
  const safeValue = structuredClone(value);
  if (safeValue.result?.accessToken)
    safeValue.result.accessToken = "[토큰 생략]";
  report.requests.push({
    name,
    request: {
      method,
      url: baseUrl + endpoint,
      body: safeBody,
      authentication: token ? "Bearer (값 생략)" : "없음",
    },
    status: response.status,
    response: safeValue,
  });
  if (status !== null) assert.equal(response.status, status, name);
  if (code) assert.equal(value.code, code, name);
  return value;
}
(async () => {
  fs.mkdirSync(out, { recursive: true });
  db = await mysql.createConnection(options);
  baseline = await snapshot();
  const [indexes] = await db.query("SHOW INDEX FROM favorite");
  report.uniqueIndex = indexes
    .filter((x) => x.Key_name === "uk_favorite_member_movie")
    .map((x) => ({ column: x.Column_name, nonUnique: x.Non_unique }));
  assert.deepEqual(
    report.uniqueIndex.map((x) => x.column),
    ["member_id", "movie_id"],
  );
  for (let i = 0; i < 2; i++) {
    const result = await call(
      "회원 " + (i ? "B" : "A") + " 생성",
      "POST",
      "/members",
      201,
      { email: emails[i], nickname: prefix + (i ? "B" : "A"), password },
    );
    memberIds.push(result.result.memberId);
  }
  const a = (
    await call("회원 A 로그인", "POST", "/auth/login", 200, {
      email: emails[0],
      password,
    })
  ).result.accessToken;
  const b = (
    await call("회원 B 로그인", "POST", "/auth/login", 200, {
      email: emails[1],
      password,
    })
  ).result.accessToken;
  await call(
    "토큰 누락",
    "POST",
    "/favorites",
    401,
    { movieId: 550 },
    null,
    "AUTH401_2",
  );
  await call(
    "무효 토큰",
    "GET",
    "/favorites",
    401,
    null,
    "invalid",
    "AUTH401_3",
  );
  assert.deepEqual(
    (await call("빈 목록", "GET", "/favorites", 200, null, a)).result,
    [],
  );
  assert.equal(
    (await call("등록 전 여부 false", "GET", "/favorites/550", 200, null, a))
      .result.isFavorite,
    false,
  );
  await call(
    "즐겨찾기 등록 201",
    "POST",
    "/favorites",
    201,
    { movieId: 550 },
    a,
    "COMMON201",
  );
  await call(
    "즐겨찾기 중복 409",
    "POST",
    "/favorites",
    409,
    { movieId: 550 },
    a,
    "FAVORITE409_1",
  );
  await call("즐겨찾기 목록", "GET", "/favorites", 200, null, a);
  assert.equal(
    (await call("등록 후 여부 true", "GET", "/favorites/550", 200, null, a))
      .result.isFavorite,
    true,
  );
  assert.deepEqual(
    (await call("B 목록 분리", "GET", "/favorites", 200, null, b)).result,
    [],
  );
  assert.equal(
    (await call("B 여부 분리", "GET", "/favorites/550", 200, null, b)).result
      .isFavorite,
    false,
  );
  await call(
    "B 해제 시도",
    "DELETE",
    "/favorites/550",
    404,
    null,
    b,
    "FAVORITE404_1",
  );
  await call(
    "B도 같은 영화 등록",
    "POST",
    "/favorites",
    201,
    { movieId: 550 },
    b,
  );
  assert.equal(
    (
      await call(
        "즐겨찾기 해제 200",
        "DELETE",
        "/favorites/550",
        200,
        null,
        a,
        "COMMON200",
      )
    ).result,
    null,
  );
  assert.equal(
    (await call("해제 후 여부 false", "GET", "/favorites/550", 200, null, a))
      .result.isFavorite,
    false,
  );
  await call(
    "재해제 404",
    "DELETE",
    "/favorites/550",
    404,
    null,
    a,
    "FAVORITE404_1",
  );
  for (const movieId of [0, -1, 1.5, "550", 9007199254740992])
    await call(
      "movieId 검증 " + movieId,
      "POST",
      "/favorites",
      400,
      { movieId },
      a,
    );
  await call(
    "memberId body 조작 거절",
    "POST",
    "/favorites",
    400,
    { movieId: 550, memberId: memberIds[1] },
    a,
  );
  await call("잘못된 경로 ID", "GET", "/favorites/0", 400, null, a);
  const both = await call(
    "영화 기록 두 행 저장",
    "POST",
    "/movie-records",
    201,
    {
      movieId: 238,
      score: 5,
      comment: "다시 보고 싶은 영화입니다.",
      addToFavorites: true,
    },
    a,
    "COMMON201",
  );
  assert.equal(both.result.rating.movieId, 238);
  assert.equal(both.result.favorite.movieId, 238);
  await call(
    "영화 기록 중복 평점",
    "POST",
    "/movie-records",
    409,
    { movieId: 238, score: 5, addToFavorites: true },
    a,
    "RATING409_1",
  );
  assert.equal(
    (
      await call(
        "평점만 저장",
        "POST",
        "/movie-records",
        201,
        { movieId: 155, score: 4, addToFavorites: false },
        a,
      )
    ).result.favorite,
    null,
  );
  await call(
    "기존 즐겨찾기 준비",
    "POST",
    "/favorites",
    201,
    { movieId: 680 },
    a,
  );
  await call(
    "기존 즐겨찾기 충돌",
    "POST",
    "/movie-records",
    409,
    { movieId: 680, score: 5, addToFavorites: true },
    a,
    "FAVORITE409_1",
  );
  const [[partial]] = await db.execute(
    "SELECT COUNT(*) AS count FROM rating WHERE member_id=? AND movie_id=680",
    [memberIds[0]],
  );
  assert.equal(partial.count, 0);
  for (const patch of [
    { score: 0 },
    { addToFavorites: "false" },
    { comment: 123 },
    { memberId: memberIds[1] },
  ])
    await call(
      "기록 DTO 검증 " + Object.keys(patch)[0],
      "POST",
      "/movie-records",
      400,
      { movieId: 13, score: 5, addToFavorites: true, ...patch },
      a,
    );
  await Promise.all([
    call("동시 요청 A", "POST", "/favorites", null, { movieId: 13 }, a),
    call("동시 요청 B", "POST", "/favorites", null, { movieId: 13 }, a),
  ]);
  const pair = report.requests.slice(-2);
  assert.deepEqual(pair.map((x) => x.status).sort(), [201, 409]);
  assert.equal(
    pair.find((x) => x.status === 409).response.code,
    "FAVORITE409_1",
  );
  source = new DataSource({
    type: "mysql",
    host: options.host,
    port: options.port,
    username: options.user,
    password: options.password,
    database: options.database,
    entities: [Member, Rating, Favorite],
    synchronize: false,
    timezone: "Z",
  });
  await source.initialize();
  // Force two real prechecks to see no row before either INSERT.
  const realFavorites = source.getRepository(Favorite);
  let arrivals = 0,
    release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  const raceRepo = new Proxy(realFavorites, {
    get(target, key) {
      if (key === "exists")
        return async (options) => {
          const found = await target.exists(options);
          if (++arrivals === 2) release();
          await gate;
          return found;
        };
      const value = target[key];
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
  const service = new FavoriteService(raceRepo, source.getRepository(Member));
  const race = await Promise.allSettled([
    service.create(memberIds[0], { movieId: 272 }),
    service.create(memberIds[0], { movieId: 272 }),
  ]);
  assert.equal(race.filter((x) => x.status === "fulfilled").length, 1);
  assert.equal(
    race.find((x) => x.status === "rejected").reason.driverError.errno,
    1062,
  );
  report.forcedUniqueRace = {
    bothPrechecksAbsent: true,
    outcomes: ["one insert succeeded", "one DB UNIQUE errno1062"],
    rowCount: await realFavorites.count({
      where: { member: { memberId: memberIds[0] }, movieId: 272 },
    }),
  };
  assert.equal(report.forcedUniqueRace.rowCount, 1);
  // Only the second save fails. MovieRecordService and transaction remain production code.
  let ratingSeenInside = false;
  const failSource = {
    transaction: (callback) =>
      source.transaction(async (manager) =>
        callback({
          getRepository(entity) {
            const repo = manager.getRepository(entity);
            if (entity !== Favorite) return repo;
            return new Proxy(repo, {
              get(target, key) {
                if (key === "save")
                  return async () => {
                    ratingSeenInside = await manager
                      .getRepository(Rating)
                      .exists({
                        where: {
                          member: { memberId: memberIds[0] },
                          movieId: 807,
                        },
                      });
                    throw new Error("test-only second write failure");
                  };
                const value = target[key];
                return typeof value === "function" ? value.bind(target) : value;
              },
            });
          },
        }),
      ),
  };
  await assert.rejects(
    () =>
      new MovieRecordService(failSource).create(memberIds[0], {
        movieId: 807,
        score: 5,
        addToFavorites: true,
      }),
    /test-only second write failure/,
  );
  const ratingAfter = await source
    .getRepository(Rating)
    .count({ where: { member: { memberId: memberIds[0] }, movieId: 807 } });
  const favoriteAfter = await realFavorites.count({
    where: { member: { memberId: memberIds[0] }, movieId: 807 },
  });
  assert.ok(ratingSeenInside);
  assert.equal(ratingAfter, 0);
  assert.equal(favoriteAfter, 0);
  report.rollback = {
    failure: "Test-only second save failure inside real MySQL transaction",
    ratingObservedBeforeFailure: true,
    ratingRowsAfterRollback: ratingAfter,
    favoriteRowsAfterRollback: favoriteAfter,
  };
  const doc = await (await fetch(baseUrl + "/docs-json")).json();
  assert.ok(doc.paths["/favorites"]);
  assert.ok(doc.paths["/movie-records"]);
  fs.writeFileSync(
    path.join(out, "openapi.json"),
    JSON.stringify(doc, null, 2),
  );
  report.passed = true;
})()
  .catch((error) => {
    report.error = { name: error.name, message: error.message };
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      if (source?.isInitialized) await source.destroy();
      if (db && baseline) {
        for (const email of emails) {
          const [rows] = await db.execute(
            "SELECT member_id FROM member WHERE email=?",
            [email],
          );
          for (const row of rows) {
            await db.execute("DELETE FROM favorite WHERE member_id=?", [
              row.member_id,
            ]);
            await db.execute("DELETE FROM rating WHERE member_id=?", [
              row.member_id,
            ]);
            await db.execute(
              "DELETE FROM member WHERE member_id=? AND email=?",
              [row.member_id, email],
            );
          }
        }
        assert.deepEqual(await snapshot(), baseline);
        report.cleanup = "Temporary rows removed; preexisting rows unchanged";
      }
    } catch (error) {
      report.cleanupError = error.message;
      report.passed = false;
      process.exitCode = 1;
    } finally {
      await db?.end();
    }
    fs.writeFileSync(
      path.join(out, "live-api-results.json"),
      JSON.stringify(report, null, 2),
    );
    console.log(
      JSON.stringify(
        {
          passed: report.passed,
          requests: report.requests.length,
          rollback: report.rollback,
          uniqueRace: report.forcedUniqueRace,
          cleanup: report.cleanup,
          error: report.error,
        },
        null,
        2,
      ),
    );
  });
