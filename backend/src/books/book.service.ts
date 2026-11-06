import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Like, QueryFailedError, Repository } from 'typeorm';
import { Category } from '../categories/category.entity.js';
import { Book } from './book.entity.js';
import { BookResponseDto } from './dto/book-response.dto.js';
import { CreateBookDto } from './dto/create-book.dto.js';

@Injectable()
export class BookService {
  constructor(
    @InjectRepository(Book)
    private readonly bookRepository: Repository<Book>,
    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
  ) {}

  async getBooks(keyword?: string): Promise<BookResponseDto[]> {
    const books = await this.bookRepository.find({
      where: keyword ? { title: Like(`%${keyword}%`) } : undefined,
      relations: { category: true },
      order: { bookId: 'DESC' },
    });

    return books.map((book) => BookResponseDto.from(book));
  }

  async createBook(request: CreateBookDto): Promise<BookResponseDto> {
    const category = await this.categoryRepository.findOneBy({
      categoryId: request.categoryId,
    });
    if (!category) {
      throw new NotFoundException('존재하지 않는 카테고리입니다.');
    }

    const duplicate = await this.bookRepository.findOneBy({
      title: request.title,
    });
    if (duplicate) {
      throw new ConflictException('이미 등록된 도서 제목입니다.');
    }

    const book = this.bookRepository.create({
      category,
      title: request.title,
      description: request.description || null,
      isAvailable: true,
    });

    try {
      return BookResponseDto.from(await this.bookRepository.save(book));
    } catch (error) {
      if (this.isDuplicateEntry(error)) {
        throw new ConflictException('이미 등록된 도서 제목입니다.');
      }
      throw error;
    }
  }

  private isDuplicateEntry(error: unknown): boolean {
    if (!(error instanceof QueryFailedError)) return false;

    const driverError = error.driverError as { code?: string };
    return driverError.code === 'ER_DUP_ENTRY';
  }
}
