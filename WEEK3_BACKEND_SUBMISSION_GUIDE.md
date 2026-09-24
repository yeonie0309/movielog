# 3주차 백엔드 제출 가이드

## 선택한 스택

- NestJS + Node.js
- MySQL 8
- ORM/DTO 없이 `mysql2`와 Raw SQL 사용

## 구현 범위

- 본문 실습: `GET /books`, `POST /books`
- Required Mission: `GET /books/category/:categoryId`, `POST /rentals`
- Optional Mission: `PATCH /rentals/:rentalId/return`
- Controller–Service–Repository 3계층 구조
- MySQL 커넥션 풀과 `.env` 기반 접속 정보
- 모든 외부 입력에 `?` 파라미터 바인딩

## 미션 인증에 필요한 캡처

Postman 화면에는 URL, 요청 Body, 상태 코드, 응답 JSON이 한 화면에 보이도록
캡처합니다.

1. 서버 콘솔의 `MySQL connection established`
2. `GET /books` — 200과 JSON 배열
3. `POST /books` — Body, 201, 생성된 `bookId`
4. `GET /books/category/1` — 200과 category_id가 1인 배열
5. `POST /rentals` — Body, 201, 생성된 `rentalId`
6. `PATCH /rentals/{rentalId}/return` — 200 응답(선택 미션)
7. 핵심 코드
   - `book.repository.ts`의 `WHERE category_id = ?`
   - `rental.repository.ts`의 `NOW()`와 `DATE_ADD`
   - Controller와 Service 연결 코드

## 자동 검증

- `npm run lint`: 통과
- `npm test`: Repository 단위 테스트 4개 통과
- `npm run test:e2e`: HTTP E2E 테스트 6개 통과
- `npm run build`: 통과
- 실제 MySQL 연결 및 GET/POST/PATCH API 검증: 통과
- 생성된 도서, 대여 기록 및 반납 시각 DB 조회: 통과

## 제출 기록 초안

```text
선택한 스택: NestJS

구현한 API:
- GET /books
- POST /books
- GET /books/category/{categoryId}
- POST /rentals
- PATCH /rentals/{rentalId}/return (선택)

아키텍처:
Controller는 HTTP 요청과 응답을 담당하고, Service는 입력값 검증과 비즈니스
흐름을 담당하며, Repository만 MySQL과 Raw SQL로 통신하도록 분리했다.

DB 연결:
@nestjs/config로 .env를 읽고 mysql2/promise의 createPool을 NestJS Custom
Provider로 등록했다. 서버 시작 시 SELECT 1로 연결을 확인한다.

SQL Injection 대응:
사용자 입력을 SQL 문자열에 직접 합치지 않고 모든 동적 값에 ? Placeholder와
파라미터 배열을 사용했다.

필수 미션 1:
GET /books/category/{categoryId}에서 Path Variable을 양의 정수로 검증한 뒤
SELECT * FROM book WHERE category_id = ? 쿼리로 해당 카테고리 도서만 조회한다.

필수 미션 2:
POST /rentals에서 userId와 bookId를 Body로 받고, rented_at은 NOW(), due_at은
DATE_ADD(NOW(), INTERVAL 7 DAY)로 계산해 대여 기록을 생성한다.

선택 미션:
PATCH /rentals/{rentalId}/return에서 returned_at을 NOW()로 갱신한다. 이미
반납되었거나 존재하지 않는 기록은 404로 응답한다.
```

## 핵심 키워드 작성본

### 3계층 아키텍처 이외의 아키텍처

레이어드 아키텍처 외에도 포트와 어댑터를 기준으로 내부 비즈니스 로직과 외부
기술을 분리하는 헥사고날 아키텍처, 의존성이 도메인 중심으로 향하도록 만드는
클린 아키텍처, 기능을 작은 독립 서비스로 분리하는 마이크로서비스 아키텍처가
있다. 규모가 작은 프로젝트는 3계층 구조가 이해와 구현이 쉽지만, 외부 시스템이
많거나 도메인 규칙이 복잡해질수록 헥사고날·클린 아키텍처가 테스트와 교체에
유리하다.

### SQL Injection을 포함한 대표적인 웹 보안 공격

SQL Injection은 입력값을 SQL 문자열에 그대로 합쳐 쿼리 구조를 바꾸는
공격이다. 이 프로젝트는 `?` Placeholder와 별도의 파라미터 배열을 사용해
방어했다. XSS는 악성 스크립트를 브라우저에서 실행시키는 공격이며 출력 인코딩과
콘텐츠 보안 정책으로 줄일 수 있다. CSRF는 로그인된 사용자의 권한으로 원치 않는
요청을 보내게 하는 공격으로 SameSite 쿠키와 CSRF 토큰을 사용한다. 인증·인가
누락과 무차별 대입 공격에는 서버 측 권한 검사, 요청 횟수 제한, 안전한 비밀번호
저장이 필요하다.

### 커넥션 풀이란?

커넥션 풀은 서버 시작 시 DB 연결을 일정 수 미리 만들어 두고 요청마다 빌렸다가
반납하는 방식이다. 매 요청마다 TCP 연결과 인증을 새로 수행하는 비용을 줄이고
동시 연결 수를 제한해 DB를 보호한다. 이 프로젝트에서는 `mysql2`의
`createPool`에 `connectionLimit: 10`을 지정했고, 서버 종료 시 풀도 함께
종료한다.

### Raw SQL vs ORM

Raw SQL은 실행할 쿼리가 명확하고 DB 기능을 세밀하게 사용할 수 있지만, 문자열과
컬럼 매핑을 직접 관리해야 하므로 오타와 스키마 결합 위험이 크다. ORM은 객체와
테이블의 매핑, 반복 CRUD, 타입 관리를 자동화해 생산성과 유지보수성이 높지만,
생성되는 SQL을 이해하지 못하면 성능 문제를 발견하기 어렵고 복잡한 쿼리에서는
추상화가 오히려 제약이 될 수 있다. 따라서 ORM을 사용해도 실제 SQL과 실행 계획을
확인하는 습관이 필요하다.

### INSERT 외의 핵심 SQL 문법

`SELECT`는 데이터를 조회하고, `UPDATE`는 기존 행을 수정하며, `DELETE`는 행을
삭제한다. `WHERE`는 대상 행을 제한하고 `JOIN`은 관련 테이블을 연결한다.
`GROUP BY`와 집계 함수는 데이터를 그룹별로 요약하며, `ORDER BY`는 정렬,
`LIMIT/OFFSET`은 조회 범위를 제어한다. 여러 변경을 하나의 작업으로 보장해야 할
때는 `COMMIT`과 `ROLLBACK`을 포함한 트랜잭션을 사용한다.

## 학습 후기 작성본

이번 주차에는 Workbench에서 직접 실행하던 SQL이 HTTP 요청을 받아 Repository에서
실행되고 JSON 응답으로 돌아오는 전체 흐름을 연결해 볼 수 있었다. Controller,
Service, Repository를 역할별로 나누니 요청 처리, 비즈니스 검증, DB 접근을 각각
독립적으로 테스트할 수 있다는 장점도 확인했다. 특히 환경변수로 DB 비밀번호를
분리하고 Placeholder로 입력값을 바인딩하는 것이 단순한 문법이 아니라 운영과
보안을 위한 기본 원칙이라는 점을 이해했다. 한편 DTO 없이 `Record<string,
unknown>`을 직접 검사하고 Raw SQL의 컬럼과 파라미터 순서를 맞추면서 반복 작업과
오타 위험을 체감했고, 다음 주차의 DTO와 ORM이 어떤 문제를 해결하는지 기대하게
되었다.

## 미션 기록 작성본

```text
이름 / 닉네임: 레아 / 이가연
선택한 스택: NestJS
GitHub 저장소: https://github.com/yeonie0309/movielog
Pull Request: [PR 생성 후 링크 입력]

1. 사전 준비
- 2주차에 생성한 umc_week2_library의 book, category, users, rental 테이블과
  더미 데이터를 재사용했다.
- DB 접속 정보는 backend/.env로 분리하고 Git 추적에서 제외했다.

2. 구조
- Controller: HTTP 경로, Path Variable, Request Body와 응답을 담당한다.
- Service: 양의 정수 ID, 필수 title 등 입력값과 비즈니스 흐름을 검증한다.
- Repository: mysql2 커넥션 풀을 통해서만 Raw SQL을 실행한다.

3. 구현 API
- GET /books: 전체 도서 목록 조회
- POST /books: 신규 도서 등록
- GET /books/category/{categoryId}: 특정 카테고리 도서 조회(필수)
- POST /rentals: 현재 시각부터 7일 기한의 신규 대여 생성(필수)
- PATCH /rentals/{rentalId}/return: 현재 시각으로 반납 처리(선택)

4. 검증
- npm run lint 통과
- npm test: Repository 단위 테스트 4개 통과
- npm run test:e2e: HTTP E2E 테스트 6개 통과
- npm run build 통과
- npm audit: 취약점 0건
- Flutter 기존 테스트 20개 통과

5. 보안
- DB 비밀번호를 코드나 Git에 저장하지 않았다.
- 외부 입력은 SQL 문자열에 합치지 않고 ? Placeholder로 바인딩했다.
```

## 트러블슈팅 작성본

이번 구현 중 실제로 발생하고 해결한 문제를 정리한 문안입니다.

```text
⚡ 이슈 No.1

이슈
👉 서버 시작 시 처음에는 Access denied 오류가 발생했고, UMC Week 2 연결로
바꾼 뒤에는 127.0.0.1:3307 연결이 거절됐다.

문제
👉 2주차 Docker MySQL 컨테이너가 중지되어 있었고, backend/.env도 다른 로컬
MySQL의 root/3306 정보를 사용하고 있었다. 이후에는 umc_week2 계정의 저장된
비밀번호와 .env 값도 일치시켜야 했다.

해결
👉 기존 데이터는 삭제하지 않고 `docker start movielog-week2-mysql`로 컨테이너를
재시작했다. `.env`를 `127.0.0.1:3307`, `umc_week2` 계정에 맞추고 비밀번호를
동기화했다. 비밀번호가 포함된 `.env`는 Git에서 제외했다. 재실행 후 서버 콘솔의
"MySQL connection established" 로그와 모든 API의 200/201 응답, DB에 생성된
도서·대여·반납 기록을 확인했다.

참고 레퍼런스
- https://docs.nestjs.com/techniques/configuration
- https://sidorares.github.io/node-mysql2/docs
```

## 노션 체크 기준

- 스터디 인증샷: 실제 스터디 사진을 첨부한 뒤 체크합니다.
- 실습 체크리스트 4개: 실제 MySQL 서버 실행과 Postman GET/POST 검증이 끝난 뒤
  모두 체크합니다.
- 필수 미션: 두 API의 핵심 코드 및 Postman 성공 화면을 첨부한 뒤 체크합니다.
- 선택 미션: `PATCH /rentals/{rentalId}/return` 성공 화면까지 첨부하면 체크할 수
  있습니다.
- 블로그 챌린지: 권장 사항이므로 블로그를 작성·제출한 경우에만 체크합니다.
