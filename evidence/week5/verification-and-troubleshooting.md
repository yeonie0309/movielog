# 5주차 프론트엔드 검증 및 트러블슈팅 기록

검증일: 2026-10-16 · PR: https://github.com/yeonie0309/movielog/pull/11

## TMDB Token 비노출 확인

- 로컬 `.env`는 `.gitignore`로 제외되며 Git 추적 대상이 아닙니다.
- `ruby evidence/week5/verify_token_exposure.rb` 실행 결과, 새 증빙을 포함한 Git 추적 파일 292개에서 토큰 원문이 발견되지 않았습니다. 스크립트는 토큰 값을 출력하지 않습니다.
- 실제 TMDB 요청 로그의 `Authorization` 값은 `Bearer ***`로 표시됩니다. [요청 로그](network_requests_and_test.txt)에는 토큰 원문이 없습니다.
- [장르 전환 영상](08-network-genre-before-after.mp4)은 앱 UI와 요청 경로·HTTP 상태만 표시하며 토큰 입력 화면이나 원문을 담지 않았습니다. 대표 시작·중간·끝 프레임을 시각적으로 확인했습니다.
- 이 검사는 **Git에서 추적하는 파일**을 확인한 것입니다. 배포 APK에 토큰이 내장되지 않는다는 뜻은 아닙니다. `flutter_dotenv`를 사용하는 이 학습용 앱은 배포 시 백엔드 프록시 등의 별도 보호가 필요합니다.

## 정적 분석

실행 명령: `flutter analyze --no-fatal-infos`

```text
Analyzing movielog...
info • Don't invoke 'print' in production code • lib/week0/dart_practice.dart:16:5 • avoid_print
info • Don't invoke 'print' in production code • lib/week0/dart_practice.dart:21:3 • avoid_print
2 issues found. (ran in 10.9s)
종료 코드: 0
```

위 두 항목은 이번 변경 범위 밖인 기존 0주차 코드의 `info`입니다. `error`와 `warning`은 없습니다.

## Guided / Required 확인 결과

| 항목 | 검증 결과 | 증빙 |
| --- | --- | --- |
| Popular 영화 5개 | 실제 TMDB 통합 테스트 통과. 화면은 첫 추천 카드와 가로 목록 4개로 구성 | [홈](01-home-popular.png), `integration_test/week5_live_tmdb_test.dart` |
| Discover 최대 30개와 중복 제거 | 실제 TMDB 통합 테스트에서 30개·ID 중복 없음 확인 | [전체 목록](02-discover-all.png), `integration_test/week5_live_tmdb_test.dart` |
| 장르 선택 전후 요청·목록 변경 | 실제 TMDB 요청에서 전체는 `with_genres` 없음, 액션 선택 후 `with_genres=28`, 전체 복귀 후 파라미터 제거 확인 | [전후 영상](08-network-genre-before-after.mp4), [요청 로그](network_requests_and_test.txt), [액션 화면](03-genre-action.png) |
| Loading / Empty / Error / Success / 재시도 | 통합 테스트에서 동일 앱 UI에 테스트 서비스를 주입해 네 상태와 재시도 성공 확인 | [화면 모음](README.md), `integration_test/week5_evidence_test.dart` |
| 포스터 경로가 없는 영화 | placeholder 표시 확인. 테스트 서비스로 재현 | [재시도 성공·placeholder](07-retry-success-placeholder-test-service.png) |
| 영화 ID 전달 | 카드 → 상세 → 평점 Dialog의 실제 TMDB ID 전달 확인 | `integration_test/week5_live_tmdb_test.dart` |
| 정적 분석 | 종료 코드 0, 기존 0주차 `info` 2개 | 이 문서의 정적 분석 결과 |

Empty/Error/Success 및 포스터 없음 화면은 **실제 TMDB 응답이 아니라 테스트 서비스로 재현**한 결과입니다. 실제 API 응답으로 오인하지 않도록 이미지 이름과 설명에도 표시했습니다.

전후 영상은 기본 screenrecord 파일이 아니라 실제 화면 연속 캡처를 이어 만든 무음 영상입니다. 프레임 간격은 약 0.8초이며, 요청·응답 오버레이는 실제 Dio interceptor에서 가져온 경로·상태만 보여 줍니다.

## 트러블슈팅: 홈·영화 탭 Hero 태그 충돌

- **상황/재현:** 실제 TMDB 데이터로 화면 이동을 검증하는 통합 테스트에서 홈의 영화 카드와 영화 탭 카드가 같은 Hero 태그를 사용해 전환 중 충돌했습니다.
- **호출 API·파라미터:** TMDB Popular/Discover 조회는 정상 응답이었고, 오류는 API가 아닌 Flutter 화면 전환에 있었습니다. 토큰 값은 기록하지 않았습니다.
- **예상/실제:** 화면 전환과 영화 상세 열기가 정상 동작해야 했지만, 동일 Hero 태그에 대한 assertion이 발생했습니다.
- **원인:** 서로 다른 탭에 동시에 존재하는 보조 카드에 동일 영화 ID 기반 Hero 태그가 붙었습니다.
- **수정:** 홈의 보조 카드 Hero 애니메이션만 비활성화하고, 영화 카드의 상세 이동과 ID 전달은 유지했습니다.
- **재검증:** Android 에뮬레이터에서 실제 TMDB 통합 테스트를 다시 실행해 상세·평점 Dialog 진입까지 통과했습니다.

## 남은 직접 확인

- 스터디 인증 사진은 실제 모임의 촬영·동의가 필요하므로 이 저장소에서 대신 만들 수 없습니다.
- 원본 MakeUs Notion 페이지에 파일을 직접 첨부했는지는 이 저장소만으로 확인할 수 없습니다.
