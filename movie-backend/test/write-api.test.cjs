const { before, after, beforeEach, test } = require("node:test");
const assert = require("node:assert/strict");
const { Test } = require("@nestjs/testing");
const { getRepositoryToken } = require("@nestjs/typeorm");
const { QueryFailedError } = require("typeorm");
const bcrypt = require("bcrypt");
const request = require("supertest");
const { Member } = require("../dist/entity/member.entity");
const { Rating } = require("../dist/entity/rating.entity");
const { MemberController } = require("../dist/controller/member.controller");
const { RatingController } = require("../dist/controller/rating.controller");
const { MemberService } = require("../dist/service/member.service");
const { RatingService } = require("../dist/service/rating.service");
const { configureApp } = require("../dist/configure-app");

let app, memberRows, ratingRows, nextMember, nextRating, forcedError;
const valid = {
  email: "new@example.com",
  nickname: "새회원",
  password: "Umc!1234",
};
function dbError(errno, key) {
  return new QueryFailedError(
    "secret SQL",
    ["secret params"],
    Object.assign(new Error("DB secret"), {
      errno,
      sqlMessage: `Duplicate entry 'sensitive-value' for key '${key}'`,
    }),
  );
}
const members = {
  exists: async ({ where }) =>
    memberRows.some((row) =>
      Object.entries(where).every(([k, v]) => row[k] === v),
    ),
  findOneBy: async ({ memberId }) =>
    memberRows.find((row) => row.memberId === memberId) ?? null,
  create: (row) => ({ ...row }),
  save: async (row) => {
    if (forcedError) throw forcedError;
    const saved = { ...row, memberId: nextMember++ };
    memberRows.push(saved);
    return saved;
  },
};
const ratings = {
  exists: async ({ where }) =>
    ratingRows.some(
      (row) =>
        row.member.memberId === where.member.memberId &&
        row.movieId === where.movieId,
    ),
  findOne: async ({ where }) =>
    ratingRows.find((row) => row.ratingId === where.ratingId) ?? null,
  find: async ({ where }) =>
    ratingRows.filter(
      (row) => Number(row.member.memberId) === where.member.memberId,
    ),
  create: (row) => ({ ...row }),
  save: async (row) => {
    if (forcedError) throw forcedError;
    if (!row.ratingId) {
      row.ratingId = nextRating++;
      ratingRows.push(row);
    }
    row.createdAt ??= new Date();
    row.updatedAt = new Date();
    return row;
  },
  remove: async (row) => {
    ratingRows = ratingRows.filter((item) => item.ratingId !== row.ratingId);
  },
};
before(async () => {
  const module = await Test.createTestingModule({
    controllers: [MemberController, RatingController],
    providers: [
      MemberService,
      RatingService,
      { provide: getRepositoryToken(Member), useValue: members },
      { provide: getRepositoryToken(Rating), useValue: ratings },
    ],
  }).compile();
  app = module.createNestApplication();
  configureApp(app, {});
  await app.init();
});
after(async () => app?.close());
beforeEach(() => {
  memberRows = [
    { memberId: 1, email: "existing@example.com", nickname: "기존회원" },
    { memberId: 2, email: "other@example.com", nickname: "다른회원" },
  ];
  ratingRows = [];
  nextMember = 3;
  nextRating = 1;
  forcedError = null;
});
function failure(body, code) {
  assert.deepEqual(
    Object.keys(body).sort(),
    ["isSuccess", "code", "message", "result"].sort(),
  );
  assert.equal(body.isSuccess, false);
  assert.equal(body.result, null);
  if (code) assert.equal(body.code, code);
  assert.equal(typeof body.message, "string");
  assert.ok(!JSON.stringify(body).includes("sensitive-value"));
  assert.ok(!JSON.stringify(body).includes("secret"));
}
test("회원가입 201: bcrypt cost 10/60자 해시와 비밀번호 없는 응답 DTO", async () => {
  const { body } = await request(app.getHttpServer())
    .post("/members")
    .send(valid)
    .expect(201);
  assert.deepEqual(body, {
    isSuccess: true,
    code: "COMMON201",
    message: "회원가입에 성공했습니다.",
    result: { memberId: 3, email: valid.email, nickname: valid.nickname },
  });
  const saved = memberRows.at(-1);
  assert.equal(saved.password.length, 60);
  assert.equal(bcrypt.getRounds(saved.password), 10);
  assert.equal(await bcrypt.compare(valid.password, saved.password), true);
  assert.equal("password" in body.result, false);
});
for (const [name, patch] of [
  ["잘못된 이메일", { email: "invalid" }],
  ["빈 이메일", { email: "" }],
  ["짧은 닉네임", { nickname: "a" }],
  ["긴 닉네임", { nickname: "abcdefghijklm" }],
  ["공백 닉네임", { nickname: "" }],
  ["숫자 닉네임", { nickname: 123 }],
  ["대문자 없는 비밀번호", { password: "umc!1234" }],
  ["소문자 없는 비밀번호", { password: "UMC!1234" }],
  ["숫자 없는 비밀번호", { password: "Umc!abcd" }],
  ["특수문자 없는 비밀번호", { password: "Umc12345" }],
  ["짧은 비밀번호", { password: "Aa!1" }],
  ["null 비밀번호", { password: null }],
  ["72바이트 초과 비밀번호", { password: "Aa!1" + "한".repeat(23) }],
  ["등록 DTO 외 임의 필드", { memberId: 100, admin: true }],
])
  test(`회원가입 검증 400: ${name}`, async () => {
    const { body } = await request(app.getHttpServer())
      .post("/members")
      .send({ ...valid, ...patch })
      .expect(400);
    failure(body, "COMMON400");
    assert.equal(memberRows.length, 2);
  });
test("필수 입력 누락 400, 정확히 72바이트 비밀번호는 허용", async () => {
  failure(
    (await request(app.getHttpServer()).post("/members").send({}).expect(400))
      .body,
  );
  await request(app.getHttpServer())
    .post("/members")
    .send({ ...valid, password: "Aa!1" + "a".repeat(68) })
    .expect(201);
});
test("사전 이메일·닉네임 중복은 서로 다른 code와 message", async () => {
  const email = await request(app.getHttpServer())
    .post("/members")
    .send({ ...valid, email: "existing@example.com" })
    .expect(409);
  const nick = await request(app.getHttpServer())
    .post("/members")
    .send({ ...valid, nickname: "기존회원" })
    .expect(409);
  failure(email.body, "MEMBER4091");
  failure(nick.body, "MEMBER4092");
  assert.notEqual(email.body.message, nick.body.message);
  assert.equal(memberRows.length, 2);
});
for (const [key, code] of [
  ["member.email", "MEMBER4091"],
  ["member.nickname", "MEMBER4092"],
  ["uk_rating_member_movie", "RATING4091"],
  ["unknown", "COMMON409"],
]) {
  test(`DB UNIQUE 전역 변환: ${key}`, async () => {
    forcedError = dbError(1062, key);
    failure(
      (
        await request(app.getHttpServer())
          .post("/members")
          .send(valid)
          .expect(409)
      ).body,
      code,
    );
  });
}
test("FK 경쟁 삭제 오류는 404, 예기치 않은 오류는 비밀값 없는 500", async () => {
  forcedError = dbError(1452, "fk_rating_member");
  failure(
    (
      await request(app.getHttpServer())
        .post("/members")
        .send(valid)
        .expect(404)
    ).body,
    "MEMBER4041",
  );
  forcedError = new Error("secret SQL password");
  failure(
    (
      await request(app.getHttpServer())
        .post("/members")
        .send(valid)
        .expect(500)
    ).body,
    "COMMON500",
  );
});
test("평점 POST 201 → GET 반영 → PATCH 200 → GET 반영 → DELETE 204/본문 없음 → GET 빈 배열", async () => {
  const { body } = await request(app.getHttpServer())
    .post("/members/1/ratings")
    .send({ movieId: 550, score: 5, comment: "최고" })
    .expect(201);
  assert.equal(body.result, 1);
  assert.equal(body.code, "COMMON201");
  assert.equal(
    (await request(app.getHttpServer()).get("/members/1/ratings").expect(200))
      .body[0].score,
    5,
  );
  const updated = await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ score: 3, comment: "수정" })
    .expect(200);
  assert.equal(updated.body.result, null);
  assert.equal(updated.body.isSuccess, true);
  const found = await request(app.getHttpServer())
    .get("/members/1/ratings")
    .expect(200);
  assert.equal(found.body[0].score, 3);
  assert.equal(found.body[0].comment, "수정");
  const removed = await request(app.getHttpServer())
    .delete("/members/1/ratings/1")
    .expect(204);
  assert.equal(removed.text, "");
  assert.deepEqual(
    (await request(app.getHttpServer()).get("/members/1/ratings").expect(200))
      .body,
    [],
  );
});
for (const [name, patch] of [
  ["영화 ID 0", { movieId: 0 }],
  ["영화 ID 소수", { movieId: 1.5 }],
  ["영화 ID 문자열", { movieId: "550" }],
  ["영화 ID 안전 정수 초과", { movieId: 9007199254740992 }],
  ["별점 0", { score: 0 }],
  ["별점 6", { score: 6 }],
  ["별점 소수", { score: 3.5 }],
  ["별점 문자열", { score: "5" }],
  ["별점 null", { score: null }],
  ["후기 501자", { comment: "a".repeat(501) }],
  ["후기 숫자", { comment: 10 }],
  ["임의 작성자", { memberId: 2 }],
])
  test(`평점 입력 400: ${name}`, async () => {
    failure(
      (
        await request(app.getHttpServer())
          .post("/members/1/ratings")
          .send({ movieId: 550, score: 5, ...patch })
          .expect(400)
      ).body,
      "COMMON400",
    );
    assert.equal(ratingRows.length, 0);
  });
test("평점 필수 score와 PATCH의 필수 score 검증, 후기 500자/생략 허용", async () => {
  await request(app.getHttpServer())
    .post("/members/1/ratings")
    .send({ movieId: 550 })
    .expect(400);
  await request(app.getHttpServer())
    .post("/members/1/ratings")
    .send({ movieId: 550, score: 1, comment: "가".repeat(500) })
    .expect(201);
  await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ comment: "후기만" })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ score: 5, movieId: 1 })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ score: 5, comment: 1 })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ score: 5 })
    .expect(200);
  assert.equal(ratingRows[0].comment, null);
});
test("중복 평점 409/없는 회원 404/다른 회원 평점 PATCH·DELETE 403/없는 평점 404", async () => {
  await request(app.getHttpServer())
    .post("/members/1/ratings")
    .send({ movieId: 550, score: 5 })
    .expect(201);
  failure(
    (
      await request(app.getHttpServer())
        .post("/members/1/ratings")
        .send({ movieId: 550, score: 4 })
        .expect(409)
    ).body,
    "RATING4091",
  );
  failure(
    (
      await request(app.getHttpServer())
        .post("/members/999/ratings")
        .send({ movieId: 550, score: 5 })
        .expect(404)
    ).body,
    "MEMBER4041",
  );
  for (const method of ["patch", "delete"]) {
    failure(
      (
        await request(app.getHttpServer())
          [method]("/members/2/ratings/1")
          .send(method === "patch" ? { score: 3 } : undefined)
          .expect(403)
      ).body,
      "RATING4031",
    );
    failure(
      (
        await request(app.getHttpServer())
          [method]("/members/1/ratings/999")
          .send(method === "patch" ? { score: 3 } : undefined)
          .expect(404)
      ).body,
      "RATING4041",
    );
  }
  assert.equal(ratingRows.length, 1);
  assert.equal(ratingRows[0].score, 5);
});
test("DB BIGINT 문자열 작성자 ID도 정상 소유자로 인식", async () => {
  ratingRows.push({
    ratingId: 1,
    member: { memberId: "1" },
    movieId: 550,
    score: 5,
    comment: null,
  });
  await request(app.getHttpServer())
    .patch("/members/1/ratings/1")
    .send({ score: 4 })
    .expect(200);
});
test("쓰기 API 경로의 양수·안전 정수 검증과 POST/PATCH/DELETE preflight", async () => {
  for (const id of ["0", "-1", "abc", "1.5", "9007199254740992"]) {
    await request(app.getHttpServer())
      .post(`/members/${id}/ratings`)
      .send({ movieId: 550, score: 5 })
      .expect(400);
    await request(app.getHttpServer())
      .delete(`/members/1/ratings/${id}`)
      .expect(400);
  }
  for (const method of ["POST", "PATCH", "DELETE"]) {
    const res = await request(app.getHttpServer())
      .options("/members/1/ratings")
      .set("Origin", "http://localhost:5173")
      .set("Access-Control-Request-Method", method)
      .expect(204);
    assert.ok(res.headers["access-control-allow-methods"].includes(method));
  }
});
