# Week 9 — Swagger와 회귀 테스트

## 실행
```sh
cd movie-backend
npm ci
npm test          # 기존70 + 신규15 = 85
npm run test:unit # Week9 가짜 Repository 단위4
npm run test:e2e  # 실제 sql.js DB 통합11
npm run lint
node scripts/verify-week9-mutations.cjs
```

기존 node:test 실행기를 유지한다. Jest로 옮기거나 ts-jest를 추가할 필요 없이 동일한 given/when/then 검증을 수행한다. test:e2e가 개발용 AppModule/MySQL을 가져오지 않으며, TypeORM 실제 엔티티·Repository·UNIQUE·관계·AuthGuard·ValidationPipe·예외필터를 조립한다. MySQL BIGINT 기본키는 SQLite AUTOINCREMENT가 요구하는 INTEGER로 테스트 초기화 동안만 바꾸고 즉시 메타데이터를 복원한다. 운영 엔티티와 DB 스키마는 수정하지 않는다.

## Swagger
운영 애플리케이션의 /swagger-ui와 /swagger-ui-json, 기존 /docs 및 /docs-json 모두 제공한다. 인증은 기존 bearer 스키마를 유지한다. 공개는 회원가입·로그인·닉네임 확인·이메일 확인·회원별 평점 조회 5개, 보호는 내 정보2·평점 쓰기3·즐겨찾기4·영화기록1 = 10개다.

요청/응답은 Nest에서 생성한 실제 경로에 코드 카탈로그를 보완한다. 회원별 평점과 중복 확인은 기존의 raw JSON을 그대로 문서화한다. 다른 API의 공통 envelope와 혼동하지 않는다. 모든15개에 요약·인증구분·오류400/401등이 표시된다. 기존 week8 즐겨찾기/영화기록의 예시도 보존한다.

별도 일회용 메모리 DB 브라우저 실습:
```sh
node scripts/serve-week9-local.cjs --memory
# http://127.0.0.1:3019/swagger-ui/
```
이 서버는 loopback에만 바인딩한다. /private/tmp/movielog-week9-swagger-auth.local.json에는 이 DB에만 유효한 테스트 JWT를 임시 저장한다. 캡처에 포함하지 않고 종료 시 제거한다. Authorize에는 Bearer 접두사 없이 token만 넣는다. 회원가입/로그인 예시의 Sample123!은 예시이며 실계정 비밀번호가 아니다.

## 테스트 범위
- 단위4: 즐겨찾기 신규/중복, 평점 중복/타인수정. 실패 시 DB save 미호출까지 검사.
- 메모리 통합11: 즐겨찾기4, 평점2, 기존즐겨찾기충돌1, 실제롤백1, 입력검증1, 문서계약1, 문서UI/JSON1.
- 과거70개 Repository 대체 HTTP 테스트는 별도로 유지.
- 실MySQL 37 HTTP요청, 강제 동시중복 errno1062 및 실제트랜잭션 롤백. 결과 live-api-results.json.
- MySQL검증은 schema 변경 없이 랜덤 접두사 임시회원만 만들고 finally에서 자신이 만든 행만 삭제한다. 기존 모든 행을 전후 비교한다.

## 의도적 실패
verify-week9-mutations.cjs는 dist의 두 파일을 한 번씩 변경한다. 각각 finally에서 원래 바이트를 복원하고 SHA-256을 대조한다. TS 원본은 변경하지 않는다.
1. FavoriteService 중복 if 제거: 가짜Repository 단위는 예외 누락, 통합은 UNIQUE 오류가 500이 되어 기대409 실패. 이는 MySQL 오류번호 변환과 SQLite 오류 변환이 다르다는 제한을 보여준다. 정상 코드는 사전 검사로409.
2. MovieRecordService transaction callback을 일반 manager 실행으로 교체: 두 번째 INSERT가 실패해도 평점1건이 남아 ROLLBACK_REQUIRED assertion 실패.
3. 원본 복원 후15개가 통과해야 스크립트 성공.

기존 즐겨찾기를 미리 검사해 409를 내는 테스트만으로는 실제 롤백을 증명하지 못한다. 별도의 DB trigger가 첫 INSERT 이후 두 번째 INSERT를 실패시키며, HTTP는 의도된 COMMON500을 반환한다. 이것은 실제 사용자 오류가 아닌 명시적인 실패 주입이다.

## 한계
sql.js는 MySQL의 collation, errno, 동시접속 동작을 완전히 재현하지 않는다. 실MySQL 검증을 함께 둔다. 서버 HTTP 테스트만으로 브라우저 CORS를 보장하지 않는다. Swagger는 same-origin 브라우저에서 실제 실행했으며, Flutter109개는 별도 회귀 테스트다. Flutter 실제 Android 시나리오를 이번 백엔드 작업에서 새로 녹화했다고 주장하지 않는다.

공식 참고: https://docs.nestjs.com/openapi/introduction · https://docs.nestjs.com/fundamentals/testing · https://nodejs.org/api/test.html
