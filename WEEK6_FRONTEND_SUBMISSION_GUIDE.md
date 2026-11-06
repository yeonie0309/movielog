# 6주차 프론트엔드 구현·검증 정리

## 기준과 범위

- 원본: MakeUs → PE (Mobile) A팀 → 레아의 워크북 → **6주차 - 중복 확인 연동과 평점 조회하기**.
- 원본 페이지: https://app.notion.com/p/makeus-challenge/6-80ab57f4596b8285aa93011bc5e03468
- 시작 시 로컬·원격 `main`은 `2445f60` 초기 설정 커밋. 5주차까지 코드는 `feature/week-5-backend`의 `ffd248a`에 존재했다.
- 브랜치: `feature/week-6-frontend`. 선행 주차 전체를 다시 PR에 포함하지 않도록 기준 브랜치는 `feature/week-5-backend`.
- PR: [#13 — feat: 6주차 중복 확인 및 평점 조회 구현](https://github.com/yeonie0309/movielog/pull/13). 화면 14장은 두 열 표로 첨부 완료. 병합하지 않음.
- 기존 0~5주차 코드 및 백엔드 보존. 기존 미추적 week4 캡처 파일은 이번 커밋에 포함하지 않는다.
- 이번 프론트는 공식 **v5** 공개 API의 GET 3개를 사용한다. 로컬 5주차 백엔드와 혼동하지 않는다.
- 회원가입 POST, 평점 생성·수정·삭제, JWT 로그인은 범위 밖이다. 가입하기는 기존 Form 검증 후 홈 이동만 한다.

## 구현 내용

1. `MovieLogButton`: 공용 `lib/widgets` 위치, 기본/회색 비활성/회색 통신 중 상태, 로딩 시 라벨 대신 중앙 흰색 인디케이터. 높이 44, 너비 null/전체/고정 지원.
2. 닉네임·이메일 입력창과 버튼을 Row의 형제로 배치하고 간격 8px 적용. 입력창은 Expanded, 버튼은 내용 너비.
3. `CheckResult` 및 `MemberCheckService`: trim·URL 인코딩 후 직접 `{available: bool}` 파싱.
4. `SignUpViewModel`: 필드별 5상태, 마지막 중복 값 기억, 편집 시 초기화, 동일 중복 재입력 즉시 복원, 늦은 응답·연타·dispose 보호.
5. 서버 오류는 `forceErrorText`에 연결해 실제 FormField의 invalid 상태로 반영. 단순 안내 Text만 바꾸지 않는다. 통신 실패와 정상 중복 문구를 구분한다.
6. 기존 `MemberRating` 모델 재사용: num→int, null comment, ISO 날짜 처리. `RatingApiService`는 memberId 1의 배열 응답을 파싱한다.
7. `MyRatingsViewModel`: Loading/Empty/Error/Success, 재시도, rating.movieId로 TMDB 상세 조회·캐시. 404만 negative-cache, 일시 실패는 다음 로드에서 재시도. 영화 조회 실패에도 평점 보존.
8. 마이페이지 `/my/ratings` 자식 화면: 중앙 제목·뒤로가기, 하단 탭 숨김, 점수·nullable 후기·등록일·TMDB 제목/포스터. 로그인한 자신이 아닌 공개 회원 1임을 명시.
9. 워크북 두 서비스는 `createWorkbookClient()`의 Dio 하나 공유. TMDB 클라이언트와 Authorization 분리. 기존 로컬 `createMovieLogClient()`는 5주차 실습용으로 보존.

## 검증 결과

- `flutter analyze --no-fatal-infos`: exit 0. 기존 0주차 `avoid_print` info 2건만 남음. 경고·오류 없음. **info가 전혀 없는 결과라고 표현하지 않는다.**
- `flutter test --reporter expanded`: **49개 통과**. 기존 주차 테스트 포함.
- Android Pixel 7 통합 테스트: 실제 공개 v5/TMDB 조회 및 테스트 서비스 상태 재현 **2개 통과**.
- `flutter run -d emulator-5554 --debug`: 실제 `lib/main.dart` 빌드·설치·실행 성공.
- 320px / 1024px 회원가입 레이아웃, Form 서버 오류, 응답 역전, dispose, 캐시·404·일시 장애 재시도 검증.
- `git diff --check`: 통과.
- `.env` ignored/untracked, 실제 TMDB 토큰이 현재 프론트 코드·테스트·도구·6주차 증빙 파일에 없는지 검사. 모든 과거 커밋을 검사했다는 뜻은 아님.
- 에뮬레이터 화면 조작은 재현 가능한 통합 테스트로 자동화했고, 생성된 화면은 별도로 육안 확인했다. 사람이 직접 실행한 수동 검사라고 가장하지 않는다.

공개 서버는 공유 데이터이므로 이후 응답 건수는 바뀔 수 있다. 2026-11-03 확인 시 회원 1 평점은 3건, movieId 13/680/550의 TMDB 제목·포스터를 연결했다. `영화광`, `movie@umc.com`은 중복 응답, 임시 예시 값은 사용 가능 응답이었다. 실제 이메일이나 비밀번호를 전송하지 않았다.

## 증빙 위치와 구분

`evidence/week6-frontend/`의 `live`는 실제 API 결과, `test`는 화면 상단에 테스트 서비스임을 표시한 재현 결과다. Empty·503을 만들기 위해 공유 서버 데이터를 변경하지 않았다. 이번 워크북은 화면 **또는** 영상을 허용하므로 필요한 상황을 사진으로 모두 남겼다.

| 파일 | 증빙 내용 | 구분 |
| --- | --- | --- |
| 01-live-before.png | 중복 확인 전 | 실제 앱 |
| 02-live-duplicated.png | 닉네임·이메일 중복, 빨간 Form, 비활성 버튼 | 실제 v5 |
| 03-live-invalidated.png | 입력 수정 후 이전 오류 해제·버튼 활성 | 실제 v5 결과 이후 편집 |
| 04-live-reentered-duplicate.png | 동일 중복 값 재입력 즉시 오류 복원, 추가 요청 없음 | 실제 v5 결과 기반 |
| 05-live-available.png | 두 필드 사용 가능·체크 표시 | 실제 v5 |
| 06-live-my-page.png | 마이페이지의 평점 진입 행 | 실제 앱 |
| 07-live-ratings-success.png | 회원 1 평점 3건·TMDB 제목·포스터 | 실제 v5 + TMDB |
| 08-test-check-loading.png | 회색 비활성 버튼·중앙 로딩 | 테스트 지연 응답 |
| 09-test-check-network-error.png | 통신 실패 전용 문구·재시도 가능 | 테스트 503 |
| 10-test-ratings-loading.png | 평점 Loading | 테스트 지연 응답 |
| 11-test-ratings-empty.png | 평점 Empty, 회원 1 고정 | 테스트 빈 배열 |
| 12-test-ratings-error.png | 평점 Error | 테스트 503 |
| 13-test-ratings-retry-success.png | 다시 시도 후 Success | 테스트 서비스 |
| 14-test-button-widths.png | null / double.infinity / 96 및 로딩 비교 | 테스트 배치 화면 |

분석·단위 테스트·통합 테스트·보안 점검 로그도 같은 폴더에 저장한다.

## Guided / Required / Challenge 대조

| 영역 | 확인 결과 |
| --- | --- |
| Guided A 직접 완성 4개 | Form 오류 연결, 입력 초기화, 이메일 확장, 네트워크 오류 구분 완료 |
| Guided B 직접 완성 4개 | Provider 4상태, 자식 화면/뒤로가기/탭 숨김, TMDB 연결, 오류 문구 완료 |
| Required 10개 | 공용 버튼/3너비/3상태/오류/무효화/진입/회원1/4상태/TMDB/공용 위치 완료 |
| Challenge 3조건 | 중복 직후 비활성, 다른 값 편집 시 해제, 동일 중복 재입력 즉시 복원 완료 |
| 최종 체크리스트 11개 | 해당 구현·테스트·증빙과 대조 완료 |

## 재실행

프로젝트 루트 `.env`의 `TMDB_ACCESS_TOKEN`은 로컬에서만 관리한다. 토큰은 채팅·Notion·PR에 복사하지 않는다.

```sh
flutter run -d emulator-5554
node tool/verify_week6.cjs
node tool/capture_week6.cjs
```

기존 로컬 5주차 회원 조회 실습(`/member-ratings`)도 보존되어 있으며 별도 로컬 서버가 필요하다. 6주차 필수 화면은 마이페이지의 **내가 등록한 평점**이다.

## 사용자에게 남은 일

1. 구현 결과와 별도 `WEEK6_FRONTEND_NOTION_PLAN.md`의 원본 Notion 작성 계획 검토·승인.
2. 승인 후 에이전트가 해당 원본 6주차 프론트 페이지에만 증빙·내용·체크를 반영한다.
3. 사용자가 최종 내용을 읽고 UMC 제출 시스템에 원본 페이지 URL을 제출한다. 에이전트는 제출 버튼을 누르지 않는다.

현재 원본 Notion은 수정하지 않은 상태이며, 학습 목표의 개인 이해 여부·CodeRabbit 설치/권한·블로그 선택 활동은 자동 완료 처리하지 않는다.

## 변경 파일

- 신규 네트워크/모델/서비스: `lib/core/network/workbook_client.dart`, `lib/data/models/check_result.dart`, `lib/data/services/member_check_service.dart`, `lib/data/services/rating_api_service.dart`.
- 기존 TMDB 확장: `lib/data/models/tmdb_movie_dto.dart`, `lib/data/services/tmdb_movie_service.dart`.
- 신규 ViewModel: `lib/view_models/sign_up_view_model.dart`, `lib/view_models/my_ratings_view_model.dart`.
- 신규 UI: `lib/widgets/movielog_button.dart`, `lib/screens/my_ratings_screen.dart`.
- 기존 UI/주입/라우팅 연결: `lib/movie_log_app.dart`, `lib/router/app_router.dart`, `lib/screens/sign_up_screen.dart`, `lib/screens/my_page_screen.dart`, `lib/widgets/sign_up/sign_up_text_field.dart`.
- 테스트: `test/week6_frontend_test.dart` 신규. `test/widget_test.dart`, `test/week5_member_api_test.dart`는 새 공용 버튼/서비스 주입에 맞게 기존 검증 보존.
- 통합 테스트: `integration_test/week6_evidence_test.dart` 신규. 기존 `integration_test/week5_backend_live_test.dart`는 명시적 로컬 API 어댑터를 주입하여 과거 실습 대상을 보존(이번 작업에서 5주차 로컬 서버 통합 테스트는 재실행하지 않음).
- 재현 도구: `tool/verify_week6.cjs`, `tool/capture_week6.cjs`.
- 문서/증빙: 이 문서, `WEEK6_FRONTEND_NOTION_PLAN.md`, `evidence/week6-frontend/`.
