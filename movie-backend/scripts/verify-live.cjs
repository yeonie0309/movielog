const assert = require("node:assert/strict");
const { writeFileSync } = require("node:fs");
const path = require("node:path");
const mysql = require("mysql2/promise");
async function main() {
  const base = process.env.API_BASE_URL ?? "http://localhost:3000";
  const cases = [
    [
      "/members/nickname/" + encodeURIComponent("수현"),
      200,
      { available: false },
    ],
    ["/members/nickname/newnickname", 200, { available: true }],
    ["/members/email/noco%40umc.com", 200, { available: false }],
    ["/members/email/new%40example.com", 200, { available: true }],
    ["/members/1/ratings", 200, null],
    ["/members/3/ratings", 200, []],
    ["/members/999/ratings", 404, null],
    ["/members/nickname/a", 400, null],
    ["/members/email/invalid", 400, null],
    ["/members/1/ratings?page=0&size=1", 200, null],
    ["/members/1/ratings?page=1&size=1", 200, null],
    ["/members/1/ratings?page=-1", 400, null],
  ];
  const results = [];
  for (const [endpoint, status, expected] of cases) {
    const response = await fetch(base + endpoint, {
      headers: { Origin: "http://localhost:5173" },
    });
    const body = await response.json();
    assert.equal(response.status, status, endpoint);
    assert.equal(
      response.headers.get("access-control-allow-origin"),
      "http://localhost:5173",
    );
    if (expected) assert.deepEqual(body, expected);
    if (endpoint === "/members/1/ratings") {
      assert.equal(body.length, 2);
      assert.deepEqual(
        body.map((row) => row.movieId),
        [155, 550],
      );
      assert.ok(body[0].ratingId > body[1].ratingId);
      assert.deepEqual(
        Object.keys(body[0]).sort(),
        [
          "ratingId",
          "movieId",
          "score",
          "comment",
          "createdAt",
          "updatedAt",
        ].sort(),
      );
    }
    if (endpoint.endsWith("page=0&size=1"))
      assert.deepEqual(
        body.map((row) => row.movieId),
        [155],
      );
    if (endpoint.endsWith("page=1&size=1"))
      assert.deepEqual(
        body.map((row) => row.movieId),
        [550],
      );
    results.push({
      request: "GET " + endpoint,
      status: response.status,
      response: body,
    });
  }
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST ?? "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3307),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: "umc_movie",
    charset: "utf8mb4",
  });
  try {
    const [tables] = await conn.query("SHOW TABLES");
    assert.deepEqual(tables.map((row) => Object.values(row)[0]).sort(), [
      "favorite",
      "member",
      "rating",
    ]);
    const [constraints] = await conn.query(
      "SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = 'umc_movie' ORDER BY TABLE_NAME, CONSTRAINT_NAME",
    );
    assert.ok(
      constraints.some(
        (row) => row.CONSTRAINT_NAME === "uk_favorite_member_movie",
      ),
    );
    assert.ok(
      constraints.some(
        (row) => row.CONSTRAINT_NAME === "uk_rating_member_movie",
      ),
    );
    const [seeds] = await conn.query(
      "SELECT member_id, nickname, email FROM member ORDER BY member_id",
    );
    const report = {
      verifiedAt: new Date().toISOString(),
      environment: "NestJS + TypeORM + actual local MySQL",
      tables,
      constraints,
      seeds,
      requests: results,
    };
    writeFileSync(
      path.resolve(
        __dirname,
        "../../evidence/week5-backend/live-api-results.json",
      ),
      JSON.stringify(report, null, 2) + "\n",
    );
    console.log(
      `실제 API ${results.length}건 / 테이블 3개 / UNIQUE 제약 확인 통과 (토큰·DB 비밀번호 기록 없음)`,
    );
  } finally {
    await conn.end();
  }
}
main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
