import { Injectable } from "@nestjs/common";
import { DataSource } from "typeorm";
import { Member } from "../entity/member.entity";
import { Rating } from "../entity/rating.entity";
import { Favorite } from "../entity/favorite.entity";
import { CreateMovieRecordDto } from "../dto/create-movie-record.dto";
import { MovieRecordResponseDto } from "../dto/movie-record-response.dto";
import { RatingResponseDto } from "../dto/rating-response.dto";
import { FavoriteResponseDto } from "../dto/favorite-response.dto";
import { ApiException } from "../dto/api-response";

@Injectable()
export class MovieRecordService {
  constructor(private readonly dataSource: DataSource) {}

  create(
    memberId: number,
    dto: CreateMovieRecordDto,
  ): Promise<MovieRecordResponseDto> {
    return this.dataSource.transaction(async (manager) => {
      // Every read and write uses this transaction's manager and connection.
      const members = manager.getRepository(Member);
      const ratings = manager.getRepository(Rating);
      const favorites = manager.getRepository(Favorite);
      const member = await members.findOneBy({ memberId });
      if (!member)
        throw new ApiException(
          404,
          "MEMBER404_1",
          "해당 회원을 찾을 수 없습니다.",
        );
      const where = { member: { memberId }, movieId: dto.movieId };
      if (await ratings.exists({ where })) {
        throw new ApiException(
          409,
          "RATING409_1",
          "이미 이 영화에 평점을 남기셨습니다.",
        );
      }
      if (dto.addToFavorites && (await favorites.exists({ where }))) {
        throw new ApiException(
          409,
          "FAVORITE409_1",
          "이미 이 영화를 즐겨찾기하셨습니다.",
        );
      }
      const rating = await ratings.save(
        ratings.create({
          member,
          movieId: dto.movieId,
          score: dto.score,
          comment: dto.comment ?? null,
        }),
      );
      const favorite = dto.addToFavorites
        ? await favorites.save(
            favorites.create({ member, movieId: dto.movieId }),
          )
        : null;
      // Errors propagate out of the callback so both writes roll back together.
      return {
        rating: RatingResponseDto.from(rating),
        favorite: favorite ? FavoriteResponseDto.from(favorite) : null,
      };
    });
  }
}
