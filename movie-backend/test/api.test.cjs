const { before, after, test } = require("node:test");
const assert = require("node:assert/strict");
const { Test } = require("@nestjs/testing");
const { getRepositoryToken } = require("@nestjs/typeorm");
const request = require("supertest");
const { Member } = require("../dist/entity/member.entity");
const { Rating } = require("../dist/entity/rating.entity");
const { MemberController } = require("../dist/controller/member.controller");
const { RatingController } = require("../dist/controller/rating.controller");
const { MemberService } = require("../dist/service/member.service");
const { RatingService } = require("../dist/service/rating.service");
const { configureApp } = require("../dist/configure-app");

let app;
let blockedApp;
const rows = [
  {
    ratingId: 2,
    movieId: "155",
    score: 4,
    comment: null,
    createdAt: new Date("2026-10-02T10:00:00Z"),
    updatedAt: new Date("2026-10-02T10:00:00Z"),
    password: "must-not-leak",
  },
  {
    ratingId: 1,
    movieId: "550",
    score: 5,
    comment: "최고의 영화!",
    createdAt: new Date("2026-10-01T10:00:00Z"),
    updatedAt: new Date("2026-10-01T10:00:00Z"),
  },
];
const members = {
  exists: async ({ where }) =>
    where.nickname !== undefined
      ? where.nickname === "수현"
      : where.email !== undefined
        ? where.email === "noco@umc.com"
        : [1, 2, 3].includes(where.memberId),
};
const ratings = {
  find: async (options) => {
    assert.deepEqual(options.order, { ratingId: "DESC" });
    const result = options.where.member.memberId === 1 ? rows : [];
    return result.slice(
      options.skip ?? 0,
      options.take === undefined
        ? undefined
        : (options.skip ?? 0) + options.take,
    );
  },
};
async function createApp(env) {
  const module = await Test.createTestingModule({
    controllers: [MemberController, RatingController],
    providers: [
      MemberService,
      RatingService,
      { provide: getRepositoryToken(Member), useValue: members },
      { provide: getRepositoryToken(Rating), useValue: ratings },
    ],
  }).compile();
  const instance = module.createNestApplication();
  configureApp(instance, env);
  await instance.init();
  return instance;
}
before(async () => {
  app = await createApp({});
  blockedApp = await createApp({ CORS_DISABLED: "true" });
});
after(async () => {
  await app?.close();
  await blockedApp?.close();
});

test("닉네임·이메일의 중복과 사용 가능을 boolean DTO로 반환", async () => {
  for (const [path, expected] of [
    ["nickname/수현", false],
    ["nickname/새닉네임", true],
    ["email/noco@umc.com", false],
    ["email/new@example.com", true],
  ]) {
    const response = await request(app.getHttpServer())
      .get("/members/" + path.split("/").map(encodeURIComponent).join("/"))
      .expect(200);
    assert.deepEqual(response.body, { available: expected });
  }
});
test("유효하지 않은 닉네임·이메일은 중복 검사 전에 400", async () => {
  for (const path of [
    "nickname/a",
    "nickname/abcdefghijklmn",
    "email/not-email",
  ]) {
    await request(app.getHttpServer())
      .get("/members/" + path)
      .expect(400);
  }
});
test("평점 DTO는 최신순, 숫자 movieId, null comment, 날짜만 노출", async () => {
  const { body } = await request(app.getHttpServer())
    .get("/members/1/ratings")
    .expect(200);
  assert.deepEqual(
    body.map((row) => row.ratingId),
    [2, 1],
  );
  assert.equal(body[0].movieId, 155);
  assert.equal(body[0].comment, null);
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
  assert.equal(body[0].createdAt, "2026-10-02T10:00:00.000Z");
});
test("존재하는 회원의 빈 목록 200과 없는 회원 404 구분", async () => {
  assert.deepEqual(
    (await request(app.getHttpServer()).get("/members/3/ratings").expect(200))
      .body,
    [],
  );
  await request(app.getHttpServer()).get("/members/999/ratings").expect(404);
});
test("유효하지 않은 memberId와 페이지 인자는 400", async () => {
  for (const path of ["abc", "0", "-1", "9007199254740992"]) {
    await request(app.getHttpServer())
      .get(`/members/${path}/ratings`)
      .expect(400);
  }
  for (const query of [
    "page=-1",
    "page=abc",
    "size=0",
    "size=101",
    "extra=1",
  ]) {
    await request(app.getHttpServer())
      .get("/members/1/ratings?" + query)
      .expect(400);
  }
});
test("page/size 선택 시 페이지 조회, 인자 생략 시 기존 배열 계약 유지", async () => {
  const response = await request(app.getHttpServer())
    .get("/members/1/ratings?page=1&size=1")
    .expect(200);
  assert.deepEqual(
    response.body.map((row) => row.ratingId),
    [1],
  );
});
test("허용 출처와 OPTIONS 응답의 CORS 헤더", async () => {
  const response = await request(app.getHttpServer())
    .get("/members/1/ratings")
    .set("Origin", "http://localhost:5173")
    .expect(200);
  assert.equal(
    response.headers["access-control-allow-origin"],
    "http://localhost:5173",
  );
  const options = await request(app.getHttpServer())
    .options("/members/1/ratings")
    .set("Origin", "http://localhost:5173")
    .set("Access-Control-Request-Method", "GET")
    .expect(204);
  assert.equal(
    options.headers["access-control-allow-origin"],
    "http://localhost:5173",
  );
});
test("허용하지 않은 출처와 CORS 미설정 시 허용 헤더 없음", async () => {
  for (const [instance, origin] of [
    [app, "http://localhost:5174"],
    [blockedApp, "http://localhost:5173"],
  ]) {
    const response = await request(instance.getHttpServer())
      .get("/members/1/ratings")
      .set("Origin", origin)
      .expect(200);
    assert.equal(response.headers["access-control-allow-origin"], undefined);
  }
});
