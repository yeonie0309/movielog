import { ConfigService } from '@nestjs/config';
import { createPool, type Pool } from 'mysql2/promise';
import { DATABASE_CONNECTION } from './database.constants.js';

export const databaseProviders = [
  {
    provide: DATABASE_CONNECTION,
    inject: [ConfigService],
    useFactory: (configService: ConfigService): Pool =>
      createPool({
        host: configService.get<string>('DB_HOST', '127.0.0.1'),
        port: configService.get<number>('DB_PORT', 3306),
        user: configService.get<string>('DB_USER', 'root'),
        password: configService.get<string>('DB_PASSWORD', ''),
        database: configService.get<string>('DB_NAME', 'umc_week2_library'),
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
        charset: 'utf8mb4',
      }),
  },
];
