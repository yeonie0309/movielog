import { BadRequestException, Injectable } from '@nestjs/common';
import type { RowDataPacket } from 'mysql2/promise';
import { parsePositiveInteger } from '../common/parse-positive-integer.js';
import { BookRepository } from './book.repository.js';

@Injectable()
export class BookService {
  constructor(private readonly bookRepository: BookRepository) {}

  async getAllBooks(): Promise<RowDataPacket[]> {
    return this.bookRepository.findAll();
  }

  async getBooksByCategory(categoryIdValue: unknown): Promise<RowDataPacket[]> {
    const categoryId = parsePositiveInteger(categoryIdValue, 'categoryId');
    return this.bookRepository.findByCategoryId(categoryId);
  }

  async createBook(body: Record<string, unknown>): Promise<{
    message: string;
    bookId: number;
  }> {
    const categoryId = parsePositiveInteger(body.categoryId, 'categoryId');
    const title = typeof body.title === 'string' ? body.title.trim() : '';

    if (title.length === 0) {
      throw new BadRequestException('title is required');
    }

    const description =
      typeof body.description === 'string' ? body.description.trim() : null;
    const bookId = await this.bookRepository.create(
      categoryId,
      title,
      description,
    );

    return { message: '도서 등록이 완료되었습니다!', bookId };
  }
}
