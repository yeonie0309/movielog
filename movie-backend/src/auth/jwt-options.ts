import { ConfigService } from "@nestjs/config";
import type { JwtModuleOptions } from "@nestjs/jwt";

export function jwtOptions(config: ConfigService): JwtModuleOptions {
  const secret = config.get<string>("JWT_SECRET");
  const rawExpiration = config.get<string>("JWT_ACCESS_EXPIRATION") ?? "3600";
  const expiration = Number(rawExpiration);
  if (!secret || Buffer.byteLength(secret, "utf8") < 32) {
    throw new Error("JWT_SECRET은 32바이트 이상으로 설정해야 합니다.");
  }
  if (
    !/^\d+$/.test(rawExpiration) ||
    !Number.isSafeInteger(expiration) ||
    expiration < 1
  ) {
    throw new Error("JWT_ACCESS_EXPIRATION은 양의 정수(초)여야 합니다.");
  }
  return {
    secret,
    signOptions: { algorithm: "HS256", expiresIn: expiration },
    verifyOptions: { algorithms: ["HS256"] },
  };
}
