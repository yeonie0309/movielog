# 5주차 백엔드 제출 가이드

원본 학습 페이지: [5주차 — 화면과 API를 처음 연결하기](https://app.notion.com/p/72339bc4fcc782d69bce01a87b351526)

## 브랜치와 구현 범위

- 시작 상태: 로컬·원격 main은 `2445f60` 초기 설정 커밋. 기존 작업은 주차별 브랜치에 존재.
- `feature/week-5-backend`를 최신 `origin/feature/week-5-frontend`에서 만들고
  `feature/week-4-backend`를 통합했습니다. main은 수정하지 않았습니다.
- 기존 도서 서비스 `backend/`는 보존하고 새 NestJS 프로젝트 `movie-backend/`를 생성했습니다.
- 새 DB `umc_movie`에 member, rating, favorite와 더미 데이터를 준비했습니다.
- Favorite은 이번 주차 안내대로 스키마만 만들고 Entity/API는 8주차 범위로 남겼습니다.
- TMDB 영화 정보는 기존 Flutter의 TMDB Client가 조회하고, 자체 API는 회원·평점만 담당합니다.
- 선택 실습인 닉네임·이메일 형식 검증과 평점 페이지네이션을 구현했습니다.
- CORS는 localhost:5173만 허용하며, 미허용 출처 차단도 확인했습니다.
- push/PR은 아직 수행하지 않았습니다. 예정 제목: `feat: 5주차 영화 평점 API와 화면 연동 구현`.

## 요구사항과 확인 위치

| 요구사항 | 구현·증빙 |
| --- | --- |
| 새 영화 서비스 프로젝트, 레이어 분리 | movie-backend/src의 controller/service/repository/entity/dto |
| 전체 ERD와 SQL·시드 | mock-frontend/erd.svg, movie-backend/sql/01_schema.sql·02_seed.sql |
| Member·Rating·공통 시간 Entity | movie-backend/src/entity |
| DTO 응답 및 API 계약 | movie-backend/src/dto, movie-backend/docs/API_SPEC.md |
| 닉네임·이메일 중복 확인 | MemberController → MemberService → TypeORM Repository |
| 회원별 평점 최신순, 없는 회원 404 | RatingController → RatingService → TypeORM Repository |
| CORS 미설정·적용 전후 | evidence/week5-backend/04·05 이미지와 cors-before-console.txt |
| 실제 화면에 모든 API 연결 | 회원가입의 중복 확인 2개 + 마이페이지의 회원별 평점 조회 |
| Postman과 실제 앱 캡처 | evidence/week5-backend/README.md |

## 검증 결과

- 새 백엔드 `npm run lint`, `npm run build`, HTTP E2E `npm test` 8개 통과.
- 실제 API 요청 12건과 member/rating/favorite 스키마·UNIQUE 제약 확인 통과.
- Flutter 전체 테스트 38개 통과.
- Android 실제 NestJS·MySQL 통합 테스트 1개 통과, 앱 화면 5장 자동 캡처.
- 기존 4주차 백엔드 lint/build, unit 6개·E2E 8개 통과.
- `flutter analyze --no-fatal-infos`: 종료 코드 0. 기존 0주차 avoid_print info 2건,
  이번 변경의 error/warning 없음. 일반 `flutter analyze`가 완전히 깨끗하다는 뜻은 아닙니다.
- 비밀값 검사는 로컬 환경 변수를 출력하지 않고 추적·미추적 소스 파일을 검사합니다.

## 직접 해야 할 일과 Notion 첨부 위치

1. MakeUs 원본의 레아의 워크북 → 5주차 백엔드 페이지를 엽니다.
2. **스터디 인증샷**: 실제 스터디 사진을 첨부합니다. 이미 같은 주차 사진이 있으면 재촬영할 필요 없습니다.
3. **실습 인증**: 증빙 README의 첫 표에 있는 Postman 11·12·13번과 CORS Console 04·05번을 올립니다.
4. **미션 기록**: 아래 진행 과정과 실제 Flutter 06·07·08번을 올립니다.
   09·10번은 빈 목록·404 추가 검증, 18번은 이번 영화 서비스의 새 ERD입니다.
   핵심 Entity·DTO·Controller·Service 코드를 파일에서 코드 블록으로 복사하거나 PR 생성 후 링크합니다.
5. **핵심 키워드 / 학습 후기 / 트러블 슈팅**: 아래 초안을 각각 해당 칸에 복사합니다.
   학습 후기는 본인이 실제로 이해한 내용에 맞게 다듬습니다.
6. 첨부 후 아래 실습 체크리스트를 확인합니다. 체크 행위 자체는 원본 Notion에서 직접 합니다.
7. 미션 제출 안내에 따라 본인의 원본 Notion 페이지 링크를 UMC 피드백 시스템에 제출합니다.
   사이트 제출은 본인 계정으로 진행합니다. PR 링크를 넣는 별도 칸은 이번 페이지의 필수 양식에 없습니다.

사진·실행 결과는 이미 만들었으므로 Postman 재실행이나 재캡처는 필수가 아닙니다.

## 실습 체크리스트 체크 가능 여부

워크북의 **5개 실습 항목은 모두 검증 완료**했습니다.

- [x] 로컬 MySQL member/rating/favorite 및 시드
- [x] Postman 닉네임·이메일 중복 확인 available 응답
- [x] Postman 회원별 평점 최신순 조회
- [x] CORS 설정 전 실제 Console 오류
- [x] CORS 설정 후 동일 간이 프론트 정상 응답

원본 페이지에는 해당 증빙을 첨부한 뒤 체크하세요. 스터디 인증은 실제 사진을 넣은 경우에만
완료로 표시하며, 본인이 읽거나 설명하지 않은 학습 항목까지 일괄 체크하지 않습니다.

## 핵심 코드

- `movie-backend/src/entity/base-time.entity.ts`: 생성·수정 시간 공통 부모
- `movie-backend/src/entity/member.entity.ts`: email/nickname UNIQUE, password 기본 조회 제외
- `movie-backend/src/entity/rating.entity.ts`: Member FK, TMDB movieId, 회원·영화 복합 UNIQUE
- `movie-backend/src/dto/check-response.dto.ts`, `rating-response.dto.ts`: 필요한 필드만 응답
- `movie-backend/src/controller/member.controller.ts`, `rating.controller.ts`: HTTP 계약과 입력 검증
- `movie-backend/src/service/member.service.ts`, `rating.service.ts`: Repository 조회와 DTO 변환
- `movie-backend/src/app.module.ts`, `configure-app.ts`: ORM 등록, synchronize=false, CORS
- `lib/core/network/movielog_client.dart`: TMDB와 분리한 자체 API Client
- `lib/data/services/member_api_service.dart`: Flutter에서 자체 API 3개 호출

## 변경 파일 목록

새 프로젝트 `movie-backend/`:

- 설정: `.gitignore`, `.env.example`, `package.json`, `package-lock.json`, `tsconfig.json`
- 실행·DI: `src/main.ts`, `src/app.module.ts`, `src/configure-app.ts`
- Entity: `src/entity/base-time.entity.ts`, `member.entity.ts`, `rating.entity.ts`
- DTO: `src/dto/check-response.dto.ts`, `member-params.dto.ts`, `rating-response.dto.ts`, `ratings-query.dto.ts`
- Controller: `src/controller/member.controller.ts`, `rating.controller.ts`
- Service: `src/service/member.service.ts`, `rating.service.ts`
- Repository 설명: `src/repository/README.md`
- SQL: `sql/01_schema.sql`, `sql/02_seed.sql`
- 검증: `test/api.test.cjs`, `scripts/verify-live.cjs`, `scripts/verify-secrets.cjs`, `scripts/capture-app.cjs`
- 문서·Postman: `README.md`, `docs/API_SPEC.md`, `postman/MovieLog-week5.postman_collection.json`

Flutter 신규:

- `lib/core/network/movielog_client.dart`
- `lib/data/models/member_rating.dart`
- `lib/data/services/member_api_service.dart`
- `lib/screens/member_ratings_screen.dart`
- `lib/widgets/sign_up/availability_check.dart`
- `test/week5_member_api_test.dart`
- `integration_test/week5_backend_live_test.dart`

Flutter 수정:

- `lib/movie_log_app.dart`: 자체 API Provider 등록
- `lib/router/app_router.dart`: 회원별 평점 경로 추가
- `lib/screens/sign_up_screen.dart`: 중복 확인 버튼 2개
- `lib/screens/my_page_screen.dart`: 회원별 평점 조회 진입 버튼

그 외:

- `mock-frontend/index.html`, `mock-frontend/erd.svg`
- `evidence/week5-backend/`: 실행 캡처와 실제 검증 기록
- `WEEK5_BACKEND_SUBMISSION_GUIDE.md`
- `README.md`: 새 백엔드 실행·제출 자료 링크

기존 4주차 백엔드의 22개 파일은 `feature/week-4-backend` 병합으로 가져온 기존 구현이며,
이번 주차에서 도서 API를 새 영화 API로 덮어쓰지 않았습니다.
작업 전부터 존재한 `backend/evidence/week4-postman/`와 `evidence/week4/flutter_analyze.local.txt`는 수정하지 않았습니다.

## 핵심 키워드 — 복사용

### SOP와 CORS

SOP는 브라우저가 다른 출처의 응답을 JavaScript에서 읽는 것을 제한하는 정책이다.
CORS는 서버가 응답 헤더로 허용 출처를 알려 브라우저가 그 응답을 읽을 수 있도록 하는 방식이다.
단순 요청은 서버에 도달해도 브라우저가 응답 읽기를 차단할 수 있고, preflight가 필요한 요청은
사전 OPTIONS 확인이 실패하면 본 요청이 보내지지 않을 수 있다. 이번에는 CORS 미설정 시
실제 Console 오류를 확인하고 localhost:5173을 허용한 뒤 같은 화면의 정상 응답을 확인했다.
Postman과 네이티브 Flutter는 브라우저의 CORS 정책을 적용받지 않는다.

### Same-Origin과 Same-Site의 차이

Same-Origin은 프로토콜·호스트·포트가 모두 같은 경우다. localhost:5173과 localhost:3000은
포트가 달라 cross-origin이다. 현대 브라우저의 Same-Site는 프로토콜과 등록 가능 도메인을
기준으로 하므로 서브도메인·포트가 달라도 같은 사이트일 수 있다.
같은 사이트라고 해서 같은 출처가 되는 것은 아니며 CORS 설정이 필요할 수 있다.

### 쿠키의 SameSite 속성

SameSite는 cross-site 요청에 쿠키를 보낼 조건을 정한다. Strict는 같은 사이트 요청으로
제한하고, Lax는 일부 안전한 최상위 탐색 요청에도 허용한다. None은 cross-site 전송을
허용하지만 Secure도 함께 설정해야 한다. SameSite와 CORS는 각각 쿠키 전송과 응답 읽기를
다루므로 서로 대체하지 않는다. 이번 주차는 로그인 전 조회 실습이어서 쿠키 인증은 구현하지 않았다.

### 복합 UNIQUE 제약을 사용하는 이유는?

각 컬럼은 반복될 수 있지만 두 값의 조합은 중복되면 안 될 때 사용한다.
rating과 favorite의 (member_id, movie_id)를 UNIQUE로 지정해 다른 회원은 같은 영화를
평가·즐겨찾기할 수 있으면서, 한 회원이 같은 영화를 중복 등록하지 못하도록 했다.
애플리케이션의 사전 조회만으로는 동시 요청을 막을 수 없으므로 DB 제약도 필요하다.

### 외부 Open API 연동 시 API Key를 프론트/백엔드 중 어디에 두어야 안전한가?

비밀로 유지해야 하는 키는 보통 백엔드 환경 변수·비밀 저장소에 보관하고 필요한 기능만
노출하는 편이 안전하다. 웹 번들이나 모바일 앱에 포함된 값은 사용자가 추출할 수 있다.
.env를 Git에서 제외하는 것은 저장소 노출을 막지만 배포 앱의 비밀값 보호까지 보장하지 않는다.
이번 학습은 워크북에 따라 Flutter가 TMDB를 직접 조회하고, 자체 API는 별도 Client로 호출해
TMDB 토큰을 자체 서버에 전달하지 않도록 했다.

참고: [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS),
[MDN SameSite](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie),
[NestJS CORS](https://docs.nestjs.com/security/cors).

## 학습 후기 — 수정해서 사용할 초안

영화 정보는 TMDB에서 조회하고 회원·평점은 자체 백엔드에서 관리하도록 역할을 나누었다.
API 명세를 먼저 정하고 DTO를 맞추니 Flutter와 서버가 같은 필드 이름·타입으로 데이터를
주고받는 흐름을 확인할 수 있었다. Postman에서는 성공하던 요청이 브라우저에서 CORS로
막히는 상황을 직접 비교했고, 네이티브 앱과 브라우저의 차이도 이해할 수 있었다.
앞으로는 이번에 전달한 memberId를 로그인 사용자 정보로 대체하고 평점 저장 기능을 연결할 예정이다.

## 트러블 슈팅 — 복사용

**이슈**: Postman에서는 성공한 닉네임 조회가 간이 프론트의 fetch에서 실패했다.

**문제**: 프론트 localhost:5173과 API localhost:3001은 다른 출처인데,
서버에 CORS가 설정되지 않아 Access-Control-Allow-Origin 헤더가 없었다.
실제 Console에서 blocked by CORS policy 메시지를 확인했다.

**해결**: NestJS 공통 설정에서 localhost:5173을 허용하고 서버를 재시작했다.
같은 화면에서 닉네임·이메일·평점 API 모두 200 응답과 Console 오류 없음을 확인했다.
이는 실습을 위해 의도적으로 재현한 오류다.

**참고레퍼런스**: https://docs.nestjs.com/security/cors

## 미션 기록 — 복사용

1. git status와 main을 확인하고 feature/week-5-backend를 생성했다.
2. 기존 도서 서비스를 보존하고 별도 NestJS 영화 서비스 프로젝트를 만들었다.
3. Member·Rating·Favorite ERD를 설계하고 별도 MySQL DB에 스키마와 시드를 생성했다.
4. API 3개의 URL·입력·상태 코드·응답 DTO를 명세로 정리했다.
5. BaseTimeEntity·Member·Rating과 TypeORM Repository 주입을 구현했다.
6. 닉네임·이메일 중복 확인과 회원별 최신순 평점 조회를 만들었다.
7. 간이 프론트에서 CORS 오류를 재현한 뒤 허용 출처를 설정해 해결했다.
8. Flutter 회원가입 화면의 중복 확인 2개와 마이페이지의 평점 조회를 실제 API에 연결했다.
9. 선택 실습인 형식 검증 400과 page/size 페이지네이션을 추가했다.
10. HTTP 자동 테스트, 실제 MySQL 요청 12건, Flutter 테스트와 Android 실행을 확인하고
    Postman·CORS Console·실제 앱·ERD 증빙을 생성했다.

## 선택 미션 — CORS 허용 범위 설명

`*`는 인증 정보를 동반하지 않는 응답을 모든 출처의 브라우저 JavaScript가 읽을 수 있게 한다.
이번 구현은 `http://localhost:5173`만 허용하므로 같은 페이지라도 `http://127.0.0.1:5173`에서
실행하면 응답 읽기가 차단된다. 02번의 정상 응답과 17번의 미허용 출처 차단을 비교했다.
CORS는 인증이나 네이티브 앱 접근 제어가 아니므로 앞으로 로그인·권한 검증은 별도로 구현해야 한다.

## 남은 범위

- 회원가입 저장·로그인/JWT·평점 CRUD·Favorite Entity/API는 이후 주차 범위.
- 실기기·iOS·배포 환경은 이번 Android 에뮬레이터 검증에 포함하지 않음.
- 원본 MakeUs Notion 첨부, 실제 스터디 사진, UMC 사이트 제출은 직접 진행.
- PR은 아직 없으며 최종 코드 검토 뒤 별도 진행 가능.
