import {
  Inject,
  Injectable,
  Logger,
  type OnApplicationBootstrap,
  type OnApplicationShutdown,
} from '@nestjs/common';
import type { Pool } from 'mysql2/promise';
import { DATABASE_CONNECTION } from './database.constants.js';

@Injectable()
export class DatabaseHealthService
  implements OnApplicationBootstrap, OnApplicationShutdown
{
  private readonly logger = new Logger(DatabaseHealthService.name);

  constructor(@Inject(DATABASE_CONNECTION) private readonly pool: Pool) {}

  async onApplicationBootstrap(): Promise<void> {
    await this.pool.query('SELECT 1');
    this.logger.log('MySQL connection established');
  }

  async onApplicationShutdown(): Promise<void> {
    await this.pool.end();
  }
}
