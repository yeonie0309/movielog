import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Member } from "./entity/member.entity";
import { Rating } from "./entity/rating.entity";
import { MemberController } from "./controller/member.controller";
import { RatingController } from "./controller/rating.controller";
import { MemberService } from "./service/member.service";
import { RatingService } from "./service/rating.service";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
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
  controllers: [MemberController, RatingController],
  providers: [MemberService, RatingService],
})
export class AppModule {}
