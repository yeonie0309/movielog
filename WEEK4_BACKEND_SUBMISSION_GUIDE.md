# 4주차 백엔드 제출 가이드

## 구현 요약

- NestJS + TypeORM을 선택했습니다.
- `Book`, `Category` 엔티티와 다대일 관계를 구현했습니다.
- `GET /books`는 최신 등록순으로 DTO 목록을 반환합니다.
- `POST /books`는 DTO 검증 후 도서를 저장하고 201을 반환합니다.
- 빈 제목 400, 없는 카테고리 404, 중복 제목 409를 처리합니다.
- 선택 미션인 카테고리 이름 포함, 제목 검색, 중복 등록 방지를 구현했습니다.
- `synchronize: false`를 유지하고 UNIQUE 제약은 별도 SQL로 관리합니다.

## 자동 검증 결과

```text
npm run lint      통과, warning 0개
npm test          2 files / 6 tests 통과
npm run test:e2e  1 file / 8 tests 통과
npm run build     통과
실제 MySQL         GET 200, 검색 200, POST 201, 빈 제목 400,
                   없는 카테고리 404, 중복 제목 409
```

## 실습 체크리스트

코드와 Postman 결과를 확인한 뒤 다음 6개를 모두 체크할 수 있습니다.

- NestJS TypeORM 설정 완료
- Book과 Category PK/FK 관계 구현
- 요청 DTO 제목·카테고리 ID 검증
- GET /books ORM Repository 조회
- POST /books 저장 및 201
- 없는 카테고리와 빈 제목 오류 확인

## 직접 첨부할 제출물

1. 스터디 인증 사진 1장
2. Postman `GET /books` 200 결과
3. Postman `POST /books` 201 결과
4. Postman 빈 제목 400 또는 없는 카테고리 404 결과
5. 선택 미션을 제출하려면 제목 검색 200과 중복 제목 409 결과
6. 생성될 Pull Request 링크

## Raw SQL과 ORM 비교

3주차에는 SQL 문자열과 물음표 파라미터 순서, RowDataPacket 컬럼명을 직접
관리했다. 4주차에는 Book과 Category를 Entity 관계로 표현하고 TypeORM
Repository가 조회·저장 SQL을 생성하도록 바꿨다. 또한 DB Entity를 그대로
노출하지 않고 Request/Response DTO로 API 계약과 검증 규칙을 분리했다.

## 핵심 키워드

### JPA / Hibernate와 TypeORM

JPA는 Java ORM 표준이고 Hibernate는 대표적인 JPA 구현체다. TypeORM은
TypeScript에서 Entity와 Repository 패턴을 제공하는 ORM 라이브러리다. 이번
프로젝트는 NestJS이므로 TypeORM을 사용했다.

### Entity Lifecycle과 Persistence Context

ORM이 관리하는 Entity는 생성·관리·삭제 상태를 거친다. 변경 사항은 트랜잭션
커밋이나 flush 시점에 SQL로 반영될 수 있으므로 객체 변경과 SQL 실행 시점이
항상 같지는 않다.

### DTO와 API Contract

DTO는 클라이언트와 주고받을 필드와 검증 규칙을 정의한다. Entity를 그대로
반환하면 DB 구조 변경이 API에 전파되고 내부 필드가 노출될 수 있으므로 요청과
응답 DTO를 분리한다.

### Validation

Controller 진입 단계에서 잘못된 요청을 차단하면 Service가 유효한 값만
처리할 수 있다. `ValidationPipe`와 `class-validator`로 카테고리 ID, 빈 제목,
제목 길이를 검증했다.

### N+1 Query

도서 N건을 조회한 뒤 각 도서의 카테고리를 별도 쿼리로 조회하면 총 N+1개의
쿼리가 발생할 수 있다. 이번 구현은 `relations: { category: true }`로 관계를
함께 조회한다.

### Migration과 synchronize

`synchronize: true`는 Entity에 맞춰 DB 스키마를 자동 변경하므로 운영 데이터가
예상치 않게 변경될 수 있다. 이번 구현은 `synchronize: false`로 두고 UNIQUE
제약을 명시적인 SQL 마이그레이션으로 적용했다.

## 학습 후기

Raw SQL에서 직접 관리하던 컬럼명과 파라미터 바인딩을 Entity와 Repository로
옮기면서 ORM이 반복적인 CRUD 코드를 줄여주는 이유를 이해했다. DTO를 분리하니
DB 구조와 API 응답 계약을 독립적으로 관리할 수 있었고, Validation을 통해 잘못된
요청이 Service까지 전달되지 않도록 만들 수 있었다. ORM을 사용하더라도 ERD,
관계, 트랜잭션, 실제 SQL과 N+1 문제를 계속 이해해야 한다는 점이 중요했다.

## 트러블슈팅

**이슈**  
NestJS 서버 실행 시 `ReferenceError: Cannot access 'Category' before initialization`
오류가 발생했다.

**문제**  
ESM 환경에서 `Book`과 `Category`가 양방향으로 import되고,
`emitDecoratorMetadata`가 관계 필드의 런타임 타입을 즉시 참조하면서 순환
초기화가 발생했다.

**해결**  
TypeORM의 `Relation<Category>`, `Relation<Book[]>` 타입을 사용해 설계 타입
메타데이터가 상대 Entity를 즉시 참조하지 않도록 변경했다. 수정 후 실제 MySQL
연결, 자동 테스트, GET/POST API를 다시 실행해 정상 동작을 확인했다.

**참고 레퍼런스**  
- https://typeorm.io/docs/relations/relations-faq/

## 미션 기록

1. 3주차 Raw SQL 도서 API와 MySQL 연결 상태를 확인했다.
2. TypeORM, class-validator, class-transformer 의존성을 추가했다.
3. Book과 Category Entity 및 다대일·일대다 관계를 구현했다.
4. TypeORM Repository를 주입하고 Entity를 Response DTO로 변환했다.
5. CreateBookDto와 ValidationPipe로 categoryId, 빈 제목, 길이를 검증했다.
6. GET /books와 POST /books를 구현하고 예외 상태를 구분했다.
7. 검색과 중복 등록 방지 선택 미션을 추가했다.
8. Unit/E2E/Build와 실제 MySQL 요청으로 결과를 검증했다.

실행 결과는 Entity–Repository–Service–Controller 흐름, 최신순 DTO 조회,
201 등록, 400·404·409 오류 응답 요구사항과 모두 일치한다.
