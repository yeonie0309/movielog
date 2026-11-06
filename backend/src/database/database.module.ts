import { Global, Module } from '@nestjs/common';
import { DatabaseHealthService } from './database-health.service.js';
import { databaseProviders } from './database.provider.js';

@Global()
@Module({
  providers: [...databaseProviders, DatabaseHealthService],
  exports: [...databaseProviders],
})
export class DatabaseModule {}
