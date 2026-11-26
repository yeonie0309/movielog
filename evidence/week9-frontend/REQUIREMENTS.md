# 9주차 프론트 요구사항과 검증 연결

원본: https://app.notion.com/p/makeus-challenge/9-05eb57f4596b8372af4a811084cdd7fa

2026-11-27 MakeUs → PE (Mobile) A팀 → 레아의 워크북에서 브라우저로 읽었다. 게스트 원본은 Notion connector에서 404였으므로 개인 복제 페이지를 대신 사용하지 않았다. 원본 페이지·체크박스·UMC 제출은 수정하지 않는다.

## 작업 기준

- 원격을 fetch한 뒤 main이 1주차 PR #2까지인 것을 확인했다.
- 시작 브랜치: codex/infra-week-1. 미추적 기존 증빙 세 곳을 보존했다.
- Mobile 최신 기반: feature/week-8-backend(c54c529), 작업: codex/week-9-frontend.
- Infra 브랜치의 작업은 이번 PR에 포함하지 않는다. 브랜치 전환 후 남은 infra/ 로컬 상태도 커밋하지 않는다.
- 이전 주차의 MovieListViewModel(30개 수집)·mock 연습 화면·기존 인증 테스트를 보존하고 실제 TMDB 목록 Route만 새 PagedMoviesViewModel로 연결한다.

## 원본의 필수·Guided 범위

| 요구사항 | 구현 | 검증 |
| --- | --- | --- |
| 기존 로그인·내 정보·평점·회원가입·중복 확인을 v8로 연결 | MovieLogApp의 실제 서비스 생성 시 version=v8; 이전 기본값은 legacy 테스트용 보존 | Android 실제 요청 로그 + 기존 회귀 테스트 |
| favorites POST201 / GET200 배열 / GET movieId 여부 / DELETE200 result=null | FavoriteApiService·FavoriteResponseDto | DTO/경로 단위 테스트 + Android 서버 요청 |
| favoriteId 아닌 movieId로 변경 | API 경로·상세 VM | favoriteId와 movieId가 다른 fixture + 실제 movieId550 |
| 최초 조회와 북마크만 로딩, 성공 Snackbar, 실패 이전 상태 | FavoriteDetailViewModel·FavoriteButton | Android 등록/해제 + conflict/timeout 테스트 |
| FAVORITE409_1·FAVORITE404_1이면 현재 여부 GET, 쓰기 자동 반복 금지 | toggle() 충돌 처리 | controlled conflict 테스트 |
| 내 즐겨찾기 route /my/favorites, 평점 행 아래 진입, 하단 탭 제외 | rootNavigatorKey 하위 route | Android 진입·뒤로가기·화면 assertion |
| 영화별 TMDB 결합, 최대 5개 동시 요청, 부분 실패와 카드별 재시도 | mapBounded·FavoritesViewModel | bounded worker 테스트 + controlled Android 화면 |
| 상세 해제 뒤 목록 재조회 | await context.push 이후 refresh | 실제 Android 왕복 영상 |
| Discover 첫 페이지만 조회, 30개 제한 제거, 더 보기 | PagedMoviesViewModel·MoviePageFooter | 20→40·중복 제거 테스트 + 실제 1/2page |
| 추가 조회 중 기존 목록 유지, 같은 page 재시도, 끝 상태·500 상한 | first/loadingMore/nextPageError/hasMore 분리 | 실패 page 재시도·500 cap 테스트 + Android 실패 주입 |
| 장르 변경 시 초기화·구 응답/오류/finally 무시 | generation | Completer 응답 역전 테스트 |
| 검색 idle/empty/error/success·별도 VM·빈 검색어 생략·검색 제출·더 보기 | MovieSearchScreen·정적 search Route 우선 | widget debounce/submit 테스트 + 실제 TMDB 검색 |
| 로그아웃·같은 계정 재로그인·다른 계정·dispose 늦은 응답 차단 | SessionGuard·AuthSessionBridge·SafeNotify·ValueKey | session bridge/late response 테스트 + Android A/B 분리 |
| AUTH401_2/3/4만 현재 세션 정리; 네트워크·403 유지 | 기존 AuthInterceptor/AuthViewModel 재사용 | 기존 week8 회귀 + v8 보호 경로 검사 |
| 토큰 client 분리·로그/캡처 비노출 | 정확한 HTTPS host + 보호 경로 allowlist·기존 TMDB 마스킹 | 요청 부착 boolean 기록·secret scan |

## 선택한 Challenge

- A: 기본 제출 검색은 유지. 스위치로 500ms 자동 검색 활성화. 편집 즉시 generation 변경, 제출·dispose 시 Timer 취소.
- B: 기본 더 보기는 유지. 스위치로 무한 스크롤 활성화 시 더 보기 숨김. extentAfter 280px 이하에서 추가 조회, 중복/실패 자동 반복 방지. ScrollController 해제.
- C: RatingDialog 체크박스는 기본 숨김, 신규 평점·미즐겨찾기 영화에만 표시. POST /v8/movie-records로 boolean 포함 통합 저장. 이미 즐겨찾기면 기존 POST ratings, 수정은 기존 PATCH 유지. 입력/네트워크 오류는 입력 유지, 지정 충돌 코드는 닫고 안내. 성공 후 북마크 재조회.

## 증빙 해석

- API 응답·이미지·영상은 실제 서버/controlled failure를 파일명과 README에 구분한다.
- 단위·위젯/Android 자동 조작을 사람의 수동 검증 또는 스터디 참석으로 표시하지 않는다.
- 완료 상태는 실제 실행 로그 기준으로 제출 가이드에 기록한다. 중단된 실행은 최종 성공과 분리한다.
- 제공 테스트 언급이 있지만 읽은 원본 제출 영역에는 별도 테스트 다운로드 링크가 없었다. 프로젝트의 기존 테스트와 요구사항에 대응하는 새 테스트를 실행한다. 참조 앱의 파일명과 프로젝트 구조 차이를 허용한다는 본문 지침을 따른다.
