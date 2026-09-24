import { type INestApplication } from '@nestjs/common';
import { Test, type TestingModule } from '@nestjs/testing';
import type { Pool } from 'mysql2/promise';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from '../src/app.module.js';
import { DATABASE_CONNECTION } from '../src/database/database.constants.js';

describe('MovieLog week 3 API (e2e)', () => {
  let app: INestApplication<App>;
  const query = vi.fn();
  const execute = vi.fn();
  const end = vi.fn();

  beforeAll(async () => {
    query.mockImplementation(async (sql: string) => {
      if (sql === 'SELECT 1') return [[{ connection: 1 }], []];
      if (sql.includes('SELECT * FROM book')) {
        return [
          [
            {
              book_id: 1,
              category_id: 1,
              title: '달빛 도서관',
              description: '소설',
              is_available: 1,
            },
          ],
          [],
        ];
      }
      throw new Error(`Unexpected query: ${sql}`);
    });

    execute.mockImplementation(async (sql: string) => {
      if (sql.includes('SELECT * FROM book WHERE category_id = ?')) {
        return [[{ book_id: 1, category_id: 1, title: '달빛 도서관' }], []];
      }
      if (sql.includes('INSERT INTO book')) return [{ insertId: 4 }, []];
      if (sql.includes('INSERT INTO rental')) return [{ insertId: 3 }, []];
      if (sql.includes('UPDATE rental')) return [{ affectedRows: 1 }, []];
      throw new Error(`Unexpected execute: ${sql}`);
    });

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(DATABASE_CONNECTION)
      .useValue({ query, execute, end } as unknown as Pool)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.listen(0, '127.0.0.1');
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /books', async () => {
    await request(app.getHttpServer())
      .get('/books')
      .expect(200)
      .expect((response) => {
        expect(response.body[0].title).toBe('달빛 도서관');
      });
  });

  it('POST /books', async () => {
    await request(app.getHttpServer())
      .post('/books')
      .send({ categoryId: 1, title: '클린 코드', description: '애자일' })
      .expect(201)
      .expect({ message: '도서 등록이 완료되었습니다!', bookId: 4 });
  });

  it('GET /books/category/:categoryId', async () => {
    await request(app.getHttpServer())
      .get('/books/category/1')
      .expect(200)
      .expect((response) => {
        expect(response.body).toHaveLength(1);
        expect(response.body[0].category_id).toBe(1);
      });
  });

  it('POST /rentals', async () => {
    await request(app.getHttpServer())
      .post('/rentals')
      .send({ userId: 1, bookId: 1 })
      .expect(201)
      .expect({ message: '도서 대여 기록이 생성되었습니다!', rentalId: 3 });
  });

  it('PATCH /rentals/:rentalId/return', async () => {
    await request(app.getHttpServer())
      .patch('/rentals/3/return')
      .expect(200)
      .expect({ message: '도서 반납 처리가 완료되었습니다!', rentalId: 3 });
  });

  it('잘못된 ID는 400으로 거절한다', async () => {
    await request(app.getHttpServer())
      .get('/books/category/not-a-number')
      .expect(400);
  });
});
