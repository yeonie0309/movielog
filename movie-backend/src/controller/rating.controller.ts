import {
  BadRequestException,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Query,
} from "@nestjs/common";
import { RatingService } from "../service/rating.service";
import { RatingsQueryDto } from "../dto/ratings-query.dto";

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
}
