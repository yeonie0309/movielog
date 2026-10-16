import { ConflictException, NotFoundException } from '@nestjs/common';
import type { Repository } from 'typeorm';
import { Category } from '../categories/category.entity.js';
import { Book } from './book.entity.js';
import { BookService } from './book.service.js';

describe('BookService', () => {
  const category: Category = {
    categoryId: 1,
    name: '문학',
    books: [],
  };
  const savedBook: Book = {
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

  let service: BookService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new BookService(
      bookRepository as unknown as Repository<Book>,
      categoryRepository as unknown as Repository<Category>,
    );
  });

  it('카테고리 관계를 포함해 최신 도서부터 DTO로 반환한다', async () => {
    bookRepository.find.mockResolvedValue([savedBook]);

    const result = await service.getBooks();

    expect(bookRepository.find).toHaveBeenCalledWith({
      where: undefined,
      relations: { category: true },
      order: { bookId: 'DESC' },
    });
    expect(result).toEqual([
      {
        bookId: 4,
        title: '클린 코드',
        description: '애자일 소프트웨어 장인 정신',
        categoryName: '문학',
        isAvailable: true,
      },
    ]);
  });

  it('존재하는 카테고리로 새 도서를 저장한다', async () => {
    categoryRepository.findOneBy.mockResolvedValue(category);
    bookRepository.findOneBy.mockResolvedValue(null);
    bookRepository.create.mockReturnValue(savedBook);
    bookRepository.save.mockResolvedValue(savedBook);

    const result = await service.createBook({
      categoryId: 1,
      title: '클린 코드',
      description: '애자일 소프트웨어 장인 정신',
    });

    expect(categoryRepository.findOneBy).toHaveBeenCalledWith({
      categoryId: 1,
    });
    expect(bookRepository.save).toHaveBeenCalledWith(savedBook);
    expect(result.bookId).toBe(4);
    expect(result.categoryName).toBe('문학');
  });

  it('존재하지 않는 카테고리는 404 예외로 거절한다', async () => {
    categoryRepository.findOneBy.mockResolvedValue(null);

    await expect(
      service.createBook({ categoryId: 999, title: '없는 카테고리' }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(bookRepository.save).not.toHaveBeenCalled();
  });

  it('중복 제목은 409 예외로 거절한다', async () => {
    categoryRepository.findOneBy.mockResolvedValue(category);
    bookRepository.findOneBy.mockResolvedValue(savedBook);

    await expect(
      service.createBook({ categoryId: 1, title: '클린 코드' }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(bookRepository.save).not.toHaveBeenCalled();
  });
});
