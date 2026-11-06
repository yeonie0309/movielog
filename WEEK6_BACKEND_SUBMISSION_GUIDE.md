# 6주차 백엔드 제출 가이드 — 입력한 데이터를 저장하기

원본: [레아의 워크북 · 6주차 백엔드](https://app.notion.com/p/makeus-challenge/6-ad6b57f4596b83b7b7cb81df305179e9).
**이 파일은 구현·제출 초안이며 원본 Notion에 이미 반영했다는 뜻이 아닙니다.**
원본 작성은 별도 [승인 계획](WEEK6_BACKEND_NOTION_PLAN.md)에 대한 승인 후 진행합니다.

## 구현 결과

- 스택: 기존 `movie-backend/`의 NestJS + TypeORM + MySQL, 별도 Spring Boot 구현 없음.
- 작업 전 main/origin/main: `2445f60` 초기 설정. 원격 fetch 후 확인.
- 브랜치: `feature/week-6-frontend`의 `08d81d9`에서 `feature/week-6-backend` 생성.
  선행 PR #13이 열려 있어 이번 PR 기준도 6주차 프론트 브랜치로 지정합니다. main은 변경하지 않음.
- POST 회원가입: 이메일·닉네임·비밀번호 검증, bcrypt cost 10/60자 저장, password를 제외한 201 응답.
- 평점 POST/PATCH/DELETE: JSON number 1~5 정수 score, TMDB 양의 movieId, 선택 comment 최대 500자.
- 소유자 검사: 없는 평점 404, 타인의 평점 403. URL memberId는 학습용이며 인증 아님.
- 쓰기 성공·전역 오류 Wrapper: isSuccess/code/message/result. DELETE 성공만 204/본문 없음.
- 선택 Mission: 이메일 MEMBER4091·닉네임 MEMBER4092 구분, 실제 DB UNIQUE 오류에도 같은 코드·형식.
- 기존 5주차 GET 성공 응답, 기존 도서 백엔드, 기존 Flutter 코드는 보존.
- DB SELECT-only 원인을 발견하고 사용자 승인 후 **umc_movie의 INSERT/UPDATE/DELETE만** 추가.
  다른 DB·DDL·계정 비밀번호는 변경하지 않았습니다.
- npm audit에서 기존 의존성 경고 4건 확인 후 호환 범위 패치. 최종 audit 0건.

## 워크북 요구사항과 결과물 매핑

| 원본의 지정 제출물 | 확인 위치 |
| --- | --- |
| API 명세 | [WEEK6_API_SPEC.md](movie-backend/docs/WEEK6_API_SPEC.md) |
| Postman 또는 화면 요청/응답 캡처 | [증빙 01~16](evidence/week6-backend/README.md) — 실제 브라우저 요청 화면 사용 |
| 핵심 코드 링크 | 아래 ‘핵심 코드’ 목록과 PR의 각 파일 |
| 트러블 슈팅 1건 | 아래 ‘이슈 → 문제 → 해결 → 참고레퍼런스’ 원본 양식 |
| 중간 과정 기록 | 요구사항 분석 → DTO → Service → Filter → 실제 DB 권한 오류 → 재검증 순서 |
| 실습 인증 지정 3장 | 회원가입 성공 01 / 검증 실패 02 / 평점 등록 성공 03 |
| 선택 Mission DB 제약 위반 재현 | 실제 MySQL UNIQUE 경쟁 14·15 + 전역 Filter 코드 |

원본 백엔드 페이지에는 프론트와 같은 별도 ‘제출 양식’ 항목이 없습니다.
따라서 **미션 기록 토글 안에 위 제출물 네 종류를 각각 명시**하고 캡처를 직접 업로드할 계획입니다.
실습 인증의 지정 3장도 해당 칸에 직접 첨부합니다. 다른 곳의 PR 링크만으로 대체하지 않습니다.

## 검증 결과

- `npm run lint` / `npm run build`: 통과.
- `npm test`: HTTP E2E 47개 통과 (기존 조회 8 + 새 쓰기 39). 이 테스트의 Repository는 대체합니다.
- 별도 실제 MySQL: 일반 HTTP 요청 23건, UNIQUE 동시성 2쌍/4요청 통과.
  bcrypt 저장·해시 길이·cost·compare·응답 비노출, 중복 저장 없음, DELETE 후 실제 조회 확인.
- 브라우저 직접 요청 13건 및 화면 캡처, 이전 23건 검증과 별개 실행임을 구분.
- 테스트 전용 barrier로 두 요청의 사전 체크를 통과시킨 뒤 실제 DB 1062와 201/409 확인.
  운영 코드에 우회 기능을 추가하지 않았습니다.
- `flutter test`: 49개 통과. 이번 작업은 Flutter 파일을 변경하지 않았습니다.
- `flutter analyze --no-fatal-infos`: exit 0. 기존 0주차 avoid_print info 2건만 남음.
- npm audit: 0 vulnerabilities. 비밀값 비노출 검사·git diff --check 통과.
- 기존 회원 3명 보존. 실행 중 새로 만든 검증 회원 4명과 캡처 회원 1명은 정리 완료.
  기존 평점/즐겨찾기는 변경하지 않았고 AUTO_INCREMENT는 되돌리지 않았습니다.

이번에 다시 수행하지 않은 항목: iOS/실기기, Flutter의 회원가입·평점 쓰기 연동, JWT 인증.
후자는 7주차 범위이며 구현 완료로 표시하지 않습니다.

## 핵심 코드

- [회원가입 DTO](movie-backend/src/dto/create-member.dto.ts): 형식/길이/72바이트 검증.
- [평점 DTO](movie-backend/src/dto/write-rating.dto.ts): score, movieId, comment 검증.
- [경로 DTO](movie-backend/src/dto/rating-params.dto.ts): memberId/ratingId 양의 안전 정수.
- [회원가입 Service](movie-backend/src/service/member.service.ts): 사전 중복 검사·bcrypt·명시적 응답 projection.
- [평점 Service](movie-backend/src/service/rating.service.ts): CRUD·존재/소유자 검사.
- [전역 Filter](movie-backend/src/filter/http-exception.filter.ts): HTTP/DB UNIQUE/FK/500 정규화.
- [공통 응답](movie-backend/src/dto/api-response.ts), [전역 등록](movie-backend/src/configure-app.ts).
- [Member Controller](movie-backend/src/controller/member.controller.ts), [Rating Controller](movie-backend/src/controller/rating.controller.ts).
- [HTTP 회귀 테스트](movie-backend/test/write-api.test.cjs), [실제 DB 재현](movie-backend/scripts/verify-week6.cjs).

## 핵심 키워드 — 원본 항목명 유지, 복사용

### Bean Validation과 @Valid

Spring에서 DTO의 이메일·길이·범위 같은 입력 규칙을 선언하고 @Valid로 요청 검증을 실행하는 방식이다.
검증을 통과해도 회원 존재 여부나 중복 저장까지 보장되지는 않아 Service 검사와 DB 제약이 함께 필요하다.
이번 구현은 NestJS를 선택했으므로 Spring 코드를 별도 실행하지는 않았다.

### class-validator와 ValidationPipe

class-validator는 DTO에 @IsEmail, @IsInt, @Min, @MaxLength 등의 규칙을 선언한다.
전역 ValidationPipe는 요청을 DTO로 변환하고 이 규칙을 실행한다. whitelist와 forbidNonWhitelisted로
허용하지 않은 필드를 400으로 막았다. DTO 검증과 저장 단계의 UNIQUE 검증은 역할이 다르다.

### bcrypt와 salt round

비밀번호를 복호화 가능한 값이나 평문으로 저장하지 않고 bcrypt 해시로 저장한다. cost 10으로
회원마다 다른 salt가 포함된 60자 해시를 만들었다. 동일 비밀번호도 서로 다른 해시가 될 수 있으며
비교에는 bcrypt.compare를 사용한다. bcrypt는 72바이트 이후 입력을 무시하므로 초과 입력을 거부했다.
응답 DTO에는 평문과 해시 모두 제외했다.

### HTTP 201 Created / 204 No Content / 409 Conflict

회원가입·평점 등록 성공은 201, 평점 삭제 성공은 본문 없는 204, 기존 데이터와 충돌하는
이메일·닉네임·회원별 영화 평점 중복은 409를 사용했다. 수정 성공은 200, 입력 오류는 400,
소유자 불일치는 403, 없는 평점은 404로 구분했다.

### UNIQUE 제약 조건과 동시성

사전 SELECT가 중복 없음이라고 응답해도 거의 동시에 도착한 두 요청이 모두 검사를 통과할 수 있다.
member의 email/nickname UNIQUE, rating의 (member_id,movie_id) 복합 UNIQUE가 최종 중복을 막는다.
실제 MySQL 동시성 검증에서 두 사전 검사를 통과시킨 뒤 1건 저장·1건 ER_DUP_ENTRY(1062)를 확인했고,
전역 Filter가 이메일 MEMBER4091 또는 닉네임 MEMBER4092의 409 응답으로 변환했다.

### @RestControllerAdvice / Exception Filter

Controller마다 동일 try-catch를 반복하지 않고 오류를 한 곳에서 공통 응답으로 바꾸는 기능이다.
Spring의 @RestControllerAdvice에 해당하는 NestJS 전역 Exception Filter를 사용했다.
Validation 오류·업무 오류·DB UNIQUE 오류를 isSuccess/code/message/result로 통일하고,
예기치 않은 500에는 SQL·바인딩 값·스택을 노출하지 않는다. DELETE 204에는 JSON을 넣지 않는다.

## 학습 후기 — 수정 가능한 초안

조회 API와 달리 저장 API는 DTO 검증을 통과한 뒤에도 회원 존재 여부, 소유자, DB 제약을 확인해야 한다는
점을 배웠다. 실제 저장이 500으로 실패해 확인해보니 기존 DB 계정이 조회 권한만 가지고 있었고,
최소 쓰기 권한 추가와 DB 연결 재생성 후 정상 저장을 검증했다. 테스트 통과와 실제 실행 성공은 별도라는
점도 확인했다. 동시 요청에서는 사전 중복 체크만으로 부족하므로 DB UNIQUE 오류까지 같은 코드와
메시지로 처리했다. 이번 주차는 URL memberId를 쓰는 학습 단계이며, 다음에는 JWT 사용자 식별과
Flutter 저장 요청을 연결하면서 인증과 단순 소유자 비교의 차이를 더 확인하고 싶다.

## 트러블 슈팅 — 원본 양식 유지

### 이슈

회원가입의 HTTP E2E 테스트는 통과했지만 실제 MySQL에 연결한 POST /members가 201 대신
COMMON500을 반환했다. 비밀번호나 SQL 원문은 오류 응답에 노출되지 않았다.

### 문제

5주차 조회 실습용 DB 계정은 umc_movie에 SELECT 권한만 가지고 있었다. Repository를 대체한
HTTP 테스트는 DB 권한을 검사하지 않으므로 실제 INSERT 실패를 사전에 잡지 못했다.
권한 추가 후에도 기존 연결 풀은 이전 DB 권한 상태를 유지해 새 연결이 필요했다.

### 해결

SHOW GRANTS로 원인을 확인하고 사용자 승인 후 해당 DB의 INSERT·UPDATE·DELETE만 추가했다.
다른 DB 권한·비밀번호는 변경하지 않았다. 작업용 서버를 재시작해 연결을 새로 만든 뒤
회원가입 201, 평점 등록/수정/삭제, 오류 응답과 실제 DB UNIQUE 경쟁까지 재검증했다.
일반 실제 API 23건과 동시성 2쌍, 실제 브라우저 요청 13건을 통과했고 원본 JSON·화면을 남겼다.

### 참고레퍼런스

- https://dev.mysql.com/doc/refman/8.4/en/grant.html
- https://dev.mysql.com/doc/refman/8.4/en/privilege-changes.html
- https://docs.nestjs.com/exception-filters

## 미션 기록 — 원본 토글 안에 순서대로 작성할 내용

1. 요구사항 분석: 기존 조회를 보존하고 회원가입·평점 쓰기 4개 API, 공통 오류 응답과 소유자 검사 범위를 정했다.
2. 설계: DTO 형식/범위 검증 → Service 존재/중복/소유자 검사 → DB UNIQUE/FK 검증으로 책임을 나눴다.
3. 구현: 회원가입 bcrypt, 비밀번호 없는 응답 DTO, 평점 POST/PATCH/DELETE, 전역 Filter를 구현했다.
4. 실제 실패 및 해결: 조회 전용 DB 계정의 쓰기 권한 문제를 발견하고 승인받은 최소 권한 추가 후 재연결했다.
5. 요청·응답 결과: 회원가입 201, 입력 오류 400, 중복 409, 타인 소유 403, 없는 평점 404,
   수정 200 후 실제 GET 반영, 삭제 204 후 GET 빈 배열을 캡처했다.
6. 선택 미션: 두 사전 검사가 통과한 실제 MySQL 경쟁을 재현해 1건 저장·1건 409 및 DB 1062를 확인했다.
7. API 명세: WEEK6_API_SPEC.md 링크. 본문에도 4개 Method/URL·입력 규칙·성공/실패 구조를 요약한다.
8. 핵심 코드 링크: 위 DTO·Service·Controller·전역 Filter·검증 스크립트의 GitHub 링크.
9. 트러블슈팅 1건: 원본의 이슈/문제/해결/참고레퍼런스 양식으로 기록하고 여기에도 원인·해결을 요약한다.
10. 검증: npm lint/build, HTTP 47개, 실제 API 23건·DB 경쟁 2쌍, 브라우저 13건, Flutter 49개,
    analyze info 2건만, audit 0건. 각 결과의 원본 로그 또는 파일을 바로 아래 연결한다.

## 사용자에게 남는 일

1. 원본 Notion 작성 계획을 검토하고 승인하기. 승인 전에는 원본을 수정하지 않습니다.
2. 실제 스터디 사진이 아직 없다면 스터디 후 제공하기. 코딩/API 증빙으로 스터디 참석을 대신 인증하지 않습니다.
3. 학습 후기의 이해·소감을 본인 경험에 맞게 확인하기.
4. 승인 후 작성·첨부 상태를 확인하고 원본 페이지 URL을 UMC 피드백 시스템에 직접 제출하기.

API 재구현·재캡처·Postman 수동 실행은 남은 필수 작업이 아닙니다. 지정 요청·응답 캡처는 이미 준비했습니다.

## 변경 파일 전체 목록 (51개)

- `README.md`
- `WEEK6_BACKEND_NOTION_PLAN.md`
- `WEEK6_BACKEND_SUBMISSION_GUIDE.md`
- `evidence/week6-backend/01-signup-201.jpg`
- `evidence/week6-backend/02-signup-validation-400.jpg`
- `evidence/week6-backend/03-rating-create-201.jpg`
- `evidence/week6-backend/04-rating-update-200.jpg`
- `evidence/week6-backend/05-rating-after-update.jpg`
- `evidence/week6-backend/06-duplicate-email-409.jpg`
- `evidence/week6-backend/07-duplicate-nickname-409.jpg`
- `evidence/week6-backend/08-duplicate-rating-409.jpg`
- `evidence/week6-backend/09-score-validation-400.jpg`
- `evidence/week6-backend/10-owner-403.jpg`
- `evidence/week6-backend/11-rating-not-found-404.jpg`
- `evidence/week6-backend/12-rating-delete-204.jpg`
- `evidence/week6-backend/13-rating-after-delete.jpg`
- `evidence/week6-backend/14-db-email-unique-race.jpg`
- `evidence/week6-backend/15-db-nickname-unique-race.jpg`
- `evidence/week6-backend/16-bcrypt-and-cleanup.jpg`
- `evidence/week6-backend/README.md`
- `evidence/week6-backend/flutter-analyze.txt`
- `evidence/week6-backend/flutter-test.txt`
- `evidence/week6-backend/git-diff-check.txt`
- `evidence/week6-backend/live-api-results.json`
- `evidence/week6-backend/npm-audit.json`
- `evidence/week6-backend/npm-lint.txt`
- `evidence/week6-backend/npm-test.txt`
- `evidence/week6-backend/security-check.txt`
- `evidence/week6-backend/ui-request-results.json`
- `evidence/week6-backend/verification-summary.json`
- `movie-backend/README.md`
- `movie-backend/docs/WEEK6_API_SPEC.md`
- `movie-backend/docs/week6-request-console.html`
- `movie-backend/package-lock.json`
- `movie-backend/package.json`
- `movie-backend/postman/MovieLog-week6.postman_collection.json`
- `movie-backend/scripts/check-week6-evidence.cjs`
- `movie-backend/scripts/make-week6-postman.cjs`
- `movie-backend/scripts/serve-week6-evidence.cjs`
- `movie-backend/scripts/verify-week6.cjs`
- `movie-backend/src/configure-app.ts`
- `movie-backend/src/controller/member.controller.ts`
- `movie-backend/src/controller/rating.controller.ts`
- `movie-backend/src/dto/api-response.ts`
- `movie-backend/src/dto/create-member.dto.ts`
- `movie-backend/src/dto/rating-params.dto.ts`
- `movie-backend/src/dto/write-rating.dto.ts`
- `movie-backend/src/filter/http-exception.filter.ts`
- `movie-backend/src/service/member.service.ts`
- `movie-backend/src/service/rating.service.ts`
- `movie-backend/test/write-api.test.cjs`
