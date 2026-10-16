-- 4주차 선택 미션: 동일한 도서 제목의 중복 등록 방지
-- TypeORM synchronize는 false로 유지하고 명시적인 SQL로 스키마를 변경한다.

USE umc_week2_library;

SET @index_exists = (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'book'
      AND index_name = 'uk_book_title'
);

SET @create_index_sql = IF(
    @index_exists = 0,
    'ALTER TABLE book ADD CONSTRAINT uk_book_title UNIQUE (title)',
    'SELECT ''uk_book_title already exists'' AS message'
);

PREPARE create_index_statement FROM @create_index_sql;
EXECUTE create_index_statement;
DEALLOCATE PREPARE create_index_statement;
