const fs = require("node:fs");
const path = require("node:path");
const items = [];
function add(name, method, endpoint, status, body, token, code, after = []) {
  const tests = [
    `pm.test('HTTP ${status}', () => pm.response.to.have.status(${status}));`,
    "const body = pm.response.json();",
    `pm.test('공통 응답 code', () => pm.expect(body.code).to.eql('${code}'));`,
    `pm.test('isSuccess', () => pm.expect(body.isSuccess).to.eql(${status < 400}));`,
    ...after,
  ];
  items.push({
    name,
    request: {
      method,
      url: "{{baseUrl}}" + endpoint,
      header: [{ key: "Content-Type", value: "application/json" }],
      auth: token
        ? {
            type: "bearer",
            bearer: [{ key: "token", value: `{{${token}}}`, type: "string" }],
          }
        : { type: "noauth" },
      ...(body
        ? {
            body: {
              mode: "raw",
              raw: JSON.stringify(body, null, 2),
              options: { raw: { language: "json" } },
            },
          }
        : {}),
    },
    event: [
      { listen: "test", script: { type: "text/javascript", exec: tests } },
    ],
  });
}
for (const who of ["A", "B"]) {
  add(
    `01 준비 · 회원 ${who} 가입`,
    "POST",
    "/members",
    201,
    {
      email: `{{email${who}}}`,
      nickname: `{{nickname${who}}}`,
      password: "{{password}}",
    },
    null,
    "COMMON201",
    [`pm.environment.set('member${who}', body.result.memberId);`],
  );
}
for (const who of ["A", "B"]) {
  add(
    `02 로그인 · 회원 ${who}`,
    "POST",
    "/auth/login",
    200,
    { email: `{{email${who}}}`, password: "{{password}}" },
    null,
    "COMMON200",
    [
      `pm.environment.set('token${who}', body.result.accessToken);`,
      "pm.test('accessToken 존재', () => pm.expect(body.result.accessToken.split('.')).to.have.lengthOf(3));",
    ],
  );
}
add(
  "03 본인 평점 등록 · memberId 없는 body",
  "POST",
  "/ratings",
  201,
  { movieId: 155, score: 4, comment: "JWT 소유권 검증" },
  "tokenA",
  "COMMON201",
  [
    "pm.environment.set('ratingId', body.result.ratingId);",
    "pm.test('movieId 전달', () => pm.expect(body.result.movieId).to.eql(155));",
  ],
);
add(
  "04 동일 영화 중복 등록",
  "POST",
  "/ratings",
  409,
  { movieId: 155, score: 3 },
  "tokenA",
  "RATING409_1",
);
add(
  "05 본인 평점 수정",
  "PATCH",
  "/ratings/{{ratingId}}",
  200,
  { score: 5, comment: "토큰 A 수정" },
  "tokenA",
  "COMMON200",
  ["pm.test('수정 결과 DTO', () => pm.expect(body.result.score).to.eql(5));"],
);
add(
  "06 토큰 B로 회원 A 평점 수정 · 403",
  "PATCH",
  "/ratings/{{ratingId}}",
  403,
  { score: 1 },
  "tokenB",
  "RATING403_1",
);
add(
  "07 토큰 없이 수정 · 401",
  "PATCH",
  "/ratings/{{ratingId}}",
  401,
  { score: 1 },
  null,
  "AUTH401_2",
);
add(
  "08 없는 평점 삭제 · 404",
  "DELETE",
  "/ratings/9007199254740991",
  404,
  null,
  "tokenA",
  "RATING404_1",
);
add(
  "09 본인 평점 삭제 · 200 및 result null",
  "DELETE",
  "/ratings/{{ratingId}}",
  200,
  null,
  "tokenA",
  "COMMON200",
  ["pm.test('삭제 result null', () => pm.expect(body.result).to.eql(null));"],
);
add(
  "실습 인증 · 토큰 없이 내 정보 조회",
  "GET",
  "/members/me",
  401,
  null,
  null,
  "AUTH401_2",
);
const collection = {
  info: {
    name: "MovieLog 7주차 JWT 인증·인가",
    schema:
      "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
  },
  variable: [{ key: "baseUrl", value: "http://localhost:3007" }],
  event: [
    {
      listen: "prerequest",
      script: {
        type: "text/javascript",
        exec: [
          "if (!pm.environment.get('emailA')) {",
          "  const tag = 'w7' + pm.variables.replaceIn('{{$guid}}').replace(/-/g, '').slice(0, 6);",
          "  pm.environment.set('emailA', tag + 'a@example.com');",
          "  pm.environment.set('emailB', tag + 'b@example.com');",
          "  pm.environment.set('nicknameA', tag + 'A');",
          "  pm.environment.set('nicknameB', tag + 'B');",
          "  pm.environment.set('password', 'Aa9!' + pm.variables.replaceIn('{{$guid}}'));",
          "}",
        ],
      },
    },
  ],
  item: items,
};
fs.writeFileSync(
  path.resolve(__dirname, "../postman/MovieLog-week7.postman_collection.json"),
  JSON.stringify(collection, null, 2) + "\n",
);
console.log(`Postman collection generated: ${items.length} requests`);
