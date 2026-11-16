# 8주차 백엔드 제출 증빙

대상 원본은 레아의 워크북 「8주차 - 서비스의 핵심 기능 만들기」이다.
https://app.notion.com/p/makeus-challenge/8-391b57f4596b82f1a1c60115790ffcb8

실제 로컬 NestJS·TypeORM·MySQL에서 HTTP 37건, 동시 중복, 실제 트랜잭션 rollback을 검증했다. 테스트 전후 기존 행의 내용이 동일함을 확인했고 이번 임시 회원·평점·즐겨찾기는 모두 제거했다.

## 사진의 의미와 첨부 위치

01~10은 Postman 데스크톱에서 실제 로컬 API에 Send 요청을 보내 촬영한 화면이다. 가져온 컬렉션에는 자동 검증의 응답 예제를 별도 보관했다. 캡처와 자동 검증은 다른 임시 회원을 사용해 생성 ID가 다를 수 있다. 임시 회원과 관련 데이터는 모두 정리했다.

| 사진 | 내용 | 원본 노션 위치 |
| --- | --- | --- |
| 01-postman-created.png | 즐겨찾기 등록201 | 실습 인증, 필수 미션 |
| 02-postman-duplicate.png | 중복409 FAVORITE409_1 | 실습 인증, 필수 미션 |
| 03-postman-list.png | 내 즐겨찾기 목록200 | 실습 인증, 필수 미션 |
| 04-postman-status-true.png | 등록 후 isFavorite true | 실습 인증, 필수 미션 |
| 05-postman-delete.png | 해제200 result null | 실습 인증, 필수 미션 |
| 06-postman-status-false.png | 해제 후 isFavorite false | 실습 인증, 필수 미션 |
| 07-postman-movie-record.png | rating과 favorite 함께 저장201 | 실습 인증, 필수 미션 |
| 08-postman-rating-only.png | false 분기 favorite null | 미션 기록 |
| 09-postman-unauthorized.png | 토큰 없는401 | 미션 기록 |
| 10-postman-record-conflict.png | 기존 즐겨찾기409 | 미션 기록 |
| 11-swagger-overview.jpg | 8주차 API 다섯 개·인증 요구 | Challenge Mission |
| 12-swagger-record-examples.jpg | 한 API 요청·성공·실패 문서 예시 | Challenge Mission |
| 13-transaction-code.jpg | 실제 transaction 코드 전체 | 실습 인증, 필수 미션 |
| 14-mysql-rollback-unique.jpg | 실제 MySQL 롤백·동시 UNIQUE·정리 | 미션 기록, 트러블슈팅 |
| 15-checks.jpg | 실제 테스트·analyze 로그 | 미션 기록 |

13~15는 실제 소스·실행 기록을 표시한 읽기 전용 뷰어 캡처다. 롤백에서는 두 번째 Favorite.save에 테스트 오류를 주입했고, 트랜잭션·DB는 실제 MySQL을 사용했다. Swagger 화면의 JSON은 문서 예시다.

실행 원본은 live-api-results.json, live-verification.txt, backend-tests-final.txt, favorite-tests.txt, backend-lint.txt, flutter-tests.txt, flutter-analyze.txt, openapi.json에 있다. 초기 실행의 실패 로그는 최종 성공 로그와 혼동되지 않도록 제출 대상에서 제외한다.

스터디 인증샷은 실제 모임 사진이므로 본인이 추가한다. 노션 전체 작성 순서는 루트 WEEK8_BACKEND_SUBMISSION_GUIDE.md를 따른다.

Postman 직접 실행 목록은 postman-live-captures.json, 정리 결과는 postman-fixture-cleanup.json에 있다. 16번 사진은 영화 기록 충돌 검증을 위해 즐겨찾기를 먼저 등록한 화면이다.

PR — https://github.com/yeonie0309/movielog/pull/18
17-pr-created.jpg는 생성된 PR 화면이며 미션 기록의 PR 링크와 함께 첨부한다.
