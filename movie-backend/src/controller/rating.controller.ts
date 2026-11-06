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
} from "@nestjs/common";
import { RatingService } from "../service/rating.service";
import { RatingsQueryDto } from "../dto/ratings-query.dto";
import { MemberIdParamsDto, RatingParamsDto } from "../dto/rating-params.dto";
import { CreateRatingDto, UpdateRatingDto } from "../dto/write-rating.dto";
import { success } from "../dto/api-response";

@Controller("members")
export class RatingController {
  constructor(private readonly ratings: RatingService) {}

  @Get(":memberId/ratings")
  getRatings(
    @Param("memberId", ParseIntPipe) memberId: number,
    @Query() query: RatingsQueryDto,
  ) {
    if (!Number.isSafeInteger(memberId) || memberId <= 0) {
      throw new BadRequestException("memberId는 양의 정수여야 합니다.");
    }
    return this.ratings.getRatingsByMember(memberId, query);
  }

  @Post(":memberId/ratings")
  @HttpCode(201)
  async create(
    @Param() params: MemberIdParamsDto,
    @Body() dto: CreateRatingDto,
  ) {
    return success(
      await this.ratings.create(params.memberId, dto),
      "평점 등록에 성공했습니다.",
      201,
    );
  }

  @Patch(":memberId/ratings/:ratingId")
  async update(@Param() params: RatingParamsDto, @Body() dto: UpdateRatingDto) {
    await this.ratings.update(params.ratingId, params.memberId, dto);
    return success(null, "평점 수정에 성공했습니다.");
  }

  @Delete(":memberId/ratings/:ratingId")
  @HttpCode(204)
  async delete(@Param() params: RatingParamsDto) {
    await this.ratings.delete(params.ratingId, params.memberId);
  }
}
