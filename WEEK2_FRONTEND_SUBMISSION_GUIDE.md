# 2주차 프론트엔드 제출 가이드

## 워크북에서 확인한 필수 범위

- `Stack`, `Positioned`, `Expanded`, `Flexible`을 화면 구성에 적용한다.
- 키보드가 열려도 화면이 넘치지 않도록 `SingleChildScrollView`를 사용한다.
- `MediaQuery`와 `LayoutBuilder`의 역할을 이해하고 화면 너비에 대응한다.
- 회원가입 화면을 `StatefulWidget`으로 만들고 `setState`로 입력 상태를 갱신한다.
- `TextEditingController`와 `FocusNode`를 만들고 `dispose()`에서 해제한다.
- `Form`, `TextFormField`, `GlobalKey<FormState>`와 `validator`로 입력값을 검증한다.
- 닉네임·이메일·비밀번호·필수 약관 동의가 모두 유효할 때만 가입 버튼을 활성화한다.
- 버튼을 누를 때 `validate()`로 한 번 더 검증한다.
- `flutter_rating_bar`로 별점을 입력하고 별점 선택 뒤 저장 버튼을 활성화한다.
- 실제 회원가입·별점 저장 API는 연결하지 않는다.

## 프로젝트에 구현한 내용

- 앱 첫 화면을 2주차 회원가입 화면으로 변경했다.
- 닉네임, 이메일, 비밀번호 `TextFormField`와 약관 `Checkbox`를 구현했다.
- 입력 중에는 버튼 활성화 조건을 빠르게 계산하고, 제출 시에는 `Form.validate()`로 다시 검증한다.
- 비밀번호 표시/숨김과 키보드의 다음 입력란 이동을 구현했다.
- `SingleChildScrollView`로 키보드가 열린 상태에서도 스크롤할 수 있게 했다.
- 화면 너비가 700px 이상이면 좌우 여백을 넓히고 Form 최대 너비를 560px로 제한했다.
- 헤더의 로고와 체크 배지를 `Stack`과 `Positioned`로 배치했다.
- 약관 문구에는 `Expanded`, 완료 안내에는 `Flexible`을 사용했다.
- 별점 미니 실습 화면과 선택 상태에 따른 저장 버튼 활성화를 구현했다.
- 0주차 시작 화면과 1주차 프로필 화면 코드는 삭제하지 않고 테스트로 보존 여부를 확인했다.

## 입력 검증 규칙

- 닉네임: 공백 제거 후 2글자 이상
- 이메일: `문자열@문자열.문자열` 형태
- 비밀번호: 8자 이상
- 약관: 필수 동의
- 가입 버튼: 네 조건이 모두 충족되어야 활성화
- 별점 저장 버튼: 1점 이상 선택해야 활성화

## 직접 확인하고 캡처할 내용

원본 MakeUs 워크스페이스의 2주차 프론트엔드 페이지에 아래 화면을 첨부한다.

1. 회원가입 입력 전 화면
2. 잘못된 값을 입력해 세 Validator 오류가 표시된 화면
   - 닉네임 예시: `가`
   - 이메일 예시: `wrong-email`
   - 비밀번호 예시: `1234`
3. 유효한 값을 모두 입력하고 약관에 동의해 `가입하기` 버튼이 활성화된 화면
   - 닉네임 예시: `무비러버`
   - 이메일 예시: `movie@example.com`
   - 비밀번호 예시: `password123`
4. 입력창을 선택해 키보드가 열린 상태에서도 화면에 overflow가 발생하지 않는 화면
5. `별점 입력 미니 실습`에서 별점을 선택해 `평점 저장` 버튼이 활성화된 화면
6. 선택 Challenge를 증빙하려면 넓은 에뮬레이터/태블릿에서 중앙 Form의 최대 너비가 제한된 화면
7. PR 생성 후 PR 링크

개인정보가 포함된 실제 이메일이나 실제 비밀번호는 캡처에 사용하지 않는다.

## 미션 내용 정리 예시

```text
이름 / 닉네임: 이가연 / 레아
GitHub 저장소: https://github.com/yeonie0309/movielog
Pull Request: PR 생성 후 입력

회원가입 Form: 닉네임, 이메일, 비밀번호, 필수 약관 동의를 구현했다.
Validator 규칙: 닉네임 2글자 이상, 이메일 형식, 비밀번호 8자 이상을 검사한다.
버튼 활성화 조건: 세 입력값이 유효하고 필수 약관에 동의한 경우에만 가입하기 버튼이 활성화된다.
제출 시 재검증: 가입하기 버튼을 누르면 Form의 validate()를 다시 실행한다.
상태 관리: StatefulWidget과 setState로 약관 동의, 비밀번호 표시 여부, 입력 완료 상태를 관리했다.
입력 객체 생명주기: 닉네임·이메일·비밀번호용 TextEditingController와 FocusNode를 생성하고 dispose()에서 모두 해제했다.
키보드 대응: SingleChildScrollView를 적용해 키보드가 열린 상태에서도 입력 영역을 스크롤할 수 있게 했다.
레이아웃 Widget: 헤더 배지는 Stack/Positioned, 약관 문구는 Expanded, 완료 문구는 Flexible을 사용했다.
반응형 처리: LayoutBuilder로 너비 700px 이상을 넓은 화면으로 판단하고, Form의 최대 너비를 560px로 제한했다.
별점 입력: flutter_rating_bar로 0.5점 단위 별점을 선택하며, 별점을 선택해야 평점 저장 버튼이 활성화된다.
API 연결 여부: 워크북 범위에 맞춰 실제 회원가입과 저장 API는 연결하지 않고 로컬 UI 상태만 구현했다.

트러블슈팅: flutter_rating_bar 4.0.1의 RatingBar.builder에 일반 Widget처럼 key를 직접 전달했지만 해당 생성자가 key 매개변수를 지원하지 않아 분석 오류가 발생했다. 패키지 API에 맞게 지원하지 않는 key를 제거하고, 화면 검증에는 주변 문구와 저장 버튼의 Key를 사용하도록 테스트를 구성했다. 이후 flutter analyze와 flutter test를 다시 실행해 신규 오류가 없고 전체 테스트가 통과하는 것을 확인했다.

2주차 회고: 이번 미션을 통해 입력 화면은 단순히 TextField를 나열하는 것이 아니라 Controller와 FocusNode의 생명주기, Validator를 통한 최종 검증, 입력 중 버튼 상태 갱신을 함께 설계해야 한다는 점을 배웠다. SingleChildScrollView와 LayoutBuilder를 적용하면서 키보드와 화면 크기에 따라 레이아웃이 달라지는 상황에도 대응해 보았다. 또한 Expanded와 Flexible의 차이, Stack의 겹침 배치, setState가 필요한 범위를 회원가입과 별점 입력 화면에서 직접 확인했다. 다음에는 입력 검증 규칙을 별도 객체로 분리하고 실제 서버 오류 상태까지 포함해 더 확장 가능한 Form 구조를 설계하고 싶다.
```

## 트러블슈팅 기록 예시

```text
이슈: flutter_rating_bar를 추가한 뒤 RatingBar.builder 호출에서 "No named parameter with the name 'key'" 분석 오류가 발생했다.
원인: 프로젝트에서 설치한 flutter_rating_bar 4.0.1의 RatingBar.builder 생성자는 key라는 named parameter를 제공하지 않았다.
해결: 패키지 생성자 명세에 맞게 RatingBar.builder의 key를 제거했다. Widget 테스트에서는 별 아이콘을 선택한 뒤 Key가 지정된 평점 저장 버튼의 onPressed 상태와 "선택한 평점" 문구를 확인하도록 구성했다.
검증: flutter analyze 결과 신규 error와 warning이 없고, flutter test의 전체 10개 테스트가 통과했다. Android Emulator에서도 별점 4.0 선택 후 저장 버튼이 활성화되는 것을 확인했다.
재발 방지: 외부 패키지 Widget을 사용할 때 현재 설치 버전의 생성자 매개변수를 먼저 확인하고, 추가 직후 analyze와 관련 Widget 테스트를 실행한다.
```

## 로컬 검증 결과

- `flutter analyze --no-fatal-infos`: 신규 오류·경고 없음
  - 0주차 Dart 연습 파일의 기존 `avoid_print` info 2건만 남아 있음
- `flutter test`: 전체 10개 통과
- Android Emulator debug 빌드·설치·실행 성공
- 키보드 표시 상태에서 overflow 로그 없음
- 별점 4.0 선택 후 저장 버튼 활성화 확인

## 제출 전 체크

- 위 다섯 필수 화면을 원본 워크스페이스 페이지에 첨부한다.
- PR 링크 입력란이 있으면 PR 생성 뒤 링크를 추가한다.
- 별도 진행 과정이나 PR 링크 입력 블록이 없다면 미션 내용 정리란 마지막에 PR 링크를 함께 적는다.
- Challenge는 필수가 아니지만, 이번 구현에는 넓은 화면 대응 코드가 포함되어 있으므로 태블릿 캡처를 추가하면 증빙할 수 있다.
