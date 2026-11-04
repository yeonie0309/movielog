# 6주차 — 입력한 데이터를 저장하기: API 명세

원본: [레아의 워크북](https://app.notion.com/p/makeus-challenge/6-ad6b57f4596b83b7b7cb81df305179e9).
선택 스택: **NestJS + TypeORM + MySQL**. 이번 검증 서버는 `http://localhost:3006`.
기본 실행 포트는 기존처럼 3000이며 `PORT`로 변경합니다. 인증/JWT는 7주차입니다.
`memberId`를 URL로 받는 것은 학습용이며 실제 로그인 사용자 인증을 대신하지 않습니다.

## 요청·응답

| 기능 | Method / Path | JSON Body | 성공 |
| --- | --- | --- | --- |
| 회원가입 | `POST /members` | email, nickname, password | 201, result: `{memberId,email,nickname}` |
| 평점 등록 | `POST /members/{memberId}/ratings` | movieId, score, comment? | 201, result: 숫자 ratingId |
| 평점 수정 | `PATCH /members/{memberId}/ratings/{ratingId}` | score, comment? | 200, result: null |
| 평점 삭제 | `DELETE /members/{memberId}/ratings/{ratingId}` | 없음 | **204, 응답 본문 없음** |

Content-Type: `application/json`. 새 쓰기 API는 아래 공통 JSON 형식을 사용합니다.
204는 JSON Wrapper를 반환하지 않는 의도적인 예외입니다.

```json
{
  "isSuccess": true,
  "code": "COMMON201",
  "message": "회원가입에 성공했습니다.",
  "result": { "memberId": 10, "email": "w6capture01@example.com", "nickname": "w6capture01" }
}
```

```json
{
  "isSuccess": false,
  "code": "MEMBER4091",
  "message": "이미 사용 중인 이메일입니다.",
  "result": null
}
```

## 입력 규칙

- email: 이메일 형식, 최대 254자, 필수.
- nickname: 문자열, 2~12자, 필수.
- password: 대문자·소문자·숫자·`!@#$%^&*` 중 특수문자를 포함한 8자 이상.
  bcrypt의 조용한 잘림을 막기 위해 UTF-8 **72바이트 이하**. 해시 cost 10.
- movieId: TMDB 외부 식별자인 양의 안전 정수. 로컬 영화 테이블 FK 아님.
- score: **JSON number인 1~5 정수**, POST/PATCH 모두 필수.
- comment: 선택 string/null, 최대 500자. 생략 또는 null이면 null 저장.
  PATCH도 워크북 예제대로 score 필수, comment 생략 시 기존 후기 삭제(null).
- memberId/ratingId: 양의 안전 정수. 경로 문자열은 숫자로 변환 후 검증.
- DTO 외 필드: `whitelist` + `forbidNonWhitelisted`로 400. 본문의 memberId/movieId 변경 등 거부.
- 비밀번호 평문·해시 모두 응답하지 않음. save() 반환 Entity를 그대로 노출하지 않음.

## 실패 계약

| HTTP | code | 조건 |
| --- | --- | --- |
| 400 | COMMON400 | 형식·범위·길이·필수 입력·DTO 외 필드 오류 |
| 409 | MEMBER4091 | 이메일 중복 (사전 검사와 실제 DB UNIQUE 모두 동일) |
| 409 | MEMBER4092 | 닉네임 중복 (사전 검사와 실제 DB UNIQUE 모두 동일) |
| 409 | RATING4091 | 회원·영화 복합 UNIQUE 중복 평점 |
| 403 | RATING4031 | 평점 소유자와 요청 memberId가 다름 |
| 404 | MEMBER4041 | 평점 등록 대상 회원 없음 / 저장 직전 FK 회원 소멸 |
| 404 | RATING4041 | 수정·삭제 대상 평점 없음 |
| 409 | COMMON409 | 알 수 없는 UNIQUE 제약 위반 (DB 내부값 비노출) |
| 500 | COMMON500 | 기타 예기치 않은 오류 (SQL·바인딩·스택 비노출) |

평점은 먼저 ID로 찾아 없으면 404, 있으면 소유자를 비교해 다르면 403.
DB BIGINT가 문자열로 반환되어도 ID 비교가 정확하도록 처리했습니다.

## 기존 5주차 및 6주차 프론트 보존

5주차의 GET 중복 확인 `{available}`와 평점 배열 성공 응답은 변경하지 않습니다.
해당 조회의 실패 응답은 전역 Filter의 공통 구조를 사용하며, 기존 message 필드는 유지합니다.
6주차 Flutter는 별도 공개 v5 API를 사용하고, 이 로컬 쓰기 API로 바꾸지 않습니다.
Favorite API, JWT, Flutter 회원가입/평점 쓰기 연동은 이번 구현에 포함하지 않습니다.

## DB·동시성

기존 `umc_movie` 스키마의 member.email, member.nickname UNIQUE,
rating(member_id,movie_id) 복합 UNIQUE 및 FK/CHECK를 그대로 사용합니다.
스키마 삭제·재생성, 기존 더미 데이터 수정, synchronize=true는 사용하지 않습니다.
동시성 검증은 테스트 전용 barrier로 양쪽 사전 중복 검사를 통과시키고,
**실제 MySQL ER_DUP_ENTRY(1062)** → 운영 전역 Filter → 409를 확인합니다.
운영 코드에 지연·검증 우회 엔드포인트를 넣지 않습니다.

## 공식 참고

- [NestJS Validation](https://docs.nestjs.com/techniques/validation)
- [NestJS Exception Filters](https://docs.nestjs.com/exception-filters)
- [bcrypt 공식 구현·72바이트 제한](https://github.com/kelektiv/node.bcrypt.js)
