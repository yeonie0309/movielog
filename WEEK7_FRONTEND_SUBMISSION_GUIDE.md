# 7주차 프론트엔드 — 회원가입과 평점 CRUD 확장

원본: [레아의 워크북](https://app.notion.com/p/makeus-challenge/7-CRUD-499b57f4596b83c5b5918118bf2710da).
이 문서는 제출 초안입니다. 원본 Notion은 아직 작성하거나 제출하지 않았습니다.

## 작업 기준

- 작업 전 로컬 main `2445f60`, fetch 후 origin/main `a10ad32` (1주차까지 반영).
- 최신 `origin/feature/week-6-frontend` `2740bbb`에는 PR #14의 6주차 백엔드가 이미 병합되어 있었습니다.
- 이를 기반으로 `feature/week-7-frontend`를 생성했습니다. main은 이동·병합하지 않았습니다.
- 로컬 6주차 백엔드의 문서 커밋 `6d0545a`는 기존 브랜치에 보존했습니다.
- 기존 미추적 `backend/evidence/week4-postman/`, `evidence/week4/flutter_analyze.local.txt`는 수정·커밋하지 않습니다.
- 별도 브랜치/PR 제목 규칙을 이번 페이지에서 찾지 못해 기존 `feature/week-N-frontend`, `feat:` 형식을 따릅니다.
- 공개 API는 **https://workbook.devnoco.com/v6**. 7주차 프론트라고 `/v7`을 사용하지 않습니다.
- 기존 도서/영화 NestJS 백엔드와 DB 권한·스키마는 이번 작업에서 변경하지 않았습니다.

## 요구사항 → 구현 → 검증

| 원본 항목 | 구현 | 증빙 |
| --- | --- | --- |
| Guided A: DTO/공통 응답/실제 가입 | CommonResponse, CreateMemberRequest, SignUpResult, SignUpService | unit/Service 테스트, 실제 POST 201 |
| 중복 확인 두 항목 통과 후 가입 | SignUpViewModel.checksAvailable, 입력 변경 무효화 | 01, 02 + 회귀 테스트 |
| 회원가입 400/409 목적지 | 비밀번호 400은 forceErrorText, 나머지는 Snackbar | VM·화면 테스트, 실제 최종409 |
| 생성 memberId 사용 | 메모리 LearningMemberSession, 상세·마이페이지 동일 ID | 실제 API JSON, 03/06 |
| Guided B: 실제 TMDB id·별점·코멘트 등록 | extra에 TmdbMovieDto, MovieDetailLoader/ViewModel, RatingDialog | 04/05/06 및 실제 CRUD 영상 |
| 정수 score 1~5·comment 500자 | 정수 입력 모드, validateServerScore, normalizedComment | 모델/Widget 테스트 |
| 수정 Dialog 초기값과 PATCH | score/comment 초기화, score 필수·null 명시 | 07/08 |
| 삭제 확인·취소 시 요청0·204 | DeleteRatingDialog, body 파싱 없음 | 09/10/11 및 실제 요청 로그 |
| 본인 목록만 수정·삭제 | 신규 회원 ID로 범위가 제한된 GET, 각 카드 오른쪽 버튼 | 06/08/11 |
| 400/403/404/409 및 안전한 안내 | CommonResponse 오류 파싱, 서버 message 사용, 403/404만 재조회 | 실제 오류 JSON, 오류별 VM 테스트 |
| 저장 실패 입력 보존 | Dialog 내부 controller/state, 재시도 가능 | 12 |
| 저장 성공/재조회 실패 분리 | 쓰기만 throw, refreshWarning과 GET 재시도 | 13/14, writes 횟수 불변 검증 |
| 가입·Dialog 이탈 및 연타 차단 | PopScope, barrierDismissible:false, 로딩 버튼·AbsorbPointer | 비동기/Widget 테스트 |
| Challenge: 다중 선택·취소·삭제 | selectedRatingIds, 편집 UI·하단 버튼 | 15 |
| Challenge: 오버레이·부분 실패 | 확인 Dialog 먼저 닫음, 검은 ModalBarrier+흰 인디케이터, 실패 선택 유지 | 16/17, 복구 영상 |
| Deep Link에서 extra 없음 | initState에 Future 생성, TMDB detail 재조회·오류 재시도 | Loader 구현, 경로 회귀 테스트 |

원본의 「스터디 인증」은 이 주차의 구현 화면·영상 목록입니다. 구현 증빙 대신 PR 링크만 넣지 않습니다.
「미션 기록」이라는 새 칸을 임의로 만들지 않고, 원본 「제출 양식」의 필드를 그대로 사용합니다.

## 증빙 사용법

검증 결과: Flutter 단위/위젯 79개 통과, Android 통합 시나리오 2개 통과,
최종 실제 v6 요청 21건(200/201/204/400/403/404/409) 확인.
정적 분석은 exit 0이며 기존 0주차 정보성 메시지 2건만 있습니다.
PNG 17장과 MP4 2개를 준비했습니다. 최종 파일별 결과는 검증 요약을 기준으로 확인합니다.

- [파일별 안내](evidence/week7-frontend/README.md)
- `01-live-crud.mp4`: 실제 v6·TMDB를 사용한 등록→조회→수정→조회→삭제 취소→삭제→빈 목록.
- `02-injected-recovery.mp4`: **실패 주입 테스트**의 입력 보존, 쓰기 성공/GET 실패, GET만 재시도, 다중 삭제 부분 실패.
- `01`~`11` PNG: 실제 서버 화면. `12`~`17` PNG: 실패를 주입해 만든 실제 앱 화면.
- 원본 요청·응답: `live-api-results.json`. 비밀번호·인증 헤더는 기록하지 않습니다.
- 정적 분석: `flutter-analyze.txt`. 기존 0주차 avoid_print info 2건만 유지.
- 단위/위젯: `flutter-test.txt`. 기존 계약이 확장된 테스트만 조정했으며 삭제·skip하지 않았습니다.
- Android 통합: `flutter-integration-test.txt`. 통과 여부와 실행 끝부분을 함께 확인합니다.
- 실제 iOS·물리 기기 테스트는 수행하지 않았습니다.

## 설계 이유와 공식 참고

1. **가입 결과는 인증이 아님**: memberId를 아는 것은 로그인 증명이 아닙니다. 서버 전용 인증을 새로 구현하지 않고 메모리 세션에만 저장합니다. 앱 재시작 시 다시 가입 안내가 나타납니다.
2. **응답 파서 구분**: GET 성공은 직접 객체/배열, 새 쓰기는 wrapper, DELETE 성공은 body 없음입니다. Swagger의 등록 result 예시는 null/숫자가 혼재하므로 강제 캐스팅하지 않습니다.
3. **삭제·수정의 재실행 방지**: 쓰기가 끝난 뒤 GET만 실패하면 저장을 다시 보내지 않습니다. 목록의 재시도는 load()만 실행합니다.
4. **이탈 차단의 범위**: PopScope는 back을 막고, Dialog 바깥 탭은 barrierDismissible로 따로 막습니다. 성공 시 로딩을 해제하고 한 프레임 뒤 pop하여 결과를 반환합니다.
5. **기존 실습 보존**: MemberCheckService는 v5 읽기 호환용으로 남기고 앱의 실제 provider는 SignUpService(v6)를 사용합니다. 반 점 입력은 기존 미니 실습에 남기고 서버 Dialog만 정수로 제한합니다.

- [공개 v6 Swagger](https://workbook.devnoco.com/docs?urls.primaryName=6%EC%A3%BC%EC%B0%A8+%28v6%29)
- [v6 OpenAPI JSON](https://workbook.devnoco.com/docs/v6-json)
- [Dio — 요청·오류 처리](https://pub.dev/packages/dio)
- [Flutter PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html)
- [Flutter showDialog](https://api.flutter.dev/flutter/material/showDialog.html)
- [TMDB 영화 상세](https://developer.themoviedb.org/reference/movie-details)

## 원본 트러블슈팅 양식 — 복사 초안

작업: 수정 / 조회 / 다중 삭제

요청 Method·Path(비밀번호 제거):
PATCH /v6/members/{본인 memberId}/ratings/{ratingId}, 이후 GET /v6/members/{본인 memberId}/ratings

요청 body(민감 정보 제거):
{"score": 5, "comment": "수정 후 서버 재조회 확인"}

기대 status·body:
PATCH 200 + 공통 응답, GET 200 + 수정된 평점 배열.
목록 확인이나 재시도 후 편집·다중 삭제 버튼을 정상 조작할 수 있어야 한다.

실제 status·code·message:
서버 쓰기 자체는 정상 처리되었다. 실패 주입 검증에서 저장 후 GET 실패 안내 Snackbar가 남아 하단 다중 삭제 버튼을 가렸다.
또한 자동화에서는 Dialog pop 애니메이션 완료 전 다음 버튼을 누르면 아직 남은 modal barrier에 입력이 차단되는 상황을 확인했다.

화면 상태:
저장 결과와 목록 상태는 구분되었으나, 이전 안내 또는 닫히는 중인 Dialog가 다음 조작과 겹쳤다.

원인과 수정:
재시도·편집 진입 시 이전 Snackbar를 정리했다. 테스트는 실제 프레임을 진행해 Dialog 전환 완료 후 조작·캡처하도록 보완했다.
저장 성공 후 GET 실패는 refreshWarning으로만 표시하고 Dialog에서는 성공으로 종료하여 쓰기 요청이 반복되지 않도록 했다.

재검증:
실패 주입 Android 시나리오에서 입력 보존, 조회만 재시도했을 때 쓰기 횟수 불변, 편집 선택과 일부 삭제 실패 후 선택 유지·로딩 해제를 검증했다.
실제 서버 시나리오와 실패 주입 시나리오는 증빙 이름과 설명으로 구분했다.

## 제출 양식 초안

PR 링크: PR 생성 후 실제 URL 기입

생성한 본인 테스트 계정(비밀번호 제외):
memberId 18 / nickname smw4ooi9q / email lea.w7.second.mw4ooi9q@example.com.
테스트 전용 가상 이메일이며 비밀번호는 기록하지 않는다. 중복·소유자 오류 재현용 본인 계정은 memberId 17이다.

닉네임/이메일 확인과 입력 변경 무효화:
두 GET available=true와 로컬 검증을 모두 통과해야 가입 버튼이 활성화된다. 입력 변경 시 확인 결과와 서버 오류를 무효화한다. 01 및 단위/위젯 테스트 참조.

회원가입 결과와 최종 409:
POST 201의 result.memberId를 세션에 저장했다. 두 확인을 통과한 뒤 같은 테스트 값을 별도 요청으로 먼저 등록하여 최종 POST409를 재현했다. 02/03 및 실제 요청 로그 참조.

선택한 TMDB id → MovieLog movieId 증거:
영화 카드의 실제 TmdbMovieDto를 extra로 전달한다. JSON의 movieId와 POST body.movieId, GET 평점.movieId가 동일함을 확인했다.
최종 검증 영화는 다크 나이트, TMDB movieId 155이며 생성된 ratingId는 12이다. 두 ID는 서로 다른 용도이다.

등록→조회→수정→조회→삭제→조회 증거:
실제 CRUD 영상과 04~11, 실제 API JSON. 삭제 취소는 DELETE 요청 0회, 최종 삭제는 204 및 GET 빈 배열로 확인했다.

오류 code 처리 증거:
실제 v6 400/403/404/409 요청·응답과 오류별 ViewModel 테스트. 403은 본인 테스트 계정 2개 사이에서 자기 평점에 대해서만 재현했다. 타인 데이터를 읽거나 수정하지 않았다.

저장 성공/재조회 실패 분리 증거:
12~14 및 복구 영상. 실패 주입으로 재현했으며, GET 재시도 전후 쓰기 횟수가 변하지 않는 것을 검증했다.

트러블슈팅:
위 트러블슈팅 기록과 코드·공식 레퍼런스 참조.

미검증 항목:
iOS·물리 기기 실행, JWT 로그인은 수행하지 않았다. JWT는 다음 인증 주차 범위이다.
조회 실패·부분 삭제 실패는 서버 장애를 유발하지 않고 테스트용 Service로 재현했다.

## 사용자에게 남는 일

1. 이 결과와 별도 Notion 작성 계획을 검토·승인하기.
2. 승인 후 원본의 첨부 이미지/영상이 실제로 열리는지 최종 확인하기.
3. 본인이 이해한 내용·후기를 확인하고 필요하면 수정하기.
4. UMC 피드백 시스템에 원본 페이지 URL을 **직접 제출**하기. 에이전트는 제출하지 않는다.

수동 확인을 자동화 실행과 같은 것으로 쓰지 않습니다. Guided/Required 항목은 테스트로 검증했지만,
사용자가 직접 화면을 조작하는 최종 수동 확인은 별도로 남습니다. 따라서 최종 체크리스트의 마지막
‘flutter analyze와 Guided/Required 수동 검증’ 항목은 본인 확인 전 자동으로 체크하지 않습니다.
확인할 때는 회원가입의 두 중복 확인→가입→영화 선택→평점·코멘트 등록→마이페이지 조회→수정→삭제 취소→삭제 순서로 실행합니다.
앱 재시작 시 학습용 회원 ID가 초기화되는 것은 의도한 동작입니다. 실제 로그인/기존 회원 복구는 다음 인증 주차 범위입니다.

공개 실습 서버에는 회원 삭제 API가 없으므로 생성한 테스트 회원은 남는다. 평점은 검증 후 삭제한다.
재시도 과정에서 만들어진 테스트 회원도 실제 사용자 계정으로 사용하지 않으며 비밀번호는 저장하지 않는다.
캡처 자동화 보완을 포함한 7회 실행에서 테스트 회원 총 14개가 생성됐다. 최종 증빙은 마지막 계정 17·18만 사용한다.
중단된 실행의 회원 10/rating 8, 회원 12/rating 9는 내용·ID를 확인해 정리했고, 완료 실행의 평점도 모두 삭제했다.

## 변경 파일 전체 목록

[changed-files.txt](evidence/week7-frontend/changed-files.txt)에 코드·테스트·문서·증빙의 전체 경로를 기록했다.
이전 주차 파일 삭제는 없으며, 기존 4주차 사용자 미추적 파일은 이 목록에 포함하지 않는다.
