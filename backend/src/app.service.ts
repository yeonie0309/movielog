import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth(): { service: string; status: string } {
    return {
      service: 'MovieLog week 3 API',
      status: 'ok',
    };
  }
}
