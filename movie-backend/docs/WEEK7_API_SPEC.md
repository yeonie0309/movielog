# MovieLog 7주차 로그인·인증·인가 API

원본은 MakeUs → PE (Mobile) A팀 → 레아의 워크북의 「7주차 - 로그인한 사용자를 구분하기」이다.
[워크북](https://app.notion.com/p/makeus-challenge/7-4d9b57f4596b8263833481c652fda02a).

| Method | 경로 | 인증 | 성공 응답 |
| --- | --- | --- | --- |
| POST | /auth/login | 공개 | 200, result {nickname, accessToken} |
| GET | /members/me | Bearer | 200, result {email, nickname, createdAt} |
| PATCH | /members/me | Bearer | 200, result {email, nickname, createdAt} |
| POST | /ratings | Bearer | 201, result RatingResponseDto |
| PATCH | /ratings/{ratingId} | Bearer | 200, result RatingResponseDto |
| DELETE | /ratings/{ratingId} | Bearer | 200, result null |
| GET | /members/{memberId}/ratings | 공개 | 기존 평점 배열, 선택적 page/size 유지 |
| POST | /members | 공개 | 기존 회원가입 201, 비밀번호 해시 저장 |
| GET | /members/nickname/{nickname}, /members/email/{email} | 공개 | 기존 {available} |

공통 응답은 `{isSuccess, code, message, result}`이다. 기존 공개 GET의 직접 배열/객체 계약은 유지한다.
회원가입 중복 코드는 기존 MEMBER4091(이메일)·MEMBER4092(닉네임)를 유지한다. 내 정보 수정의 닉네임 중복은 MEMBER409_1이다.
평점 쓰기 경로의 이전 `/members/{memberId}/ratings...`는 제거하여 토큰 없이 작성자를 지정하는 우회가 생기지 않게 했다.
이전 주차 쓰기 실습을 재실행할 때는 `feature/week-6-backend` 브랜치의 해당 버전을 사용한다.

## 요청 DTO

- 로그인은 email과 비어 있지 않은 문자열 password를 받는다. 가입 당시의 비밀번호를 bcrypt.compare로 확인하며 현재 가입 형식 규칙을 다시 적용하지 않는다. bcrypt의 72바이트 경계를 넘는 입력은 AUTH401_1로 거절한다.
- 내 정보 수정은 2~12자 nickname만 받는다. 자기 닉네임 유지가 가능하며 다른 회원의 닉네임과 DB UNIQUE 경쟁은 MEMBER409_1로 처리한다.
- 평점 등록은 기존 movieId, 정수 score 1~5, 선택적 comment(최대 500자)를 받는다. 수정은 score와 선택적 comment를 받는다. comment 생략/null은 코멘트 삭제로 처리한다.
- 평점 응답은 ratingId, movieId, score, comment, createdAt, updatedAt이다.
- memberId는 검증된 JWT의 sub에서만 결정한다. 추가 body 필드는 ValidationPipe에서 400으로 거절한다.
- 비밀번호를 읽는 Repository 조회는 로그인에서만 명시적 select를 사용한다. 응답 DTO는 비밀번호를 포함하지 않는다.

## 인증 실패와 소유권 실패

| 상황 | HTTP | code |
| --- | --- | --- |
| 없는 이메일 또는 틀린 비밀번호 | 401 | AUTH401_1 |
| Bearer 토큰 미제공 | 401 | AUTH401_2 |
| 변조·서명 오류·유효하지 않은 claims | 401 | AUTH401_3 |
| 만료된 토큰 | 401 | AUTH401_4 |
| 존재하지 않는 회원 | 404 | MEMBER404_1 |
| 다른 회원이 사용하는 닉네임 | 409 | MEMBER409_1 |
| 존재하지 않는 평점 | 404 | RATING404_1 |
| 다른 회원의 평점 수정·삭제 | 403 | RATING403_1 |
| 동일 영화 중복 평점 | 409 | RATING409_1 |

로그인 실패 두 사유는 동일한 message와 code를 돌려준다. 평점은 존재 확인 후 소유권을 검사한다.
본 주차는 소유권 실패를 403으로 구분하는 워크북 정책을 따른다.

## 환경변수와 실행

`movie-backend/.env`에 로컬 임의 JWT_SECRET(최소 32바이트), JWT_ACCESS_EXPIRATION=3600을 설정한다.
이 작업에서 로컬 비밀키를 생성했으며 실제 값은 Git과 증빙에 포함하지 않는다.

```sh
cd /Users/yeonie/UMC11/movielog/movie-backend
npm ci
npm run build
PORT=3007 DB_NAME=umc_movie node --env-file=../backend/.env --env-file=.env dist/main.js
```

60초 만료 실습은 서버를 종료한 뒤 위 실행 명령 앞에 `JWT_ACCESS_EXPIRATION=60`을 추가한다.
이 서버가 실행 중일 때 다음 명령으로 실제 Postman 컬렉션과 확장 검증을 수행한다.

```sh
node --env-file=../backend/.env scripts/verify-week7.cjs
```

검증은 고유 이메일의 새 테스트 회원 2명을 생성하고 이 두 회원의 평점만 조작한다.
실행 후 해당 데이터만 정리하고 기존 회원·평점 행이 일치하는지 확인한다.
보고서 저장 전 테스트 토큰의 만료를 기다린다. DB 스키마와 권한은 기존 설정을 사용한다.

Postman GUI에서는 `postman/MovieLog-week7.postman_collection.json`을 Import하고 빈 Environment를 선택한 뒤 순서대로 실행한다.
Pre-request 스크립트가 임시 이메일·닉네임·비밀번호를 생성하며 회원가입/로그인 응답에서 memberId/token/ratingId를 Environment에 연결한다.
GUI를 직접 재실행하면 새로운 테스트 회원이 생성되므로 사용한 테스트 계정을 별도로 기록한다.

## 공식 참고

- [NestJS JWT 모듈](https://github.com/nestjs/jwt)
- [NestJS Guards](https://docs.nestjs.com/guards)
- [JWT 표준 RFC 7519](https://www.rfc-editor.org/rfc/rfc7519)
- [bcrypt 공식 저장소](https://github.com/kelektiv/node.bcrypt.js)
