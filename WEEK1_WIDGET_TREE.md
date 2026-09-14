# MovieLog 1주차 Widget Tree

## 1. 전체 앱 구조

```text
MovieLogApp
└─ MaterialApp
   ├─ theme: AppTheme.light
   └─ home: ProfileScreen
      └─ Scaffold
         ├─ appBar: CommonAppBar
         │  └─ AppBar
         │     └─ Text("내 프로필")
         └─ body: SafeArea
            └─ SingleChildScrollView
               └─ Padding
                  └─ Column
                     ├─ ProfileHeader
                     ├─ SizedBox
                     ├─ Center
                     │  └─ EditProfileButton
                     ├─ Container (margin)
                     │  └─ ProfileStats
                     └─ FavoriteGenres
```

`MovieLogApp`은 앱의 최상위 Widget이다. `MaterialApp`에 `AppTheme.light`를 연결해 Material 3, 공통 색상, 글자 스타일, AppBar 스타일과 Manrope 폰트를 앱 전체에 적용한다. 첫 화면은 정적인 `ProfileScreen`이며, 상태 변경이 없으므로 `StatelessWidget`으로 작성했다.

## 2. 프로필 헤더

```text
ProfileHeader
└─ Column
   ├─ Container
   │  └─ ClipOval
   │     └─ Image.asset("profile_movielog.jpg")
   │        └─ 오류 발생 시 _ProfileFallback
   │           └─ ColoredBox
   │              └─ Icon(Icons.person)
   ├─ SizedBox
   ├─ Text("무비러버")
   ├─ SizedBox
   └─ Text("매주 주말엔 영화관으로...")
```

프로필 사진은 `Image.asset`으로 표시하고 `ClipOval`로 원형으로 자른다. 이미지 로드에 실패하거나 이미지 경로가 없으면 기본 사람 아이콘을 표시한다. `Column`의 주축은 세로이므로 이미지, 닉네임, 소개가 위에서 아래로 배치된다.

## 3. 프로필 수정 버튼

```text
EditProfileButton
└─ SizedBox
   └─ ElevatedButton
      └─ Text("프로필 수정")
```

프로필 수정은 화면의 주요 동작이므로 `ElevatedButton`을 선택했다. 1주차는 정적인 UI 구현이 목표이므로 버튼의 모양만 구현하고 화면 이동이나 입력 기능은 연결하지 않았다.

## 4. 통계 영역

```text
ProfileStats
└─ IntrinsicHeight
   └─ Row
      ├─ Expanded
      │  └─ Padding
      │     └─ StatItem("본 영화", "342", movie.svg)
      ├─ Expanded
      │  └─ Padding
      │     └─ StatItem("평점", "4.2", star.svg)
      └─ Expanded
         └─ Padding
            └─ StatItem("즐겨찾기", "58", bookmark.svg)

StatItem
└─ Container
   └─ Column
      ├─ Row
      │  ├─ SvgPicture.asset
      │  ├─ SizedBox
      │  └─ Text(label)
      ├─ SizedBox
      └─ Text(value)
```

통계 데이터는 `List<ProfileStatData>`로 관리하고 `map`으로 동일한 `StatItem`을 세 번 생성한다. `Row`의 주축은 가로이므로 세 카드가 왼쪽에서 오른쪽으로 배치된다. `Expanded`가 남은 가로 공간을 동일하게 나누고, `crossAxisAlignment: CrossAxisAlignment.stretch`가 카드 높이를 맞춘다.

각 `StatItem`은 `Container`의 `padding`으로 카드 테두리와 내용 사이의 안쪽 여백을 만든다. `BoxDecoration`으로 테두리와 8px 둥근 모서리를 적용했다. SVG 아이콘에는 `colorFilter`를 적용해 공통 테마 색상을 사용한다.

## 5. 선호 장르 영역

```text
FavoriteGenres
└─ Column
   ├─ Text("선호하는 장르")
   ├─ SizedBox
   └─ Wrap
      ├─ Chip("드라마")
      ├─ Chip("SF")
      └─ Chip("애니메이션")
```

장르 데이터도 `List<String>`과 `map`으로 Chip을 생성한다. `Wrap`을 사용해 화면 너비가 좁아질 경우 Chip이 다음 줄로 자연스럽게 이동할 수 있도록 했다.

## 6. Padding과 Margin 적용 위치

- `Padding`: 프로필 화면의 좌우 16px 여백, 통계 카드 내부, 카드 사이, 장르 Chip 내부에 적용했다.
- `Margin`: `ProfileStats`를 감싸는 `Container`의 위아래 24px 바깥 여백에 적용했다.
- Padding은 Widget의 테두리와 내용 사이의 안쪽 여백이고, Margin은 해당 Widget과 주변 Widget 사이의 바깥 여백이다.

## 7. 0주차 시작 화면 보존

```text
StartScreen
└─ Scaffold
   └─ SafeArea
      └─ Padding
         └─ Column
            ├─ _WelcomeContent
            │  ├─ Text("FLUTTER 0주차")
            │  ├─ SvgPicture.asset("movielog_logo.svg")
            │  ├─ Text("영화의 순간을 기록하세요")
            │  └─ Text("보고 싶은 영화부터...")
            ├─ Spacer
            └─ ElevatedButton("시작하기")
```

0주차의 `StartScreen` 코드는 삭제하지 않고 보존했다. 1주차 Asset 학습 요구사항에 따라 임시 `Icons.movie_outlined`만 실제 `assets/logos/movielog_logo.svg`로 교체했다.

## 8. 의미 단위로 분리한 Widget

- `ProfileScreen`: 프로필 화면 전체 구조
- `CommonAppBar`: 여러 화면에서 재사용할 공용 AppBar
- `ProfileHeader`: 프로필 이미지, 닉네임, 소개
- `EditProfileButton`: 프로필 수정 주요 동작
- `ProfileStats`: 통계 데이터 배치
- `StatItem`: 재사용 가능한 통계 카드 한 개
- `FavoriteGenres`: 선호 장르 제목과 Chip 목록

화면을 의미 단위로 분리해 각 Widget의 책임을 작게 유지하고, 반복되는 통계와 장르 UI는 데이터 기반으로 생성했다.
