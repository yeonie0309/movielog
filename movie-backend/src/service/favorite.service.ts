import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Favorite } from "../entity/favorite.entity";
import { Member } from "../entity/member.entity";
import { CreateFavoriteDto } from "../dto/create-favorite.dto";
import {
  FavoriteResponseDto,
  FavoriteStatusResponseDto,
} from "../dto/favorite-response.dto";
import { ApiException } from "../dto/api-response";

@Injectable()
export class FavoriteService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favorites: Repository<Favorite>,
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async create(
    memberId: number,
    dto: CreateFavoriteDto,
  ): Promise<FavoriteResponseDto> {
    const member = await this.members.findOneBy({ memberId });
    if (!member)
      throw new ApiException(
        404,
        "MEMBER404_1",
        "해당 회원을 찾을 수 없습니다.",
      );
    if (
      await this.favorites.exists({
        where: { member: { memberId }, movieId: dto.movieId },
      })
    ) {
      throw new ApiException(
        409,
        "FAVORITE409_1",
        "이미 이 영화를 즐겨찾기하셨습니다.",
      );
    }
    // The UNIQUE constraint also protects simultaneous requests after this check.
    const saved = await this.favorites.save(
      this.favorites.create({ member, movieId: dto.movieId }),
    );
    return FavoriteResponseDto.from(saved);
  }

  async getMyFavorites(memberId: number): Promise<FavoriteResponseDto[]> {
    const rows = await this.favorites.find({
      where: { member: { memberId } },
      order: { favoriteId: "DESC" },
    });
    return rows.map(FavoriteResponseDto.from);
  }

  async getStatus(
    memberId: number,
    movieId: number,
  ): Promise<FavoriteStatusResponseDto> {
    return FavoriteStatusResponseDto.from(
      await this.favorites.exists({ where: { member: { memberId }, movieId } }),
    );
  }

  async delete(memberId: number, movieId: number): Promise<void> {
    const result = await this.favorites.delete({
      member: { memberId },
      movieId,
    });
    if (result.affected === 0) {
      throw new ApiException(
        404,
        "FAVORITE404_1",
        "즐겨찾기한 영화를 찾을 수 없습니다.",
      );
    }
  }
}
