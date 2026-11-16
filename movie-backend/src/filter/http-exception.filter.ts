import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
} from "@nestjs/common";
import type { Response } from "express";
import { QueryFailedError } from "typeorm";

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    let status = 500;
    let code = "COMMON500";
    let message = "서버 내부 오류가 발생했습니다.";

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      const payload =
        typeof body === "string"
          ? { message: body }
          : (body as { message?: string | string[]; code?: string });
      message = Array.isArray(payload.message)
        ? payload.message[0]
        : (payload.message ?? exception.message);
      code = payload.code ?? `COMMON${status}`;
    } else if (exception instanceof QueryFailedError) {
      const driver = exception.driverError as {
        errno?: number;
        sqlMessage?: string;
      };
      if (driver.errno === 1062) {
        status = 409;
        // Inspect only the constraint identifier, never return SQL or duplicate values.
        const key = /for key ['`]([^'`]+)['`]/i
          .exec(driver.sqlMessage ?? "")?.[1]
          ?.split(".")
          .pop();
        [code, message] =
          key === "email"
            ? ["MEMBER4091", "이미 사용 중인 이메일입니다."]
            : key === "nickname"
              ? ["MEMBER4092", "이미 사용 중인 닉네임입니다."]
              : key === "uk_rating_member_movie"
                ? ["RATING409_1", "이미 이 영화에 평점을 남기셨습니다."]
                : ["COMMON409", "이미 존재하는 데이터입니다."];
      } else if (driver.errno === 1452) {
        status = 404;
        code = "MEMBER404_1";
        message = "해당 회원을 찾을 수 없습니다.";
      }
    }
    response
      .status(status)
      .json({ isSuccess: false, code, message, result: null });
  }
}
