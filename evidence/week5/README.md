# 5주차 프론트엔드 화면 증빙

2026-10-16 Android 에뮬레이터(1080×2400)에서 직접 캡처했습니다. 이미지에 TMDB 토큰이나 개인 정보는 포함되지 않습니다.

## 실제 TMDB API 응답

| 홈: Popular | Discover: 전체 30편 | Genre: 액션 선택 |
| --- | --- | --- |
| <img src="./01-home-popular.png" width="230" alt="TMDB 인기 영화 홈"> | <img src="./02-discover-all.png" width="230" alt="전체 Discover 영화 30편"> | <img src="./03-genre-action.png" width="230" alt="액션 장르 필터 결과"> |

홈의 인기 영화는 추천 카드 1개와 가로 목록 4개로 구성됩니다. 한 화면에는 가로 목록 일부만 보이며, 실제 5개 사용 여부는 `integration_test/week5_live_tmdb_test.dart`에서 검증했습니다. Discover의 30편도 화면 상단의 개수와 통합 테스트로 확인했습니다. 액션 칩 선택 후 `with_genres=28` 재조회는 Service 테스트와 실제 API 통합 테스트로 확인했습니다.

## 테스트 서비스로 재현한 상태

실제 TMDB 응답을 조작한 캡처가 **아닙니다**. `integration_test/week5_evidence_test.dart`에서 결과를 제어하는 테스트 서비스를 주입하고, 같은 앱 UI를 에뮬레이터에서 캡처했습니다.

| Loading | Empty |
| --- | --- |
| <img src="./04-loading-test-service.png" width="230" alt="Loading 스켈레톤"> | <img src="./05-empty-test-service.png" width="230" alt="Empty 화면"> |

| Error와 다시 시도 버튼 | 다시 시도 성공 + 포스터 없음 placeholder |
| --- | --- |
| <img src="./06-error-test-service.png" width="230" alt="Error 상태와 다시 시도 버튼"> | <img src="./07-retry-success-placeholder-test-service.png" width="230" alt="재시도 성공과 포스터 placeholder"> |

테스트 순서는 Loading → Empty → 액션 장르 요청 실패(Error) → `다시 시도` 성공입니다. 마지막 영화의 `poster_path`는 `null`로 설정해 placeholder도 함께 검증했습니다. 네 상태 전환은 통합 테스트 1개가 통과했습니다.

## 검증

- `flutter test`: 34개 통과
- `flutter test integration_test/week5_evidence_test.dart -d emulator-5554`: 1개 통과
- `flutter test integration_test/week5_live_tmdb_test.dart -d emulator-5554`: 1개 통과
- `flutter analyze --no-fatal-infos`: 종료 코드 0, 기존 0주차 `avoid_print` info 2개

원본 Notion의 화면 증빙란에는 위 이미지들을 첨부하되, 04~07번은 반드시 **테스트 서비스로 재현**했다고 표시하세요. 스터디 인증 사진은 이 저장소에서 만들 수 없으므로 실제 모임 사진을 별도로 첨부해야 합니다.
