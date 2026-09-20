# 2주차 SQL로 데이터 다루기

## 실행 순서

MySQL 8.0 이상에서 아래 순서로 실행한다.

1. `01_schema.sql`
2. `02_seed.sql`
3. `03_required_queries.sql`

`01_schema.sql`은 실습 전용 `umc_week2_library` 데이터베이스를 삭제하고 다시
만든다. 보관할 데이터가 있는 같은 이름의 데이터베이스에는 실행하지 않는다.

MovieLog 확장 미션은 별도의 `movielog_week2` 데이터베이스에서 실행한다.

```sql
DROP DATABASE IF EXISTS movielog_week2;
CREATE DATABASE movielog_week2
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE movielog_week2;
```

그다음 아래 순서를 따른다.

1. `docs/week1-data-modeling/schema.sql`
2. `docs/week2-sql/04_movielog_seed.sql`
3. `docs/week2-sql/05_movielog_extension_query.sql`

## 공통 ERD 관계

- `users` 1:N `rental`
- `category` 1:N `book`
- `book` N:M `tag` (`book_tag`)
- `users` N:M `book` (`book_like`)
- `users` 1:N `notification`

## Required Mission 결과 검증

### 체크리스트: 단일 테이블 조회

- 기준 테이블: `book`
- WHERE: `is_available = TRUE`
- 정렬: `book_id DESC`
- 예상 결과: `우주를 읽는 법`, `달빛 도서관` 순서
- 검증: 다른 테이블을 JOIN하지 않고 대여 가능한 책만 최신 ID 순으로 조회된다.

### 미션 1: 문학 카테고리의 대여 가능 도서

- 기준 테이블: `book`
- JOIN: 카테고리 이름을 가져오기 위해 `category` 연결
- WHERE: `문학`, `is_available = TRUE`
- 정렬·범위: `book_id DESC`, `LIMIT 10`
- 예상 결과: `달빛 도서관 / 소설 / 문학` 한 행
- 검증: 문학 도서 중 대여 가능한 책만 최신 ID 순으로 조회된다.

### 미션 2: 특정 사용자가 대여 중인 책

- 기준 테이블: `rental`
- JOIN: 책 제목을 가져오기 위해 `book` 연결
- WHERE: `user_id = 1`, `returned_at IS NULL`
- 정렬: `due_at ASC`, 동일 값은 `rental_id ASC`
- 예상 결과: `겨울의 편지 / 2026-08-10 / 2026-08-17` 한 행
- 검증: 민서가 아직 반납하지 않은 책만 반납 예정일 순으로 조회된다.

### 미션 3: 태그와 좋아요 여부

- 기준 테이블: `book`
- JOIN: `book_tag → tag`로 태그를, `book_like`로 사용자 좋아요를 연결
- WHERE: `book_id = 1`, 좋아요 JOIN의 `user_id = 1`
- 정렬: `tag.name ASC`, 동일 값은 `tag_id ASC`
- 예상 결과: 달빛 도서관의 `소설`, `추천` 태그 두 행과 `is_liked = 1`
- 검증: 선택한 책의 모든 태그와 민서의 좋아요 여부가 함께 조회된다.

### MovieLog 확장: 진행 중인 회원 미션

- 기준 테이블: `member_missions`
- JOIN: 미션 내용은 `missions`, 가게명은 `stores`에서 가져온다.
- WHERE: 회원 1, 진행 가능한 회원 미션, 활성 미션, 삭제되지 않은 미션·가게
- 정렬·범위: 보상 포인트 내림차순, `member_missions.id` 내림차순, 최대 10개
- 예상 결과: `마포 맛집` 500P 미션, `무비 카페` 300P 미션 순서
- 검증: 완료 미션은 제외되고 로그인 회원의 진행 중 미션만 높은 보상순으로 나온다.

## 캡처할 화면

- `SELECT VERSION();` 결과
- `01_schema.sql`, `02_seed.sql` 실행 성공과 8개 테이블
- 단일 테이블 대여 가능 도서 조회 결과
- 미션 1 결과
- 미션 2 결과
- 미션 3 결과
- `LIMIT 10 OFFSET 0` 실행 결과
- MovieLog ERD에서 `member_missions → missions → stores` JOIN 경로
- MovieLog 확장 쿼리 결과
