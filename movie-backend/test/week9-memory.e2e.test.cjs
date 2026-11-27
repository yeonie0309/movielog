const { before, after, beforeEach, test } = require("node:test");
const assert = require("node:assert/strict");
const request = require("supertest");
const { memoryApp } = require("./helpers/memory-app.cjs");
let ctx, member, auth;
before(async () => {
  ctx = await memoryApp();
});
after(async () => {
  await ctx?.app.close();
});
beforeEach(async () => {
  await ctx.favorites.clear();
  await ctx.ratings.clear();
  await ctx.members.clear();
  member = await ctx.members.save(
    ctx.members.create({
      email: "memory@example.com",
      nickname: "메모리회원",
      password: "unused-login-fixture",
    }),
  );
  auth =
    "Bearer " +
    ctx.jwt.sign({ sub: String(member.memberId), email: member.email });
});
const call = (method, url) =>
  request(ctx.app.getHttpServer())[method](url).set("Authorization", auth);

test("favorite integration 1: 토큰 없는 POST는 401 AUTH401_2, 저장 0건", async () => {
  const response = await request(ctx.app.getHttpServer())
    .post("/favorites")
    .send({ movieId: 550 })
    .expect(401);
  assert.equal(response.body.code, "AUTH401_2");
  assert.equal(await ctx.favorites.count(), 0);
});
test("favorite integration 2: 인증 POST는 201 COMMON201과 실제 DB 저장", async () => {
  const response = await call("post", "/favorites")
    .send({ movieId: 550 })
    .expect(201);
  assert.equal(response.body.code, "COMMON201");
  assert.equal(response.body.result.movieId, 550);
  assert.equal(await ctx.favorites.count(), 1);
});
test("favorite integration 3: 중복 POST는 409 FAVORITE409_1, DB는 1건 유지", async () => {
  await call("post", "/favorites").send({ movieId: 550 }).expect(201);
  const response = await call("post", "/favorites")
    .send({ movieId: 550 })
    .expect(409);
  assert.equal(response.body.code, "FAVORITE409_1");
  assert.equal(await ctx.favorites.count(), 1);
});
test("favorite integration 4: 미등록 영화 GET은 200 isFavorite false", async () => {
  const response = await call("get", "/favorites/550").expect(200);
  assert.equal(response.body.result.isFavorite, false);
});
test("rating integration 1: 토큰 없는 POST는 401 AUTH401_2", async () => {
  const response = await request(ctx.app.getHttpServer())
    .post("/ratings")
    .send({ movieId: 550, score: 5 })
    .expect(401);
  assert.equal(response.body.code, "AUTH401_2");
  assert.equal(await ctx.ratings.count(), 0);
});
test("rating integration 2: 인증 POST는 201 COMMON201과 실제 DB 저장", async () => {
  const response = await call("post", "/ratings")
    .send({ movieId: 550, score: 5, comment: "좋아요" })
    .expect(201);
  assert.equal(response.body.code, "COMMON201");
  assert.equal(response.body.result.movieId, 550);
  assert.equal(
    (
      await ctx.ratings.findOneByOrFail({
        ratingId: response.body.result.ratingId,
      })
    ).comment,
    "좋아요",
  );
});
test("transaction: 기존 즐겨찾기 충돌은 FAVORITE409_1, 평점 개수 불변", async () => {
  await call("post", "/favorites").send({ movieId: 550 }).expect(201);
  const before = await ctx.ratings.count();
  const response = await call("post", "/movie-records")
    .send({ movieId: 550, score: 5, addToFavorites: true })
    .expect(409);
  assert.equal(response.body.code, "FAVORITE409_1");
  assert.equal(await ctx.ratings.count(), before);
});
test("transaction rollback: 첫 INSERT 이후 두 번째 INSERT 실패 시 평점을 실제 DB에서 롤백한다", async () => {
  // A real SQLite trigger rejects the SECOND write after the rating INSERT.
  // Unlike the early duplicate check, this proves rollback rather than no-write.
  await ctx.db.query(
    "CREATE TRIGGER week9_fail_favorite BEFORE INSERT ON favorite BEGIN SELECT RAISE(ABORT, 'week9 controlled second-write failure'); END;",
  );
  try {
    const before = await ctx.ratings.count();
    const response = await call("post", "/movie-records")
      .send({ movieId: 550, score: 5, addToFavorites: true })
      .expect(500);
    assert.equal(response.body.code, "COMMON500");
    assert.equal(
      await ctx.ratings.count(),
      before,
      "ROLLBACK_REQUIRED: 첫 INSERT가 남으면 트랜잭션이 무효",
    );
    assert.equal(await ctx.favorites.count(), 0);
  } finally {
    await ctx.db.query("DROP TRIGGER week9_fail_favorite");
  }
});
test("validation: 잘못된 평점은 400, DB 쓰기 없음", async () => {
  await call("post", "/ratings").send({ movieId: 550, score: 6 }).expect(400);
  assert.equal(await ctx.ratings.count(), 0);
});
test("Swagger: 모든 15개 API의 설명·인증 구분·요청 예시·오류 코드를 문서화한다", async () => {
  const operations = Object.values(ctx.document.paths).flatMap((item) =>
    ["get", "post", "patch", "delete"]
      .filter((m) => item[m])
      .map((m) => item[m]),
  );
  assert.equal(operations.length, 15);
  for (const operation of operations) {
    assert.ok(operation.summary);
    assert.ok(operation.description);
    assert.ok(operation.responses[400]);
  }
  for (const path of ["/members", "/auth/login"]) {
    const op = ctx.document.paths[path].post;
    assert.deepEqual(op.security, []);
    assert.ok(
      op.requestBody.content["application/json"].schema.properties.password
        .writeOnly,
    );
  }
  for (const [path, method, status, code] of [
    ["/ratings", "post", 409, "RATING409_1"],
    ["/ratings/{ratingId}", "patch", 403, "RATING403_1"],
    ["/members/me", "patch", 409, "MEMBER409_1"],
    ["/favorites", "post", 409, "FAVORITE409_1"],
  ]) {
    const op = ctx.document.paths[path][method];
    assert.deepEqual(op.security, [{ bearer: [] }]);
    assert.ok(op.responses[status].description.includes(code));
  }
  assert.equal(
    ctx.document.paths["/members/{memberId}/ratings"].get.responses[200]
      .content["application/json"].schema.type,
    "array",
  );
});
test("Swagger: /swagger-ui와 기존 /docs의 UI·JSON이 인증 없이 제공된다", async () => {
  for (const url of ["/swagger-ui/", "/docs/"]) {
    const response = await request(ctx.app.getHttpServer())
      .get(url)
      .expect(200);
    assert.ok(response.text.includes("Swagger UI"));
  }
  const response = await request(ctx.app.getHttpServer())
    .get("/swagger-ui-json")
    .expect(200);
  assert.equal(response.body.info.version, "9.0");
});
