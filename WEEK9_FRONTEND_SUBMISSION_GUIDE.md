# 9주차 프론트엔드 제출 가이드

원본: 「9주차 - 즐겨찾기 연동과 검색, 페이지네이션」

PR: https://github.com/yeonie0309/movielog/pull/20

브랜치: codex/week-9-frontend → feature/week-8-backend

검증: Flutter 109개(신규15), Android 통합 실행2개, 실제 요청44건 통과. analyze 오류·경고0, 기존 week0 info2건. Android 기본 main.dart 실행도 확인했다.

원본 Notion은 수정하지 않았고 UMC에 제출하지 않았다. 아래 문구는 실제 작업 기록 초안이며, 본인의 이해 여부·스터디 참석·사람이 직접 수행하는 수동 검증은 직접 확인한다.

## 1. 스터디 인증 — 원본 순서대로

### 새 문법 한 문장 설명

- **Map:** key로 값을 찾는 자료 구조이며, movieId별 TMDB 영화 정보 캐시에 사용해 즐겨찾기 정보와 영화 정보를 결합한다.
- **Future.wait:** 여러 Future의 완료를 기다려 입력 순서대로 결과를 모으는 기능이며, bounded worker들을 함께 기다리는 데 사용한다.
- **record:** 여러 값을 별도 클래스 없이 묶는 값 타입이며, `(page: 1, query: '배트맨', genre: null)`처럼 이름 있는 필드를 표현할 수 있다.
- **interface:** 구현 클래스가 제공할 메서드의 계약을 선언하는 기능이며, MovieSearchService로 검색 서비스의 메서드 규칙을 분리했다.
- **mixin:** 여러 클래스에 공통 동작을 재사용하는 기능이며, SafeNotify로 dispose 후 상태 알림을 방지한다.
- **ValueKey:** 값으로 위젯의 동일성을 구분하는 키이며, 영화 ID·세션 값이 바뀔 때 이전 사용자의 상태를 재사용하지 않게 한다.
- **요청 generation:** 현재 요청 조건의 버전 번호이며, 검색어·장르가 변경되면 번호를 올려 이전 응답의 성공·오류·finally 처리를 무시한다.

정의를 읽고 본인이 설명할 수 있는지 확인한다. 자료만 붙인 상태를 설명 완료로 표시하지 않는다.

### 증빙 순서

1. 상세 북마크 등록·해제: `01-favorite-roundtrip.mp4`, `01-favorite-before.png`, `02-favorite-added.png`.
2. 마이페이지 → 내 즐겨찾기: `03-my-favorites.png`.
3. 상세 해제 → 뒤로가기 갱신: `01-favorite-roundtrip.mp4`, `04-return-refresh-empty.png`.
4. 더 보기·같은 page 재시도: `02-pagination-search.mp4`, `06-next-page-error-injected.png`, `07-next-page-recovered.png`.
5. 검색 아이콘 → 검색 → 상세: `02-pagination-search.mp4`, `08-search-success.png`, `24-search-result-detail.png`.
6. 계정 전환 후 이전 목록 비노출: `04-account-isolation.mp4`, `18-account-b-empty.png`.
7. 실제 요청 로그: `27-checks-rendered.jpg`, `28-network-rendered.jpg`, `29-safety-rendered.jpg`와 원본 TXT/JSON. 이 세 이미지는 실제 실행 출력의 **원문 렌더링**이며 터미널·브라우저 사진이 아니다. Authorization 값·비밀번호·토큰은 출력하지 않았다.

사진·영상 파일은 `evidence/week9-frontend/`에 있다. 별도의 모임 참석 사진을 요구하면 실제 사진을 추가한다. Android 자동 조작 영상이 스터디 참석 사진을 대신하지 않는다.

## 2. Essential·Guided Practice

기존 안내와 예제는 지우지 않는다. Guided A에는 상세 북마크 영상, Guided B에는 내 즐겨찾기 왕복 영상과 부분 실패 사진을 첨부한다.

복사 문구:

> MovieLog는 v8 API로 연결하고 TMDB와 MovieLog의 HTTP Client 및 인증 정보를 분리했다. 즐겨찾기 경로에는 favoriteId가 아니라 TMDB movieId를 사용한다. 즐겨찾기 해제는 HTTP 200과 result=null을 확인한다.
>
> 북마크는 서버 성공을 확인한 뒤 변경하고, 요청 중에는 북마크 영역만 로딩한다. 409·404 충돌은 현재 여부 GET으로 재확인하며, timeout이 발생한 POST를 자동 반복하지 않는다.
>
> 내 즐겨찾기는 JWT로 조회하고 movieId로 TMDB 정보를 보충한다. 보충 요청을 최대 5개로 제한하고 한 영화 조회 실패는 해당 카드의 재시도로 처리한다. 상세에서 해제하고 돌아오면 목록을 재조회한다.

## 3. Required Mission

### A. 내 즐겨찾기

> 마이페이지의 평점 행 아래에 내 즐겨찾기 진입을 추가했다. /my/favorites는 제목이 중앙에 있고 뒤로가기 버튼이 있으며 하단 NavigationBar는 표시하지 않는다. 목록·빈 목록·목록 조회 오류·TMDB 한 건 실패를 구분했다. 상세에서 해제하고 뒤로가면 목록을 갱신한다.

사진: 03, 04, 11, 12, 13. 영상: 01.

### B. 영화 목록 더 보기

> 홈의 인기 영화 5개 조회는 유지하고 영화 목록만 첫 page 조회와 더 보기로 변경했다. 추가 요청 중에는 기존 목록을 유지한다. 실패 시 nextPage를 증가시키지 않아 같은 page를 재시도한다. movieId로 중복을 제거하고 마지막 page 또는 500page에서 추가 조회를 중단한다. 장르 변경 시 목록·page·추가 로딩·오류를 초기화하고 이전 generation의 응답을 무시한다.

사진: 05, 06, 07. 영상: 02. 장르 응답 역전은 controlled Android 영상06·사진26과 Flutter 테스트로, 500 상한은 Flutter 테스트로 확인한다. 다음 page 오류 화면은 실패 주입이며 실제 TMDB 장애로 기록하지 않는다.

### C. 영화 검색

> 영화 목록 AppBar에 검색 아이콘과 /movies/search Route를 추가했다. 목록과 검색은 별도의 PagedMoviesViewModel을 사용한다. 기본은 검색 제출 시에만 요청하며 빈 문자열은 전송하지 않는다. 검색 결과·빈 결과·오류·추가 조회를 구분하고 카드에서 상세로 이동한다. 입력이 바뀌는 즉시 generation을 바꿔 debounce 대기 중에도 이전 응답이 반영되지 않게 했다.

사진: 08, 09, 14, 24. 영상: 02. 검색 오류는 실패 주입이다.

### D. 세션과 보안

> AuthViewModel의 sessionVersion과 /members/me에서 받은 email을 SessionGuard에 연결했다. 로그아웃·계정 전환 시 이전 사용자 목록과 캐시를 즉시 비우며, 같은 계정의 재로그인도 새 세션으로 구분한다. 늦은 응답과 dispose 이후 알림을 차단한다. AUTH401_2/3/4만 세션 만료로 처리하며, 네트워크 실패와 403에서는 로그인 상태를 유지한다. 토큰을 다른 호스트로 전달하지 않도록 두 Client의 요청을 제한했다.

사진: 18, 20. 영상: 04. 실제 무효 토큰 응답은 AUTH401_3이며 403·늦은 401은 기존 인증 회귀 테스트에서도 검증한다.

## 4. Challenge Mission

### A. 500ms debounce

> 자동 검색 스위치를 켜면 입력이 멈춘 뒤 500ms에 검색한다. 제출 동작도 유지하며 제출·입력 변경·dispose 시 대기 타이머를 취소한다. 기본 제출 검색과 선택 자동 검색을 모두 확인할 수 있다.

사진: 15. 영상: 02. 타이머 경계·제출 중복 방지·dispose는 widget 테스트로 확인한다.

### B. 무한 스크롤

> 무한 스크롤 스위치를 켜면 더 보기 버튼을 숨기고 extentAfter가 280px 이하일 때 다음 page를 요청한다. 중복 요청을 막고, 실패한 page는 자동 반복하지 않고 명시적으로 재시도한다. ScrollController의 리스너와 객체를 dispose에서 정리한다.

사진: 19. 영상: 02.

### C. 평점·즐겨찾기 통합 저장

> 평점 등록 Dialog의 코멘트 아래에 즐겨찾기에도 추가 체크박스를 제공한다. 기본은 숨김이며 미즐겨찾기 영화의 신규 등록에서만 표시한다. 정수 score와 boolean addToFavorites를 POST /v8/movie-records로 전송하고 이미 즐겨찾기한 영화는 기존 POST ratings로 처리한다. 평점 수정 PATCH는 유지했다.
>
> 저장 전 별점 선택이 필요하고 저장 중에는 중복 제출과 닫힘을 막는다. 입력값 오류·네트워크 실패는 입력을 유지한다. RATING409_1·FAVORITE409_1·MEMBER404_1은 Dialog를 닫고 안내하며 성공 후 북마크를 재조회한다. 서버 트랜잭션의 성공 응답을 사용하고 클라이언트에서 평점과 즐겨찾기를 별도 POST로 흉내 내지 않는다.

사진: 16(별점·코멘트·체크와 활성 저장 버튼), 17. 영상: 03. 오류별 Dialog 동작은 추가 widget 테스트로 확인한다.

## 5. 트러블슈팅 기록 — 복사 초안

**문제 상황:** 검색·장르를 변경한 뒤 이전 요청의 응답이나 오류가 도착하면 새 목록에 섞이거나 추가 조회 상태를 덮어쓸 위험이 있었다.

**어느 화면/어떤 API/어떤 조건:** 영화 목록의 Discover 추가 page와 검색 화면의 Search Movie 요청이 진행 중일 때 장르·검색어를 바꾸는 경우이다.

**최소 재현 단계:** 첫 목록 로드 → 다음 page를 지연 → 새 장르/검색어로 첫 page 요청 → 이전 요청의 성공 또는 오류를 늦게 완료한다. 자동 검색은 새 입력 후 500ms 타이머가 실행되기 전에도 이전 응답을 완료한다.

**기대 결과 / 실제 결과:** 새 조건의 결과만 반영되어야 한다. 요청 번호 검사가 부족하면 이전 영화나 오류가 섞이고 현재 로딩이 종료될 수 있다. 해당 경계 조건을 재현하는 테스트를 추가했다.

**확인한 로그:** Flutter의 Completer 기반 응답 역전 테스트와 Android 실행 기록을 사용했다. 실제 서버 지연이라고 단정하지 않고 제어된 재현 조건으로 기록했다.

**원인 / 수정한 파일·코드:** PagedMoviesViewModel에서 입력·조건 변경 즉시 generation을 증가시키고 목록·page·하단 로딩·오류를 초기화했다. 요청의 성공·catch·finally에서 현재 generation과 dispose 상태를 함께 검사했다. 검색 화면은 제출·dispose 시 debounce 타이머를 취소한다.

**동일 조건 재검증:** 이전 요청의 성공·오류가 현재 화면을 변경하지 않고 실패한 다음 page를 그대로 재시도하는 테스트가 통과했다. 빈 검색어는 요청하지 않으며 500page 다음 요청도 차단한다.

**확인하지 못한 환경/서버 계약:** iOS 실기기 실행과 장시간 운영 부하 테스트는 수행하지 않았다. Android의 일부 오류 화면은 명시적인 실패 주입으로 검증했다. 자동 검증과 사람이 직접 수행하는 수동 확인은 구분한다.

추가 실제 실행 이슈: ALB 등의 Infra 문제가 아니라 Android 테스트 입력 포커스와 TMDB의 일시적인 한 건 조회 연결 실패가 있었다. 중단 실행은 성공으로 제출하지 않고 별도 기록했다. 입력 조작을 포커스·controller 값 확인으로 보완하고, 영화 한 건 실패는 카드별 재시도로 복구했다.

## 6. 최종 체크리스트

기술 항목은 아래 결과 파일과 사진을 확인한 뒤 체크한다. 수동 검증 항목은 본인이 아래 순서를 직접 실행한 후 체크한다.

1. 상세 북마크 등록·해제, 실패 시 이전 아이콘과 상태 재조회 확인.
2. 마이 → 내 즐겨찾기 → 상세 해제 → 뒤로가기 갱신. 내 즐겨찾기·검색에 하단 탭이 없는지 확인.
3. 홈은 인기 영화 5개 유지. 영화 목록은 더 보기로 30개를 넘겨 표시.
4. 첫 로딩·추가 로딩·빈 목록·오류·끝 상태, 실패 page 재시도 확인.
5. 검색·장르 변경, 화면 이탈, 로그아웃·계정 전환의 응답 무시를 테스트 기록과 대조.
6. TMDB 한 건 실패에서도 다른 카드가 유지되고 그 카드만 재시도되는지 확인.
7. 캡처·영상·로그에 토큰이나 비밀번호가 보이지 않는지 확인.
8. analyze·전체 테스트·Android 실행 기록 첨부. 사람의 Required 수동 검증은 수행 후 완료로 표시.

## 7. 제출 양식 — 원본 필드 유지

PR 링크: https://github.com/yeonie0309/movielog/pull/20

PR 생성 증빙: 30-pr-created.jpg

영화 상세 즐겨찾기 등록·해제 영상: 01-favorite-roundtrip.mp4

마이페이지 → 내 즐겨찾기 → 상세 해제 → 뒤로가기 갱신 영상: 01-favorite-roundtrip.mp4

내 즐겨찾기 빈 목록·조회 오류·영화 정보 일부 실패 화면: 04-return-refresh-empty.png / 11-favorites-error-injected.png / 12-favorites-partial-injected.png / 13-favorites-card-recovered-fixture.png. 오류·부분 실패 사진은 controlled fixture이다.

영화 목록 더 보기와 다음 page 조회 실패 후 재시도 영상: 02-pagination-search.mp4. 다음 page의 실패만 주입하고 성공 재시도는 실제 TMDB를 사용했다.

영화 검색 결과·결과 없음·오류 화면: 08-search-success.png / 09-search-empty.png / 14-search-error-injected.png. 오류만 주입했다.

장르·검색어 변경 시 이전 응답이 섞이지 않는 확인: 25-search-generation-injected.png / 26-genre-generation-injected.png / 06-generation-isolation.mp4와 Flutter Completer 테스트·500ms debounce widget 테스트. 이 응답 역전은 controlled fixture이며 실제 서버 지연으로 기록하지 않는다. 사람의 직접 확인은 별도로 수행한다.

로그아웃·계정 전환 후 이전 계정 즐겨찾기 비노출 확인: 04-account-isolation.mp4 / 18-account-b-empty.png.

401/409 처리(세션 만료, FAVORITE409_1, FAVORITE404_1): 20-invalid-token-cleared-actual.png는 실제 AUTH401_3. 21/22 사진과 05-controlled-conflicts.mp4는 409/404 주입 시 GET 재조회 동작. 23은 timeout 주입 시 이전 아이콘 유지와 쓰기 자동 반복 금지.

토큰/비밀번호 비노출 확인: .env 미추적·변경 텍스트 비밀값 검사·Client 호스트 제한 테스트·마스킹 요청 로그. 비밀번호와 Authorization 값은 제출하지 않는다.

선택한 Challenge Mission과 증거: A 500ms 자동 검색(15, 영상02), B 무한 스크롤(19, 영상02), C 통합 저장(16/17, 영상03).

트러블슈팅: 위 트러블슈팅 기록 참조.

## 8. 직접 해야 하는 마지막 작업

- 앱에서 본인이 사용할 v8 테스트 계정으로 가입·로그인한다. 자동 테스트 계정의 비밀번호는 보관·공유하지 않는다.
- 위 수동 확인 순서를 직접 실행하고 본인의 설명·이해·스터디 인증을 확인한다.
- 원본 Notion의 정확한 필드에 문구와 실제 사진·영상·로그 사진·PR 링크를 첨부한다. 파일명 텍스트만 붙인 상태를 증빙 첨부 완료로 표시하지 않는다.
- UMC 제출은 본인이 직접 진행한다. 블로그·CodeRabbit 피드백·지식in 활동은 실제 진행한 경우만 완료로 표시한다.

참고: [MovieLog v8 Swagger](https://workbook.devnoco.com/docs/v8), [TMDB Search](https://developer.themoviedb.org/reference/search-movie), [TMDB Discover](https://developer.themoviedb.org/reference/discover-movie).
