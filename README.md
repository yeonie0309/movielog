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

## 5주차 백엔드와 화면 연결

기존 도서 서비스는 `backend/`, 새 영화 평점 서비스는 `movie-backend/`에 있습니다.
회원가입의 닉네임·이메일 중복 확인과 마이페이지의 회원별 평점 조회를 실제 API에 연결했습니다.

- [새 백엔드 실행 방법](movie-backend/README.md)
- [API 명세](movie-backend/docs/API_SPEC.md)
- [제출 가이드와 변경 파일 목록](WEEK5_BACKEND_SUBMISSION_GUIDE.md)
- [Postman·CORS·Flutter 화면 증빙](evidence/week5-backend/README.md)

## 6주차 백엔드 — 입력한 데이터를 저장하기

NestJS 영화 서비스에 회원가입·평점 등록/수정/삭제를 추가했습니다. 기존 Flutter·조회 API는 보존합니다.

- [6주차 API 명세](movie-backend/docs/WEEK6_API_SPEC.md)
- [제출물·실행 결과·Notion 작성 초안](WEEK6_BACKEND_SUBMISSION_GUIDE.md)
- [실제 요청·응답 캡처 및 검증 로그](evidence/week6-backend/README.md)
- [원본 Notion 반영 승인 계획](WEEK6_BACKEND_NOTION_PLAN.md)

## 7주차 프론트엔드 — 회원가입과 평점 CRUD 확장

공개 MovieLog v6에 회원가입 및 평점 등록·수정·삭제를 연결했습니다.
가입으로 받은 학습용 회원 ID는 메모리 세션에만 보관하며 로그인 인증은 아닙니다.
기존 0~6주차 실습과 백엔드는 보존합니다.

- [요구사항·구현·검증·제출 양식](WEEK7_FRONTEND_SUBMISSION_GUIDE.md)
- [실제 API/실패 주입 화면·영상·로그](evidence/week7-frontend/README.md)
- [원본 Notion 작성 승인 계획](WEEK7_FRONTEND_NOTION_PLAN.md)
