import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Member } from "./entity/member.entity";
import { Rating } from "./entity/rating.entity";
import { MemberController } from "./controller/member.controller";
import { RatingController } from "./controller/rating.controller";
import { MemberService } from "./service/member.service";
import { RatingService } from "./service/rating.service";
import { JwtModule } from "@nestjs/jwt";
import { jwtOptions } from "./auth/jwt-options";
import { AuthGuard } from "./auth/auth.guard";
import { AuthController } from "./controller/auth.controller";
import { AuthService } from "./service/auth.service";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: jwtOptions,
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: "mysql",
        host: config.get("DB_HOST", "127.0.0.1"),
        port: Number(config.get("DB_PORT", 3307)),
        username: config.get("DB_USER", "umc_week2"),
        password: config.get("DB_PASSWORD", ""),
        database: config.get("DB_NAME", "umc_movie"),
        entities: [Member, Rating],
        synchronize: false,
        charset: "utf8mb4",
        timezone: "Z",
      }),
    }),
    TypeOrmModule.forFeature([Member, Rating]),
  ],
  controllers: [AuthController, MemberController, RatingController],
  providers: [AuthService, AuthGuard, MemberService, RatingService],
})
export class AppModule {}
