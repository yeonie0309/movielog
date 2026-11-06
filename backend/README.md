# MovieLog 3주차 Backend

UMC PE 워크북의 **3주차 - 첫 API 만들고 검증하기** 실습을 NestJS와
MySQL Raw SQL로 구현한 프로젝트입니다. Flutter 앱과 분리된 `backend/`
디렉터리에서 실행합니다.

## 구현 범위

- Controller → Service → Repository 3계층 구조
- `mysql2/promise` 커넥션 풀과 NestJS Custom Provider
- `.env` 기반 DB 접속 정보 관리
- Raw SQL과 `?` 파라미터 바인딩
- 본문 실습: 전체 도서 조회 및 신규 도서 등록
- 필수 미션: 카테고리별 도서 조회 및 신규 대여 생성
- 선택 미션: 도서 반납 처리
- 단위 테스트와 HTTP E2E 테스트

## 사전 준비

저장소 루트의 SQL을 MySQL Workbench에서 순서대로 실행합니다.

1. `docs/week2-sql/01_schema.sql`
2. `docs/week2-sql/02_seed.sql`

`01_schema.sql`은 `umc_week2_library` 데이터베이스를 삭제하고 다시 만들기
때문에 같은 이름의 보관할 데이터가 없는지 먼저 확인해야 합니다.

## 환경 변수

```bash
cd backend
cp .env.example .env
```

`.env`의 `DB_PASSWORD`를 MySQL Workbench에서 사용하는 로컬 비밀번호로
바꿉니다. `.env`는 Git에서 제외되며 커밋하면 안 됩니다.

```dotenv
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3307
DB_USER=umc_week2
DB_PASSWORD=본인의_MySQL_비밀번호
DB_NAME=umc_week2_library
```

이 저장소에서 2주차에 만든 Docker DB를 사용한다면 먼저 컨테이너를 실행합니다.

```bash
docker start movielog-week2-mysql
```

MySQL Workbench에서는 `UMC Week 2` 연결(`127.0.0.1:3307`)과 같은 접속
정보를 사용합니다. 별도의 로컬 MySQL을 사용하는 경우에는 해당 서버의 포트와
계정으로 `.env`를 변경합니다.

## 실행과 검증

```bash
cd backend
npm install
npm run start:dev
```

DB 연결에 성공하면 서버 로그에 `MySQL connection established`가 표시되고
`http://localhost:3000`에서 다음 응답을 확인할 수 있습니다.

```json
{
  "service": "MovieLog week 3 API",
  "status": "ok"
}
```

자동 검증 명령은 다음과 같습니다.

```bash
npm run lint
npm test
npm run test:e2e
npm run build
```

E2E 테스트는 MySQL을 가짜 커넥션으로 교체하므로 로컬 DB 비밀번호 없이도
API 라우팅, 상태 코드, 응답 JSON을 검증합니다. 실제 DB 검증은 `.env` 설정
후 개발 서버와 Postman으로 진행합니다.

## API

### 전체 도서 조회

```http
GET /books
```

### 신규 도서 등록

```http
POST /books
Content-Type: application/json

{
  "categoryId": 1,
  "title": "클린 코드",
  "description": "애자일 소프트웨어 장인 정신"
}
```

### 특정 카테고리 도서 조회 — 필수 미션

```http
GET /books/category/1
```

Repository SQL:

```sql
SELECT * FROM book WHERE category_id = ? ORDER BY book_id ASC;
```

### 신규 도서 대여 기록 생성 — 필수 미션

```http
POST /rentals
Content-Type: application/json

{
  "userId": 1,
  "bookId": 1
}
```

Repository SQL:

```sql
INSERT INTO rental (user_id, book_id, rented_at, due_at, returned_at)
VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), NULL);
```

### 도서 반납 처리 — 선택 미션

```http
PATCH /rentals/1/return
```

Repository SQL:

```sql
UPDATE rental
SET returned_at = NOW()
WHERE rental_id = ? AND returned_at IS NULL;
```

## Postman

`postman/MovieLog-week3.postman_collection.json`을 Postman에서 Import하면 모든
요청이 준비됩니다. 컬렉션 변수 `baseUrl`의 기본값은
`http://localhost:3000`입니다.
