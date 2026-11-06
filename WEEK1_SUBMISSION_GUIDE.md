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
트러블슈팅: 0주차 시작 화면의 기본 Icon을 SvgPicture.asset으로 교체한 뒤, const Column 내부에서 const 생성자가 아닌 SvgPicture.asset을 호출해 const_with_non_const 컴파일 오류가 발생했다. 부모 Column의 const를 제거하고 값이 고정된 Text와 SizedBox에만 const를 개별 적용한 뒤 flutter analyze와 flutter test로 해결을 확인했다.
1주차 회고: 이번 미션을 통해 화면마다 색상과 TextStyle을 직접 반복하기보다 AppColors, AppTextStyles, AppTheme로 디자인 시스템을 분리하는 이유를 이해했다. 프로필 화면을 ProfileHeader, ProfileStats, StatItem, FavoriteGenres처럼 의미 단위로 나누면서 재사용 가능한 Widget의 장점도 확인했다. 또한 PNG와 SVG Asset의 차이, Row와 Column의 주축·교차축, Padding과 Margin의 역할을 실제 화면에 적용해 보았다. 다음 화면을 구현할 때도 먼저 Widget Tree와 공통 스타일을 설계한 뒤 작은 Widget 단위로 개발하고 싶다.
```

## 트러블슈팅 기록 예시

```text
이슈: 0주차 시작 화면의 Icons.movie_outlined를 MovieLog SVG 로고로 교체한 뒤 const_with_non_const 컴파일 오류가 발생했다.
원인: flutter_svg의 SvgPicture.asset 생성자는 const 생성자가 아닌데, 해당 Widget이 const Column 내부에 포함되어 있었다.
해결: 부모 Column의 const를 제거하고, 컴파일 시점에 값이 고정되는 Text와 SizedBox에만 const를 개별 적용했다. 이후 flutter analyze에서 컴파일 오류가 사라지고 flutter test 2개가 모두 통과하는 것을 확인했다.
다른 해결 방법: SvgPicture.asset을 별도의 StatelessWidget으로 분리하거나, SVG를 포함하는 더 작은 상위 영역만 non-const Widget으로 구성할 수도 있다.
다시 발생하지 않게 확인한 내용: 외부 패키지 Widget의 생성자가 const를 지원하는지 먼저 확인하고, Asset이나 패키지 Widget을 추가한 직후 flutter analyze와 flutter test를 실행한다.
```

## 제출

- 원본 MakeUs 워크스페이스 페이지의 공유 링크를 복사한다.
- UMC 11기 PE 파트 워크북 AI 피드백 시스템에 제출한다.
- 기술 블로그는 필수가 아닌 선택 사항이며, 제출 시 상점 3점 대상이다.
