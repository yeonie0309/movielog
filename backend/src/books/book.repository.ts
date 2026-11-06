import { Inject, Injectable } from '@nestjs/common';
import type { Pool, ResultSetHeader, RowDataPacket } from 'mysql2/promise';
import { DATABASE_CONNECTION } from '../database/database.constants.js';

@Injectable()
export class BookRepository {
  constructor(@Inject(DATABASE_CONNECTION) private readonly pool: Pool) {}

  async findAll(): Promise<RowDataPacket[]> {
    const sql = 'SELECT * FROM book ORDER BY book_id ASC';
    const [rows] = await this.pool.query<RowDataPacket[]>(sql);
    return rows;
  }

  async findByCategoryId(categoryId: number): Promise<RowDataPacket[]> {
    const sql = 'SELECT * FROM book WHERE category_id = ? ORDER BY book_id ASC';
    const [rows] = await this.pool.execute<RowDataPacket[]>(sql, [categoryId]);
    return rows;
  }

  async create(
    categoryId: number,
    title: string,
    description: string | null,
  ): Promise<number> {
    const sql =
      'INSERT INTO book (category_id, title, description, is_available) VALUES (?, ?, ?, TRUE)';
    const [result] = await this.pool.execute<ResultSetHeader>(sql, [
      categoryId,
      title,
      description,
    ]);
    return result.insertId;
  }
}
