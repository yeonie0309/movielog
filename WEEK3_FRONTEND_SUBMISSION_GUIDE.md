# 3주차 프론트엔드 제출 가이드

## 워크북에서 확인한 필수 범위

- 시작 화면에서 회원가입 화면으로 이동하고, 가입 완료 뒤 홈으로 이동한다.
- 회원가입 화면과 홈 화면에서는 뒤로가기로 이전 단계에 돌아가지 않도록 한다.
- `GoRouter`와 `GoRoute`로 홈·영화 목록·영화 상세·마이페이지 경로를 구성한다.
- `NavigationBar`로 홈·영화·마이페이지를 전환한다.
- 영화 카드는 `GestureDetector`로 탭을 처리한다.
- 영화 상세 화면은 Path Parameter로 영화 ID를 전달하고 뒤로가기를 지원한다.
- 공통 Mock 영화 데이터를 `ListView`와 `GridView`에 표시한다.
- 장르 Chip과 필터를 구현한다.
- `flutter_rating_bar`를 사용한 별점 입력을 Dialog에 배치한다.
- 평균 평점 4.5는 읽기 전용으로 표시한다.
- 즐겨찾기 상태를 아이콘에 반영하고 결과를 Snackbar로 알린다.
- 화면과 역할별 Widget을 4개 이상 분리한다.
- API·인증·Provider·MVVM은 연결하지 않고 평점과 즐겨찾기는 로컬 상태로만 관리한다.

## 추가 구현한 Challenge

- `StatefulShellRoute.indexedStack`으로 탭별 탐색 상태를 유지한다.
- 장르 선택을 `genres` Query Parameter로 URL에 반영한다.
- `DraggableScrollableSheet`와 `CheckboxListTile`로 복수 장르를 선택한다.
- 적용 버튼을 누르기 전까지 선택 결과가 목록에 반영되지 않게 했다.
- 선택 장르가 없으면 전체 영화를 표시한다.
- Dialog에서 별점을 초기화하거나 다시 선택할 수 있다.
- 좁은 화면은 2열, 중간 화면은 3열, 넓은 화면은 5열 Grid로 표시한다.

## 구현한 화면과 이동 흐름

```text
시작(/start)
  -> 회원가입(/register)
  -> 홈(/home)

NavigationBar
  홈(/home) <-> 영화(/movies?genres=드라마,SF) <-> 마이(/my)

영화 카드 탭
  -> 상세(/movies/:movieId)
  -> 뒤로가기
```

## 직접 확인하고 제출할 내용

원본 MakeUs 워크스페이스의 3주차 프론트엔드 페이지와 PR에 아래 내용을 첨부한다.

1. 시작 → 회원가입 → 유효한 입력 완료 → 홈 이동
2. 홈·영화·마이 NavigationBar 전환
3. 영화 카드 탭 → URL의 영화 ID에 맞는 상세 화면 → 뒤로가기
4. 장르 필터 BottomSheet 열기 → 복수 선택 → 적용 → 목록 변경
5. 상세 화면의 평균 평점 4.5 표시
6. 평점 Dialog 열기 → 별점 선택 → 저장 Snackbar → 다시 열어 초기화/재선택
7. 즐겨찾기 추가·해제 시 아이콘 변화와 Snackbar
8. 가능하면 에뮬레이터에서 위 흐름을 한 번에 담은 화면 녹화
9. PR 생성 후 PR 링크

평점과 즐겨찾기는 앱을 다시 시작하면 초기화되는 것이 정상이다. 이번 주차 범위에서는 서버 저장을 구현하지 않는다.

## 미션 내용 정리 예시

```text
이름 / 닉네임: 이가연 / 레아
GitHub 저장소: https://github.com/yeonie0309/movielog
Pull Request: PR 생성 후 입력

라우팅: GoRouter와 GoRoute로 /start, /register, /home, /movies, /movies/:movieId, /my 경로를 구성했다.
화면 전환: 시작 화면은 context.go('/register'), 가입 완료는 context.go('/home')를 사용해 이전 화면이 스택에 남지 않게 했다. 영화 상세는 context.push()로 열고 context.pop()으로 돌아온다.
하단 탐색: NavigationBar와 StatefulShellRoute.indexedStack으로 홈·영화·마이페이지를 전환하고 각 탭 상태를 유지했다.
영화 데이터: 공통 Mock 영화 6개를 모델과 데이터 파일로 분리해 홈, 목록, 상세 화면에서 함께 사용했다.
목록 UI: 홈은 가로 ListView, 영화 목록은 화면 너비에 따라 2·3·5열로 바뀌는 GridView를 사용했다.
사용자 인터랙션: 영화 카드를 GestureDetector로 감싸 상세 화면으로 이동하게 했다.
Path Parameter: /movies/:movieId의 movieId로 공통 Mock 데이터에서 영화를 찾아 상세 정보를 표시했다.
Query Parameter: 선택한 복수 장르를 /movies?genres=장르1,장르2 형태로 반영했다.
장르 필터: Draggable BottomSheet 안에 CheckboxListTile 목록과 고정 적용 버튼을 두었고, 적용을 눌러야 결과가 목록에 반영된다. 선택값이 없으면 전체 영화를 표시한다.
평점: 상세 화면에 평균 평점을 읽기 전용으로 표시하고, Dialog의 MovieRatingInput에서 0.5점 단위로 내 평점을 선택·초기화·재선택할 수 있게 했다.
즐겨찾기: 상세 화면의 아이콘으로 로컬 즐겨찾기 상태를 표시하고 추가·삭제 결과를 Snackbar로 알렸다.
상태 범위: 워크북 범위에 맞춰 API, 인증, Provider, MVVM은 연결하지 않았고 평점과 즐겨찾기는 상세 화면의 로컬 상태로 관리했다.

트러블슈팅: 장르 필터의 CheckboxListTile을 배경만 그리는 DecoratedBox 안에 배치했을 때, ListTile의 잉크 효과가 보이려면 Material 조상이 필요하다는 assertion을 Widget 테스트가 발견했다. BottomSheet 최상단을 Material로 변경하고 borderRadius와 clipBehavior를 함께 지정해 배경, 모서리, 체크 상호작용이 모두 정상 동작하도록 수정했다. 또한 상세 화면의 평점 버튼은 작은 테스트 화면에서 스크롤 영역 아래에 있어 직접 tap하면 빗나갈 수 있었기 때문에 ensureVisible로 실제 사용자 스크롤을 반영해 검증했다.

3주차 회고: 이번 미션을 통해 화면 이동은 단순히 새 화면을 띄우는 것이 아니라 이전 화면을 남길지에 따라 go, push, pop을 구분해야 한다는 점을 배웠다. Path Parameter로 상세 대상의 ID를 전달하고 Query Parameter로 필터 상태를 표현하면서 URL과 화면 상태의 관계도 확인했다. NavigationBar와 StatefulShellRoute를 사용해 탭별 흐름을 유지했고, Dialog·BottomSheet·Snackbar를 각각 입력, 선택, 결과 안내에 맞게 적용했다. 다음에는 서버와 상태 관리 계층을 연결해 로컬 상태를 앱 재실행 뒤에도 유지하고 싶다.
```

## 트러블슈팅 기록 예시

```text
문제가 발생한 기능: 장르 필터 BottomSheet의 CheckboxListTile 렌더링
예상한 결과: 체크 항목을 누르면 Material 잉크 효과와 선택 상태가 정상 표시되어야 한다.
실제 결과: Widget 테스트에서 ListTile의 배경색 또는 ink splash가 보이지 않을 수 있다는 assertion이 발생했다.
원인: CheckboxListTile의 상위 배경을 DecoratedBox로만 구성해 Material 조상이 없었다.
수정: BottomSheet 최상위 DecoratedBox를 Material로 교체하고 동일한 배경색, 둥근 모서리, Clip.antiAlias를 적용했다.
검증: 장르 선택 후 적용하면 Query Parameter와 영화 목록이 함께 변경되는 테스트를 포함해 전체 Flutter 테스트 20개가 통과했다.
재발 방지: ListTile 계열 Widget은 잉크 효과를 그릴 수 있는 Material 조상 안에 배치하고 상호작용 테스트를 함께 작성한다.
```

## 로컬 검증 결과

- `flutter analyze --no-fatal-infos`: 신규 오류·경고 없음
  - 0주차 Dart 연습 파일의 기존 `avoid_print` info 2건만 남아 있음
- `flutter test`: 전체 20개 통과
- Chrome debug 빌드·실행 성공
- macOS 실행은 Xcode가 설치되어 있지 않아 확인하지 못함
- Android 에뮬레이터는 검증 시점에 연결되어 있지 않았음

## 제출 전 체크

- 앱의 전체 사용자 흐름을 Android Emulator에서 직접 확인하고 화면 녹화를 만든다.
- 녹화 또는 요구된 화면을 PR 본문에 첨부한다.
- 원본 MakeUs 워크스페이스 페이지의 Required Mission과 최종 체크리스트는 증빙 첨부 뒤 체크한다.
- PR 링크 입력란이 별도로 없다면 미션 내용 정리 마지막에 PR 링크를 추가한다.
