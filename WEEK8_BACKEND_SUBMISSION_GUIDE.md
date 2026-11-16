# 8주차 백엔드 원본 노션 작성 가이드

대상은 레아의 워크북 「8주차 - 서비스의 핵심 기능 만들기」이다.
https://app.notion.com/p/makeus-challenge/8-391b57f4596b82f1a1c60115790ffcb8

PR_LINK_PENDING

브랜치는 feature/week-8-backend이다. 원격 main은 a10ad32로 이전 주차 전체가 반영되지 않았다. 8주차 프론트 PR #17이 반영된 origin/feature/week-7-backend의 2fa4973에서 작업했다. 원본 페이지의 별도 브랜치·PR 제목 규칙을 찾지 못해 기존 feature/week-N-backend 형식을 사용했다.

## 1. 스터디 인증샷

맨 위 「잠깐! 스터디 인증샷」에는 실제 스터디 모임 사진을 본인이 첨부한다. 아래 「실습 인증」에는 기술 실행 사진을 넣는다.

## 2. 핵심 키워드

아래 각 정의를 해당 키워드 아래에 붙여넣는다. 설명할 수 있는지 본인이 확인한다.

### 트랜잭션(Transaction)

트랜잭션은 여러 데이터베이스 작업을 하나의 논리적 작업 단위로 묶어 처리하는 기능이다. 모든 작업이 성공하면 commit하고 중간에 실패하면 rollback한다. 평점과 즐겨찾기 동시 저장에서는 Rating.save와 Favorite.save가 한 트랜잭션에 속해야 한다. NestJS·TypeORM 구현에서는 DataSource.transaction() 콜백의 manager로 꺼낸 Repository만 사용했다. 주입받은 일반 Repository를 섞어 사용하면 같은 트랜잭션 연결에 참여하지 않을 수 있어 이 방식을 선택했다.

참고 — https://typeorm.io/docs/transactions/

### commit / rollback

commit은 트랜잭션의 변경을 최종 확정하는 작업이다. rollback은 트랜잭션에서 수행한 변경을 취소하는 작업이다. 영화 기록 저장에서 즐겨찾기 저장이 실패하면 앞서 실행한 평점 INSERT도 취소되어야 한다. 실제 MySQL 트랜잭션에서 두 번째 저장에 오류를 넣고, 앞선 평점이 트랜잭션 내부에 존재했다가 종료 후 0건이 되는 것을 확인했다.

참고 — https://typeorm.io/docs/transactions/

### 원자성(Atomicity)

원자성은 트랜잭션의 작업들이 모두 반영되거나 모두 반영되지 않아야 한다는 성질이다. 영화 기록 요청의 addToFavorites가 true일 때 평점과 즐겨찾기는 함께 저장되어야 한다. 평점만 남으면 사용자가 의도한 결과가 완성되지 않는다. 서비스에서 오류를 삼키지 않고 트랜잭션 콜백 밖으로 전달해 두 저장의 원자성을 유지했다.

참고 — https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html

### ACID

ACID는 트랜잭션의 네 성질인 원자성·일관성·격리성·지속성을 뜻한다. 원자성은 전체 성공 또는 취소, 일관성은 제약을 만족하는 상태 유지, 격리성은 동시 작업 사이의 간섭 제어, 지속성은 commit한 데이터의 보존을 의미한다. 영화 기록에서는 트랜잭션으로 두 저장을 묶고 UNIQUE로 중복 관계를 제한한다. 격리 수준에 따라 동시 요청이 관찰하는 데이터가 달라질 수 있어 사전 중복 검사만으로 중복을 막는다고 가정하지 않았다.

참고 — https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html

### UNIQUE 제약 조건

UNIQUE는 지정된 컬럼 또는 컬럼 조합이 중복되는 행을 데이터베이스에서 거절하는 제약 조건이다. favorite의 (member_id, movie_id)에 적용하면 한 회원이 같은 영화를 두 번 등록하는 것을 막으면서 여러 회원이 같은 영화를 등록할 수 있다. 서버의 사전 검사는 명확한 오류를 빠르게 안내하고, DB UNIQUE는 동시에 검사를 통과한 요청까지 막는다. 실제 두 검사가 모두 미등록을 확인하도록 한 뒤 INSERT를 진행했을 때 한 건만 저장됐다. DB 1062 오류는 제약 이름을 기준으로 FAVORITE409_1로 변환하고 내부 SQL은 반환하지 않았다.

참고 — https://dev.mysql.com/doc/refman/8.4/en/create-table.html

### 낙관적 잠금(Optimistic Locking)

낙관적 잠금은 데이터를 읽을 때의 버전과 수정 시점의 버전을 비교해 동시 수정 충돌을 감지하는 방법이다. 두 사용자가 version 3인 평점을 읽은 뒤 한 요청이 먼저 수정해 version 4가 되면, 다른 요청의 version 3 기반 수정은 충돌로 처리한다. SQL에서는 WHERE id = ? AND version = ? 조건과 갱신된 행 수를 이용할 수 있다. UNIQUE가 중복 행 생성을 제한하는 데 비해 낙관적 잠금은 기존 행의 변경 내용이 덮어써지는 충돌을 감지한다. 이 주차 구현의 즐겨찾기 중복 방지는 UNIQUE를 사용했으며, 버전 필드를 사용하는 낙관적 잠금 기능은 추가하지 않았다.

참고 — https://typeorm.io/docs/entities/

## 3. 학습 후기 초안

본인의 이해에 맞춰 조정한 뒤 붙여넣는다.

평점과 즐겨찾기를 각각 저장하면 두 번째 작업이 실패했을 때 평점만 남을 수 있다는 점을 트랜잭션으로 확인했다. TypeORM에서는 콜백의 manager가 만든 Repository를 사용해야 두 저장이 같은 트랜잭션에 참여한다는 점이 중요했다.

서버 사전 중복 검사만으로는 동시 요청을 막을 수 없어 복합 UNIQUE를 함께 유지했다. 동시에 두 검사가 미등록을 확인하는 상황을 재현해도 실제 DB에는 한 행만 남았고, DB 오류는 서비스의 중복 코드로 변환했다. 낙관적 잠금과 UNIQUE가 각각 동시 수정과 중복 생성을 다룬다는 차이도 정리했다.

## 4. 실습 체크리스트

기술 구현·실제 실행 검증을 완료했다. 아래 증빙을 확인하고 원본 일곱 항목을 체크한다.

| 원본 항목 | 증빙 |
| --- | --- |
| Favorite 엔티티가 BaseTimeEntity를 상속하고 member·movieId 저장 | entity/favorite.entity.ts |
| POST /favorites에서 토큰 회원 사용, 요청 memberId 제외 | 01, Controller의 @LoginMember |
| 중복 요청409 FAVORITE409_1 | 02, live-api-results.json |
| 내 목록 최신 등록순 | 03, FavoriteService 및 HTTP 회귀 테스트 |
| 등록 전후 isFavorite false·true | 실행 원본의 등록 전 false와 04 true. 06은 해제 후 false |
| DELETE 200 공통 응답 | 05 |
| 평점·즐겨찾기를 같은 트랜잭션에 저장 | 07, 13, 14 |

## 5. 실습 인증

원본의 네 요청 아래에 다음 사진과 문구를 넣는다.

1. POST 성공·중복 — 01-postman-created.png, 02-postman-duplicate.png.
2. 목록·여부·해제 — 03-postman-list.png, 04-postman-status-true.png, 05-postman-delete.png, 06-postman-status-false.png.
3. 영화 기록 성공 — 07-postman-movie-record.png.
4. 트랜잭션 코드 — 13-transaction-code.jpg와 아래 한 문장.

평점과 즐겨찾기는 하나의 영화 기록 요청이므로 DataSource.transaction() 안에서 두 저장을 실행해, 두 번째 저장 실패 시 먼저 저장한 평점까지 함께 취소하도록 했다.

01~10 사진은 Postman 데스크톱에서 실제 로컬 API에 요청을 보내 촬영한 응답이다. 자동 검증의 HTTP 37건은 live-api-results.json에 별도 기록했다. 두 실행에 사용한 임시 회원과 관련 데이터는 모두 정리했으며 사진에서 토큰·비밀번호는 제외했다.

## 6. 필수 Standard Mission

기술 구현 완료. 실습 인증의 01~07과 13 사진을 여기에 다시 첨부하거나 같은 페이지의 실습 인증 위치를 안내한다. 핵심 코드 링크와 과정 설명을 반드시 함께 넣는다.

복사할 문구

NestJS 스택으로 POST /favorites, GET /favorites, GET /favorites/{movieId}, DELETE /favorites/{movieId}, POST /movie-records를 구현했다. 로그인한 회원은 AuthGuard와 @LoginMember로 식별하고 요청 body에는 movieId 등 기능 입력만 받는다. 즐겨찾기는 회원별 최신순으로 조회하며 중복409·없는 관계404·잘못된 입력400·인증 실패401을 공통 응답으로 처리했다.

addToFavorites가 true이면 평점과 즐겨찾기를 같은 트랜잭션에서 저장하고, false이면 평점만 저장하여 favorite null을 반환한다. 사전 검사와 DB 복합 UNIQUE를 함께 적용했으며 DB 중복 오류도 FAVORITE409_1로 변환했다.

핵심 코드

- https://github.com/yeonie0309/movielog/blob/feature/week-8-backend/movie-backend/src/entity/favorite.entity.ts
- https://github.com/yeonie0309/movielog/blob/feature/week-8-backend/movie-backend/src/controller/favorite.controller.ts
- https://github.com/yeonie0309/movielog/blob/feature/week-8-backend/movie-backend/src/service/favorite.service.ts
- https://github.com/yeonie0309/movielog/blob/feature/week-8-backend/movie-backend/src/service/movie-record.service.ts

## 7. 선택 Challenge Mission

Swagger를 적용했다. 11-swagger-overview.jpg와 12-swagger-record-examples.jpg를 첨부한다.

복사할 문구

Swagger UI /docs와 OpenAPI JSON /docs-json을 제공했다. 즐겨찾기·영화 기록 API의 Method·URL·입력 규칙·요청 예시·성공/실패 상태와 code를 문서화했다. 보호 API에는 Bearer 인증 요구를 표시하고 공개 로그인·회원가입·중복 확인·회원별 평점 조회와 구분했다. Swagger 예시는 문서 예시이며 실제 실행 증빙은 Postman 직접 요청 사진과 실행 원본으로 첨부했다.

## 8. 미션 기록

원본 「미션 기록」 토글 안에 아래 내용을 붙여넣고, 08~10·14·15 사진과 PR 링크를 함께 첨부한다. 이 페이지는 프론트 제출 양식과 구성이 달라 별도 제출 양식 필드를 만들 필요가 없다.

1. 요구사항 분석

즐겨찾기 API 네 개와 영화 기록 API를 확인했다. 사용자 식별은 토큰을 사용하고, 빈 목록·미등록 여부를 정상 응답으로 처리해야 한다는 계약을 정리했다. 기존 NestJS·TypeORM 코드와 5주차 favorite 스키마를 확인해 재사용했다.

2. 구현 과정

Favorite 엔티티와 입력·응답 DTO를 추가한 뒤 Service·Controller를 AppModule에 등록했다. 기존 AuthGuard·@LoginMember·ValidationPipe·공통 응답을 사용했다. MovieRecordService는 콜백 manager의 Repository만 사용해 두 저장을 하나의 트랜잭션으로 묶었다. DB UNIQUE 오류에 FAVORITE409_1 변환도 추가했다.

3. 실제 실행 결과

백엔드 테스트70개, Flutter 테스트94개를 통과했다. TypeScript 정적 검사도 통과했고 Flutter analyze는 기존 week0 info2건이다. 로컬 NestJS·MySQL에 HTTP37건을 보내 인증·입력 검증·중복·회원별 분리·등록·조회·해제·영화 기록 true/false 분기를 확인했다.

4. 동시성·실패 검증

동시 즐겨찾기 요청은 201과409로 처리됐고 DB에는 한 행만 남았다. 두 사전 검사가 모두 미등록을 확인하도록 동기화한 뒤에도 UNIQUE가 한 INSERT를 거절했다. 실제 MySQL 트랜잭션의 두 번째 저장에 테스트 오류를 넣었을 때 먼저 INSERT한 평점과 즐겨찾기가 모두 0건임을 확인했다.

5. 데이터와 증빙

이번 검증에서 생성한 임시 회원·평점·즐겨찾기를 모두 정리했고 기존 데이터가 동일함을 비교했다. 실제 Postman 요청·응답 화면, Swagger 문서 화면, 트랜잭션 코드와 실행 결과를 첨부했다. 토큰·비밀번호 원문은 저장소와 사진에서 제외했다.

PR 링크

PR_LINK_PENDING

## 9. 트러블슈팅

원본 「이슈 No.1」 토글 안에 아래 내용을 이슈·문제·해결 순서로 넣는다.

이슈

동시 요청의 사전 중복 검사와 여러 저장 작업의 부분 반영 가능성.

문제

즐겨찾기 요청 두 개가 동시에 미등록을 확인한 뒤 INSERT하면 사전 검사만으로는 중복을 막을 수 없다. 평점과 즐겨찾기를 따로 저장하면 두 번째 저장의 실패로 평점만 남을 수도 있다.

해결

(member_id, movie_id) 복합 UNIQUE를 유지하고 DB1062 오류를 제약 이름에 따라 FAVORITE409_1로 변환했다. MovieRecordService의 DataSource.transaction() 안에서 manager가 제공한 Repository만 사용하고 예외를 밖으로 전달하도록 했다.

재검증

실제 HTTP 동시 요청에서 201·409와 한 행 저장을 확인했다. 사전 검사를 동시에 통과시킨 DB 경쟁 검증에서도 한 건만 저장됐다. 두 번째 저장 오류 주입 뒤 실제 MySQL의 평점·즐겨찾기가 모두0건임을 확인했다. 14번 사진과 live-api-results.json에 결과를 기록했다.

참고

https://typeorm.io/docs/transactions/
https://docs.nestjs.com/techniques/validation

## 10. 제출 전 본인 확인

- 실제 스터디 사진을 맨 위 인증 영역에 넣는다.
- 실습 인증과 미션 기록에 실제 이미지가 표시되는지 확인한다.
- 필수·선택 미션의 코드 링크와 PR 링크를 연다.
- 핵심 키워드와 학습 후기를 본인의 이해에 맞게 확인한다.
- UMC 워크북 제출은 본인이 진행한다.

낙관적 잠금은 핵심 키워드로 정리한 개념이다. 이 주차의 필수 기능과 Swagger 선택 미션 범위에는 버전 기반 수정 API 구현이 없다.
