# 0주차 제출 가이드

## 1. 변경 파일을 기존 프로젝트에 반영한 뒤 브랜치 확인

```bash
cd ~/UMC11/movielog
git switch -c feature/week-0
```

이미 브랜치가 있다면 `git switch feature/week-0`을 사용합니다.

## 2. 첫 번째 커밋: Dart 연습

```bash
dart run lib/week0/dart_practice.dart
git add lib/week0/dart_practice.dart
git commit -m "feat: 0주차 Dart 기본 문법 연습"
```

예상 출력:

```text
인사이드 아웃
인터스텔라
라라랜드
닉네임: 무비러버
```

## 3. 두 번째 커밋: MovieLog 시작 화면

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

화면을 확인하고 실행 중인 터미널에서 `q`를 눌러 종료한 뒤 커밋합니다.

```bash
git add lib/main.dart lib/movie_log_app.dart lib/screens/start_screen.dart test/widget_test.dart README.md SUBMISSION_GUIDE.md
git commit -m "feat: MovieLog 0주차 시작 화면 구현"
```

## 4. 제출 전 확인

- `flutter doctor -v` 결과 캡처
- `flutter devices` 결과 캡처
- MovieLog 실행 화면 캡처
- 운영체제, IDE, Flutter 버전, 실행 기기 기록
- Android SDK 미인식 문제와 해결 과정 기록
- Pull Request에 실행 화면과 학습 회고 첨부
