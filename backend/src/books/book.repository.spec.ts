import type { Pool } from 'mysql2/promise';
import { BookRepository } from './book.repository.js';

describe('BookRepository', () => {
  it('카테고리 ID를 문자열 조합 없이 바인딩한다', async () => {
    const execute = vi.fn().mockResolvedValue([[{ book_id: 1 }], []]);
    const repository = new BookRepository({ execute } as unknown as Pool);

    await repository.findByCategoryId(2);

    expect(execute).toHaveBeenCalledWith(
      expect.stringContaining('WHERE category_id = ?'),
      [2],
    );
  });

  it('도서 입력값을 INSERT SQL과 분리해 바인딩한다', async () => {
    const execute = vi.fn().mockResolvedValue([{ insertId: 4 }, []]);
    const repository = new BookRepository({ execute } as unknown as Pool);
    const maliciousTitle = "'); DROP TABLE book; --";

    const bookId = await repository.create(
      1,
      maliciousTitle,
      'parameter binding test',
    );

    const [sql, params] = execute.mock.calls[0] as [string, unknown[]];
    expect(sql).toContain('VALUES (?, ?, ?, TRUE)');
    expect(sql).not.toContain(maliciousTitle);
    expect(params).toEqual([1, maliciousTitle, 'parameter binding test']);
    expect(bookId).toBe(4);
  });
});
