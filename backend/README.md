# MovieLog 4주차 Backend

UMC PE 워크북의 **4주차 - ORM으로 생산성 높이고 첫 API 완성하기**를
NestJS, TypeORM, MySQL로 구현한 프로젝트입니다. 3주차의 Raw SQL 기반 도서
API를 Entity, Repository, DTO 중심 구조로 리팩터링했습니다.

## 구현 범위

- `Book`, `Category` TypeORM Entity와 `Category 1 : N Book` 관계
- `synchronize: false`로 기존 MySQL 스키마 보호
- 요청 DTO 검증과 응답 DTO 분리
- `GET /books`: 카테고리 이름을 포함한 최신순 도서 목록
- `POST /books`: 존재하는 카테고리에 도서 등록 및 `201 Created`
- 빈 제목 `400`, 없는 카테고리 `404`, 중복 제목 `409`
- 선택 미션: `GET /books?keyword=ORM` 제목 검색
- 선택 미션: 도서 제목 UNIQUE 제약과 중복 등록 방지
- 3주차 대여·반납 API 회귀 보존

## 사전 준비

2주차 MySQL 스키마와 Seed가 필요합니다.

1. `docs/week2-sql/01_schema.sql`
2. `docs/week2-sql/02_seed.sql`
3. `backend/migrations/20261003_add_unique_book_title.sql`

3번은 선택 미션인 중복 도서 등록 방지용입니다. TypeORM의
`synchronize`는 운영과 유사하게 `false`로 유지하며, 스키마 변경은 명시적인
SQL로 적용합니다.

## 환경 변수

```bash
cd backend
cp .env.example .env
```

`.env`의 접속 정보는 MySQL Workbench 또는 Docker MySQL 설정과 일치해야
합니다. `.env`는 Git에 커밋하지 않습니다.

```dotenv
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=3307
DB_USER=umc_week2
DB_PASSWORD=본인의_MySQL_비밀번호
DB_NAME=umc_week2_library
```

## 설치·실행

```bash
cd backend
npm install
npm run start:dev
```

서버 시작 로그에 다음 두 문장이 표시되면 Raw SQL용 Pool과 TypeORM 연결이
모두 정상입니다.

```text
MySQL connection established
Nest application successfully started
```

## API

### 전체 도서 조회

```http
GET /books
```

```json
[
  {
    "bookId": 6,
    "title": "ORM 실전 테스트 20261003",
    "description": "TypeORM 실제 DB 연결 검증",
    "categoryName": "문학",
    "isAvailable": true
  }
]
```

### 제목 검색

```http
GET /books?keyword=ORM
```

### 신규 도서 등록

```http
POST /books
Content-Type: application/json

{
  "categoryId": 1,
  "title": "ORM 실전",
  "description": "TypeORM으로 등록한 도서"
}
```

- 정상 등록: `201 Created`
- 빈 제목: `400 Bad Request`
- 없는 카테고리: `404 Not Found`
- 중복 제목: `409 Conflict`

## 자동 검증

```bash
npm run lint
npm test
npm run test:e2e
npm run build
```

- Unit Test: Entity Repository를 Mock으로 대체해 Service 동작 검증
- E2E Test: HTTP 요청, DTO Validation, 상태 코드, 응답 DTO 검증
- 실제 DB: 로컬 MySQL에서 GET·검색·POST·오류 응답 검증

## Postman

`postman/MovieLog-week4-orm.postman_collection.json`을 Import하면 제출용 요청이
준비됩니다. 컬렉션 변수 `baseUrl`의 기본값은 `http://localhost:3000`입니다.

## 3주차 Raw SQL 보존

3주차 원본은 `feature/week-3-backend` 브랜치에 그대로 남아 있습니다. 현재
브랜치에서는 도서 API만 TypeORM으로 교체했고, 3주차 대여·반납 API는 회귀
확인을 위해 유지했습니다.
