-- docs/week1-data-modeling/schema.sql을 movielog_week2 DB에 실행한 뒤 사용한다.
SET NAMES utf8mb4;

INSERT INTO regions (id, parent_region_id, code, name, depth)
VALUES
    (1, NULL, 'SEOUL', '서울특별시', 1),
    (2, 1, 'MAPO', '마포구', 2);

INSERT INTO food_categories (id, code, name, display_order)
VALUES
    (1, 'KOREAN', '한식', 1),
    (2, 'CAFE', '카페', 2);

INSERT INTO members (
    id, region_id, email, name, nickname, gender, birth_date, status
)
VALUES
    (1, 2, 'lea@example.com', '이가연', '레아', 'female', '2000-01-01',
     'active');

INSERT INTO stores (
    id, region_id, food_category_id, name, address, status
)
VALUES
    (1, 2, 1, '마포 맛집', '서울특별시 마포구 월드컵로 1', 'open'),
    (2, 2, 2, '무비 카페', '서울특별시 마포구 월드컵로 2', 'open');

INSERT INTO missions (
    id, store_id, title, description, minimum_order_amount, reward_points,
    started_at, ended_at, status
)
VALUES
    (1, 1, '한식 메뉴 주문하기', '대표 메뉴를 주문하고 인증해 주세요.',
     15000.00, 500, '2026-09-01 00:00:00', '2026-09-30 23:59:59',
     'active'),
    (2, 2, '카페 방문 인증하기', '음료를 주문하고 방문을 인증해 주세요.',
     8000.00, 300, '2026-09-01 00:00:00', '2026-09-30 23:59:59',
     'active'),
    (3, 1, '완료된 과거 미션', '완료 상태 필터 확인용 데이터입니다.',
     10000.00, 100, '2026-08-01 00:00:00', '2026-08-31 23:59:59',
     'ended');

INSERT INTO member_missions (
    id, member_id, mission_id, status, accepted_at, completed_at
)
VALUES
    (1, 1, 1, 'in_progress', '2026-09-10 10:00:00', NULL),
    (2, 1, 2, 'accepted', '2026-09-11 10:00:00', NULL),
    (3, 1, 3, 'completed', '2026-08-10 10:00:00', '2026-08-15 12:00:00');
