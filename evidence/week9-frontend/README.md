# 9주차 프론트 실행 증빙

PR: https://github.com/yeonie0309/movielog/pull/20

30-pr-created.jpg는 실제 GitHub PR 생성 화면이며 네 사진이 width260의 2×2 표로 로드된 것을 확인했다.

원본 「9주차 - 즐겨찾기 연동과 검색, 페이지네이션」의 **스터디 인증·Guided/Required·Challenge·제출 양식**에 맞춰 준비했다. 원본 Notion과 UMC 제출은 수정하지 않았다.

## 실제 서버·Android 화면

| 파일 | 내용 | 원본 첨부 위치 |
| --- | --- | --- |
| 01-favorite-before.png | 실제 v8 여부 조회 후 미등록 북마크 | 상세 즐겨찾기 |
| 02-favorite-added.png | 실제 등록 후 북마크·Snackbar | 상세 즐겨찾기 |
| 03-my-favorites.png | JWT 목록과 TMDB 제목·포스터 결합, 중앙 제목·하단 탭 없음 | 내 즐겨찾기 |
| 04-return-refresh-empty.png | 상세 해제 후 뒤로가기·재조회한 실제 빈 목록 | 복귀 갱신·빈 목록 |
| 05-discover-first-page.png | TMDB Discover 첫 page | 더 보기 |
| 07-next-page-recovered.png | 같은 2page의 실제 성공 응답을 append | 실패 후 재시도 |
| 08-search-success.png | TMDB 배트맨 검색 결과 | 검색 결과 |
| 09-search-empty.png | 실제 TMDB 0건 응답 | 검색 없음 |
| 15-debounce-success.png | 자동 검색 스위치·500ms 검색 결과 | Challenge A |
| 16-integrated-save-ready.png | 별점4·코멘트·체크 선택·활성 저장 버튼 | Challenge C |
| 17-integrated-save-success.png | POST movie-records 201 이후 Dialog 닫힘·북마크 갱신 | Challenge C |
| 18-account-b-empty.png | 실제 다른 계정의 빈 목록 | 계정 전환 |
| 19-infinite-scroll.png | 실제 3page 요청까지 이어진 목록 | Challenge B |
| 20-invalid-token-cleared-actual.png | 실제 AUTH401_3 후 로그인 이동·토큰 삭제 | 401 처리 |
| 24-search-result-detail.png | 실제 검색 카드의 movie.id로 상세 이동 | 검색→상세 |

20은 화면 로그인 상태를 fixture로 준비한 뒤 실제 서버에 무효 토큰을 보내 받은 응답이다. 정상 로그인·계정 전환은 live 단계에서 실제 서버로 별도 확인했다.

## 제어된 실패·지연으로 검증한 실제 앱 화면

| 파일 | 주입 조건 | 확인한 동작 |
| --- | --- | --- |
| 06-next-page-error-injected.png | 다음 page 전송 실패 | 기존 목록 유지·같은 page 재시도 |
| 10-favorites-empty-fixture.png | 빈 목록 fixture | 빈 화면 안내 |
| 11-favorites-error-injected.png | 목록 조회 실패 | 전체 조회 오류·재시도 |
| 12-favorites-partial-injected.png | TMDB 영화 한 건 실패 | 다른 카드 유지·개별 재시도 |
| 13-favorites-card-recovered-fixture.png | 한 건 재시도 성공 | 해당 카드만 복구 |
| 14-search-error-injected.png | 검색 전송 실패 | 검색 오류·입력 유지·재시도 |
| 21-conflict409-reconciled-injected.png | FAVORITE409_1 | 쓰기 반복 없이 GET으로 등록 상태 맞춤 |
| 22-conflict404-reconciled-injected.png | FAVORITE404_1 | GET으로 미등록 상태 맞춤 |
| 23-timeout-icon-retained-injected.png | POST timeout | 이전 아이콘 유지·상태 조회로 복구 유도 |
| 25-search-generation-injected.png | 이전 검색 응답을 늦게 완료 | 최신 검색 카드 유지 |
| 26-genre-generation-injected.png | 이전 장르 응답을 늦게 완료 | 새 장르 카드 유지 |

이 사진은 실제 프로젝트 Widget/ViewModel을 Pixel 7 에뮬레이터에서 실행해 adb로 캡처했다. **주입한 실패·합성 영화 데이터를 실제 서버 장애·저장 데이터로 적지 않는다.**

## 영상

- `01-favorite-roundtrip.mp4`: 실제 등록 → 마이페이지 목록 → 상세 해제 → 뒤로가기 빈 목록.
- `02-pagination-search.mp4`: 실제 첫/다음 page, 실패 주입 후 같은 page 재시도, 무한 스크롤, 검색·상세·빈 결과·오류·debounce.
- `03-integrated-save.mp4`: 별점·코멘트·체크 → 실제 통합 저장201 → Dialog 닫힘·북마크 변경.
- `04-account-isolation.mp4`: 실제 로그아웃 → 다른 계정 로그인 → 이전 목록 비노출.
- `05-controlled-conflicts.mp4`: 제어된 409/404/timeout 처리. 실제 서버 충돌이 발생한 영상이 아니다.
- `06-generation-isolation.mp4`: 제어된 검색·장르 응답 역전과 최신 목록 유지.

## 검사·요청 원본

- `flutter-analyze.txt`: 정적 분석 원문. 기존 week0 avoid_print 정보2건.
- `flutter-test.txt`: 전체 Flutter 테스트109개(기존94 + 신규15).
- `android-live.txt`, `result-live.json`: 실제 v8/TMDB 연결과 일부 명시적 전송 실패 주입 단계.
- `android-states.txt`, `result-states.json`: 부분 실패·충돌·generation fixture와 실제 무효 토큰 요청.
- `v8-contract.json`: 공식 Swagger에서 발췌한 공개 계약. 서버 실행 결과와 구분한다.
- `verification-summary.json`: 증빙·비밀값·diff 검사 결과.
- `REQUIREMENTS.md`: 원본 요구사항과 구현/검증 연결.
- `changed-files.txt`: 이번 작업 파일 목록.
- `checks.html`, `network.html`, `safety.html`: 위 실제 JSON·명령 출력을 읽는 뷰어. 해당 뷰어의 사진은 네이티브 터미널·Postman 화면이라고 표기하지 않는다.
- `27-checks-rendered.jpg`, `28-network-rendered.jpg`, `29-safety-rendered.jpg`: 실제 TXT·JSON을 문서 이미지로 렌더링한 자료다. 이미지에 **원문 렌더링이며 UI 스크린샷이 아님**을 표시했다. 브라우저의 file URL과 터미널 앱 접근이 제한되어 UI 사진으로 대체했다고 주장하지 않는다. 앱 화면 PNG26장과 영상6개는 실제 Android 캡처다.

Authorization은 값 대신 부착 여부만 기록한다. TMDB의 기존 로그도 토큰은 마스킹한다. 비밀번호·accessToken을 출력하지 않는다. .env는 미추적이다.

## 테스트 데이터와 중단 실행

최종 성공 실행은 테스트 회원23·24를 사용했다. 모든 실행 시도를 합쳐 테스트 회원12명을 생성했으며 서버에 회원 삭제 API가 없어 회원 자체는 남는다. 비밀번호는 강한 임의값으로 메모리에서 생성하고 보관하지 않는다.

각 중단 실행의 `passed=false` 기록과 즐겨찾기·평점 정리 확인을 `interrupted-attempts/`에 별도 보관했다. 원인은 테스트 입력 포커스·닫힘 대기, TMDB의 일시적인 연결 실패 등이었다. 실패 실행을 최종 성공 결과로 제출하지 않는다.

최종 실제 실행의 즐겨찾기·평점은 모두 삭제하고 재조회해 빈 결과를 확인했다. 토큰도 로그아웃으로 삭제했다. 다른 회원의 데이터는 조회·변경하지 않았다.

## 직접 확인할 부분

기술 실행은 자동화된 Android 조작과 테스트로 확인했다. 본인의 v8 계정으로 Required 흐름을 직접 확인한 뒤 수동 검증 항목을 체크한다. 스터디 참석·개념 이해·원본 Notion 반영·UMC 제출은 본인이 진행한다. iOS 실기기와 장시간 부하 검증은 수행하지 않았다.

워크북 위에서부터 복사할 문구와 각 파일의 위치는 루트 `WEEK9_FRONTEND_SUBMISSION_GUIDE.md`를 따른다.
