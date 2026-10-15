# 5주차 프론트엔드 제출 가이드

## 구현 범위

- TMDB 전용 Dio Client, `.env` 토큰 설정, 디버그 요청·응답 로그(Authorization 마스킹)
- Popular / Discover / Genre API의 DTO 및 stateless Service
- 홈의 인기 영화 최대 5개, 영화 목록의 TMDB ID 중복 없는 최대 30개
- 장르 API Chip과 `with_genres` 재조회, 요청 중 장르 변경 방지
- Provider/ChangeNotifier 기반 Loading·Empty·Error·Success와 재시도
- 포스터 경로 null·로드 실패 placeholder, 영화 ID의 상세·평점 Dialog 전달
- 기존 0~4주차 Mock 화면과 테스트를 유지하면서 실제 앱 경로만 TMDB 화면으로 전환

## 실행 전 설정

1. TMDB 계정의 **API Read Access Token**을 발급합니다. 짧은 API Key가 아닙니다.
2. 프로젝트 루트의 `.env`에 `TMDB_ACCESS_TOKEN=긴_토큰`을 저장합니다.
3. 토큰 원문은 코드·PR·스크린샷·영상·로그에 넣지 않습니다. `.env`는 Git에서 제외됩니다.
4. `flutter pub get` 후 `flutter run -d <device-id>`로 실행합니다.

`flutter_dotenv`의 Flutter asset 방식은 학습용 구성입니다. 배포 앱에서는 토큰이 완전히 숨겨지지 않으므로 운영 서비스는 백엔드 프록시를 검토해야 합니다.

## PR과 원본 Notion에 넣을 증빙

1. 홈: 인기 영화 5개(첫 추천 카드 포함)가 보이는 화면
2. 영화 탭: 전체 Discover 목록의 실제 개수(최대 30개)와 포스터가 보이는 화면
3. 장르 선택 전후 화면 및 디버그 로그의 `/discover/movie` 요청 변화: 전체는 `with_genres` 없음, 선택 후에는 장르 ID 포함. 로그에는 토큰 원문이 없어야 합니다.
4. Loading / Empty / Error / Success 상태: Empty/Error는 테스트용 Service 또는 네트워크 조건을 사용해 확인하고, 재시도 결과도 기록합니다.
5. 포스터가 없는 항목의 placeholder: 위젯 테스트로 재현되며, 실제 화면 증빙이 필요하면 포스터가 없는 TMDB 항목을 찾거나 테스트용 Service를 사용합니다.
6. `flutter analyze --no-fatal-infos`, `flutter test` 결과
7. 스터디 인증 사진, PR 링크, 트러블슈팅 기록

실제 TMDB 응답은 계속 바뀌므로 제목과 개수는 실행 시점의 결과를 적습니다. Token을 일부러 공개하거나 영상에 입력하는 방식으로 Error를 재현하지 않습니다.

## 워크북 최종 체크리스트 판단

코드·자동 테스트로 Client 분리, `.env` 제외, 5개/30개, DTO 변환, 장르 재조회, 상태·재시도, 영화 ID 전달을 확인할 수 있습니다. 다만 **실제 TMDB 200 응답, 요청 로그와 화면, 수동 상태 검증, PR·스터디 증빙은 직접 확인한 후** 해당 항목에 체크합니다. Challenge Mission의 다중 장르 선택 및 실패 Dialog는 구현 범위에 포함하지 않았으므로 체크하지 않습니다.

## Notion 제출 양식 예시

```text
PR 링크: (생성 후 링크)
TMDB Token 비노출 확인: .env는 Git에서 제외했고, 디버그 로그의 Authorization은 Bearer ***로 마스킹함. PR·캡처·영상에 원문 없음.
Popular 5개 화면: (홈 캡처 첨부)
Discover 최대 30개 화면과 실제 개수: (영화 탭 캡처 첨부, 실행 시 표시된 개수 기입)
Genre API 및 with_genres 요청 증거: (전체/장르 선택 전후 요청 로그 또는 영상 첨부)
Loading / Empty / Error / Success: 네 상태 구현 및 재시도 테스트 결과 첨부
포스터 null·실패 처리: TmdbPosterImage placeholder와 위젯 테스트 확인
movie.id 전달 위치: 영화 카드 → /movies/:movieId → MovieDetailScreen → RatingDialog.movieId
트러블슈팅: (실제 겪은 오류와 수정·재검증 결과 기입)
미검증 항목: (수동 확인하지 못한 항목이 있다면 사실대로 기입)
```

평점 Dialog는 TMDB ID를 전달하지만 자체 백엔드에 평점을 저장하는 API 연결은 이번 주차 범위가 아닙니다.
