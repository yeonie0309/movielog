# 9주차 백엔드 증빙
원본 노션의 정확한 순서는 루트 WEEK9_BACKEND_SUBMISSION_GUIDE.md 참고.

| 파일 | 내용 | 위치 |
|---|---|---|
| 01-swagger-all.jpg | 실제 Swagger 15개, 공개/보호 구분 | 실습인증 |
| 02-favorite-documentation.jpg | 실제 POST favorites 확장 | 실습인증 |
| 03-authorized-masked.jpg | 실제 Authorize 완료·토큰 마스킹 UI | 실습인증 |
| 04-swagger-favorite-201.jpg | 실제 memory DB POST movieId551 →201 | 실습인증 |
| 05-swagger-favorite-409.jpg | 같은 실제 요청→409/FAVORITE409_1 | 실습인증 |
| 06-required-rating-docs.jpg | 실제 평점 등록·수정 Swagger | Required |
| 07-all-tests-passed-rendered.jpg | 실제전체85/신규15 통과 로그 문서 | 실습인증·Required |
| 08-unit-code-rendered.jpg | 실제 단위 테스트4 코드 문서 | Required |
| 09-duplicate-removed-rendered.jpg | 예상된 단위·통합2 실패 원문 | 실습인증 |
| 10-transaction-removed-rendered.jpg | 예상된 rollback1 실패 원문 | 선택미션 |
| 11-live-mysql-rendered.jpg | 실제MySQL37 HTTP·동시중복·롤백·정리 결과 | 선택·미션기록 |
| 12-flutter-checks-rendered.jpg | 분석·Flutter109 회귀 원문 | 미션기록 |
| 13-rollback-code-rendered.jpg | 메모리DB 롤백 코드 문서 | 선택미션 |
| 14-restored-passed-rendered.jpg | 원본복원 후15 통과 원문 | 실습·선택 |
| 15-pr.jpg | 실제 생성된 PR 화면(생성 후 추가) | PR·미션기록 |

01~06은 실제 브라우저 캡처, 07~14는 실제원문을 렌더링한 문서로 터미널 캡처가 아니다. 운영진이 터미널 원화면을 요구할 때는 가이드의 명령을 본인 터미널에서 실행해 캡처한다. 원본 TXT·JSON·코드를 함께 제공한다.
Swagger 실습은 일회용 메모리DB, live-api-results.json은 실제MySQL이다. 실패실험은 dist 임시변경이며 SHA256 검증과 finally 복원 후 재실행했다. 실제개인 JWT/비밀번호는 증빙에 포함하지 않는다. 원본 노션/UMC 제출은 수정·실행하지 않았다.
