import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { BookService } from './book.service.js';
import { BookResponseDto } from './dto/book-response.dto.js';
import { CreateBookDto } from './dto/create-book.dto.js';
import { GetBooksQueryDto } from './dto/get-books-query.dto.js';

@Controller('books')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @Get()
  async getBooks(@Query() query: GetBooksQueryDto): Promise<BookResponseDto[]> {
    return this.bookService.getBooks(query.keyword);
  }

  @Post()
  async createBook(@Body() body: CreateBookDto): Promise<BookResponseDto> {
    return this.bookService.createBook(body);
  }
}
