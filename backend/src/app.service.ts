import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): { service: string; status: string } {
    return {
      service: 'MovieLog week 4 ORM API',
      status: 'ok',
    };
  }
}
