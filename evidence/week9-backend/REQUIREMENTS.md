# 원본 워크북 검토 — 9주차 백엔드
- 원본: https://app.notion.com/p/makeus-challenge/9-dd2b57f4596b825d83dc018f8b2553da
- 제목: 9주차 - 함께 테스트하고 다듬기
- 검토일: 2026-11-27~28. MakeUs 게스트 원본을 브라우저에서 읽음. 원본 내용/체크박스 수정 안 함.
- main: local 2445f60, origin/main a10ad32. 최신 주차가 main에 없어 codex/week-9-frontend(b88ce34) 기반 codex/week-9-backend.
- 기존 미추적 backend/evidence/week4-postman/, evidence/week4/flutter_analyze.local.txt, evidence/week7-frontend/submission-responses/, infra/ 보존·제외.

## 본문 실습 1~6
1. Swagger /swagger-ui, 공개·보호 API 및 Bearer 설정. 기존 /docs 보존.
2. 공개 POST /members, POST /auth/login의 요청/성공/실패 예시.
3. 보호 POST /favorites의 토큰 필요 여부, Authorize 실제 실행 201와 반복 409.
4. Fake Repository 단위 2개: 신규 저장; 중복 FAVORITE409_1 및 save 미호출.
5. 실제 sql.js 메모리 DB 통합 4개: 무인증401/AUTH401_2, 인증201, 중복409/FAVORITE409_1, 미등록영화 조회200/isFavorite=false.
6. 중복 검사 제거 → 단위·통합 모두 실패 → 복원 후 통과. 컴파일 산출물 임시 변형으로 재현하며 원본 TS와 최종 산출물 보존.

## Required Mission
- 기존 평점 POST/PATCH/DELETE, 회원별 평점 GET, 내 정보 GET/PATCH, 즐겨찾기 GET/status/DELETE 문서화.
- API 요약·인증 여부·실패 HTTP 및 code.
- 평점 단위2: 같은 영화 중복 RATING409_1; 타인 평점 수정 RATING403_1.
- 평점 통합2: 무토큰 POST401; 인증 POST201.
- Swagger 사진 + 테스트 코드 + 전체 통과 출력.

## Challenge / 선택 미션
- 기존 즐겨찾기 + addToFavorites=true → FAVORITE409_1, 평점 개수 불변.
- 이 사전 검사만으로는 롤백 증명이 안 됨: 실제 메모리 DB trigger로 두 번째 INSERT 실패를 유도하여 첫 INSERT 롤백 확인.
- 트랜잭션 제거 → rating 1건 잔존으로 테스트 실패, 복원 → 통과.
- 실제 MySQL에서도 트랜잭션 안에서 평점을 확인한 후 두 번째 save에 제어된 실패 주입 → 저장0건.

## 증빙 및 사용자 영역
- 실습 인증: 전체Swagger+favorites확장, 실제201/409, 전체 테스트 통과, 의도적인 중복 실패와 이유.
- 필수: 평점 문서 및 코드·통과 결과. 선택: 롤백 코드·통과·트랜잭션 제거 실패.
- 미션 기록: 최종 산출물만이 아닌 기존상태→구현선택→실행→실패실험→복원→결론.
- 핵심키워드6, 학습후기, 체크리스트7, 트러블슈팅 작성 가이드.
- 실제 스터디 인증 사진은 사용자만 추가 가능. 제출은 사용자가 진행.
- 로그 이미지는 실제 TXT를 이미지화한 문서이며 터미널 캡처라고 표시하지 않음.
