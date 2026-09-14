# 1주차 제출 가이드

## 구현 기준

- 실행 화면: `W1-01 내 프로필 (Manrope) - Final Sync`
- Primary: `#6750A4`
- Surface: `#FAF9F5`
- 기본 간격: 8px 단위
- 모바일 좌우 여백: 16px
- 기본 Radius: 8px
- 하단 NavigationBar와 실제 화면 이동·입력 기능은 구현하지 않음

## 프로젝트에서 확인할 내용

- `AppColors`: 공통 원본 색상
- `AppTextStyles`: 반복되는 글자 스타일
- `AppTheme`: ColorScheme, TextTheme, AppBarTheme, Manrope
- `CommonAppBar`: 재사용 가능한 AppBar
- `ProfileHeader`: 로컬 프로필 이미지와 오류 fallback
- `ProfileStats`와 `StatItem`: `List`, `map`, 재사용 가능한 통계 카드
- `FavoriteGenres`: 장르 Chip
- `EditProfileButton`: 모양만 구현한 ElevatedButton
- `StartScreen`: `movielog_logo.svg`로 교체된 0주차 로고

## 직접 확인하고 캡처할 내용

1. Android Emulator에서 프로필 화면을 실행한다.
2. Figma의 `W1-01`과 Flutter 실행 화면을 나란히 비교해 캡처한다.
3. `WEEK1_WIDGET_TREE.md`를 열어 작성된 Widget Tree 문서를 확인하고 캡처한다.

4. 실행 화면과 Widget Tree 캡처를 원본 MakeUs 워크스페이스의 1주차 페이지에 첨부한다.
5. PR 링크와 아래 미션 내용을 같은 페이지에 기록한다.

## 미션 내용 기록 예시

```text
이름 / 닉네임: 이가연 / 레아
GitHub 저장소: https://github.com/yeonie0309/movielog
Pull Request: PR 생성 후 입력
실행 화면: Android Emulator 캡처 첨부
재사용한 Widget: CommonAppBar, StatItem
사용한 비트맵 이미지: assets/images/profile/profile_movielog.jpg
사용한 SVG 아이콘: movie.svg, star.svg, bookmark.svg
교체한 MovieLog 로고 경로: assets/logos/movielog_logo.svg
선택한 버튼과 선택 이유: ElevatedButton — 주요 동작을 테두리형 스타일로 강조하기 위해 선택
사용한 주축/교차축 정렬: 통계 Row의 spaceBetween/stretch, 각 카드 Column의 center
Padding을 적용한 위치: 화면 좌우 여백, 통계 카드 내부, 장르 Chip 내부
Margin을 적용한 위치: ProfileStats 위·아래 간격
AppColors에서 관리한 값: violet, violetContainer, warmWhite, white, black, gray, outline
ThemeData에서 관리한 값: Material 3, ColorScheme, TextTheme, AppBarTheme, 시스템 UI 스타일
적용한 Font: Manrope
트러블슈팅: 직접 발생한 내용 기록
1주차 회고: 직접 작성
```

## 제출

- 원본 MakeUs 워크스페이스 페이지의 공유 링크를 복사한다.
- UMC 11기 PE 파트 워크북 AI 피드백 시스템에 제출한다.
- 기술 블로그는 필수가 아닌 선택 사항이며, 제출 시 상점 3점 대상이다.
