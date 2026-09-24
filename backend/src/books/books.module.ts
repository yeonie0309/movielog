import { Module } from '@nestjs/common';
import { BookController } from './book.controller.js';
import { BookRepository } from './book.repository.js';
import { BookService } from './book.service.js';

@Module({
  controllers: [BookController],
  providers: [BookService, BookRepository],
})
export class BooksModule {}
