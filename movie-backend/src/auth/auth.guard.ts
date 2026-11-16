import { CanActivate, ExecutionContext, Injectable } from "@nestjs/common";
import { JwtService, TokenExpiredError } from "@nestjs/jwt";
import type { Request } from "express";
import { ApiException } from "../dto/api-response";

export type AuthenticatedRequest = Request & { memberId: number };

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization;
    const bearer =
      typeof header === "string" ? /^Bearer ([^\s]+)$/i.exec(header) : null;
    if (!bearer) {
      throw new ApiException(401, "AUTH401_2", "로그인이 필요한 요청입니다.");
    }
    try {
      const payload = await this.jwt.verifyAsync(bearer[1], {
        algorithms: ["HS256"],
      });
      const id = Number(payload.sub);
      if (
        typeof payload.sub !== "string" ||
        !/^[1-9]\d*$/.test(payload.sub) ||
        !Number.isSafeInteger(id) ||
        typeof payload.email !== "string" ||
        !Number.isFinite(payload.exp)
      ) {
        throw new Error("Invalid token claims");
      }
      request.memberId = id;
      return true;
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new ApiException(
          401,
          "AUTH401_4",
          "토큰이 만료되었습니다. 다시 로그인해주세요.",
        );
      }
      throw new ApiException(401, "AUTH401_3", "유효하지 않은 토큰입니다.");
    }
  }
}
