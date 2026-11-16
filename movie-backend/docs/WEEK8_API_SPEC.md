# 8주차 즐겨찾기와 영화 기록 API

기존 NestJS·TypeORM·MySQL 스택을 사용한다. 로컬 기준 주소는 `http://localhost:3008`이다. `POST /auth/login`으로 받은 토큰을 `Authorization: Bearer {accessToken}`에 넣는다. 아래 다섯 API는 모두 인증이 필요하며 요청 URL·body·query에 memberId를 넣지 않는다.

| Method | URL | 요청 | 성공 result |
| --- | --- | --- | --- |
| POST | /favorites | `{ "movieId": 550 }` | 201, Favorite |
| GET | /favorites | 없음 | 200, 최신 등록순 Favorite 배열. 빈 목록은 `[]` |
| GET | /favorites/{movieId} | 양의 안전 정수 movieId | 200, `{ "isFavorite": true }` 또는 false |
| DELETE | /favorites/{movieId} | 양의 안전 정수 movieId | 200, null |
| POST | /movie-records | 아래 JSON | 201, `{ "rating": Rating, "favorite": Favorite 또는 null }` |

```json
{
  "movieId": 238,
  "score": 5,
  "comment": "다시 보고 싶은 영화입니다.",
  "addToFavorites": true
}
```

movieId는 1 이상 Number.MAX_SAFE_INTEGER 이하 정수이다. score는 1~5 정수, comment는 생략/null 또는 500자 이하 문자열이다. addToFavorites는 필수 boolean이다. 숫자·boolean을 문자열로 보내면 400이다. body의 임의 필드도 거절한다.

Favorite에는 favoriteId·movieId·createdAt을 반환한다. Rating에는 ratingId·movieId·score·comment·createdAt·updatedAt을 반환한다. DB BIGINT는 응답에서 숫자로 변환하고 날짜는 JSON ISO 문자열로 직렬화한다.

성공 응답은 `isSuccess`, `code`, `message`, `result`를 포함한다. code는 성공 상태에 따라 COMMON200 또는 COMMON201이다. 삭제도 200과 공통 envelope를 사용한다.

| 상태 | code | 조건 |
| --- | --- | --- |
| 400 | COMMON400 | body/path 입력 검증 실패 |
| 401 | AUTH401_2 | 토큰 누락·잘못된 Bearer 형식 |
| 401 | AUTH401_3 | 무효 서명·claims |
| 401 | AUTH401_4 | 토큰 만료 |
| 404 | MEMBER404_1 | 등록 주체 회원 없음 |
| 404 | FAVORITE404_1 | 내 즐겨찾기에 없는 영화 해제 |
| 409 | FAVORITE409_1 | 사전 검사 또는 DB UNIQUE 즐겨찾기 중복 |
| 409 | RATING409_1 | 영화 기록에서 평점 중복 |
| 500 | COMMON500 | 예기치 않은 오류. 내부 SQL·파라미터는 응답에서 제외 |

다른 회원의 즐겨찾기는 내 목록·여부에 포함되지 않는다. 해제도 토큰 회원과 movieId를 함께 조건으로 사용한다. 같은 영화를 여러 회원이 각각 등록할 수 있다. 복합 UNIQUE의 대상은 `(member_id, movie_id)`이다.

영화 기록은 `DataSource.transaction()` 안에서 받은 manager의 Member·Rating·Favorite Repository만 사용한다. addToFavorites가 false이면 평점만 저장하고 favorite는 null이다. true이면 두 저장이 모두 성공해야 commit한다. 기존 중복은 쓰기 전에 확인하며 저장 중 DB 오류도 콜백 밖으로 전파해 rollback한다.

## Swagger와 실행

```sh
cd /Users/yeonie/UMC11/movielog/movie-backend
npm ci
npm run build
PORT=3008 DB_NAME=umc_movie node --env-file=.env --env-file=../backend/.env dist/main.js
```

JWT 설정은 movie-backend/.env, 기존 DB 설정은 backend/.env를 사용한다. 두 파일의 실제 값은 Git에 포함하지 않는다. Swagger UI는 `/docs`, OpenAPI JSON은 `/docs-json`이다. 공개 회원가입·로그인·중복 확인·회원별 평점 조회에는 자물쇠가 없고 보호 API에는 Bearer 요구를 표시한다. Swagger의 JSON은 문서 예시이며 실제 실행 결과는 evidence/week8-backend/live-api-results.json에 보관한다.

기존 5주차 스키마의 favorite 테이블을 사용하므로 DB 재생성이나 synchronize를 실행하지 않는다. 신규 환경은 기존 sql/01_schema.sql을 먼저 적용한다.

## 검증 재현

```sh
npm test
npm run lint
DB_NAME=umc_movie node --env-file=.env --env-file=../backend/.env scripts/verify-week8.cjs
node scripts/make-week8-postman.cjs
```

verify-week8은 위 로컬 서버가 실행 중일 때 사용한다. 두 임시 회원을 만들고 실제 HTTP·UNIQUE·rollback을 검증한 뒤 이번 실행의 행만 제거한다. 사전 존재 데이터는 전후 비교한다. 롤백 검증은 실제 트랜잭션의 두 번째 저장에 테스트 오류를 주입한다. 서비스에 공개 실패 주입 endpoint는 추가하지 않는다.

Postman 컬렉션은 실제 HTTP 응답을 토큰 없이 저장한 예제를 포함한다. 앱에서 각 요청 아래 예제를 열면 저장한 응답을 확인할 수 있다. 재실행할 때는 본인 로컬 환경에 accessToken을 넣고 요청을 순서대로 보낸다. 등록 후 중복 요청은 409가 정상이다.

## 참고

- [TypeORM Transactions](https://typeorm.io/docs/transactions/)
- [TypeORM Relations](https://typeorm.io/docs/relations/relations/)
- [NestJS OpenAPI](https://docs.nestjs.com/openapi/introduction)
- [NestJS Validation](https://docs.nestjs.com/techniques/validation)
