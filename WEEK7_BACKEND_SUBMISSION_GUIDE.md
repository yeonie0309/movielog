# 7주차 백엔드 제출 가이드

대상은 원본 [레아의 워크북 · 7주차 - 로그인한 사용자를 구분하기](https://app.notion.com/p/makeus-challenge/7-4d9b57f4596b8263833481c652fda02a)이다.
아래 내용은 원본 페이지 위에서부터 배치하는 작성 초안이다. 학습 후기와 이해 여부는 본인이 읽고 확인한다.
PR 링크는 생성 후 이 문서에 확정한다.

## 완료한 작업과 검증

- 기존 NestJS + TypeORM movie-backend에 JWT 로그인, 내 정보 조회·수정, 토큰 기반 평점 쓰기를 구현했다.
- 선택 미션의 실제 60초 만료와 `@LoginMember` 데코레이터도 구현·검증했다.
- backend lint/build 및 HTTP 테스트 60개, Flutter 테스트 79개, Flutter analyze(exit 0, 기존 week0 info 2건)를 통과했다.
- Postman 컬렉션을 Newman으로 실제 실행하여 요청 12개와 검증 41개를 통과했다. 워크북의 9단계에 A/B 가입·로그인과 무토큰 me 조회가 포함된 구성이다.
- 실제 MySQL 확장 검증까지 총 25건의 HTTP 요청을 확인했다. 임시 회원 A=11, B=12, 평점 ratingId=6, TMDB movieId=155였다.
- 60초가 지나 같은 토큰이 AUTH401_4로 거절되는 것을 실제 시계로 확인했다.
- 생성한 테스트 회원 2명과 평점만 정리했으며 기존 DB의 회원·평점 행이 이전과 일치했다.
- 01~07·09~12 사진은 실제 실행 기록/CLI 로그의 읽기 전용 뷰어 캡처다. 08은 실제 jwt.io 페이지 캡처다.

작업 전 로컬 main은 2445f60, 원격 main은 a10ad32(1주차까지)였다.
최신 7주차 프론트 36ce39b에서 feature/week-7-backend를 만들었다. 기존 형식에 맞춘 브랜치 이름이다.
이전 사용자 미추적 증빙과 프론트 제출 응답 사진은 작업 대상에서 제외했다.

## 📸 스터디 인증샷

원본 상단 안내는 스터디리더가 매 주차 실제 스터디 사진 한 장을 남기는 항목이다.
여기에는 실제 모임 사진을 첨부한다. 기술 실행 증빙은 아래 실습 인증과 미션 기록에 넣는다.

## 🎯 핵심 키워드 — 각 토글에 복사

### 인증(Authentication)과 인가(Authorization)

인증은 요청자의 신원을 확인하는 절차이다. 로그인에서는 이메일과 비밀번호 해시를 비교하고, 보호된 요청에서는 JWT의 서명과 만료를 검증하여 요청자를 식별한다. 인가는 식별한 요청자가 특정 자원에 대해 해당 행동을 할 권한이 있는지 판단하는 절차이다. 평점 수정·삭제에서는 토큰의 회원 ID와 DB 작성자 ID를 비교한다. 인증을 통과한 회원 B라도 회원 A의 평점에는 수정 권한이 없으므로 403을 받는다.

검토한 지점은 공통 인증과 기능별 소유권 규칙의 위치다. 인증은 Guard에, 평점 소유권은 Service에 두어 새 컨트롤러가 같은 검증을 사용할 수 있게 했다. [NestJS Guards](https://docs.nestjs.com/guards)

### 해시와 salt, bcrypt

비밀번호 해시는 입력값을 단방향 계산으로 변환한 값이다. bcrypt는 비밀번호 저장용 해시 함수로 임의 salt와 조정 가능한 비용을 사용한다. salt는 동일한 비밀번호도 서로 다른 해시로 저장되게 하고, 비용은 한 번의 계산에 필요한 작업량을 결정한다. 저장 문자열 안에 salt와 비용 정보가 포함되므로 compare는 입력값을 저장된 조건으로 계산해 일치 여부를 확인할 수 있다.

Member.password의 select:false 설정 때문에 로그인 조회에는 password 선택을 명시했다. 내 정보 응답은 email·nickname·createdAt만 옮겨 담는다. 현재 가입 규칙을 로그인 DTO에 다시 적용하면 과거 규칙으로 가입한 회원이 막힐 수 있어 로그인 DTO는 이메일과 비어 있지 않은 비밀번호를 확인한다. bcrypt의 72바이트 경계를 넘는 입력은 일반 로그인 실패로 처리하여 뒤쪽 문자가 잘려 같은 비밀번호로 인정되는 문제를 막았다. [bcrypt 공식 문서](https://github.com/kelektiv/node.bcrypt.js)

### JWT — Header / Payload / Signature, Claim

JWT는 당사자 사이에 Claim을 전달하기 위한 표준이다. 이 프로젝트의 서명된 JWT는 Header, Payload, Signature 세 부분으로 구성된다. Header는 서명 알고리즘 정보를, Payload는 토큰 주체와 발급·만료 정보 같은 Claim을 담는다. Signature는 Header와 Payload의 무결성을 검증하는 데 사용한다. sub는 토큰 주체, iat는 발급 시각, exp는 만료 시각을 나타낸다.

프로젝트는 HS256과 32바이트 이상의 로컬 비밀키를 사용하고, sub를 회원 ID 문자열로 발급한다. 검증에는 HS256만 허용하며 숫자로 사용할 수 있는 sub와 exp도 확인한다. payload는 Base64URL로 읽을 수 있으므로 비밀번호를 포함하지 않는다. 실제 실습 토큰은 sub 11, exp-iat 60초였고 jwt.io에서 확인했다. [RFC 7519](https://www.rfc-editor.org/rfc/rfc7519), [NestJS JWT](https://github.com/nestjs/jwt)

### Bearer 인증과 Authorization 헤더

Bearer는 토큰을 지참한 요청자를 인증하는 HTTP 인증 방식이다. 클라이언트는 Authorization 헤더에 `Bearer {accessToken}`을 넣고 서버는 그 값을 검증한다. 헤더는 GET·POST·PATCH·DELETE 모두에서 사용할 수 있어 공통 인증 정보를 전달하기에 적합하다. 보호된 평점 API는 이 헤더에서 확인한 회원 ID를 사용한다.

선택한 설계에서는 URL과 body에서 작성자 ID를 받는 쓰기 경로를 제거했다. body의 memberId 추가는 400으로 거절하며 이전 URL은 404로 응답한다. [NestJS JWT](https://github.com/nestjs/jwt)

### HandlerInterceptor / Guard

Spring의 HandlerInterceptor는 컨트롤러 실행 전후 요청 처리를 공통화하는 지점이며, NestJS Guard는 컨트롤러 실행 전에 요청 처리 허용 여부를 결정하는 구성요소이다. Guard의 canActivate에서 토큰을 검증하고, 성공하면 요청 객체에 회원 ID를 보관해 후속 컨트롤러가 사용하게 한다.

이 프로젝트는 보호된 메서드에 @UseGuards(AuthGuard)를 적용하고, @LoginMember 커스텀 파라미터 데코레이터로 회원 ID를 받는다. 공개 닉네임·이메일 확인과 회원별 평점 조회는 공개 계약을 유지한다. [NestJS Guards](https://docs.nestjs.com/guards)

### 401 Unauthorized와 403 Forbidden의 차이

401은 보호된 요청의 인증이 유효하지 않은 경우에 사용한다. 토큰 누락은 AUTH401_2, 변조는 AUTH401_3, 만료는 AUTH401_4로 구분했다. 403은 요청자를 인증했지만 대상 자원에 대한 권한이 없을 때 사용한다. 다른 회원 토큰으로 평점을 수정하면 RATING403_1을 반환한다.

자원의 존재 여부 확인 후 소유권을 확인하여 없는 평점은 RATING404_1을 반환한다. 본 주차는 학습 목표에 맞춰 소유권 실패를 403으로 구분한다. 자원 존재 자체를 숨기는 정책과의 차이도 검토했다. [NestJS Guards](https://docs.nestjs.com/guards)

## 📢 학습 후기 — 검토 후 복사

요청자의 회원 ID를 검증된 JWT에서 가져오도록 바꾸면서 인증과 인가의 역할을 연결해 이해했다. Guard가 요청자를 확인한 뒤에도 Service에서 평점 작성자를 별도로 확인해야 본인 데이터만 수정·삭제할 수 있었다.

두 테스트 계정으로 동일한 수정 요청을 보내 200과 403의 차이를 확인하고, 토큰을 제거했을 때의 401과도 비교했다. 토큰 payload를 한 글자 변경하면 서명 검증에서 거절되고, 60초 뒤에는 만료 전용 코드가 반환되는 흐름도 확인했다.

비밀번호 해시 조회가 필요한 로그인과 정보를 제한해야 하는 응답 DTO를 구분하는 점, 기존 쓰기 경로를 함께 정리해야 인증 우회가 남지 않는 점이 주요 검토 지점이었다. 이후 새 API에도 Guard 적용 여부와 자원 소유권 규칙을 함께 확인하겠다.

## ✅ 실습 체크리스트

| 원본 항목 | 구현·실행 결과 | 증빙 |
| --- | --- | --- |
| ApiException을 전역 처리기가 code·상태 코드로 변환 | 확인 완료 | 02·03·06·07, 실제 JSON |
| 로그인 토큰 발급과 jwt.io payload 확인 | 확인 완료 | 01·08 |
| 미가입 이메일/틀린 비밀번호의 동일 응답과 이유 | 실행 확인 완료. 위 키워드의 가입 여부 노출 이유를 읽고 설명 가능 여부 확인 | 09 |
| 토큰 없는 GET /members/me 401 | 확인 완료 | 02 |
| payload 한 글자 변경 시 서명 검증 401 | 확인 완료 | 06 |
| 평점 쓰기에서 클라이언트 memberId 제거 | 확인 완료 | 04, 60개 테스트, 이전 경로 404 |
| 회원 두 명의 403 재현 및 401과 비교 설명 | 실행 확인 완료. 위 키워드 설명 확인 | 02·03 |

각 항목의 실행 증빙은 모두 준비되어 있다. 이해·설명 가능 여부까지 확인하고 체크한다.

## ☑️ 실습 인증

다음 순서로 사진 원본을 직접 첨부하고 캡션을 적는다.

1. 05-my-info-get-patch.jpg — 본인 토큰으로 내 정보 조회·닉네임 수정 성공.
2. 06-tampered-401.jpg — payload 한 글자 변경 후 AUTH401_3.
3. 08-jwt-io-payload.jpg — sub/email/iat/exp 디코딩. 만료된 localhost 실습 토큰 사용.
4. 09-identical-login-failure.jpg — 미가입 이메일과 틀린 비밀번호가 동일한 AUTH401_1.
5. 11-cli-checks.jpg — backend lint/60개 테스트와 Flutter analyze/79개 테스트 실제 로그.
6. 12-postman-newman.jpg — 실제 Postman 컬렉션 12요청·41검증 결과.

jwt.io 사진은 payload 확인 증빙이다. 서버 비밀키는 로컬 설정으로 관리하며, 서버 서명 검증 결과는 정상 200과 변조 401 사진으로 확인한다.

## 🔥 미션 → 필수

실습 1~6 및 Postman 9단계 시나리오를 완료했다. 아래 네 장을 미션 기록에도 순서대로 첨부한다.

| 원본 제출물 | 직접 첨부할 사진 |
| --- | --- |
| 로그인 성공, accessToken이 보이도록 | 01-login-200.jpg |
| 토큰 없는 GET /members/me 401 | 02-no-token-401.jpg |
| 다른 회원 토큰으로 평점 수정 403 | 03-other-member-403.jpg |
| 본인 토큰으로 평점 등록 201 | 04-rating-create-201.jpg |

요청 body는 movieId·score·comment이며 memberId가 없다. 401의 AUTH401_2와 403의 RATING403_1이 서로 다르다.
실제 응답은 `live-api-results.json`, 시나리오 실행 결과는 12 사진을 함께 첨부한다.

## 🔥 미션 → 선택

### 토큰 만료

JWT_ACCESS_EXPIRATION=60으로 실행한 서버에서 로그인했다. 같은 토큰의 만료 전 내 정보 조회는 200, 실제 60초 경과 후에는 401·AUTH401_4로 응답했다. 무토큰 AUTH401_2와도 구분됨을 확인했다. 기본 로컬 설정은 3600초이며 만료 실습은 실행 환경변수로 60초를 적용했다.

07-expiry-before-after.jpg를 첨부한다. 왼쪽 만료 전 성공과 오른쪽 만료 후 401이 함께 보인다.

### @LoginMember

createParamDecorator로 Guard가 검증한 회원 ID를 추출하는 @LoginMember를 구현했다. 내 정보와 평점 쓰기 컨트롤러에 적용하여 요청 객체의 문자열 키를 직접 읽는 코드를 줄였다. 실제 내 정보 조회 200과 테스트로 정상 동작을 확인했다.

10-login-member-decorator.jpg를 첨부한다. 적용 전 칸은 워크북 기본 예시이고, 적용 후 칸은 프로젝트의 실제 데코레이터·컨트롤러 코드이다.

## 💪 미션 기록 토글 — 과정과 결과를 함께 작성

### 1. 작업 기준과 요구사항

main과 git status를 먼저 확인했다. main은 이전 주차까지의 변경을 모두 포함하지 않아 최신 7주차 프론트 브랜치를 기준으로 백엔드 브랜치를 만들었다. 워크북에서 로그인·me 조회/수정·토큰 기반 평점 쓰기, 공통 오류 코드, 삭제 200 계약을 확인했다. 선택 미션 두 가지도 구현 범위에 포함했다.

### 2. 구현 과정

@nestjs/jwt를 추가하고 환경변수에서 비밀키와 초 단위 만료를 읽도록 구성했다. 로그인에서 password를 명시적으로 조회해 bcrypt.compare로 확인한 뒤 sub/email/iat/exp를 가진 토큰을 발급했다.

AuthGuard가 서명과 만료를 검사하고 @LoginMember가 인증된 회원 ID를 전달하도록 연결했다. 내 정보는 DTO로 필요한 필드만 반환하며 닉네임 수정은 본인을 제외해 중복 검사한다.

평점 쓰기 URL에서 memberId를 제거하고 Service 소유권 검사를 유지했다. POST/PATCH는 평점 DTO, DELETE는 200 공통 응답과 null result를 반환한다. 토큰 없이 접근할 수 있는 이전 쓰기 경로를 제거했다.

### 3. 실제 실행 순서

새 테스트 회원 A/B 가입 → A/B 로그인 → A 평점 등록 201 → 중복 409 → A 수정 200 → B 수정 403 → 무토큰 수정 401 → 없는 평점 삭제 404 → A 삭제 200 순서로 실행했다.

이후 내 정보 조회·닉네임 유지/수정/중복, 로그인 실패 응답 통일, payload 한 글자 변경, body 작성자 주입 거절, 이전 쓰기 경로 제거, 삭제 후 빈 목록을 검증했다. 같은 토큰의 만료 전 200과 60초 후 AUTH401_4도 확인했다.

여기에 필수 01~04 사진과 선택 07·10 사진, Newman 결과 12 사진을 각각 캡션과 함께 직접 첨부한다.

### 4. 테스트와 데이터 정리

Backend lint/build와 HTTP 테스트 60개, Flutter analyze와 테스트 79개가 통과했다. 실제 API는 총 25건을 확인했다. 검증에서 생성한 회원 2명과 평점을 정리한 후 기존 DB 행이 유지되는지 비교했다. 증빙의 테스트 토큰은 저장 전에 만료를 확인했다.

### 5. PR과 검토

PR 링크는 생성 후 이 문서에 확정한다. API 명세, 코드, 실행 기록 및 사진을 함께 첨부했다. 이해 확인과 실제 스터디 사진 첨부, UMC 제출은 본인이 진행한다.

## ⚡ 트러블 슈팅 — 이슈 / 문제 / 해결

이슈 No.1 — 토큰 인증으로 전환할 때 이전 평점 쓰기 경로 정리

문제 — 기존 코드는 memberId를 URL로 받아 평점을 작성했고 DELETE는 204였다. 새 토큰 경로만 추가하면 이전 경로가 인증을 우회할 수 있고, 새 공통 응답 본문과 204 계약도 맞지 않는다.

해결 — 쓰기 경로를 /ratings로 옮기고 Guard와 @LoginMember를 적용했다. 이전 memberId 쓰기 경로는 제거하고 삭제 응답은 워크북의 200·COMMON200·result null로 변경했다. 기존 입력 검증 테스트도 새 계약과 실제 토큰을 사용하도록 갱신했다.

재검증 — 이전 경로 404, 보호된 쓰기 무토큰 401, 본인 수정 200, 다른 회원 수정·삭제 403, 삭제 200 및 빈 목록을 테스트했다. Postman 9단계도 실제 MySQL로 통과했다.

이슈 No.2 — 로그인용 비밀번호 조회와 응답 DTO의 범위

문제 — Member.password에 select:false가 설정되어 있어 일반 조회는 로그인 비교에 필요한 해시를 가져오지 않는다. 로그인에서 해시를 읽더라도 응답에 비밀번호가 포함되지 않아야 한다.

해결 — 로그인 Repository 조회에서만 password 선택을 명시하고, 로그인 응답은 nickname/accessToken DTO, 내 정보 응답은 email/nickname/createdAt DTO로 구성했다.

재검증 — 실제 bcrypt 로그인 성공과 미가입/틀린 비밀번호의 동일 실패를 확인했다. 내 정보 응답 필드가 세 개이고 비밀번호 필드가 없는지도 테스트했다. [bcrypt](https://github.com/kelektiv/node.bcrypt.js), [NestJS JWT](https://github.com/nestjs/jwt)

## 직접 마무리할 일

1. 원본 상단 스터디 인증샷에 실제 모임 사진을 첨부한다.
2. 핵심 키워드·학습 후기 초안을 읽고 본인이 이해한 내용에 맞춰 반영한다.
3. 실습 인증과 미션 기록에 위 사진 원본을 첨부하고 이미지가 실제 표시되는지 확인한다.
4. 실습 체크리스트의 이해·설명 가능 여부까지 확인하고 체크한다.
5. 원본 Notion 페이지 URL을 UMC 피드백 시스템에 제출한다.

기술 구현·실행·캡처는 완료했다. 사진과 실행 원본은 [evidence/week7-backend](evidence/week7-backend/README.md), API 명세는 [WEEK7_API_SPEC.md](movie-backend/docs/WEEK7_API_SPEC.md)에 있다.
