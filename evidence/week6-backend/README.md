# 6주차 백엔드 — 실제 실행 증빙

아래 01~13은 브라우저 요청 콘솔에서 **실제 로컬 NestJS·MySQL API를 호출한 화면**입니다.
Postman 화면으로 가장한 이미지가 아닙니다. 워크북의 ‘Postman 또는 화면 요청/응답’ 중 후자를 사용합니다.
JSON 입력·Method·URL·HTTP status·응답·실행 시각이 함께 보입니다.
비밀번호 입력은 워크북의 공개 실습용 값이며 개인 계정 비밀번호가 아닙니다.

## 실습 인증 — 원본에서 지정한 3장

| 지정 제출 항목 | 직접 첨부할 파일 |
| --- | --- |
| 회원가입 성공 응답 1장 | [01-signup-201.jpg](01-signup-201.jpg) |
| 검증 실패 응답 1장 | [02-signup-validation-400.jpg](02-signup-validation-400.jpg) |
| 평점 등록 또는 수정 성공 응답 1장 | [03-rating-create-201.jpg](03-rating-create-201.jpg), 필요 시 04 추가 |

## 미션 기록 — API 명세·핵심 코드·중간 과정과 함께 첨부

| 증빙 | 파일 |
| --- | --- |
| 평점 수정 200 → 실제 조회 반영 | [04](04-rating-update-200.jpg), [05](05-rating-after-update.jpg) |
| 이메일/닉네임 서로 다른 409 | [06](06-duplicate-email-409.jpg), [07](07-duplicate-nickname-409.jpg) |
| 중복 평점 409, 별점 범위 400 | [08](08-duplicate-rating-409.jpg), [09](09-score-validation-400.jpg) |
| 소유자 403, 없는 평점 404 | [10](10-owner-403.jpg), [11](11-rating-not-found-404.jpg) |
| DELETE 204 본문 없음 → 실제 빈 배열 조회 | [12](12-rating-delete-204.jpg), [13](13-rating-after-delete.jpg) |
| 실제 이메일 DB UNIQUE 경쟁 | [14](14-db-email-unique-race.jpg) |
| 실제 닉네임 DB UNIQUE 경쟁 | [15](15-db-nickname-unique-race.jpg) |
| 실제 bcrypt 저장 및 테스트 데이터 정리 | [16](16-bcrypt-and-cleanup.jpg) |

14~16은 실제 실행 JSON을 표시한 **검증 기록 화면**입니다. 14·15의 HTTP 서버는 테스트 전용
임시 포트이며, 운영 Service/Controller/Filter와 실제 TypeORM Repository·MySQL을 사용합니다.
barrier는 두 요청의 사전 검사 뒤 도착 시점을 맞추기 위한 테스트 장치입니다.
단순히 반복 요청하여 사전 검사에서 막힌 결과를 DB 제약 위반이라고 주장하지 않습니다.

## 원본 결과 파일

- [live-api-results.json](live-api-results.json): 실제 API 23건 + 이메일/닉네임 동시성 2쌍(4요청), DB 해시 검증, 생성 fixture 정리.
- [ui-request-results.json](ui-request-results.json): 캡처 당시 실제 브라우저 요청 13건의 DOM 읽기 기록.
- npm-lint.txt / npm-test.txt / npm-audit.json: 최종 컴파일·HTTP 테스트·의존성 점검.
- flutter-analyze.txt / flutter-test.txt: 기존 Flutter 회귀 확인.
- security-check.txt / git-diff-check.txt: 비밀값 비노출 및 공백 오류 확인.

캡처용 회원 ID 10와 그 평점은 생성·수정·삭제 확인 후 정리했습니다. 기존 회원 3명 및 기존
평점/즐겨찾기는 그대로 보존했습니다. DB AUTO_INCREMENT는 실습 후 증가한 값을 되돌리지 않습니다.

## 재현

```sh
cd movie-backend
npm ci
npm run build
PORT=3006 DB_NAME=umc_movie node --env-file=../backend/.env dist/main.js
# 다른 터미널에서:
node --env-file=../backend/.env scripts/verify-week6.cjs
node scripts/serve-week6-evidence.cjs
```

`http://localhost:5173`의 요청 콘솔은 재실행 시 실습용 회원을 다시 만들므로 기존 `w6capture01`
fixture가 없는지 확인합니다. 실행 후 회원 정리는 API에서 제공하지 않으며, 자기 실습 데이터만
확인 후 DB에서 정리해야 합니다. Postman 대안은 `MovieLog-week6.postman_collection.json`입니다.
