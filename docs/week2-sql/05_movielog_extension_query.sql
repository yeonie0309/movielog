-- 자신의 1주차 MovieLog ERD 확장 미션
-- 요구사항: 로그인한 회원이 수행 중인 미션을 보상 포인트가 높은 순으로
--           최대 10개 보여 준다.

SET @member_id = 1;

SELECT
    s.name AS store_name,
    m.title AS mission_title,
    m.minimum_order_amount,
    m.reward_points,
    mm.status AS member_mission_status,
    mm.accepted_at
FROM member_missions AS mm
JOIN missions AS m ON m.id = mm.mission_id
JOIN stores AS s ON s.id = m.store_id
WHERE mm.member_id = @member_id
  AND mm.status IN ('accepted', 'in_progress', 'verification_requested')
  AND m.status = 'active'
  AND m.deleted_at IS NULL
  AND s.deleted_at IS NULL
ORDER BY m.reward_points DESC, mm.id DESC
LIMIT 10 OFFSET 0;

-- 기준 테이블은 회원별 수행 상태가 저장된 member_missions다.
-- 화면에 가게명과 미션 정보가 필요하므로 missions와 stores를 PK/FK로 JOIN한다.
-- 로그인 회원과 진행 가능한 상태만 남기고, 보상 포인트 내림차순과 매핑 ID
-- 내림차순으로 순서를 고정한 뒤 최대 10개만 조회한다.
