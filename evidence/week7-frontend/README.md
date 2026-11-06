# 7주차 프론트 증빙

모든 PNG/MP4는 Android 에뮬레이터의 실제 실행 화면입니다. UI를 합성하지 않았습니다.
단, **실제 서버 연결**과 **테스트용 실패 주입**은 아래처럼 구분해야 합니다.

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
