import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import type { RowDataPacket } from 'mysql2/promise';
import { BookService } from './book.service.js';

@Controller('books')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @Get()
  async getBooks(): Promise<RowDataPacket[]> {
    return this.bookService.getAllBooks();
  }

  @Get('category/:categoryId')
  async getBooksByCategory(
    @Param('categoryId') categoryId: string,
  ): Promise<RowDataPacket[]> {
    return this.bookService.getBooksByCategory(categoryId);
  }

  @Post()
  async createBook(@Body() body: Record<string, unknown>): Promise<{
    message: string;
    bookId: number;
  }> {
    return this.bookService.createBook(body);
  }
}
