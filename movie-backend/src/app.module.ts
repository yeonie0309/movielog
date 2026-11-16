import { Favorite } from "./entity/favorite.entity";
import { FavoriteController } from "./controller/favorite.controller";
import { MovieRecordController } from "./controller/movie-record.controller";
import { FavoriteService } from "./service/favorite.service";
import { MovieRecordService } from "./service/movie-record.service";
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
        entities: [Member, Rating, Favorite],
        synchronize: false,
        charset: "utf8mb4",
        timezone: "Z",
      }),
    }),
    TypeOrmModule.forFeature([Member, Rating, Favorite]),
  ],
  controllers: [
    AuthController,
    MemberController,
    RatingController,
    FavoriteController,
    MovieRecordController,
  ],
  providers: [
    AuthService,
    AuthGuard,
    MemberService,
    RatingService,
    FavoriteService,
    MovieRecordService,
  ],
})
export class AppModule {}
