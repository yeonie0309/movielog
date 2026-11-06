// Read-only local viewer for saved real execution records and source snippets.
const { createServer } = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "../..");
const out = path.join(root, "evidence/week7-backend");
const escape = (value) =>
  String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
const clean = (value) =>
  value.replace(/\x1b\[[0-9;]*m/g, "").replaceAll("\r", "\n");
const card = (title, text) =>
  `<article><h2>${escape(title)}</h2><pre>${escape(text)}</pre></article>`;
createServer((req, res) => {
  const report = JSON.parse(
    fs.readFileSync(path.join(out, "live-api-results.json")),
  );
  const routes = {
    "/login": ["01 로그인 성공 · accessToken", ["02 로그인 · 회원 A"]],
    "/unauthorized": [
      "02 토큰 없는 내 정보 조회 · 401",
      ["실습 인증 · 토큰 없이 내 정보 조회"],
    ],
    "/forbidden": [
      "03 다른 회원 토큰으로 수정 · 403",
      ["06 토큰 B로 회원 A 평점 수정 · 403"],
    ],
    "/created": [
      "04 본인 토큰으로 평점 등록 · 201",
      ["03 본인 평점 등록 · memberId 없는 body"],
    ],
    "/profile": [
      "05 내 정보 조회·수정",
      ["내 정보 조회 / LoginMember 데코레이터", "닉네임 수정"],
    ],
    "/tampered": [
      "06 payload 한 글자 변경 · 서명 검증 401",
      ["payload 한 글자 교체"],
    ],
    "/expired": [
      "07 60초 만료 전·후",
      ["만료 전 /members/me 성공", "60초 만료 후 AUTH401_4"],
    ],
    "/equal-login": [
      "09 로그인 실패 응답 통일",
      ["틀린 비밀번호", "미가입 이메일"],
    ],
  };
  let title, content;
  if (routes[req.url]) {
    const [name, names] = routes[req.url];
    title = name;
    content = names
      .map((name) => {
        const record = report.requests.find((r) => r.name === name);
        return card(
          `${record.request.method} ${record.request.url} · HTTP ${record.status}`,
          JSON.stringify(record, null, 2),
        );
      })
      .join("");
  } else if (req.url === "/decorator") {
    title = "10 @LoginMember 적용 전후 및 실제 응답";
    content =
      card(
        "워크북 기본 예시 · 요청 객체에서 직접 추출",
        '@UseGuards(AuthGuard)\nasync getMyInfo(@Req() request: Request) {\n  const memberId = request["memberId"] as number;\n  return this.members.getMyInfo(memberId);\n}',
      ) +
      card(
        "프로젝트 적용 코드 · 커스텀 데코레이터",
        fs.readFileSync(
          path.join(root, "movie-backend/src/auth/login-member.decorator.ts"),
          "utf8",
        ) +
          '\n  @Get("me")' +
          fs
            .readFileSync(
              path.join(
                root,
                "movie-backend/src/controller/member.controller.ts",
              ),
              "utf8",
            )
            .split('  @Get("me")')[1]
            .split('  @Patch("me")')[0],
      ) +
      card(
        "실제 API 정상 응답",
        JSON.stringify(
          report.requests.find(
            (r) => r.name === "내 정보 조회 / LoginMember 데코레이터",
          ),
          null,
          2,
        ),
      );
  } else if (req.url === "/tests") {
    title = "11 실제 CLI 검증 결과";
    content =
      card(
        "npm run lint",
        fs.readFileSync(path.join(out, "lint.txt"), "utf8"),
      ) +
      card(
        "npm test · 실제 출력 마지막 부분",
        clean(fs.readFileSync(path.join(out, "test.txt"), "utf8"))
          .trim()
          .split("\n")
          .slice(-10)
          .join("\n"),
      ) +
      card(
        "flutter test · 실제 완료 출력",
        clean(fs.readFileSync(path.join(out, "flutter-test.txt"), "utf8"))
          .split("\n")
          .filter((line) => line.includes("All tests passed"))
          .join("\n")
          .trim(),
      ) +
      card(
        "flutter analyze --no-fatal-infos",
        fs.readFileSync(path.join(out, "flutter-analyze.txt"), "utf8"),
      );
  } else if (req.url === "/newman") {
    title = "12 실제 Postman 컬렉션 실행 결과 · Newman";
    content =
      card(
        "Newman 실제 표준 출력 · 결과 요약",
        clean(fs.readFileSync(path.join(out, "newman.txt"), "utf8"))
          .trim()
          .split("\n")
          .slice(-24)
          .join("\n"),
      ) +
      card(
        "실제 MySQL 데이터 정리 확인",
        JSON.stringify(report.cleanup, null, 2),
      );
  } else {
    res.writeHead(404);
    res.end();
    return;
  }
  const page = `<!doctype html><meta charset="utf-8"><title>${escape(title)}</title><style>body{font:16px system-ui;max-width:1200px;margin:24px;padding:0 20px;color:#182433}h1{font-size:25px;margin-bottom:8px}p{color:#465268;margin:8px 0 20px}main{display:grid;grid-template-columns:${req.url === "/newman" ? "1fr" : "repeat(auto-fit,minmax(550px,1fr))"};gap:16px}article{min-width:0;border:1px solid #cdd6df;border-radius:10px;overflow:hidden}h2{font-size:16px;background:#edf3fa;padding:12px;margin:0}pre{font:15px/1.35 Menlo,monospace;white-space:pre-wrap;overflow-wrap:anywhere;word-break:break-word;margin:0;padding:16px}</style><h1>MovieLog 7주차 · ${escape(title)}</h1><p>실제 NestJS + MySQL 실행 기록 · ${escape(report.verifiedAt)}<br>출처 · evidence/week7-backend/live-api-results.json 및 실제 CLI 로그<br>표시된 localhost 실습 토큰은 저장 전에 만료를 확인했고, 생성한 테스트 회원 2명은 정리했습니다.</p><main>${content}</main>`;
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(page);
}).listen(5177, "127.0.0.1", () =>
  console.log("Week 7 evidence viewer: http://localhost:5177/login"),
);
