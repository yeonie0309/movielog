import { ValidationPipe, type INestApplication } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Test, type TestingModule } from '@nestjs/testing';
import type { Pool } from 'mysql2/promise';
import request from 'supertest';
import type { App } from 'supertest/types';
import type { Repository } from 'typeorm';
import { BookController } from '../src/books/book.controller.js';
import { Book } from '../src/books/book.entity.js';
import { BookService } from '../src/books/book.service.js';
import { Category } from '../src/categories/category.entity.js';
import { DATABASE_CONNECTION } from '../src/database/database.constants.js';
import { RentalController } from '../src/rentals/rental.controller.js';
import { RentalRepository } from '../src/rentals/rental.repository.js';
import { RentalService } from '../src/rentals/rental.service.js';

describe('MovieLog week 4 ORM API (e2e)', () => {
  let app: INestApplication<App>;

  const category: Category = {
    categoryId: 1,
    name: '문학',
    books: [],
  };
  const book: Book = {
    bookId: 4,
    category,
    title: '클린 코드',
    description: '애자일 소프트웨어 장인 정신',
    isAvailable: true,
  };

  const bookRepository = {
    find: vi.fn(),
    findOneBy: vi.fn(),
    create: vi.fn(),
    save: vi.fn(),
  };
  const categoryRepository = {
    findOneBy: vi.fn(),
  };
  const execute = vi.fn();

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [BookController, RentalController],
      providers: [
        BookService,
        RentalService,
        RentalRepository,
        {
          provide: getRepositoryToken(Book),
          useValue: bookRepository as unknown as Repository<Book>,
        },
        {
          provide: getRepositoryToken(Category),
          useValue: categoryRepository as unknown as Repository<Category>,
        },
        {
          provide: DATABASE_CONNECTION,
          useValue: { execute } as unknown as Pool,
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
  });

  beforeEach(() => {
    vi.clearAllMocks();
    bookRepository.find.mockResolvedValue([book]);
    categoryRepository.findOneBy.mockImplementation(
      async ({ categoryId }: { categoryId: number }) =>
        categoryId === 1 ? category : null,
    );
    bookRepository.findOneBy.mockResolvedValue(null);
    bookRepository.create.mockImplementation((value: Partial<Book>) =>
      Object.assign(new Book(), book, value),
    );
    bookRepository.save.mockImplementation(async (value: Book) => value);
    execute.mockImplementation(async (sql: string) => {
      if (sql.includes('INSERT INTO rental')) return [{ insertId: 3 }, []];
      if (sql.includes('UPDATE rental')) return [{ affectedRows: 1 }, []];
      throw new Error(`Unexpected execute: ${sql}`);
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /books는 카테고리 이름을 포함한 DTO를 반환한다', async () => {
    await request(app.getHttpServer())
      .get('/books')
      .expect(200)
      .expect([
        {
          bookId: 4,
          title: '클린 코드',
          description: '애자일 소프트웨어 장인 정신',
          categoryName: '문학',
          isAvailable: true,
        },
      ]);
  });

  it('GET /books?keyword=클린은 제목 검색 조건을 전달한다', async () => {
    await request(app.getHttpServer()).get('/books?keyword=클린').expect(200);

    expect(bookRepository.find).toHaveBeenCalledWith(
      expect.objectContaining({
        relations: { category: true },
        order: { bookId: 'DESC' },
      }),
    );
  });

  it('POST /books는 ORM으로 저장하고 201을 반환한다', async () => {
    await request(app.getHttpServer())
      .post('/books')
      .send({
        categoryId: 1,
        title: '클린 코드',
        description: '애자일 소프트웨어 장인 정신',
      })
      .expect(201)
      .expect({
        bookId: 4,
        title: '클린 코드',
        description: '애자일 소프트웨어 장인 정신',
        categoryName: '문학',
        isAvailable: true,
      });
  });

  it('빈 제목은 DTO 검증에서 400으로 거절한다', async () => {
    await request(app.getHttpServer())
      .post('/books')
      .send({ categoryId: 1, title: '   ' })
      .expect(400);

    expect(bookRepository.save).not.toHaveBeenCalled();
  });

  it('존재하지 않는 카테고리는 404로 응답한다', async () => {
    await request(app.getHttpServer())
      .post('/books')
      .send({ categoryId: 999, title: '없는 카테고리' })
      .expect(404);
  });

  it('중복 제목은 409로 응답한다', async () => {
    bookRepository.findOneBy.mockResolvedValueOnce(book);

    await request(app.getHttpServer())
      .post('/books')
      .send({ categoryId: 1, title: '클린 코드' })
      .expect(409);
  });

  it('3주차 POST /rentals를 계속 지원한다', async () => {
    await request(app.getHttpServer())
      .post('/rentals')
      .send({ userId: 1, bookId: 1 })
      .expect(201)
      .expect({ message: '도서 대여 기록이 생성되었습니다!', rentalId: 3 });
  });

  it('3주차 PATCH /rentals/:rentalId/return을 계속 지원한다', async () => {
    await request(app.getHttpServer())
      .patch('/rentals/3/return')
      .expect(200)
      .expect({ message: '도서 반납 처리가 완료되었습니다!', rentalId: 3 });
  });
});
