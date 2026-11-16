const { before, after, beforeEach, test } = require("node:test");
const assert = require("node:assert/strict");
const { Test } = require("@nestjs/testing");
const { JwtModule, JwtService } = require("@nestjs/jwt");
const { ConfigService } = require("@nestjs/config");
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
const { AuthController } = require("../dist/controller/auth.controller");
const { AuthService } = require("../dist/service/auth.service");
const { jwtOptions } = require("../dist/auth/jwt-options");

let app, jwt, memberRows, ratingRows, nextMember, nextRating, forcedError;
const testSecret = "test-only-week7-jwt-key-at-least-32-bytes";
const legacyPassword = "old";
const legacyHash = bcrypt.hashSync(legacyPassword, 10);
const bearer = (id = 1) =>
  "Bearer " + jwt.sign({ sub: String(id), email: "existing@example.com" });
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
      Object.entries(where).every(([k, v]) =>
        v?.type === "not" ? row[k] !== v.value : row[k] === v,
      ),
    ),
  findOneBy: async ({ memberId }) =>
    memberRows.find((row) => row.memberId === memberId) ?? null,
  findOne: async ({ where, select }) => {
    assert.equal(select.password, true);
    return memberRows.find((row) => row.email === where.email) ?? null;
  },
  update: async ({ memberId }, patch) => {
    if (forcedError) throw forcedError;
    Object.assign(
      memberRows.find((row) => row.memberId === memberId),
      patch,
    );
  },
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
    imports: [
      JwtModule.register({
        secret: testSecret,
        signOptions: { expiresIn: 3600, algorithm: "HS256" },
      }),
    ],
    controllers: [AuthController, MemberController, RatingController],
    providers: [
      AuthService,
      MemberService,
      RatingService,
      { provide: getRepositoryToken(Member), useValue: members },
      { provide: getRepositoryToken(Rating), useValue: ratings },
    ],
  }).compile();
  jwt = module.get(JwtService);
  app = module.createNestApplication();
  configureApp(app, {});
  await app.init();
});
after(async () => app?.close());
beforeEach(() => {
  memberRows = [
    {
      memberId: 1,
      email: "existing@example.com",
      nickname: "기존회원",
      password: legacyHash,
      createdAt: new Date("2026-11-01T00:00:00Z"),
    },
    {
      memberId: 2,
      email: "other@example.com",
      nickname: "다른회원",
      password: legacyHash,
      createdAt: new Date("2026-11-01T00:00:00Z"),
    },
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
  ["uk_rating_member_movie", "RATING409_1"],
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
    "MEMBER404_1",
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
test("평점 POST 201 → GET 반영 → PATCH 200 → GET 반영 → DELETE 200/공통 응답 → GET 빈 배열", async () => {
  const { body } = await request(app.getHttpServer())
    .post("/ratings")
    .set("Authorization", bearer(1))
    .send({ movieId: 550, score: 5, comment: "최고" })
    .expect(201);
  assert.equal(body.result.ratingId, 1);
  assert.equal(body.code, "COMMON201");
  assert.equal(
    (await request(app.getHttpServer()).get("/members/1/ratings").expect(200))
      .body[0].score,
    5,
  );
  const updated = await request(app.getHttpServer())
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ score: 3, comment: "수정" })
    .expect(200);
  assert.equal(updated.body.result.score, 3);
  assert.equal(updated.body.isSuccess, true);
  const found = await request(app.getHttpServer())
    .get("/members/1/ratings")
    .expect(200);
  assert.equal(found.body[0].score, 3);
  assert.equal(found.body[0].comment, "수정");
  const removed = await request(app.getHttpServer())
    .delete("/ratings/1")
    .set("Authorization", bearer(1))
    .expect(200);
  assert.equal(removed.body.result, null);
  assert.equal(removed.body.code, "COMMON200");
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
          .post("/ratings")
          .set("Authorization", bearer(1))
          .send({ movieId: 550, score: 5, ...patch })
          .expect(400)
      ).body,
      "COMMON400",
    );
    assert.equal(ratingRows.length, 0);
  });
test("평점 필수 score와 PATCH의 필수 score 검증, 후기 500자/생략 허용", async () => {
  await request(app.getHttpServer())
    .post("/ratings")
    .set("Authorization", bearer(1))
    .send({ movieId: 550 })
    .expect(400);
  await request(app.getHttpServer())
    .post("/ratings")
    .set("Authorization", bearer(1))
    .send({ movieId: 550, score: 1, comment: "가".repeat(500) })
    .expect(201);
  await request(app.getHttpServer())
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ comment: "후기만" })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ score: 5, movieId: 1 })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ score: 5, comment: 1 })
    .expect(400);
  await request(app.getHttpServer())
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ score: 5 })
    .expect(200);
  assert.equal(ratingRows[0].comment, null);
});
test("중복 평점 409/없는 회원 404/다른 회원 평점 PATCH·DELETE 403/없는 평점 404", async () => {
  await request(app.getHttpServer())
    .post("/ratings")
    .set("Authorization", bearer(1))
    .send({ movieId: 550, score: 5 })
    .expect(201);
  failure(
    (
      await request(app.getHttpServer())
        .post("/ratings")
        .set("Authorization", bearer(1))
        .send({ movieId: 550, score: 4 })
        .expect(409)
    ).body,
    "RATING409_1",
  );
  failure(
    (
      await request(app.getHttpServer())
        .post("/ratings")
        .set("Authorization", bearer(999))
        .send({ movieId: 550, score: 5 })
        .expect(404)
    ).body,
    "MEMBER404_1",
  );
  for (const method of ["patch", "delete"]) {
    failure(
      (
        await request(app.getHttpServer())
          [method]("/ratings/1")
          .set("Authorization", bearer(2))
          .send(method === "patch" ? { score: 3 } : undefined)
          .expect(403)
      ).body,
      "RATING403_1",
    );
    failure(
      (
        await request(app.getHttpServer())
          [method]("/ratings/999")
          .set("Authorization", bearer(1))
          .send(method === "patch" ? { score: 3 } : undefined)
          .expect(404)
      ).body,
      "RATING404_1",
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
    .patch("/ratings/1")
    .set("Authorization", bearer(1))
    .send({ score: 4 })
    .expect(200);
});
test("이전 작성자 경로 제거·평점 ID 검증·쓰기 preflight", async () => {
  for (const id of ["0", "-1", "abc", "1.5", "9007199254740992"]) {
    await request(app.getHttpServer())
      .post(`/members/${id}/ratings`)
      .send({ movieId: 550, score: 5 })
      .expect(404);
    await request(app.getHttpServer())
      .delete(`/ratings/${id}`)
      .set("Authorization", bearer(1))
      .expect(400);
  }
  for (const method of ["POST", "PATCH", "DELETE"]) {
    const res = await request(app.getHttpServer())
      .options("/ratings")
      .set("Origin", "http://localhost:5173")
      .set("Access-Control-Request-Method", method)
      .expect(204);
    assert.ok(res.headers["access-control-allow-methods"].includes(method));
  }
});

test("로그인 200: bcrypt 검증, 표준 sub/email/iat/exp, 응답 비밀번호 제외", async () => {
  const { body } = await request(app.getHttpServer())
    .post("/auth/login")
    .send({ email: "existing@example.com", password: legacyPassword })
    .expect(200);
  assert.equal(body.code, "COMMON200");
  assert.deepEqual(Object.keys(body.result).sort(), [
    "accessToken",
    "nickname",
  ]);
  const payload = jwt.verify(body.result.accessToken);
  assert.equal(payload.sub, "1");
  assert.equal(payload.email, "existing@example.com");
  assert.equal(payload.exp - payload.iat, 3600);
  assert.equal(Object.hasOwn(payload, "password"), false);
});
test("미가입 이메일과 틀린 비밀번호는 완전히 같은 AUTH401_1 응답", async () => {
  const bodies = [];
  for (const email of ["missing@example.com", "existing@example.com"]) {
    const res = await request(app.getHttpServer())
      .post("/auth/login")
      .send({ email, password: "wrong" })
      .expect(401);
    failure(res.body, "AUTH401_1");
    bodies.push(res.body);
  }
  assert.deepEqual(bodies[0], bodies[1]);
});
test("로그인 DTO는 기존 약한 비밀번호를 허용하지만 빈 값·타입·임의 필드는 거절", async () => {
  for (const patch of [
    { email: "invalid" },
    { password: "" },
    { password: null },
    { password: 123 },
    { memberId: 2 },
  ]) {
    await request(app.getHttpServer())
      .post("/auth/login")
      .send({
        email: "existing@example.com",
        password: legacyPassword,
        ...patch,
      })
      .expect(400);
  }
  const password72 = "Aa1!" + "a".repeat(68);
  memberRows[0].password = bcrypt.hashSync(password72, 10);
  await request(app.getHttpServer())
    .post("/auth/login")
    .send({ email: "existing@example.com", password: password72 })
    .expect(200);
  failure(
    (
      await request(app.getHttpServer())
        .post("/auth/login")
        .send({ email: "existing@example.com", password: password72 + "x" })
        .expect(401)
    ).body,
    "AUTH401_1",
  );
});
test("Guard: 토큰 없음/다른 스킴/빈 Bearer는 AUTH401_2", async () => {
  for (const header of [null, "Basic abc", "Bearer "]) {
    const call = request(app.getHttpServer()).get("/members/me");
    if (header) call.set("Authorization", header);
    failure((await call.expect(401)).body, "AUTH401_2");
  }
});
test("Guard: payload 한 글자 교체·다른 비밀키·잘못된 JWT는 AUTH401_3", async () => {
  const token = bearer().slice(7);
  const parts = token.split(".");
  parts[1] = (parts[1][0] === "e" ? "f" : "e") + parts[1].slice(1);
  const otherKey = new JwtService({
    secret: "another-test-only-key-at-least-32-bytes",
  });
  for (const token of [
    parts.join("."),
    otherKey.sign(
      { sub: "1", email: "existing@example.com" },
      { expiresIn: 60 },
    ),
    "not-a-jwt",
  ]) {
    failure(
      (
        await request(app.getHttpServer())
          .get("/members/me")
          .set("Authorization", "Bearer " + token)
          .expect(401)
      ).body,
      "AUTH401_3",
    );
  }
});
test("Guard: 만료된 서명 유효 토큰은 AUTH401_4", async () => {
  const token = jwt.sign(
    { sub: "1", email: "existing@example.com" },
    { expiresIn: -1 },
  );
  failure(
    (
      await request(app.getHttpServer())
        .get("/members/me")
        .set("Authorization", "Bearer " + token)
        .expect(401)
    ).body,
    "AUTH401_4",
  );
});
test("Guard: 안전한 문자열 sub와 email·exp가 없는 토큰은 거절", async () => {
  for (const sub of [undefined, "0", "-1", "abc", "9007199254740992", 1]) {
    const token = jwt.sign({ sub, email: "existing@example.com" });
    failure(
      (
        await request(app.getHttpServer())
          .get("/members/me")
          .set("Authorization", "Bearer " + token)
          .expect(401)
      ).body,
      "AUTH401_3",
    );
  }
  const withoutExpiration = new JwtService({ secret: testSecret }).sign({
    sub: "1",
    email: "existing@example.com",
  });
  failure(
    (
      await request(app.getHttpServer())
        .get("/members/me")
        .set("Authorization", "Bearer " + withoutExpiration)
        .expect(401)
    ).body,
    "AUTH401_3",
  );
});
test("내 정보 DTO는 email/nickname/createdAt만 반환, 회원 없음은 MEMBER404_1", async () => {
  const { body } = await request(app.getHttpServer())
    .get("/members/me")
    .set("Authorization", bearer())
    .expect(200);
  assert.deepEqual(body.result, {
    email: "existing@example.com",
    nickname: "기존회원",
    createdAt: "2026-11-01T00:00:00.000Z",
  });
  failure(
    (
      await request(app.getHttpServer())
        .get("/members/me")
        .set("Authorization", bearer(999))
        .expect(404)
    ).body,
    "MEMBER404_1",
  );
});
test("내 닉네임 유지·수정·재조회, 타인 닉네임·DB 경쟁 중복은 MEMBER409_1", async () => {
  const patch = (nickname) =>
    request(app.getHttpServer())
      .patch("/members/me")
      .set("Authorization", bearer())
      .send({ nickname });
  await patch("기존회원").expect(200);
  assert.equal(
    (await patch("변경회원").expect(200)).body.result.nickname,
    "변경회원",
  );
  assert.equal(
    (
      await request(app.getHttpServer())
        .get("/members/me")
        .set("Authorization", bearer())
        .expect(200)
    ).body.result.nickname,
    "변경회원",
  );
  failure((await patch("다른회원").expect(409)).body, "MEMBER409_1");
  forcedError = dbError(1062, "member.nickname");
  failure((await patch("경쟁닉네임").expect(409)).body, "MEMBER409_1");
});
test("내 정보 수정은 닉네임 2~12자만 허용, 작성자 주입과 빈 요청 거절", async () => {
  for (const body of [
    {},
    { nickname: "a" },
    { nickname: "a".repeat(13) },
    { nickname: null },
    { nickname: 1 },
    { nickname: "허용닉", memberId: 2 },
    { nickname: "허용닉", email: "other@example.com" },
  ]) {
    await request(app.getHttpServer())
      .patch("/members/me")
      .set("Authorization", bearer())
      .send(body)
      .expect(400);
  }
  assert.equal(memberRows[0].nickname, "기존회원");
});
test("보호된 모든 쓰기는 인증 우선, 이전 memberId 기반 쓰기 경로는 제거", async () => {
  for (const [method, path] of [
    ["post", "/ratings"],
    ["patch", "/ratings/1"],
    ["delete", "/ratings/1"],
    ["patch", "/members/me"],
  ]) {
    failure(
      (await request(app.getHttpServer())[method](path).send({}).expect(401))
        .body,
      "AUTH401_2",
    );
  }
  for (const [method, path] of [
    ["post", "/members/1/ratings"],
    ["patch", "/members/1/ratings/1"],
    ["delete", "/members/1/ratings/1"],
  ]) {
    await request(app.getHttpServer())
      [method](path)
      .set("Authorization", bearer())
      .expect(404);
  }
});
test("소유자는 토큰으로 결정하고 쿼리 memberId 조작을 사용하지 않음", async () => {
  const { body } = await request(app.getHttpServer())
    .post("/ratings?memberId=2")
    .set("Authorization", bearer(1))
    .send({ movieId: 155, score: 4 })
    .expect(201);
  assert.equal(body.result.movieId, 155);
  assert.equal(ratingRows[0].member.memberId, 1);
  failure(
    (
      await request(app.getHttpServer())
        .delete("/ratings/1")
        .set("Authorization", bearer(2))
        .expect(403)
    ).body,
    "RATING403_1",
  );
});
test("JWT 설정은 비밀키 누락·짧은 키·잘못된 만료를 시작 전에 거절", () => {
  for (const options of [
    {},
    { JWT_SECRET: "short" },
    { JWT_SECRET: testSecret, JWT_ACCESS_EXPIRATION: "0" },
    { JWT_SECRET: testSecret, JWT_ACCESS_EXPIRATION: "1h" },
    { JWT_SECRET: testSecret, JWT_ACCESS_EXPIRATION: "1.5" },
  ]) {
    assert.throws(() => jwtOptions(new ConfigService(options)));
  }
  assert.equal(
    jwtOptions(
      new ConfigService({
        JWT_SECRET: testSecret,
        JWT_ACCESS_EXPIRATION: "60",
      }),
    ).signOptions.expiresIn,
    60,
  );
});
