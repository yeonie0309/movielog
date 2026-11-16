# 7주차 백엔드 실행 증빙

검증일은 2026-11-07(KST)이며 원본 JSON의 ISO 시각은 UTC이다.
실제 NestJS + TypeORM + MySQL을 사용했다. Postman 컬렉션은 Newman으로 실행했다.
01~07, 09~12는 **실제 API/CLI 기록을 로컬 읽기 전용 뷰어에서 캡처한 사진**이다.
08은 **실제 jwt.io 페이지에서 payload를 확인한 사진**이다.
13은 생성된 [PR #16](https://github.com/yeonie0309/movielog/pull/16) 화면이다.

| 파일 | 원본 Notion에서 첨부할 위치 |
| --- | --- |
| 01-login-200.jpg | 필수 미션 로그인 성공 응답, accessToken 표시 |
| 02-no-token-401.jpg | 필수 미션 토큰 없는 GET /members/me 401 |
| 03-other-member-403.jpg | 필수 미션 다른 회원 토큰으로 PATCH 403 |
| 04-rating-create-201.jpg | 필수 미션 본인 평점 POST 201, body에 memberId 없음 |
| 05-my-info-get-patch.jpg | 실습 인증의 내 정보 조회·수정 |
| 06-tampered-401.jpg | 실습 인증의 payload 한 글자 변조 401 |
| 07-expiry-before-after.jpg | 선택 미션의 만료 전 200 / 60초 후 AUTH401_4 |
| 08-jwt-io-payload.jpg | 실습 인증의 sub/email/iat/exp 디코딩 |
| 09-identical-login-failure.jpg | 실습 인증의 미가입 이메일·틀린 비밀번호 동일 응답 |
| 10-login-member-decorator.jpg | 선택 미션의 기본 예시 / 적용 코드 / 정상 API 응답 |
| 11-cli-checks.jpg | 실습 인증의 backend lint/test, Flutter analyze/test |
| 12-postman-newman.jpg | 필수 미션의 9단계 시나리오 실행 결과 |
| 13-pr-created.jpg | PR 생성 및 기준 브랜치 확인 |

로그인 A는 memberId 11, B는 12, 생성 평점은 ratingId 6, TMDB movieId 155였다.
스크립트가 두 회원과 평점을 정리한 뒤 기존 DB 행의 동일성을 확인했다.
사진의 accessToken은 localhost 실습용이며 저장 전에 만료를 확인했다.
jwt.io에서는 만료된 테스트 토큰으로 payload를 읽었다. JWT_SECRET은 로컬 환경변수로 관리한다.
서명 검증은 실제 API의 정상 요청 200 및 변조 요청 AUTH401_3으로 확인했다.

실행 로그는 `lint.txt`, `test.txt`, `flutter-analyze.txt`, `flutter-test.txt`, `newman.txt`에 있다.
실제 요청 25건과 Newman 12요청/41검증, 만료 및 정리 결과는 `live-api-results.json`에 기록했다.
`node movie-backend/scripts/serve-week7-evidence.cjs`로 동일한 기록을 로컬에서 볼 수 있다.

원본 페이지의 상단 스터디 인증샷은 실제 스터디 모임 사진을 사용한다.
필수 네 사진은 **미션 기록 토글 안에도 항목별로 직접 첨부**해 결과와 진행 과정을 함께 남긴다.
