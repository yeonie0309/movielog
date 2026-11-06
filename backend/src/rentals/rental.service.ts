import { Injectable, NotFoundException } from '@nestjs/common';
import { parsePositiveInteger } from '../common/parse-positive-integer.js';
import { RentalRepository } from './rental.repository.js';

@Injectable()
export class RentalService {
  constructor(private readonly rentalRepository: RentalRepository) {}

  async createRental(body: Record<string, unknown>): Promise<{
    message: string;
    rentalId: number;
  }> {
    const userId = parsePositiveInteger(body.userId, 'userId');
    const bookId = parsePositiveInteger(body.bookId, 'bookId');
    const rentalId = await this.rentalRepository.create(userId, bookId);

    return { message: '도서 대여 기록이 생성되었습니다!', rentalId };
  }

  async returnRental(rentalIdValue: unknown): Promise<{
    message: string;
    rentalId: number;
  }> {
    const rentalId = parsePositiveInteger(rentalIdValue, 'rentalId');
    const affectedRows = await this.rentalRepository.returnRental(rentalId);

    if (affectedRows === 0) {
      throw new NotFoundException('반납할 대여 기록을 찾을 수 없습니다.');
    }

    return { message: '도서 반납 처리가 완료되었습니다!', rentalId };
  }
}
