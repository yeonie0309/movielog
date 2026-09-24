import { Inject, Injectable } from '@nestjs/common';
import type { Pool, ResultSetHeader } from 'mysql2/promise';
import { DATABASE_CONNECTION } from '../database/database.constants.js';

@Injectable()
export class RentalRepository {
  constructor(@Inject(DATABASE_CONNECTION) private readonly pool: Pool) {}

  async create(userId: number, bookId: number): Promise<number> {
    const sql = `
      INSERT INTO rental (user_id, book_id, rented_at, due_at, returned_at)
      VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), NULL)
    `;
    const [result] = await this.pool.execute<ResultSetHeader>(sql, [
      userId,
      bookId,
    ]);
    return result.insertId;
  }

  async returnRental(rentalId: number): Promise<number> {
    const sql = `
      UPDATE rental
      SET returned_at = NOW()
      WHERE rental_id = ? AND returned_at IS NULL
    `;
    const [result] = await this.pool.execute<ResultSetHeader>(sql, [rentalId]);
    return result.affectedRows;
  }
}
