# MovieLog 5주차 Movie API

## 6주차 저장 API 확장

회원가입 및 평점 POST/PATCH/DELETE와 공통 오류 Filter를 추가했습니다.
기존 GET 성공 응답은 보존합니다. [6주차 API 명세](docs/WEEK6_API_SPEC.md),
[6주차 제출 가이드](../WEEK6_BACKEND_SUBMISSION_GUIDE.md),
[실제 요청·응답 캡처](../evidence/week6-backend/README.md)를 참고하세요.

- 필요한 DB 권한: `umc_movie`의 SELECT·INSERT·UPDATE·DELETE. 비밀번호 변경이나 DDL 권한 추가 없음.
- `npm test`: 기존 조회 8개 + 신규 쓰기 39개, 총 47개 HTTP E2E (DB Repository 대체).
- `node --env-file=../backend/.env scripts/verify-week6.cjs`: 실제 MySQL/API + DB UNIQUE 경쟁.
  **이 실행에서 새로 만든 고유 prefix fixture만 정리하며 기존 데이터는 수정하지 않습니다.**
- `node scripts/serve-week6-evidence.cjs`: 127.0.0.1:5173 실제 요청·응답 캡처 UI.
- `postman/MovieLog-week6.postman_collection.json`: 01~13 순차 실행, memberId/ratingId 자동 저장.
- `PORT=3006 DB_NAME=umc_movie node --env-file=../backend/.env dist/main.js`: 이번 증빙 서버 실행.
- 신규 회원 비밀번호는 bcrypt cost 10/60자 해시. 기존 5주차 더미 비밀번호는 마이그레이션하지 않습니다.
- 공개 v5를 사용하는 6주차 Flutter는 변경하지 않았습니다. 로그인·JWT·실제 Flutter 쓰기 연동은 다음 주차 범위입니다.

기존 `backend/`의 3~4주차 도서 서비스를 보존하고 새로 만든 NestJS + TypeORM
프로젝트입니다. [API 명세](docs/API_SPEC.md), [제출 가이드](../WEEK5_BACKEND_SUBMISSION_GUIDE.md).

## 실행

Node 24, MySQL 8. DB 스키마와 시드는 `sql/01_schema.sql` → `sql/02_seed.sql` 순서로
Workbench에서 실행합니다. 삭제 SQL은 없고 기존 도서 DB와 분리됩니다. DB 계정에는
새 `umc_movie` DB의 조회 권한이 필요합니다.

`.env.example`을 참고해 `.env`를 로컬에 생성한 뒤:

```sh
cd movie-backend
npm ci
npm run build
npm start
```

현재 Mac에서는 기존 `backend/.env`의 DB 계정을 재사용할 수 있습니다. 이 경우
그 파일에 들어 있는 도서 DB 이름을 반드시 다음처럼 덮어씁니다. 비밀번호는 출력하지 않습니다.

```sh
cd /Users/yeonie/UMC11/movielog/movie-backend
DB_NAME=umc_movie CORS_DISABLED=false node --env-file=../backend/.env dist/main.js
```

간이 프론트는 별도 터미널에서 실행합니다.

```sh
cd /Users/yeonie/UMC11/movielog/mock-frontend
python3 -m http.server 5173 --bind 127.0.0.1
```

`http://localhost:5173`에서 API 3개를 실행합니다. CORS 미설정 실습은 API 서버를
종료하고 `CORS_DISABLED=true`로 실행한 뒤, **같은 화면·URL**에서 요청합니다.
실습 후에는 `false`로 재실행합니다. CORS는 원래 출처 하나만 허용하며 `*`를 사용하지 않습니다.

Flutter는 루트에서 `flutter run -d emulator-5554`로 실행합니다.
회원가입의 중복 확인 버튼 2개, 마이페이지 → 회원별 영화 평점 조회가 실제 API에 연결됩니다.
실제 회원가입·로그인·평점 저장은 6~7주차 범위이므로 이번 조회 기능과 구분합니다.
실기기는 `--dart-define=MOVIELOG_API_BASE_URL=http://<Mac의 LAN IP>:3000`을 사용합니다.

## 검증

```sh
npm run lint
npm test
node --env-file=../backend/.env scripts/verify-live.cjs
node scripts/capture-app.cjs
```

- `npm test`: Repository를 대체한 HTTP E2E 8개. 빌드된 코드의 DTO 메타데이터까지 검증.
- `verify-live`: 실제 서버·MySQL을 사용한 요청 12건과 스키마 조회. DB를 변경하지 않음.
- `capture-app`: 실제 Android UI에서 API 3개 조회 및 제출용 PNG 자동 생성.
- Postman: `postman/MovieLog-week5.postman_collection.json` Import.
- `build:watch`는 TypeScript 컴파일 감시이며 서버 실행은 별도 터미널의 `npm start`입니다.

시드: 회원 1 수현(평점 2건), 2 민서(1건), 3 빈목록(0건).
실습 전용 더미 비밀번호 문자열을 사용하며 비밀번호는 API DTO에 포함되지 않습니다.
