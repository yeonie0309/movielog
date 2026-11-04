const { writeFileSync } = require("node:fs");
const path = require("node:path");
const item = (name, method, url, body, script) => ({
  name,
  request: {
    method,
    header: body ? [{ key: "Content-Type", value: "application/json" }] : [],
    url: "{{baseUrl}}" + url,
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
  ...(script
    ? {
        event: [
          {
            listen: "test",
            script: { type: "text/javascript", exec: script.split("\n") },
          },
        ],
      }
    : {}),
});
const collection = {
  info: {
    name: "MovieLog · Week 6 · 실제 저장 API",
    schema:
      "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    description:
      "로컬 실습용. 01→02→03 순서로 실행. password는 공개 워크북 예제 전용이며 개인 비밀번호가 아님. 5주차 GET 계약 유지. 204는 JSON 본문 없음.",
  },
  variable: [
    { key: "baseUrl", value: "http://localhost:3006" },
    { key: "tag", value: "w6capture01" },
    { key: "memberId", value: "" },
    { key: "ratingId", value: "" },
  ],
  item: [
    item(
      "01 회원가입 성공 · 201 · 비밀번호 응답 제외",
      "POST",
      "/members",
      {
        email: "{{tag}}@example.com",
        password: "Umc!1234",
        nickname: "{{tag}}",
      },
      'pm.test("201 Created", () => pm.response.to.have.status(201));\nconst body=pm.response.json();\npm.test("password excluded",()=>pm.expect(body.result).not.to.have.property("password"));\nif(pm.response.code===201)pm.collectionVariables.set("memberId",body.result.memberId);',
    ),
    item(
      "02 회원가입 입력 검증 실패 · 400",
      "POST",
      "/members",
      { email: "invalid-email", password: "weak", nickname: "a" },
      'pm.test("400 + common response",()=>{pm.response.to.have.status(400);pm.expect(pm.response.json().isSuccess).to.eql(false)});',
    ),
    item(
      "03 평점 등록 · 201",
      "POST",
      "/members/{{memberId}}/ratings",
      { movieId: 550, score: 5, comment: "워크북 평점 등록 실습" },
      'pm.test("201 Created",()=>pm.response.to.have.status(201));\nif(pm.response.code===201)pm.collectionVariables.set("ratingId",pm.response.json().result);',
    ),
    item(
      "04 평점 수정 · 200",
      "PATCH",
      "/members/{{memberId}}/ratings/{{ratingId}}",
      { score: 4, comment: "수정 후 조회로 확인할 후기" },
    ),
    item("05 수정 후 조회 · 200", "GET", "/members/{{memberId}}/ratings"),
    item("06 중복 이메일 · 409", "POST", "/members", {
      email: "{{tag}}@example.com",
      password: "Umc!1234",
      nickname: "newnickname",
    }),
    item("07 중복 닉네임 · 409", "POST", "/members", {
      email: "new-{{tag}}@example.com",
      password: "Umc!1234",
      nickname: "{{tag}}",
    }),
    item("08 중복 평점 · 409", "POST", "/members/{{memberId}}/ratings", {
      movieId: 550,
      score: 3,
    }),
    item("09 잘못된 별점 · 400", "POST", "/members/{{memberId}}/ratings", {
      movieId: 155,
      score: 6,
    }),
    item(
      "10 다른 회원의 평점 수정 · 403",
      "PATCH",
      "/members/1/ratings/{{ratingId}}",
      { score: 1 },
    ),
    item(
      "11 없는 평점 · 404",
      "PATCH",
      "/members/{{memberId}}/ratings/9007199254740991",
      { score: 1 },
    ),
    item(
      "12 평점 삭제 · 204",
      "DELETE",
      "/members/{{memberId}}/ratings/{{ratingId}}",
      null,
      'pm.test("204 without body",()=>{pm.response.to.have.status(204);pm.expect(pm.response.text()).to.eql("")});',
    ),
    item("13 삭제 후 조회 · 빈 배열", "GET", "/members/{{memberId}}/ratings"),
  ],
};
writeFileSync(
  path.resolve(__dirname, "../postman/MovieLog-week6.postman_collection.json"),
  JSON.stringify(collection, null, 2) + "\n",
);
