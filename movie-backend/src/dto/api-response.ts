import { HttpException } from "@nestjs/common";

export function success<T>(result: T, message: string, status = 200) {
  return { isSuccess: true, code: `COMMON${status}`, message, result };
}

export class ApiException extends HttpException {
  constructor(status: number, code: string, message: string) {
    super({ code, message }, status);
  }
}
