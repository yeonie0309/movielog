import type { Pool } from 'mysql2/promise';
import { RentalRepository } from './rental.repository.js';

describe('RentalRepository', () => {
  it('현재 시각과 7일 뒤 반납 예정일을 Raw SQL로 생성한다', async () => {
    const execute = vi.fn().mockResolvedValue([{ insertId: 3 }, []]);
    const repository = new RentalRepository({ execute } as unknown as Pool);

    const rentalId = await repository.create(1, 2);

    expect(execute).toHaveBeenCalledWith(
      expect.stringMatching(/NOW\(\).*DATE_ADD\(NOW\(\), INTERVAL 7 DAY\)/s),
      [1, 2],
    );
    expect(rentalId).toBe(3);
  });

  it('반납할 rentalId를 UPDATE SQL에 바인딩한다', async () => {
    const execute = vi.fn().mockResolvedValue([{ affectedRows: 1 }, []]);
    const repository = new RentalRepository({ execute } as unknown as Pool);

    const affectedRows = await repository.returnRental(7);

    expect(execute).toHaveBeenCalledWith(
      expect.stringContaining('SET returned_at = NOW()'),
      [7],
    );
    expect(affectedRows).toBe(1);
  });
});
