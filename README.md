# MovieLog

UMC 11기 PE(Mobile) Flutter 필수 미션 프로젝트입니다.

## 실행

```bash
flutter pub get
flutter run -d emulator-5554
```

## Dart 연습 실행

```bash
dart run lib/week0/dart_practice.dart
```

`Movie` 클래스, `List<Movie>`, 반복문, Null Safety 기본값 처리를 확인할 수 있습니다.

## 0주차 구현 내용

- Flutter 및 Android Emulator 개발 환경 구성
- Figma `W0-01` 기준 MovieLog 시작 화면 구현
- `Icons.movie_outlined` 기본 Material 아이콘 사용
- 앱 설정과 화면 Widget 분리
- Widget 테스트 추가

## 1주차 구현 내용

- Material 3 기반 `AppColors`, `AppTextStyles`, `AppTheme` 구성
- Manrope 폰트와 MovieLog 공통 이미지·SVG Asset 등록
- 0주차 시작 화면의 기본 아이콘을 MovieLog SVG 로고로 교체
- 공용 `CommonAppBar`와 정적인 프로필 화면 구현
- 프로필 이미지, 재사용 가능한 통계 카드, 선호 장르 Chip 구현
- `List`와 `map`을 활용한 통계·장르 UI 생성
- 프로필 이미지 로드 실패 시 기본 아이콘 표시
- SVG 아이콘에 테마 색상 `colorFilter` 적용

1주차 제출 전 확인 사항은 `WEEK1_SUBMISSION_GUIDE.md`에 정리되어 있습니다.
