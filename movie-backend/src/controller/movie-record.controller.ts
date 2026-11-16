import { Body, Controller, HttpCode, Post, UseGuards } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { AuthGuard } from "../auth/auth.guard";
import { LoginMember } from "../auth/login-member.decorator";
import { CreateMovieRecordDto } from "../dto/create-movie-record.dto";
import { success } from "../dto/api-response";
import { MovieRecordService } from "../service/movie-record.service";

@ApiTags("8주차 영화 기록")
@ApiBearerAuth()
@Controller("movie-records")
@UseGuards(AuthGuard)
export class MovieRecordController {
  constructor(private readonly records: MovieRecordService) {}

  @Post()
  @HttpCode(201)
  @ApiOperation({ summary: "평점과 선택적 즐겨찾기를 한 트랜잭션으로 저장" })
  async create(
    @LoginMember() memberId: number,
    @Body() dto: CreateMovieRecordDto,
  ) {
    return success(
      await this.records.create(memberId, dto),
      "영화 기록을 저장했습니다.",
      201,
    );
  }
}
