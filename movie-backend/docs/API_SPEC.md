# 5주차 MovieLog API 명세

출처: [레아의 워크북 — 화면과 API를 처음 연결하기](https://app.notion.com/p/72339bc4fcc782d69bce01a87b351526)

Base URL: `http://localhost:3000` (Android 에뮬레이터: `http://10.0.2.2:3000`)
인증: 이번 주차는 로그인 전 조회 실습. TMDB 토큰을 보내지 않습니다.

| 이름 | Method / URL | Request | 성공 응답 |
| --- | --- | --- | --- |
| 닉네임 중복 확인 | `GET /members/nickname/{nickname}` | Path string, 2~12자 | 200 `{ "available": boolean }` |
| 이메일 중복 확인 | `GET /members/email/{email}` | Path string, 이메일 형식, 최대 254자 | 200 `{ "available": boolean }` |
| 회원별 평점 | `GET /members/{memberId}/ratings` | Path 양의 정수; 선택 Query `page>=0`, `1<=size<=100` | 200 `RatingResponse[]`, `ratingId DESC` |

중복이면 `available=false`, 없으면 `true`. 한글·이메일 경로 값은 클라이언트에서
URL 인코딩합니다. 값에 큰따옴표를 추가하면 다른 닉네임이 되므로 추가하지 않습니다.

```json
[
  {
    "ratingId": 2,
    "movieId": 155,
    "score": 4,
    "comment": "다시 봐도 명작",
    "createdAt": "2026-10-02T10:00:00.000Z",
    "updatedAt": "2026-10-02T10:00:00.000Z"
  }
]
```

- `ratingId`, `movieId`, `score`: JSON number. `comment`: string 또는 null.
- 날짜는 UTC ISO 8601 string. 회원·비밀번호·Entity 관계 객체는 응답하지 않습니다.
- 기존 회원에게 평점이 없으면 200 `[]`; 회원이 없으면 404.
- 형식 오류는 400. DB 내부 오류는 NestJS 기본 500 응답으로 내부 상세를 숨깁니다.
- 페이지 인자가 없으면 전체 배열. 하나라도 지정하면 기본 `page=0`, `size=10`으로
  `skip/take`를 적용합니다. 배열 응답 계약은 유지합니다.
- CORS 허용 출처: `http://localhost:5173`. OPTIONS preflight도 처리합니다.
- `Origin` 미허용은 브라우저가 응답을 읽지 못하게 하며, Postman/네이티브 앱의
  접근 권한 통제나 회원 인증을 대신하지 않습니다.
- DB: 별도 `umc_movie`, `synchronize: false`. Member/Rating Entity와
  공통 BaseTimeEntity를 사용합니다. Favorite은 SQL 스키마만 준비합니다.

ERD: [erd.svg](../../mock-frontend/erd.svg)

## 공식 참고 자료

- [NestJS 데이터베이스](https://docs.nestjs.com/techniques/database)
- [NestJS CORS](https://docs.nestjs.com/security/cors)
- [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)
