USE umc_movie;
START TRANSACTION;
-- 로그인용 해시가 아닌 실습 전용 더미 문자열. 기존 회원을 덮어쓰지 않습니다.
INSERT INTO member (email, password, nickname)
SELECT 'noco@umc.com', '$2a$10$dummyEncodedPasswordValue', '수현'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'noco@umc.com' OR nickname = '수현');
INSERT INTO member (email, password, nickname)
SELECT 'minseo@umc.com', '$2a$10$dummyEncodedPasswordValue', '민서'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'minseo@umc.com' OR nickname = '민서');
INSERT INTO member (email, password, nickname)
SELECT 'empty@umc.com', '$2a$10$dummyEncodedPasswordValue', '빈목록'
WHERE NOT EXISTS (SELECT 1 FROM member WHERE email = 'empty@umc.com' OR nickname = '빈목록');

INSERT INTO rating (member_id, movie_id, score, comment, created_at, updated_at)
SELECT member_id, 550, 5, '최고의 영화!', '2026-10-01 10:00:00', '2026-10-01 10:00:00'
FROM member m WHERE email = 'noco@umc.com'
AND NOT EXISTS (SELECT 1 FROM rating r WHERE r.member_id=m.member_id AND r.movie_id=550);
INSERT INTO rating (member_id, movie_id, score, comment, created_at, updated_at)
SELECT member_id, 155, 4, '다시 봐도 명작', '2026-10-02 10:00:00', '2026-10-02 10:00:00'
FROM member m WHERE email = 'noco@umc.com'
AND NOT EXISTS (SELECT 1 FROM rating r WHERE r.member_id=m.member_id AND r.movie_id=155);
INSERT INTO rating (member_id, movie_id, score, comment, created_at, updated_at)
SELECT member_id, 550, 3, '호불호가 갈릴 것 같아요', '2026-10-03 10:00:00', '2026-10-03 10:00:00'
FROM member m WHERE email = 'minseo@umc.com'
AND NOT EXISTS (SELECT 1 FROM rating r WHERE r.member_id=m.member_id AND r.movie_id=550);
COMMIT;
