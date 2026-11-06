# 4주차 ORM 실제 DB 검증 결과

검증 환경: NestJS + TypeORM + MySQL `umc_week2_library`

| 요청 | 기대 상태 | 실제 상태 | 결과 |
|---|---:|---:|---|
| `GET /books` | 200 | 200 | 최신순·`categoryName` 포함 |
| `GET /books?keyword=ORM` | 200 | 200 | 제목 검색 결과 1건 |
| `POST /books` 정상 요청 | 201 | 201 | `bookId: 6` 생성 |
| `POST /books` 빈 제목 | 400 | 400 | DTO Validation에서 차단 |
| `POST /books` 없는 카테고리 | 404 | 404 | Service에서 존재 여부 확인 |
| `POST /books` 중복 제목 | 409 | 409 | 중복 사전 확인 및 UNIQUE 제약 |

## 실행 로그 요약

```text
TypeOrmCoreModule dependencies initialized
MySQL connection established
Nest application successfully started
```

## 한 문장 검증

Entity–Repository–Service–Controller 흐름으로 도서 목록 조회와 등록이 동작하며,
DTO 검증과 카테고리·중복 제목 예외 응답이 워크북 요구사항과 일치한다.
