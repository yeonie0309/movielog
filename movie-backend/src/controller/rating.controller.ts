import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from "@nestjs/common";
import { RatingService } from "../service/rating.service";
import { RatingsQueryDto } from "../dto/ratings-query.dto";
import { RatingIdParamsDto } from "../dto/rating-params.dto";
import { CreateRatingDto, UpdateRatingDto } from "../dto/write-rating.dto";
import { success } from "../dto/api-response";
import { AuthGuard } from "../auth/auth.guard";
import { LoginMember } from "../auth/login-member.decorator";

@Controller()
export class RatingController {
  constructor(private readonly ratings: RatingService) {}

  @Get("members/:memberId/ratings")
  getRatings(
    @Param("memberId", ParseIntPipe) memberId: number,
    @Query() query: RatingsQueryDto,
  ) {
    if (!Number.isSafeInteger(memberId) || memberId <= 0) {
      throw new BadRequestException("memberId는 양의 정수여야 합니다.");
    }
    return this.ratings.getRatingsByMember(memberId, query);
  }

  @Post("ratings")
  @UseGuards(AuthGuard)
  @HttpCode(201)
  async create(@LoginMember() memberId: number, @Body() dto: CreateRatingDto) {
    return success(
      await this.ratings.create(memberId, dto),
      "평점 등록에 성공했습니다.",
      201,
    );
  }

  @Patch("ratings/:ratingId")
  @UseGuards(AuthGuard)
  async update(
    @LoginMember() memberId: number,
    @Param() params: RatingIdParamsDto,
    @Body() dto: UpdateRatingDto,
  ) {
    return success(
      await this.ratings.update(params.ratingId, memberId, dto),
      "평점 수정에 성공했습니다.",
    );
  }

  @Delete("ratings/:ratingId")
  @UseGuards(AuthGuard)
  @HttpCode(200)
  async delete(
    @LoginMember() memberId: number,
    @Param() params: RatingIdParamsDto,
  ) {
    await this.ratings.delete(params.ratingId, memberId);
    return success(null, "평점을 삭제했습니다.");
  }
}
