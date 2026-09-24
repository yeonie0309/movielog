import { Module } from '@nestjs/common';
import { RentalController } from './rental.controller.js';
import { RentalRepository } from './rental.repository.js';
import { RentalService } from './rental.service.js';

@Module({
  controllers: [RentalController],
  providers: [RentalService, RentalRepository],
})
export class RentalsModule {}
