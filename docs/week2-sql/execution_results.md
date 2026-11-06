# MySQL 8.4 실행 결과

검증 환경은 기존 로컬 데이터와 분리한 `mysql:8.4` 컨테이너다.

## 환경 및 시드

- MySQL: `8.4.10`
- 생성 테이블: `book`, `book_like`, `book_tag`, `category`, `notification`,
  `rental`, `tag`, `users`
- 행 수: users 2, category 2, book 3, rental 2, tag 3, book_tag 3,
  book_like 2, notification 2

## 단일 테이블 조회

| book_id | title | description |
| ---: | --- | --- |
| 3 | 우주를 읽는 법 | 과학 교양 |
| 1 | 달빛 도서관 | 소설 |

`book`만 사용해 대여 가능한 도서가 최신 ID 순으로 조회되므로 체크리스트와
일치한다.

## 미션 1

| title | description | category_name |
| --- | --- | --- |
| 달빛 도서관 | 소설 | 문학 |

문학 카테고리에서 대여 가능한 책만 조회되므로 요구사항과 일치한다.

## 미션 2

| title | rented_at | due_at |
| --- | --- | --- |
| 겨울의 편지 | 2026-08-10 10:00:00 | 2026-08-17 10:00:00 |

사용자 1이 아직 반납하지 않은 대여 기록만 반납 예정일 순으로 조회되므로
요구사항과 일치한다.

## 미션 3

| title | tag_name | is_liked |
| --- | --- | --- |
| 달빛 도서관 | 추천 | 1 |
| 달빛 도서관 | 소설 | 1 |

책 1의 모든 태그와 사용자 1의 좋아요 여부가 함께 조회되므로 요구사항과
일치한다.

## LIMIT/OFFSET

| book_id | title | description |
| --- | --- | --- |
| 3 | 우주를 읽는 법 | 과학 교양 |
| 2 | 겨울의 편지 | 에세이 |
| 1 | 달빛 도서관 | 소설 |

`book_id DESC LIMIT 10 OFFSET 0`이 적용되어 첫 페이지가 일관된 최신순으로
조회된다.

## MovieLog 확장 미션

| store_name | mission_title | reward_points | member_mission_status |
| --- | --- | ---: | --- |
| 마포 맛집 | 한식 메뉴 주문하기 | 500 | in_progress |
| 무비 카페 | 카페 방문 인증하기 | 300 | accepted |

완료된 미션은 제외되고 회원 1의 진행 가능한 미션만 높은 보상 포인트 순으로
조회되므로 확장 요구사항과 일치한다.
