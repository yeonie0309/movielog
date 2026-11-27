# 9주차 백엔드 — 원본 노션 위에서부터 작성하기

대상: MakeUs → PE (Mobile) A팀 → 레아의 워크북 → **9주차 - 함께 테스트하고 다듬기**.
원본 노션은 수정하지 않았습니다. 아래 내용은 복사할 초안입니다. 본인의 이해·경험에 관한 표현은 읽고 맞게 조정하세요.
PR 링크: https://github.com/yeonie0309/movielog/pull/21 스터디 인증 사진과 UMC 제출은 직접 진행합니다.

## 1. 학습 목표 / 본문
제공된 설명·실습 코드는 지우지 않습니다. 필요하면 해당 실습 바로 아래에 구현 경로와 결과를 덧붙입니다.

복사할 내용:
> NestJS + TypeORM 프로젝트의 기존15개 API를 Swagger로 문서화했다. /swagger-ui와 /swagger-ui-json을 추가하고 기존 /docs를 보존했다. 기존 node:test 실행기를 유지해 단위4개와 실제 sql.js 메모리 DB 통합11개를 추가했다. 공개5개와 보호10개의 인증 표시를 구분했고, 보호 API는 Swagger Authorize로 직접 호출했다.

## 2. “잠깐! 스터디 인증샷” / 스터디 인증
실제 팀원들과 진행한 스터디 사진을 여기에 넣습니다. API·테스트 사진으로 대체하지 않습니다. 스터디를 아직 하지 않았다면 해당 인증은 미완료입니다.

## 3. 핵심 키워드 — 각각의 토글 안에

### Swagger / OpenAPI
OpenAPI는 HTTP API의 경로·메서드·입력·응답·인증 방식을 기계가 읽을 수 있는 형식으로 표현하는 표준이다. Swagger UI는 그 명세를 읽어 문서와 호출 화면을 제공하는 도구다. NestJS에서는 실제 Controller 경로에서 문서를 생성하고 요청·응답 메타데이터를 보완한다.
예를 들어 POST /favorites는 Bearer JWT와 movieId를 받으며 성공은201/COMMON201, 중복은409/FAVORITE409_1이다. GET /members/{memberId}/ratings는 공개 API이며 공통 envelope가 아닌 배열을 반환하므로 실제 계약을 그대로 기록해야 한다.
문서 생성이 자동이어도 예시·설명이 정확한지는 별도 검증이 필요하다. 생성된 OpenAPI15개와 인증 구분을 테스트로 확인했다.
참고: https://docs.nestjs.com/openapi/introduction

### 단위 테스트
단위 테스트는 작은 로직을 외부 환경에서 분리하여 검증하는 테스트다. 서비스 테스트에서는 DB 대신 가짜 Repository를 주입해 특정 조건에서 어떤 판단을 내리는지 확인할 수 있다.
중복 즐겨찾기가 있다고 설정한 뒤 FavoriteService.create를 호출하면 FAVORITE409_1이 발생하고 save는0회여야 한다. 예외가 났다는 사실과 저장하지 않았다는 사실을 함께 검사한다. 평점도 같은 영화 중복과 다른 회원의 평점 수정 시도를 각각 검사했다.
빠르고 원인 파악이 쉽지만 실제 SQL·인증·URL·HTTP 응답까지 보장하지는 않는다.
참고: https://docs.nestjs.com/fundamentals/testing

### 통합 테스트
통합 테스트는 여러 구성요소가 함께 동작할 때의 결과를 검증하는 테스트다. 이 프로젝트에서는 HTTP 요청이 Controller→Guard→ValidationPipe→Service→실제 TypeORM Repository와 메모리 DB를 거쳐 응답하는 흐름을 확인한다.
예를 들어 인증 없는 POST /favorites는401/AUTH401_2, 인증 요청은201, 중복은409, 미등록 영화의 여부 조회는200/isFavorite=false여야 한다. 테스트 사이에는 자식 테이블부터 비워 데이터가 섞이지 않게 한다.
sql.js는 실행 중 메모리에서만 존재하며 개발 MySQL과 분리된다. 다만 MySQL의 오류번호·collation·동시접속 특성까지 같지는 않아 실제 MySQL 검증도 병행했다.
참고: https://docs.nestjs.com/fundamentals/testing

### Mock, Stub
Stub은 테스트에 필요한 미리 정해진 응답을 제공하는 대역이다. Mock은 호출 횟수·인자 등 상호작용을 기록하고 검증할 수 있는 대역이다. 같은 가짜 객체가 두 역할을 함께 할 수 있다.
exists가 true를 반환하도록 만든 함수는 중복 상황을 만드는 Stub 역할이고, save를 mock.fn으로 만들어 호출0회를 확인하는 부분은 Mock 역할이다. 가짜 응답이 실제 DB 동작과 달라질 수 있으므로 통합 테스트와 구분한다.
이 프로젝트는 Jest 대신 기존 Node의 mock.fn을 사용하며, 핵심은 도구 이름보다 검증하려는 행동이다.
참고: https://nodejs.org/api/test.html#mocking

### given-when-then
테스트를 준비(given), 실행(when), 결과 검증(then)으로 나누는 구성 방식이다.
given: 회원1이 영화550을 이미 즐겨찾기한 상황.
when: 같은 회원이 영화550을 다시 등록.
then: FAVORITE409_1이며 save가 호출되지 않음.
상황과 기대 결과가 테스트 이름에 드러나면 실패 원인을 빨리 찾을 수 있다. 상태 변경이 없는지도 함께 검증하면 예외 발생만 검사할 때보다 강한 테스트가 된다.
참고: https://docs.nestjs.com/fundamentals/testing

### 회귀 테스트
회귀 테스트는 코드 변경 후 기존 동작이 다시 깨지지 않았는지 확인하는 테스트다. 이미 해결한 버그나 중요한 계약을 테스트로 고정해 다음 변경에서 감지한다.
중복 검사를 임시로 제거하자 단위 테스트는 예외 누락, 통합 테스트는 기대409와 실제500 차이로 실패했다. 트랜잭션 제거 시에는 첫 INSERT가 남아 롤백 검증이 실패했다. 원본 복원 후 신규15개와 전체85개가 통과했다.
테스트가 항상 초록색인 것보다 실제 결함에 빨간색으로 반응하는지 확인하는 것이 중요하다고 판단했다.
참고: https://nodejs.org/api/test.html

## 4. 학습 후기 — 복사할 초안
Swagger의 공개·보호 표시뿐 아니라 실제 응답 형식과 오류 code까지 맞추는 과정에서 API 문서도 검증 대상이라는 점을 이해했다. 특히 중복 확인과 회원별 평점 조회는 기존 raw JSON 형식이므로 다른 API의 envelope와 구분해 기록했다.

가짜 Repository 테스트와 실제 메모리 DB 통합 테스트를 나누면서 각 테스트가 보장하는 범위를 확인했다. 중복 예외와 save 미호출을 단위 테스트로 고정하고, 인증·검증·저장·응답은 HTTP 통합 테스트로 확인했다.

기존 즐겨찾기 사전 검사에서409가 발생하는 것만으로는 롤백을 증명할 수 없다는 점이 가장 중요했다. 첫 INSERT 이후 두 번째 INSERT를 실패시킨 뒤 저장 개수를 확인했고, 트랜잭션을 제거했을 때 실제로 테스트가 실패했다. 메모리 DB와 MySQL의 차이는 실DB 검증으로 보완했다.

## 5. 실습 체크리스트 — 7개 판단
다음 기술 항목은 실제 검증했으므로 결과·사진을 반영한 뒤 체크할 수 있습니다.
1. Swagger 설치 및 브라우저 문서 열기: 완료. 사진01.
2. 보호 자물쇠/공개 무자물쇠: 완료. 사진01.
3. Authorize 후 즐겨찾기 등록 성공: 완료. 사진03+04.
4. 같은 요청409: 완료. 사진05.
5. 가짜 Repository 단위2: 완료. 파일 week9-unit.test.cjs의 favorite2개, 사진07+08.
6. 테스트 전용 메모리 DB 통합4: 완료. week9-memory.e2e.test.cjs의 favorite4개, 사진07.
7. 중복 검사 제거 실패 확인 및 복원: 완료. 사진09+14.
체크 자체는 본인이 내용을 확인한 뒤 합니다. 실제 스터디 참석·설명 가능 여부는 자동으로 체크하지 않습니다.

## 6. 실습 인증 — 아래 순서대로 사진 첨부
사진은 /Users/yeonie/UMC11/movielog/evidence/week9-backend/에 있습니다.
- “Swagger 전체 목록과 POST /favorites 펼친 화면”: 01-swagger-all.jpg + 02-favorite-documentation.jpg
- “Authorize 후201·중복409”: 03-authorized-masked.jpg + 04-swagger-favorite-201.jpg + 05-swagger-favorite-409.jpg
- “단위·통합 모두 통과”: 07-all-tests-passed-rendered.jpg + 14-restored-passed-rendered.jpg
- “중복 검사 제거 실패 화면과 이유”: 09-duplicate-removed-rendered.jpg
  설명: 중복 검사 제거 시 단위 테스트는 기대한 예외가 발생하지 않아 실패했고, 통합 테스트는 SQLite UNIQUE 예외가500이 되어 기대409와 달라 실패했다. 컴파일 산출물에서 임시 변경한 뒤 원본 바이트를 복원했으며, 복원 후 다시 통과했다.

주의: 01~06은 실제 Swagger 브라우저 캡처입니다. 07~14는 실제 실행 TXT/코드를 이미지 문서로 렌더링한 것이며 터미널 화면 캡처가 아닙니다. 원본 TXT/코드도 함께 첨부할 수 있습니다. 운영진이 터미널 원화면을 엄격하게 요구한다면 본인 터미널에서 아래 두 명령을 실행한 결과를 추가 캡처합니다.
```sh
cd /Users/yeonie/UMC11/movielog/movie-backend
npm test
node scripts/verify-week9-mutations.cjs
```
두 번째 명령은 내부에서 의도적인 실패 후 복원을 검증합니다. 상세 실패 출력은 evidence/week9-backend/duplicate-removed.txt 및 transaction-removed.txt에 보관됩니다.

## 7. Required Mission
사진06(평점문서), 사진08(평점단위코드), 사진07(전체통과)를 넣습니다.
아래를 함께 복사합니다:
> 기존15개 API에 요약·인증·입력·성공 및 오류 HTTP/code를 문서화했다. 필수 범위인 평점 등록·수정·삭제, 회원별 평점 조회, 내 정보 조회·수정, 즐겨찾기 목록·여부·삭제를 포함한다. 평점 단위 테스트는 중복 RATING409_1과 타인수정 RATING403_1을 검증하며 save 미호출까지 확인한다. 실제 메모리 DB 평점 통합 테스트는 무인증401과 인증201을 검사한다. 전체85개 테스트가 통과했다.

코드:
- movie-backend/src/swagger.ts, swagger-week9.ts
- movie-backend/test/week9-unit.test.cjs
- movie-backend/test/week9-memory.e2e.test.cjs
기존 설명을 지우지 말고 미션 토글 내부의 작성 영역에 추가합니다.

## 8. Challenge / 선택 미션
사진13(롤백코드)+07/14(통과)+10(트랜잭션제거실패)+11(실MySQL)을 넣습니다.
> 기존 즐겨찾기 영화에 addToFavorites=true로 기록을 요청했을 때 FAVORITE409_1이며 평점 개수가 바뀌지 않는지 검사했다. 이 검사는 사전 차단이므로 실제 롤백을 따로 증명했다. 메모리 DB의 두 번째 INSERT를 trigger로 실패시키자 COMMON500이 반환되고 첫 평점 INSERT가 롤백되어0건이었다. 트랜잭션을 제거하면1건이 남아 테스트가 실패했으며 복원 후 통과했다. 실제 MySQL에서도 트랜잭션 안에서 평점이 존재하는 것을 확인한 뒤 두 번째 save에 제어된 실패를 주입했고, 트랜잭션 밖에서는 평점·즐겨찾기 모두0건이었다.
> 사전 중복409, DB trigger 실패500, MySQL 제어된 실패는 서로 다른 검증이다.

## 9. 미션 기록 — 과정 포함해서 복사
이름 / 닉네임: 이가연 / 레아
저장소: https://github.com/yeonie0309/movielog
PR: https://github.com/yeonie0309/movielog/pull/21
환경: NestJS12·TypeORM, node:test·Supertest·sql.js, 실제 로컬 MySQL.

진행 과정:
1. main과 git status를 확인했다. main에 최신 주차가 없어 codex/week-9-frontend를 기반으로 codex/week-9-backend를 만들고 기존 미추적 파일은 보존했다.
2. 원본 본문 실습1~6과 필수·선택 미션을 요구사항별로 정리했다.
3. 기존 Swagger 경로를 보존하며 /swagger-ui를 추가하고 공개5개/보호10개를 문서화했다.
4. 가짜 Repository 단위4개와 실제 메모리 DB 통합11개를 추가했다. SQLite 기본키 호환 설정은 테스트 초기화에만 적용했다.
5. Swagger에서 일회용 메모리DB 회원 JWT로 Authorize한 뒤 movieId551 등록201, 같은 요청409를 직접 확인했다. 토큰이 포함되는 curl 영역은 캡처에서 제외했다.
6. 중복 검사 제거 시2개 실패, 트랜잭션 제거 시1개 실패를 확인한 뒤 원본을 복원했다.
7. 백엔드85개·Flutter109개 통과, Flutter 분석 오류/경고0·기존 info2개, 실제 MySQL37개 HTTP요청 및 DB rollback/UNIQUE 검증을 완료했다. 임시 데이터를 제거하고 기존 행이 동일함을 확인했다.

결과와 증빙:
- Swagger: 사진01·02·06
- 단위/메모리 통합: 사진07·08·14 및 테스트 코드
- 회귀 실패 실험: 사진09·10
- 실제 MySQL: 사진11 및 live-api-results.json
- Flutter: 사진12
- 기술적 미검증: 메모리DB로 MySQL 고유 동작을 보장하지 않으며 실MySQL을 별도 검증했다. 이번 변경에서 새로운 Android 실행 영상은 촬영하지 않았다. 터미널 원화면 요구 시 실습 인증의 안내대로 별도 캡처한다.
- 스터디 참석 인증·워크북 제출: 본인이 진행한다.

## 10. 트러블슈팅 — 아래 복사

상황: 기존 Repository 대체 테스트는 실제 DB 제약·트랜잭션을 검증하지 못했고, MySQL BIGINT 자동 증가 키를 메모리 SQLite에서 그대로 만들 수 없었다.
원인: 테스트 대역은 실제SQL을 실행하지 않으며 SQLite AUTOINCREMENT는 INTEGER 기본키를 요구한다.
수정: 같은 운영 엔티티·서비스·Guard·Pipe를 사용하는 sql.js 테스트 앱을 구성했다. 생성 기본키 메타데이터만 초기화 동안 INTEGER로 바꾸고 finally에서 복원했다. 운영 스키마는 변경하지 않았다.
재검증: 메모리 통합11개와 전체85개 통과. 실제MySQL37 HTTP요청·동시중복·롤백·정리도 통과했다.

상황: 이미 즐겨찾기한 영화의 요청이409여도 트랜잭션이 실제로 작동하는지는 증명되지 않았다.
원인: 서비스가 첫 INSERT 전에 중복을 검사해 저장 자체를 시작하지 않기 때문이다.
수정: 두 번째 INSERT를 실패시키는 실제 DB trigger를 테스트에 추가하고 첫 INSERT의 잔존 여부를 검사했다.
재검증: 원본은 평점0건, transaction 제거 시1건으로 테스트 실패, 원본 복원 후15개 통과. 실제MySQL에서도 첫 저장 후 제어된 실패 주입으로 롤백을 확인했다.

## 11. PR / 제출
실습 인증은 실행 결과를 모으는 곳이고, 미션 기록은 과정·판단·결과를 설명하는 곳입니다. 필요한 사진은 두 곳에 재사용할 수 있습니다. PR에도 대표 사진과 테스트 결과를 첨부합니다.
원본 노션 내용 입력·본인 이해 확인·스터디 사진 추가 후 UMC 제출은 직접 합니다. CodeRabbit은 기본 브랜치가 아닌 PR을 자동 건너뛸 수 있어 리뷰 완료로 표시하지 않습니다.

최종 PR: https://github.com/yeonie0309/movielog/pull/21
브랜치: codex/week-9-backend → codex/week-9-frontend
