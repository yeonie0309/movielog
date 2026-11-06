# 2주차 백엔드 제출 가이드

## 구현한 필수 범위

- 공통 온라인 도서 대여 시스템의 MySQL 8 스키마 8개와 PK/FK 관계
- 책·카테고리·대여·태그·좋아요·알림 공통 더미 데이터
- 문학 카테고리 대여 가능 도서 조회
- 특정 사용자의 미반납 도서 조회
- 특정 책의 태그와 사용자 좋아요 여부 조회
- `ORDER BY`, `LIMIT`, `OFFSET` 페이지네이션 예시
- 1주차 MovieLog ERD 확장 조회 1개와 검증용 더미 데이터
- MySQL 8.4 실제 실행 결과 및 Dart 자동 검증

## 직접 해야 하는 작업

워크북 체크리스트가 MySQL Server와 Workbench 사용을 명시하므로 아래는 사용자가
직접 진행하고 캡처해야 한다.

1. MySQL Community Server와 MySQL Workbench를 설치한다.
2. Host `127.0.0.1`, Port `3306`으로 로컬 연결을 만든다.
3. `SELECT VERSION();`을 실행하고 결과를 캡처한다.
4. `docs/week2-sql/01_schema.sql`과 `02_seed.sql`을 순서대로 실행한다.
5. Workbench의 Schemas에서 `umc_week2_library`와 8개 테이블을 캡처한다.
6. `03_required_queries.sql`의 단일 테이블 조회와 미션 1~3 결과를 각각 캡처한다.
7. `LIMIT 10 OFFSET 0` 결과를 캡처한다.
8. MovieLog 확장 미션은 README의 순서대로 별도 `movielog_week2` DB에서 실행하고
   결과를 캡처한다.
9. `erd.mmd` 또는 제공 기준 ERD에서 공통 쿼리의 JOIN 경로를 표시한다.
10. `movielog_join_path.mmd`를 열어 MovieLog 확장 JOIN 경로를 캡처한다.
11. 캡처와 아래 기록을 원본 MakeUs 워크스페이스 페이지의 `미션 기록`에 첨부한다.

`01_schema.sql`은 실습 전용 `umc_week2_library` 데이터베이스를 삭제하고 다시
만드므로, 같은 이름으로 보관 중인 데이터가 없는지 확인한 뒤 실행한다.

## 핵심 키워드에 붙여 넣을 내용

### 1. 요구사항 → SQL로 번역하기

화면 요구사항은 결과, 기준 테이블, 관계, 조건, 정렬·범위 순서로 나눌 수 있다.
화면에 표시할 값은 SELECT 컬럼, 데이터가 시작되는 곳은 FROM, 다른 테이블의 값은
PK/FK 관계에 따른 JOIN, 결과를 좁히는 규칙은 WHERE에 대응한다. 목록 화면은 결과
순서를 보장하기 위해 ORDER BY를 사용하고 한 번에 가져올 개수는 LIMIT과 OFFSET으로
제한한다. 화면에서 사용하지 않는 컬럼까지 `SELECT *`로 조회하기보다 필요한 컬럼을
명시하면 쿼리 의도와 응답 구조가 분명해진다.

### 2. DDL과 DML

DDL(Data Definition Language)은 데이터 구조를 정의하는 언어로 CREATE, ALTER,
DROP이 대표적이다. `CREATE TABLE`은 테이블과 컬럼·제약조건을 만들고,
`ALTER TABLE`은 이미 존재하는 구조에 컬럼이나 제약조건을 추가·변경·삭제한다.
DML(Data Manipulation Language)은 행 데이터를 다루며 INSERT, UPDATE, DELETE가
대표적이다. 따라서 CREATE TABLE로 저장 공간과 규칙을 먼저 만든 뒤 INSERT로 실제
행을 추가한다. SELECT는 데이터를 조회하는 DQL로 따로 구분하기도 하지만 넓게는
DML 범주에 포함해 설명하기도 한다.

### 3. PK·FK와 JOIN 조건

PK는 테이블의 각 행을 유일하게 식별하며 중복과 NULL을 허용하지 않는다. FK는 다른
테이블의 PK 또는 UNIQUE 값만 참조하게 해 테이블 사이의 참조 무결성을 보장한다.
JOIN의 ON 절에는 ERD에 정의된 PK와 FK의 대응 관계를 작성해야 한다. 관계없는
컬럼이나 불완전한 조건으로 연결하면 한 행이 여러 행과 결합되는 카테시안 곱에 가까운
결과가 만들어져 중복 행과 잘못된 집계가 발생할 수 있다.

### 4. WHERE와 NULL

NULL은 빈 문자열이나 0이 아니라 값이 없거나 알려지지 않았다는 상태다. SQL의
`NULL = NULL` 비교 결과는 TRUE가 아니라 UNKNOWN이므로 WHERE 조건을 통과하지
않는다. 따라서 NULL 여부는 `= NULL`이나 `<> NULL` 대신 `IS NULL`과
`IS NOT NULL`로 검사해야 한다. 이번 미반납 도서 쿼리에서는 `returned_at IS NULL`을
사용해 아직 반납 시각이 기록되지 않은 대여만 조회했다.

### 5. ORDER BY와 일관된 정렬

관계형 데이터베이스는 ORDER BY가 없으면 결과 행의 순서를 보장하지 않는다. 실행
계획, 인덱스, 데이터 변경에 따라 같은 쿼리도 다른 순서로 반환될 수 있다. 또한 첫
정렬 컬럼에 같은 값이 존재하면 그 행들의 상대 순서는 여전히 불확실하므로 PK 같은
유일한 보조 정렬 기준을 추가하는 것이 좋다. 예를 들어 반납 예정일 다음에
`rental_id ASC`, 보상 포인트 다음에 `member_missions.id DESC`를 적용했다.

### 6. LIMIT / OFFSET과 페이지네이션

`LIMIT page_size OFFSET offset`은 offset만큼 건너뛴 뒤 page_size개를 반환한다.
페이지 번호가 1부터 시작한다면 offset은 `(page - 1) * page_size`로 계산할 수 있다.
구현이 단순하고 특정 페이지로 바로 이동하기 쉽지만, 데이터가 많을수록 앞의 행을
많이 건너뛰어야 하므로 뒤쪽 페이지가 느려질 수 있다. 조회 도중 데이터가 추가·삭제되면
페이지 사이에서 중복이나 누락도 생길 수 있어 대규모 목록에서는 마지막으로 본
정렬 키를 기준으로 다음 데이터를 찾는 커서 방식도 고려한다.

## 미션 기록에 붙여 넣을 내용

```text
어떤 요구사항에서 어떤 테이블을 기준으로 시작했나요?
미션 1은 도서의 제목·설명과 대여 가능 상태가 있는 book을 기준으로 시작했다. 미션 2는 사용자의 대여 상태와 반납 예정일이 있는 rental을 기준으로 시작했다. 미션 3은 선택한 책의 상세 정보를 조회하므로 book을 기준으로 시작했다. MovieLog 확장 미션은 회원이 수락한 미션의 상태가 저장된 member_missions를 기준으로 시작했다.

JOIN이 필요한 이유를 1주차 기준 ERD의 관계로 설명할 수 있나요?
한 테이블에 화면의 모든 정보가 중복 저장되어 있지 않기 때문에 ERD의 PK/FK 관계를 따라 JOIN해야 한다. book.category_id는 category.category_id를 참조하므로 카테고리 이름을 위해 category를 JOIN했다. rental.book_id는 book.book_id를 참조하므로 대여 기록의 책 제목을 위해 book을 JOIN했다. 태그는 book과 tag의 N:M 관계를 book_tag가 해소하며, 좋아요는 users와 book의 N:M 관계를 book_like가 해소한다. MovieLog에서는 member_missions.mission_id → missions.id, missions.store_id → stores.id 경로를 사용했다.

더미 데이터에서 결과가 예상과 달랐을 때 어떤 조건 또는 관계를 먼저 확인했나요?
먼저 WHERE의 사용자 ID, 책 ID, 카테고리 이름과 NULL 비교 방식이 더미 데이터와 일치하는지 확인한다. 다음으로 JOIN의 ON 절이 ERD의 PK/FK 조합을 정확히 사용했는지 확인하고, N:M 매핑 테이블 때문에 예상보다 행이 늘어난 것은 아닌지 살펴본다. 결과 내용은 맞지만 순서가 다르면 ORDER BY와 동일 값에 대한 보조 정렬 기준을 확인한다.
```

## ERD 사진 아래 설명

```text
공통 도서 대여 ERD는 users 1:N rental, category 1:N book, book N:M tag(book_tag), users N:M book(book_like), users 1:N notification 관계로 구성했다. 미션 1은 book → category, 미션 2는 rental → book, 미션 3은 book → book_tag → tag와 book → book_like 경로를 사용한다. MovieLog 확장 쿼리는 회원별 미션 상태를 기준으로 member_missions → missions → stores 순서로 JOIN해 미션과 가게 정보를 조회한다. 모든 ON 조건은 FK가 참조하는 PK와 연결했다.
```

## 학습 후기

```text
1주차에는 요구사항에서 저장할 데이터를 찾아 ERD로 표현했다면, 이번 주차에는 그 관계가 실제 SQL의 JOIN과 WHERE 조건으로 어떻게 연결되는지 확인했다. 화면 문장을 결과, 테이블, 관계, 조건, 정렬·범위로 분해하니 SELECT부터 LIMIT까지 쿼리를 작성하는 순서가 명확해졌다. 특히 NULL은 = 연산자로 비교할 수 없다는 점과 ORDER BY가 없으면 결과 순서가 보장되지 않는다는 점을 실행 결과를 통해 이해했다. N:M 관계에서는 book_tag나 book_like 같은 매핑 테이블이 필요하고, JOIN 조건을 잘못 작성하면 중복 행이 발생할 수 있다는 것도 알게 됐다. 다음에는 실행 계획과 인덱스를 확인하고 OFFSET 방식과 커서 방식의 성능 차이까지 비교해 보고 싶다.
```

## 트러블슈팅

```text
이슈
👉 SQL 파일을 실제로 검증하려고 mysql 명령을 실행했지만 로컬 환경에 MySQL CLI와 MySQL Workbench가 설치되어 있지 않아 명령을 실행할 수 없었다.

문제
👉 SQL 문장을 파일로 작성하고 문자열 테스트만 통과시켜서는 MySQL 버전별 문법, FK 생성 순서, 실제 JOIN 결과까지 검증했다고 보기 어려웠다.

해결
👉 기존 로컬 데이터와 완전히 분리된 공식 MySQL 8.4 Docker 컨테이너를 만들고 01_schema.sql → 02_seed.sql → 필수 쿼리 순서로 실행했다. 공통 테이블 8개와 시드 행 수를 확인하고, 필수 미션 3개 및 MovieLog 확장 쿼리의 결과가 예상 문장과 일치하는지 검증했다. 제출용 SELECT VERSION()과 Workbench 실행 화면은 워크북 요구사항에 맞춰 로컬 MySQL Server와 Workbench에서 다시 실행해 캡처한다.

참고 레퍼런스
- MySQL 8.4 Reference Manual: https://dev.mysql.com/doc/refman/8.4/en/
- MySQL Docker Image: https://hub.docker.com/_/mysql
```

## 체크 항목 판단

- `스터디 인증샷`: 실제 스터디 사진을 원본 페이지에 첨부한 후에만 체크한다.
- `MySQL Server와 Workbench 설치 및 SELECT VERSION()`: 사용자가 로컬에서 설치하고
  실행 화면을 확인한 뒤 체크한다.
- `01_schema.sql과 02_seed.sql 실행`: Workbench에서 순서대로 실행한 뒤 체크한다.
- `1주차 기준 ERD의 PK/FK 확인`: 완료했으므로 체크 가능하다.
- `단일 테이블 쿼리`: 작성·MySQL 검증 완료로 체크 가능하다.
- `JOIN 쿼리`: 필수 3개 및 확장 쿼리 검증 완료로 체크 가능하다.
- `ORDER BY와 LIMIT/OFFSET`: 작성·검증 완료로 체크 가능하다.
- `필수 미션 3개와 확장 미션`: 코드와 실행 결과는 완료됐다. Workbench 캡처와 미션
  기록을 첨부한 뒤 제출 체크를 완료한다.
- `블로그 챌린지`: 선택 사항이므로 작성하지 않았다면 체크하지 않는다.
