import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { AuthGuard } from "../auth/auth.guard";
import { LoginMember } from "../auth/login-member.decorator";
import {
  CreateFavoriteDto,
  FavoriteMovieParamsDto,
} from "../dto/create-favorite.dto";
import { success } from "../dto/api-response";
import { FavoriteService } from "../service/favorite.service";

@ApiTags("8주차 즐겨찾기")
@ApiBearerAuth()
@Controller("favorites")
@UseGuards(AuthGuard)
export class FavoriteController {
  constructor(private readonly favorites: FavoriteService) {}

  @Post()
  @HttpCode(201)
  @ApiOperation({ summary: "로그인 회원의 즐겨찾기 등록" })
  async create(
    @LoginMember() memberId: number,
    @Body() dto: CreateFavoriteDto,
  ) {
    return success(
      await this.favorites.create(memberId, dto),
      "즐겨찾기를 등록했습니다.",
      201,
    );
  }

  @Get()
  @ApiOperation({ summary: "내 즐겨찾기 최신순 목록" })
  async list(@LoginMember() memberId: number) {
    return success(
      await this.favorites.getMyFavorites(memberId),
      "내 즐겨찾기 목록을 조회했습니다.",
    );
  }

  @Get(":movieId")
  @ApiOperation({ summary: "특정 영화 즐겨찾기 여부" })
  async status(
    @LoginMember() memberId: number,
    @Param() params: FavoriteMovieParamsDto,
  ) {
    return success(
      await this.favorites.getStatus(memberId, params.movieId),
      "즐겨찾기 여부를 조회했습니다.",
    );
  }

  @Delete(":movieId")
  @HttpCode(200)
  @ApiOperation({ summary: "내 즐겨찾기 해제" })
  async delete(
    @LoginMember() memberId: number,
    @Param() params: FavoriteMovieParamsDto,
  ) {
    await this.favorites.delete(memberId, params.movieId);
    return success(null, "즐겨찾기를 해제했습니다.");
  }
}
