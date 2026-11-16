const fs = require("node:fs");
const path = require("node:path");
const report = require("../../evidence/week8-backend/live-api-results.json");
const names = [
  "즐겨찾기 등록 201",
  "즐겨찾기 중복 409",
  "즐겨찾기 목록",
  "등록 후 여부 true",
  "즐겨찾기 해제 200",
  "해제 후 여부 false",
  "영화 기록 두 행 저장",
  "평점만 저장",
  "토큰 누락",
  "기존 즐겨찾기 충돌",
];
const items = names.map((name, i) => {
  const row = report.requests.find((r) => r.name === name);
  const endpoint = new URL(row.request.url).pathname;
  const request = {
    method: row.request.method,
    header: [{ key: "Content-Type", value: "application/json" }],
    auth:
      row.request.authentication === "없음"
        ? { type: "noauth" }
        : {
            type: "bearer",
            bearer: [
              { key: "token", value: "{{accessToken}}", type: "string" },
            ],
          },
    url: "{{baseUrl}}" + endpoint,
    description:
      "실제 로컬 API 실행 응답을 예제로 보관했습니다. 실행 원본은 evidence/week8-backend/live-api-results.json에 있습니다. 재실행은 본인 토큰을 로컬 환경 accessToken 변수에 설정합니다.",
    ...(row.request.body
      ? {
          body: {
            mode: "raw",
            raw: JSON.stringify(row.request.body, null, 2),
            options: { raw: { language: "json" } },
          },
        }
      : {}),
  };
  return {
    name: String(i + 1).padStart(2, "0") + " " + name,
    request,
    response: [
      {
        name: "실제 실행 응답 · " + row.status,
        originalRequest: request,
        status: {
          200: "OK",
          201: "Created",
          401: "Unauthorized",
          409: "Conflict",
        }[row.status],
        code: row.status,
        header: [
          { key: "Content-Type", value: "application/json; charset=utf-8" },
        ],
        _postman_previewlanguage: "json",
        body: JSON.stringify(row.response, null, 2),
      },
    ],
  };
});
const collection = {
  info: {
    name: "MovieLog 8주차 Backend · 실제 실행 응답",
    schema:
      "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    description:
      "실제 NestJS + MySQL 실행 응답 예제. 비밀번호·토큰 값은 포함하지 않습니다. 예제를 열어 보거나 본인의 로컬 토큰으로 요청을 재실행합니다.",
  },
  variable: [
    { key: "baseUrl", value: "http://localhost:3008" },
    { key: "accessToken", value: "" },
  ],
  item: items,
};
fs.writeFileSync(
  path.resolve(__dirname, "../postman/MovieLog-week8.postman_collection.json"),
  JSON.stringify(collection, null, 2),
);
