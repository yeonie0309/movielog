# 8주차 프론트 실행 증빙

원본 「8주차 - JWT 토큰 기반 로그인 및 세션 복원」의 스터디 인증과 제출 양식에 아래 파일을 직접 첨부한다.

## 실제 서버·Android 화면

| 사진 | 내용 | 원본 첨부 항목 |
| --- | --- | --- |
| 01-login-failure.png | 실제 AUTH401_1 로그인 실패 | 로그인→GET me |
| 02-login-me.png | 실제 로그인 후 내 정보 | 로그인→GET me |
| 03-profile-409.png | 실제 MEMBER409_1, 입력 유지 | 닉네임 수정 |
| 04-profile-success.png | 실제 PATCH me 성공과 닉네임 반영 | 닉네임 수정·가입일 Challenge |
| 05-rating-ready.png | 정수 별점·코멘트와 활성 저장 버튼 | 평점 등록 |
| 06-rating-created.png | 등록 response의 Rating·TMDB 155 결합 | CRUD·영화 정보 결합 |
| 07-rating-updated.png | 실제 수정 후 5점·코멘트 결과 카드 | 평점 수정 |
| 08-rating-deleted.png | 삭제200 이후 현재 세션 빈 목록 | 평점 삭제 |
| 09-restart-restored.png | 별도 프로세스에서 토큰과 GET me 복원 | 재시작 복원 |
| 10-logout.png | 토큰·회원 삭제 후 로그인 화면 | 로그아웃 |
| 11-invalid-token.png | 실제 무효 토큰 AUTH401_3 후 로그인 | 무효 토큰 |
| 15-email-remembered.png | 이메일만 기억하고 비밀번호는 빈 입력 | 이메일 저장 Challenge |

01~06·08~18은 adb가 실제 Android 에뮬레이터 표면을 캡처한 원본 PNG다.
07은 동일 실행의 실제 녹화본에서 수정 결과 카드가 보이는 frame 248(63.28초)을 추출했다. 픽셀 내용은 보정하지 않았다.

## 실패 주입으로 검증한 실제 앱 화면

| 사진 | 조건 | 원본 첨부 항목 |
| --- | --- | --- |
| 12-injected-restore-retry.png | 복원 GET me 503 주입, 토큰 유지 | 네트워크 재시도 |
| 13-injected-403-retained.png | 평점 수정403 주입, Dialog·Snackbar 안내, signedIn 유지 | 403 처리 |
| 14-injected-expiry-snackbar.png | 평점 수정 AUTH401_4 주입, 세션 정리·만료 Snackbar | 만료 처리 |
| 16-discard-confirmation.png | 프로필 변경 후 뒤로가기 | 변경 내용 이탈 Challenge |
| 17-injected-member-loading.png | 내 정보 응답 지연 | 내 정보 로딩 Challenge |
| 18-injected-member-retry.png | 내 정보503 주입, 재시도 버튼 | 내 정보 재시도 Challenge |

화면은 실제 배포 앱의 Widget/ViewModel을 사용한다. 주입된 API 실패와 합성 평점 9000을 실제 서버 장애·실제 저장 데이터로 기재하지 않는다. 실제 다른 회원의 평점 수정403은 result-live.json의 별도 요청에서도 확인했다.

## CLI·요청 기록 사진

- 19-flutter-checks.jpg — 실제 analyze·94개 테스트·Android 4단계 로그를 읽는 뷰어 화면.
- 20-safe-network.jpg — 실제 v7 요청17건과 등록 body/result를 읽는 뷰어 화면.
- PR 화면은 생성 후 별도 첨부한다.

## 영상

- 01-login-profile-crud.mp4 — 실제 v7 로그인·내 정보·닉네임 중복/수정·평점 등록/수정/삭제.
- 02-restart-logout-invalid.mp4 — 설치 데이터를 보존한 별도 프로세스에서 복원·로그아웃·보호 redirect·이메일 저장·무효 토큰.

JWT·비밀번호를 화면이나 영상에 출력하지 않는다. 녹화에 표시되는 비밀번호 필드는 가려져 있다.

## 실행 원본

- android-live.txt, result-live.json — 실제 회원52·53, TMDB movieId155, 최종 ratingId36. 평점36 삭제 확인.
- android-restore.txt, result-restore.json — 새 프로세스 GET me 200, 로그아웃 시 secure storage null, 보호 redirect, 무효401.
- android-errors.txt, result-errors.json — 실패 주입 시나리오.
- android-invalid.txt, result-invalid.json — 최종 코드에서 실제 AUTH401_3과 Snackbar·토큰 삭제 추가 확인.
- flutter-test.txt — 전체 회귀 테스트.
- flutter-analyze.txt — 정적 분석. 기존 week0 avoid_print 정보2건.
- interrupted-test-data.json — 중단 실행의 남은 데이터 내역.

요청 기록은 password·accessToken을 제외하고 Authorization 값 대신 부착 여부를 기록한다.
실습 서버에 생성된 테스트 회원은 총14명이며 회원 삭제 API가 없다. 중단 실행의 회원50·평점35 한 건은 인증 정보가 테스트 앱 자동 제거로 삭제되어 남았다. 최종 성공 실행의 평점36은 삭제했다.

## 체크 기준

Guided/Required의 기술 구현 및 Android 자동 실행은 확인했다. 마지막 수동 검증 체크는 본인이 제출 가이드의 확인 순서를 실행한 뒤 선택한다. 스터디 모임 진행·이해 여부·UMC 제출도 본인이 확인한다.

전체 작성 문구와 원본 순서는 저장소 루트의 WEEK8_FRONTEND_SUBMISSION_GUIDE.md를 따른다.
