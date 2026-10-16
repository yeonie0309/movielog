# 5주차 백엔드 제출 증빙

2026-10-17, 실제 로컬 NestJS + TypeORM + MySQL과 Android 에뮬레이터에서 검증했습니다.
API 응답은 테스트 서비스가 아닌 실제 `umc_movie` DB의 실습용 시드입니다.

## 필수 첨부 — 실습 인증

| 확인 내용 | 첨부 파일 |
| --- | --- |
| Postman 닉네임 중복: 200 false | [11-postman-nickname-duplicate.jpg](11-postman-nickname-duplicate.jpg) |
| Postman 이메일 중복: 200 false | [12-postman-email-duplicate.jpg](12-postman-email-duplicate.jpg) |
| Postman 회원 1 평점: 최신순 2건 | [13-postman-ratings-latest.jpg](13-postman-ratings-latest.jpg) |
| CORS 설정 전 실제 Console 오류 | [04-cors-before-console.jpg](04-cors-before-console.jpg) |
| 같은 서버에 CORS 적용 후 3개 API 성공·Console 오류 없음 | [05-cors-after-console.jpg](05-cors-after-console.jpg) |

CORS Console 증빙은 앱 검증과 충돌하지 않도록 **3001번** 보조 서버에서
`CORS_DISABLED=true` → `false`로 재시작했습니다. 동일한 브라우저 Origin
`http://localhost:5173`과 동일한 API URL을 사용했습니다. 실제 앱·Postman 기본 서버는 3000번입니다.

## 필수 미션 첨부 — 미션 기록

| 확인 내용 | 첨부 파일 |
| --- | --- |
| Flutter 닉네임·이메일 중복 응답 | [06-app-duplicate.png](06-app-duplicate.png) |
| Flutter 닉네임·이메일 사용 가능 응답 | [07-app-available.png](07-app-available.png) |
| Flutter 회원별 평점 2건과 TMDB movieId | [08-app-ratings.png](08-app-ratings.png) |
| Flutter 기존 회원의 빈 목록 | [09-app-empty.png](09-app-empty.png) |
| Flutter 없는 회원 404 안내 | [10-app-not-found.png](10-app-not-found.png) |
| 회원·평점·즐겨찾기 ERD | [18-movie-service-erd.jpg](18-movie-service-erd.jpg) |

화면 전환과 버튼은 통합 테스트로 조작했습니다. 회원 ID는 에뮬레이터 숫자 IME의
합성 입력 문제를 피하기 위해 화면의 `TextEditingController`에 설정했고,
API 요청과 응답은 실제 서버를 사용했습니다. 실기기 숫자 키보드 조작은 별도 미검증입니다.

핵심 코드는 제출 가이드의 Entity/DTO/Controller/Service 경로를 참고해
Notion 코드 블록에 복사하거나, 추후 PR 파일 링크를 첨부합니다.

## 추가 증빙

- [02-web-all-apis-200.jpg](02-web-all-apis-200.jpg): 간이 프론트의 API 3개 정상 응답
- [03-web-available-200.jpg](03-web-available-200.jpg): 사용 가능 true
- [14-postman-nickname-available.jpg](14-postman-nickname-available.jpg), [15-postman-email-available.jpg](15-postman-email-available.jpg)
- [16-postman-member-not-found.jpg](16-postman-member-not-found.jpg): 없는 회원 404
- [17-cors-denied-origin.jpg](17-cors-denied-origin.jpg): `127.0.0.1:5173` 미허용 출처 차단
- [19-postman-validation-400.jpg](19-postman-validation-400.jpg): 닉네임 형식 오류 400
- [20-postman-pagination.jpg](20-postman-pagination.jpg): 두 번째 페이지 평점 1건
- [live-api-results.json](live-api-results.json): 실제 API 12건과 DB 테이블·제약
- [flutter-live-test.txt](flutter-live-test.txt): Android 실제 API 통합 테스트 통과 기록
- [cors-before-console.txt](cors-before-console.txt): 실제 브라우저 CORS 보안 오류 텍스트

실제 모임의 스터디 인증 사진은 별도 촬영·첨부해야 합니다.
