-- 공통 실습 Required Mission 3개와 LIMIT/OFFSET 확인 쿼리
SET NAMES utf8mb4;
USE umc_week2_library;

-- 실습 체크리스트: 단일 테이블에서 대여 가능한 책 조회
SELECT
    b.book_id,
    b.title,
    b.description
FROM book AS b
WHERE b.is_available = TRUE
ORDER BY b.book_id DESC;

-- 미션 1
-- 요구사항: 문학 카테고리의 대여 가능한 도서를 최신순으로 10개 조회한다.
-- 기준 테이블: book
-- JOIN 이유: 카테고리 이름은 category에 있으므로 book.category_id와 연결한다.
-- 조건/정렬·범위: 문학, 대여 가능 / book_id 내림차순 / 최대 10개
SELECT
    b.title,
    b.description,
    c.name AS category_name
FROM book AS b
JOIN category AS c ON c.category_id = b.category_id
WHERE c.name = '문학'
  AND b.is_available = TRUE
ORDER BY b.book_id DESC
LIMIT 10;

-- 미션 2
-- 요구사항: 특정 사용자가 아직 반납하지 않은 책을 반납 예정일 순으로 조회한다.
-- 기준 테이블: rental
-- JOIN 이유: 대여 기록에는 제목이 없으므로 rental.book_id로 book과 연결한다.
-- 조건/정렬: 사용자 1, returned_at IS NULL / due_at 오름차순
SET @user_id = 1;

SELECT
    b.title,
    r.rented_at,
    r.due_at
FROM rental AS r
JOIN book AS b ON b.book_id = r.book_id
WHERE r.user_id = @user_id
  AND r.returned_at IS NULL
ORDER BY r.due_at ASC, r.rental_id ASC;

-- 미션 3
-- 요구사항: 특정 책의 태그 목록과 특정 사용자의 좋아요 여부를 조회한다.
-- 기준 테이블: book
-- JOIN 이유: 태그 N:M은 book_tag와 tag를, 좋아요 N:M은 book_like를 거친다.
-- 조건/정렬: 책 1, 사용자 1 / 태그 이름 오름차순
SET @book_id = 1;
SET @user_id = 1;

SELECT
    b.title,
    t.name AS tag_name,
    (bl.user_id IS NOT NULL) AS is_liked
FROM book AS b
LEFT JOIN book_tag AS bt ON bt.book_id = b.book_id
LEFT JOIN tag AS t ON t.tag_id = bt.tag_id
LEFT JOIN book_like AS bl
    ON bl.book_id = b.book_id
   AND bl.user_id = @user_id
WHERE b.book_id = @book_id
ORDER BY t.name ASC, t.tag_id ASC;

-- 추가 실습: 일관된 페이지네이션
-- 첫 페이지는 OFFSET 0, 두 번째 페이지는 OFFSET 10으로 바꿔 실행한다.
SELECT
    b.book_id,
    b.title,
    b.description
FROM book AS b
ORDER BY b.book_id DESC
LIMIT 10 OFFSET 0;
