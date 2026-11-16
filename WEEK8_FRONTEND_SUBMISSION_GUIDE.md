# 8주차 프론트엔드 제출 가이드

대상은 레아의 원본 「8주차 - JWT 토큰 기반 로그인 및 세션 복원」이다.

https://app.notion.com/p/makeus-challenge/8-JWT-200b57f4596b83018ee881b5bf4f501d

PR_LINK_PENDING

## 작업 기준

- 로컬 main은 2445f60, fetch한 origin/main은 a10ad32였다. 최신 이전 주차를 포함한 origin/feature/week-7-backend의 68a05c8에서 feature/week-8-frontend를 생성했다.
- 워크북의 별도 브랜치·PR 제목 규칙을 찾지 못해 기존 feature/week-N-frontend와 feat 형식을 적용했다.
- 신규 앱 기본 진입은 인증 Router를 사용한다. 이전 주차의 별도 Router 주입 방식으로 기존 실습과 테스트를 실행할 수 있다.
- 앱의 실제 인증·평점 쓰기는 공개 워크북 v7 API를 사용한다. 이전 v6 실습 Service는 이전 주차 호출자 호환용으로 보존했으며, v7 쓰기 Service에는 memberId 인자가 없다.
- 학습에 사용하는 공개 API의 login/me 응답에는 memberId가 없고 토큰 기반 내 평점 전체 조회도 없다. JWT의 임의 claim으로 회원 ID를 추정하지 않는다. v7 등록 응답의 Rating을 현재 로그인 세션에서 보관하고 수정·삭제한다. 재시작·로그아웃·회원 전환 시 이 목록은 초기화된다.

## 구현과 검증 범위

Flutter 테스트94개, Android UI 시나리오3개, 실제 v7 요청16건을 통과했다. analyze는 종료 코드0이며 기존 week0 info2건이다.

| 원본 항목 | 구현 및 확인 방법 |
| --- | --- |
| 로그인 모델·Service·401 입력 오류 | LoginRequest/LoginResult, AuthApiService, 로그인 화면과 실제 AUTH401_1 |
| TokenStorage | flutter_secure_storage의 Android write/read/delete 및 별도 프로세스 복원 |
| 보호 API Bearer | 정확한 HTTPS host와 v7 me/ratings 경로 검사, 공개·TMDB Client 분리 |
| 신규 로그인 | 토큰 저장 → signedIn → MainScreen.loadMember() |
| 앱 재실행 | 토큰 읽기 → GET me 성공 → signedIn, 실패 시 retryRequired |
| 인증 Router | redirect와 refreshListenable, 초기화/재시도 중 스플래시, 로그아웃 후 보호 경로 차단 |
| 내 정보·닉네임 수정 | GET/PATCH me, 2~12자·중복 입력 유지·재시도·수정 결과 즉시 반영 |
| 평점 등록·수정·삭제 | v7 DTO 및 성공 status, memberId 없는 쓰기, comment 명시 전송 |
| 세션 만료 | AUTH401_2/3/4의 세션 정리, 로그인 화면의 일회성 Snackbar |
| 오류 정책 | 로그인 AUTH401_1·권한403·중복409·네트워크 실패를 분리 |
| 이전 응답 차단 | sessionVersion 검증, 늦은 성공·401·프로필 응답 회귀 테스트 |
| 저장·정리 경합 | 진행 중 토큰 저장 후 삭제, 정리 중 로그인 차단, 삭제 실패 재시도 |
| Challenge 이메일 | SharedPreferences에 이메일만 저장, 로그인 화면 재생성 후 복원 |
| Challenge 내 정보 상태 | 로딩·오류·재시도 UI |
| Challenge 가입일 | MemberInfo.createdAt을 로컬 날짜로 표시 |
| Challenge 수정 이탈 | 변경 내용이 있으면 확인 Dialog, 계속 수정·나가기 분기 |

Android UI 자동 조작 검증과 단위·위젯 테스트를 수행했다. 원본 체크리스트의 수동 검증 문구에 맞춰 제출 전 본인도 아래 확인 순서를 실행한다.

## 1. 스터디 인증

원본의 스터디 인증 목록 바로 아래에 다음 사진·영상을 직접 첨부한다.

1. 로그인 실패·성공과 내 정보 — 01, 02 사진.
2. 재시작 세션 복원 — 09 사진과 02-restart-logout-invalid.mp4.
3. 닉네임 수정 409·성공 — 03, 04 사진.
4. 평점 등록·수정·삭제 — 05~08 사진과 01-login-profile-crud.mp4.
5. 무효 토큰·만료 안내 — 11 실제 무효 토큰, 14 만료 코드 실패 주입 사진.
6. 로그아웃과 보호 경로 차단 — 10 사진, 복원 영상, result-restore.json.
7. 안전한 요청·응답 및 analyze·테스트 — 19-flutter-checks.jpg와 20-safe-network.jpg.

사진을 이미지 블록으로, 영상을 동영상 또는 파일 블록으로 첨부한다. 업로드 후 실제 이미지와 영상이 열리는지 확인한다.

## 2. Guided Practice A

모델·보안 저장·Interceptor·AuthViewModel·Router·MainScreen 내 정보·세션 복원 항목은 구현했다.
실행 증빙을 확인한 뒤 기술 완료 항목을 체크한다.

복사할 설명

로그인 API 성공 후 Access Token을 Android 보안 저장소에 저장하고 signedIn으로 전환했다. MainScreen 진입 시 GET /v7/members/me를 호출해 내 정보를 보관한다. 앱 재시작에서는 저장된 토큰을 읽고 GET me 검증에 성공한 뒤에만 홈으로 이동한다. 네트워크 실패는 토큰을 유지하고 재시도 상태로 처리한다.

## 3. Guided Practice B

v7 전용 AuthenticatedRatingApiService에 공개·보호 Client를 전달했다. 쓰기 메서드에는 memberId 인자가 없으며 공개 회원별 GET만 회원 ID를 받는다.

복사할 설명

POST /v7/ratings의 요청 body에는 movieId·score·comment를 사용한다. 등록·수정 성공 result의 Rating 객체를 현재 세션에 반영하고, 삭제 성공은 200과 result null을 확인한다. AUTH401_2/3/4는 세션을 정리하고 403·409는 오류를 안내한다. 세션 버전이 달라진 응답은 반영하지 않는다.

## 4. Required Mission

기술 구현 항목은 모두 구현했다. 사진·영상과 함께 확인 후 체크한다.

| 항목 | 첨부할 증빙 |
| --- | --- |
| 현재 세션 Rating 수정·삭제 | 06~08, 실제 CRUD 영상 |
| v7 status/result/code 파서 | result-live.json, 요청·응답 요약 |
| 내 정보와 프로필 수정 | 02~04 |
| 닉네임 길이·409·입력 유지·네트워크 재시도 | 03, 위젯·ViewModel 테스트 |
| 재시작·로그아웃·보호 redirect | 09~11, 복원 영상 |
| 마이페이지 앱바 로그아웃 | 10 |
| 로그인 화면 만료 Snackbar | 14, AUTH401_4 실패 주입이라고 캡션 명시 |

## 5. Challenge Mission

네 항목을 구현했다. 각각 아래 증빙을 넣고 확인 후 체크한다.

- 이메일 저장 — 15. 기기 설정 저장소에는 이메일만 저장한다.
- 내 정보 로딩·실패·재시도 — 17, 18. API 실패를 주입한 시나리오이다.
- 닉네임 아래 가입일 — 04, 09.
- 변경 내용 이탈 확인 Dialog — 16. 계속 수정과 나가기를 검증했다.

심화 iOS 재설치 flag는 iOS 환경에서의 추가 학습 항목이다. 선택한 실제 검증 환경은 Android이다.

## 6. 트러블슈팅 기록

원본 코드 블록의 필드 이름을 유지하고 다음 내용을 옮긴다.

인증 상태와 재현 순서

사용자 A의 보호 API 요청을 시작한 뒤 로그아웃하거나 B로 로그인하면 A의 응답이 늦게 도착할 수 있다. 보호 API 여러 건에서 동시에 401을 받는 상황도 검토했다.

요청 종류(로그인/공개/보호)

보호 요청인 GET/PATCH /v7/members/me와 POST/PATCH/DELETE /v7/ratings. 비교 대상으로 로그인 요청 POST /v7/auth/login과 공개 회원별 평점 조회를 사용했다.

status·code(토큰/비밀번호 제거)

실제 로그인 실패 401·AUTH401_1, 무효 토큰 401·AUTH401_3, 다른 테스트 회원의 평점 수정 403·RATING403_1, 닉네임 중복 409·MEMBER409_1을 확인했다. AUTH401_4는 실패 주입으로 검증했다.

예상한 AuthStatus

현재 세션의 응답만 반영한다. 보호401은 signedOut으로 전환하고, 403과 일시 네트워크 실패는 signedIn을 유지한다. 시작 시 검증 실패는 retryRequired로 처리한다.

실제 AuthStatus/화면

로그인 실패는 입력 오류로 표시되고 보호401은 로그인 화면으로 이동한다. 403은 오류를 안내하면서 로그인 상태를 유지한다. 복원 네트워크 실패는 재시도 화면으로 표시된다. 자동화에서 Dialog 종료·입력 프레임 전에 조작하거나 캡처하면 이전 상태가 관찰되는 경우가 있었다.

원인

비동기 응답이 요청 시작 순서와 다르게 도착할 수 있으며, 인증 상태 변경과 토큰 저장·삭제가 겹칠 수 있다. 입력·Dialog 애니메이션 역시 다음 프레임에 반영된다.

수정

요청 시작 시 세션 버전을 기록하고 완료 시 현재 버전과 비교했다. 보호401도 요청 당시 버전을 전달한다. 로그아웃은 진행 중 토큰 저장 후 삭제하며 정리 중 새 로그인을 막는다. 로그인 화면은 sessionExpired를 한 번 소비해 Snackbar를 표시한다. 테스트는 입력값·포커스·버튼 활성화·Dialog 종료 프레임을 확인한다.

재시작·로그아웃·회원 전환 재검증

Android 별도 프로세스에서 토큰 복원과 GET me 200, 로그아웃 후 토큰 삭제·보호 경로 차단을 확인했다. 이전 세션의 성공·401·프로필 응답이 새 세션을 바꾸지 않는 회귀 테스트와 토큰 저장·삭제 경합 검증을 통과했다.

추가 실행 이슈

Android 자동화에서 포커스를 해제한 뒤 입력값을 다시 넣을 때 포커스·버튼 활성화 프레임을 기다리지 않으면 이전 값으로 요청하거나 비활성 버튼을 누를 수 있었다. 입력 필드를 명시적으로 선택하고 controller 값과 프레임을 확인하도록 보완했다. 앱의 로그인은 포커스 해제·비동기 작업 전에 제출할 값을 지역 변수로 고정한다.

Flutter 통합 테스트는 기본 설정에서 종료 후 앱을 제거한다. 실제 저장소 복원을 확인하는 실행에는 --no-uninstall을 사용해 설치 데이터를 유지하고 다음 프로세스에서 GET me를 검증했다.

공식 참고

- https://pub.dev/packages/flutter_secure_storage
- https://pub.dev/packages/dio
- https://pub.dev/documentation/go_router/latest/go_router/GoRouter-class.html
- https://workbook.devnoco.com/docs/v7-json

## 7. 최종 체크리스트

| 원본 항목 | 체크 판단 |
| --- | --- |
| 비밀번호 비저장·로그 비노출 | 코드·실행 증빙 확인 후 체크 |
| 보호 host/path에만 Bearer | Interceptor 테스트·실행 기록 확인 후 체크 |
| 로그인401·보호401·403 구분 | 실제401/403과 오류 주입 시나리오 확인 후 체크 |
| 복원 GET me와 신규 로그인 loadMember | 실제 두 프로세스 실행 확인 후 체크 |
| 네트워크 실패에 토큰 유지 | 테스트·12·18 확인 후 체크 |
| v7 경로·parser·status·code | 명세 대조·실제 CRUD 확인 후 체크 |
| TMDB와 MovieLog 토큰 분리 | Client 코드·비노출 기록 확인 후 체크 |
| movieId와 영화 정보 결합·placeholder | 06·07, TMDB 오류 대체 표시 코드 확인 후 체크 |
| 이전 세션 응답 무시 | 회귀 테스트 확인 후 체크 |
| 내 평점 전체 복원의 한계 문서화 | 위 작업 기준과 제출 양식에 기록 후 체크 |
| 실제 플랫폼 보안 저장 | Android 실행·복원·삭제 확인 후 체크 |
| analyze·Guided/Required 수동 검증 기록 | 자동 검증 결과 첨부 후 아래 본인 확인 순서까지 실행하고 체크 |

본인 확인 순서

회원가입 또는 본인 계정 로그인 → 마이페이지 정보 확인 → 프로필 닉네임 수정 → 영화 상세에서 정수 평점·코멘트 등록 → 이번 로그인 평점 목록에서 수정·삭제 → 로그아웃 → 보호 화면 접근 시 로그인 이동 확인. 재시작 때는 로그인 상태에서 앱을 완전히 종료하고 다시 열어 내 정보가 복원되는지 확인한다.

## 8. 제출 양식

### PR 링크

PR_LINK_PENDING

### 로그인→GET me 증거

01·02 사진과 실제 요청·응답 기록을 첨부했다. 로그인 AUTH401_1을 확인한 뒤 정상 로그인 200과 GET /v7/members/me 200을 확인했다. 내 정보는 email·nickname·createdAt을 표시한다.

### 재시작 복원 / 로그아웃 / 만료 증거

09~11 사진과 복원 영상을 첨부했다. Android 설치 데이터를 보존한 별도 프로세스에서 저장된 토큰으로 GET me 200을 확인했다. 로그아웃 후 토큰과 내 정보가 제거되고 보호 경로가 로그인으로 이동한다. 실제 무효 토큰은 서버의 AUTH401_3으로, 시간 만료 AUTH401_4의 UI 흐름은 실패 주입으로 검증했다.

### 닉네임 수정 증거

03·04 사진. 중복 닉네임 PATCH의 MEMBER409_1과 입력 유지, 다른 닉네임 PATCH 200과 마이페이지 즉시 반영을 확인했다. 길이 검증과 네트워크 오류 재시도도 테스트했다.

### 평점 v6→v7 변경 표와 동작 영상

| 항목 | v6 | v7 |
| --- | --- | --- |
| 등록 | /members/{memberId}/ratings | /ratings |
| 수정·삭제 | /members/{memberId}/ratings/{ratingId} | /ratings/{ratingId} |
| 사용자 식별 | 경로의 memberId | Bearer 토큰 |
| 등록·수정 result | 기존 계약 | Rating 객체 |
| 삭제 성공 | 204 | 200, result null |

05~08과 실제 CRUD 영상을 첨부했다. PATCH에서는 score와 comment를 함께 보낸다.

### TMDB id → MovieLog movieId → 영화 정보 결합 증거

실제 TMDB 다크 나이트 ID 155를 사용했다. POST body.movieId와 반환 Rating.movieId가 같으며, 현재 세션 목록에서 TMDB 영화 제목·포스터와 결합했다. 영화 정보 조회 실패 시 평점은 유지하고 영화 #ID와 대체 포스터를 표시한다.

### 401/403/409 처리

실제 로그인401·무효 토큰401·다른 테스트 회원의 평점 수정403·닉네임 중복409를 확인했다. 만료401과 네트워크 실패는 실패 주입으로 UI를 검증했다. 로그인 실패는 Form 안내, 보호401은 세션 정리, 403·409는 오류 안내를 수행한다.

### 보안 저장 검증 플랫폼·결과

Android Pixel 7 에뮬레이터에서 실제 flutter_secure_storage 저장·읽기·삭제를 검증했다. 앱 프로세스를 다시 실행한 뒤 GET me로 복원하고, 로그아웃 후 저장값이 null인지 확인했다.

### 토큰/비밀번호 비노출 확인

실제 JWT와 비밀번호는 Git·요청 응답 증빙·사진·영상에 포함하지 않았다. 요청 기록에는 Bearer 부착 여부만 표시하며 로그인 응답 accessToken과 요청 password는 제거했다. TMDB 로그의 Authorization은 ***로 가린다.

### 트러블슈팅

위 세션 버전 검사·토큰 저장/삭제 경합·Android 입력 프레임·통합 테스트 자동 제거 옵션 기록과 테스트 결과를 참조한다.

## 검증 한계와 실습 데이터

- iOS·물리 기기 검증과 실제 만료 시간 전체 경과 검증은 수행하지 않았다. AUTH401_4는 실패 주입으로 검증한다.
- 수동 확인과 Android UI 자동 조작을 구분한다. 제출 전 마지막 체크 항목의 수동 확인은 본인이 진행한다.
- 반복 실행에서 공개 실습 서버에 테스트 회원 14개가 생성됐다. 회원 삭제 API가 없어 회원은 남는다. 최종 성공 실행의 회원은 52·53이며 생성 평점 36은 삭제했다.
- 앞선 중단 실행의 회원 50에 평점 35 한 건이 남았다. 당시 테스트 앱 자동 제거로 인증 정보가 삭제되어 후속 정리를 수행하지 못했다. 이후 실행에는 --no-uninstall과 실패 시 평점 정리를 적용했다.
- 이전 사용자 미추적 week4·week7 자료는 별도로 보존했다.
