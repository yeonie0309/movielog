# 4주차 프론트엔드 제출 가이드

## 구현 요약

- `FakeMovieService.fetchMovies()`가 1초 뒤 영화 목록을 반환하도록 구현했습니다.
- `Future`는 `initState()`에서 한 번 생성하고 `FutureBuilder`로 관찰합니다.
- Loading, Empty, Error, Success 상태를 각각 분리된 위젯으로 처리했습니다.
- Error 화면의 `다시 시도` 버튼은 새로운 성공 Future를 만들어 목록을 다시 불러옵니다.
- 장르 선택값은 `SharedPreferencesAsync`의 `selected_genre` 키에 저장하고 앱 시작 시 복원합니다.
- 오류 상세나 스택 트레이스는 사용자 화면에 노출하지 않습니다.
- 실제 서버 API, Dio, Retrofit, Provider는 사용하지 않았습니다.
- 5주차 실제 API 교체 위치에 `TODO(5주차 유저별 평점 조회 API)`를 남겼습니다.

## 상태 화면 확인 방법

1. 앱에서 회원가입을 완료해 홈 화면으로 이동합니다.
2. 하단 `영화` 탭을 누릅니다.
3. 영화 화면 오른쪽 위의 실험 아이콘을 누릅니다.
4. 다음 메뉴로 각 상태를 재현합니다.
   - `성공 상태`: 1초간 Loading 후 영화 목록 표시
   - `빈 상태`: 1초간 Loading 후 Empty 화면 표시
   - `오류 상태`: 1초간 Loading 후 Error 화면 표시
5. Error 화면에서 `다시 시도`를 누르면 Loading 후 성공 목록이 표시됩니다.
6. 성공 목록을 아래로 당기면 새로고침할 수 있습니다.

## 직접 캡처할 증빙

- Loading 화면: `evidence/week4/loading.png` 생성 완료
- Success 화면: `evidence/week4/success.png` 생성 완료
- Empty 화면: `evidence/week4/empty.png` 생성 완료
- Error → Retry 성공 영상: `evidence/week4/error_retry_success.mp4` 생성 완료
- 앱 재시작 후 장르 복원 영상: `evidence/week4/genre_persistence_restore.mp4` 생성 완료
  - 자동 증빙 시나리오는 다음 과정을 포함합니다.
  1. 성공 상태에서 `드라마` 등 장르 칩을 선택합니다.
  2. 앱의 전체 위젯 트리를 종료하고 다시 생성합니다.
  3. 새 앱 화면에서 영화 탭을 다시 불러옵니다.
  4. 이전 장르 칩과 필터 결과가 복원된 것을 촬영합니다.
- `flutter analyze --no-fatal-infos` 결과: `evidence/week4/flutter_analyze.txt` 생성 완료
- 스터디 인증 사진
- 생성할 Pull Request 링크

## 체크 가능한 항목

코드와 실행 증빙을 모두 확인한 뒤 Required Mission과 최종 체크리스트를 체크합니다. Challenge Mission에서는 아래 항목을 체크할 수 있습니다.

- `RefreshIndicator`로 당겨서 새로고침
- `Future.timeout`으로 응답 시간 제한
- 원형 인디케이터 대신 Skeleton UI
- Fake Service의 성공/빈 값/실패 단위 테스트
- Loading/Empty/Error/Success 위젯 테스트

정렬 기준 저장은 구현하지 않았으므로 해당 Challenge 항목은 체크하지 않습니다.

## 제출 양식 초안

```text
이름 / 닉네임: 레아 / 이가연
GitHub 저장소: https://github.com/yeonie0309/movielog
Pull Request: [PR 생성 후 링크 입력]
Loading 화면: PR에 첨부 완료
Success 화면: PR에 첨부 완료
Empty 화면: PR에 첨부 완료
Error → Retry 성공 영상: PR에 첨부 완료
앱 재시작 후 장르 복원 영상: PR에 첨부 완료
flutter analyze 결과: PR에 첨부 완료
Future 생성 위치: MovieListScreen의 initState에서 _loadInitialData() Future를 생성했습니다.
SharedPreferences 키: selected_genre
트러블슈팅: Future를 build 안에서 생성하면 rebuild마다 요청이 반복될 수 있어 initState에서 한 번 생성했습니다. 재시도와 명시적인 상태 미리보기/새로고침 때만 새 Future를 할당했습니다. 비동기 작업 후에는 mounted를 확인해 dispose된 위젯에서 setState가 호출되지 않도록 했습니다.
4주차 회고: FutureBuilder의 snapshot 상태를 기준으로 Loading, Empty, Error, Success UI를 분리하면서 비동기 화면의 상태 설계를 익혔습니다. 또한 SharedPreferencesAsync로 장르 설정을 저장하고 앱 재시작 후 복원해 보며 단순 설정값의 로컬 저장 흐름을 이해했습니다. 비밀번호나 토큰 같은 민감 정보는 SharedPreferences에 저장하면 안 된다는 점도 확인했습니다.
```

## 트러블슈팅 기록 초안

```text
문제: 영화 목록 Future를 build에서 생성하면 화면이 다시 그려질 때마다 Mock 요청이 반복될 수 있었다.
원인: build는 상태 변화나 부모 위젯 갱신에 따라 여러 번 호출될 수 있기 때문이다.
수정: Future를 late 필드로 선언하고 initState에서 한 번 생성했다. 재시도 버튼을 누르거나 사용자가 직접 새로고침할 때만 새 Future를 할당했다.
결과: 불필요한 중복 요청 없이 Loading → Success/Empty/Error 상태가 안정적으로 전환되었다.

문제: 비동기 장르 복원과 BottomSheet 결과 처리 도중 화면이 dispose될 가능성이 있었다.
원인: await 전후로 위젯의 생명주기가 달라질 수 있기 때문이다.
수정: 비동기 작업 뒤 mounted를 확인한 후에만 setState 또는 화면 상태 변경을 수행했다.
결과: dispose된 위젯의 context나 state를 사용하는 오류를 예방했다.
```
