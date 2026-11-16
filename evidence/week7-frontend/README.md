# 7주차 프론트 증빙

PNG/MP4는 Android 통합 테스트 실행 화면이며, 18~27·30~32 JPG는 Chrome에서 앱을 직접 조작한 화면입니다. UI를 합성하지 않았습니다.
단, **실제 서버 연결**과 **테스트용 실패 주입**은 아래처럼 구분해야 합니다.

PR: https://github.com/yeonie0309/movielog/pull/15

## 보완 증빙 — 원본 Notion의 스터디 인증에 첨부

**등록 Dialog의 활성화 증빙은 19와 20을 나란히 첨부합니다.** 기존 04 한 장은 선택 전 상태만 증명합니다. 07은 수정 화면이므로 등록 활성화 증빙으로 대체하지 않습니다.

| 파일 | 직접 확인한 결과 |
| --- | --- |
| 18-manual-signup-complete.jpg | 사용자가 가입한 후 영화 목록으로 이동한 상태 |
| 19-manual-rating-unselected.jpg | 등록 Dialog: 별점 0, 코멘트 TextField, 저장 비활성 |
| 20-manual-rating-selected-enabled.jpg | 등록 Dialog: 별점 4, 코멘트 입력, 보라색 저장 버튼 활성 |
| 21-manual-rating-created.jpg | 직접 저장 후 성공 Snackbar |
| 22-manual-created-get-list.jpg | 학습 회원 19, TMDB 155, 4점·입력 코멘트 재조회 |
| 23-manual-edit-prefilled.jpg | 수정 Dialog: 기존 4점·코멘트 초기값 |
| 24-manual-updated-get-list.jpg | 직접 5점·코멘트 수정 후 목록 재조회 |
| 25-manual-delete-confirm.jpg | 삭제 확인 Dialog |
| 26-manual-delete-cancelled.jpg | 취소 후 1건 유지 |
| 27-manual-delete-empty.jpg | 삭제 후 빈 목록·성공 안내 |
| 28-flutter-analyze-actual-output.jpg | 새로 실행한 실제 프로세스 stdout/stderr와 exit 0. 터미널 앱 캡처가 아닌 로그 뷰어 캡처 |
| 29-github-pr-15.jpg | 실제 GitHub PR #15 페이지 캡처 시점의 제목·브랜치·검증 설명 |
| 30-manual-duplicate-unavailable.jpg | 본 작업이 만든 기존 계정의 닉네임·이메일 중복 안내 |
| 31-manual-duplicate-available.jpg | 새 닉네임·이메일의 사용 가능 안내 |
| 32-manual-checks-invalidated.jpg | 두 입력값 변경 후 체크 아이콘·사용 가능 안내 제거 |

수동 조작은 실제 공개 v6와 TMDB에 연결한 Flutter 웹 앱에서 수행했습니다. 회원 19의 테스트 평점은 삭제 후 빈 목록을 확인했습니다. 가입 비밀번호 입력·가입 완료는 사용자가 수행했습니다. 18은 이후 화면만 캡처했습니다.

수동 확인 범위와 자동 테스트 범위를 혼동하지 않습니다. 서버400의 비밀번호 필드 오류, 최종 가입409, 저장 중 이탈/연타 방지, 쓰기 실패/GET 실패 분리·재시도·부분 실패는 기존 자동 테스트 증빙이며 **이번 직접 조작에서는 재검증하지 않았습니다.** Guided/Required 수동 검증 전체 완료 항목은 아직 일괄 체크하지 않습니다.

- [실제 CRUD 영상 직접 첨부](https://github.com/user-attachments/assets/13f97958-1cab-4904-bade-35d7009c203a)
- [실패 주입 복구 영상 직접 첨부](https://github.com/user-attachments/assets/a3207aaa-1185-4b72-a10b-6dc78345cde4)

## 실제 공개 v6 + TMDB

| 파일 | 내용 |
| --- | --- |
| 01-live-input-invalidated.png | 중복 확인 후 입력 변경 무효화 |
| 02-live-final-signup-409.png | 확인 통과 후 최종 가입 중복 |
| 03-live-signup-success.png | 가입 성공 후 영화 목록 이동 |
| 04-live-rating-unselected.png | 코멘트 입력창·별점 선택 전 비활성 버튼 |
| 05-live-rating-created-snackbar.png | 상세 화면의 등록 성공 안내 |
| 06-live-rating-list.png | 생성 회원 ID로 서버 평점 조회, TMDB 정보 결합 |
| 07-live-edit-prefilled.png | 기존 별점·코멘트 초기값 |
| 08-live-updated-list.png | PATCH 후 GET 수정 반영 |
| 09-live-delete-confirm.png | 삭제 확인 Dialog |
| 10-live-delete-cancelled.png | 취소 후 평점 보존, DELETE 0회 |
| 11-live-delete-empty.png | 204 삭제 및 GET 빈 목록 |
| 01-live-crud.mp4 | 등록→조회→수정→조회→취소→삭제→빈 목록 영상 |
| live-api-results.json | 비밀번호·헤더가 제외된 실제 요청/응답, 회원/영화/평점 ID |

## 실패 주입 — 실제 앱의 복구 동작

| 파일 | 내용 |
| --- | --- |
| 12-injected-write-failure-input-retained.png | 쓰기 실패 후 입력 유지 |
| 13-injected-write-success-get-error.png | 쓰기는 성공, GET만 실패 |
| 14-injected-get-only-retry.png | 쓰기 반복 없이 GET만 재시도 |
| 15-injected-multiple-selection.png | 편집·다중 선택 |
| 16-injected-bulk-loading-overlay.png | Dialog는 닫고 검은 오버레이·흰 인디케이터 |
| 17-injected-partial-delete.png | 성공한 항목 제거, 실패한 항목 선택 유지 |
| 02-injected-recovery.mp4 | 위 복구 흐름 영상 |

## 검증 로그

- flutter-analyze.txt: 정적 분석 원본 결과
- flutter-test.txt: 단위/위젯 회귀 테스트
- flutter-integration-test.txt: Android 실제/주입 통합 실행
- security-check.txt: 실제 로컬 비밀값과 비교한 비노출 검사

네트워크 오류와 부분 실패는 재현성을 위해 Service를 주입했습니다. 실제 서버 장애가 아닙니다.
테스트 계정은 자동 생성한 가상 이메일을 사용하며 실제 개인정보나 타인 데이터가 아닙니다.
실제 회원 정보와 최종 결과는 live-api-results.json을 기준으로 확인합니다.
요청 body의 password, Authorization 헤더는 수집하지 않습니다. 영상은 가입 후부터 녹화합니다.
