import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { Rating } from "../entity/rating.entity";
import { RatingResponseDto } from "../dto/rating-response.dto";
import { RatingsQueryDto } from "../dto/ratings-query.dto";
import { ApiException } from "../dto/api-response";
import { CreateRatingDto, UpdateRatingDto } from "../dto/write-rating.dto";

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating) private readonly ratings: Repository<Rating>,
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async getRatingsByMember(
    memberId: number,
    query: RatingsQueryDto,
  ): Promise<RatingResponseDto[]> {
    if (!(await this.members.exists({ where: { memberId } }))) {
      throw new ApiException(
        404,
        "MEMBER404_1",
        "해당 회원을 찾을 수 없습니다.",
      );
    }
    const paginated = query.page !== undefined || query.size !== undefined;
    const size = query.size ?? 10;
    const rows = await this.ratings.find({
      where: { member: { memberId } },
      order: { ratingId: "DESC" },
      ...(paginated ? { skip: (query.page ?? 0) * size, take: size } : {}),
    });
    return rows.map(RatingResponseDto.from);
  }

  async create(
    memberId: number,
    dto: CreateRatingDto,
  ): Promise<RatingResponseDto> {
    const member = await this.members.findOneBy({ memberId });
    if (!member)
      throw new ApiException(
        404,
        "MEMBER404_1",
        "해당 회원을 찾을 수 없습니다.",
      );
    if (
      await this.ratings.exists({
        where: { member: { memberId }, movieId: dto.movieId },
      })
    ) {
      throw new ApiException(
        409,
        "RATING409_1",
        "이미 이 영화에 평점을 남기셨습니다.",
      );
    }
    const saved = await this.ratings.save(
      this.ratings.create({
        member,
        movieId: dto.movieId,
        score: dto.score,
        comment: dto.comment ?? null,
      }),
    );
    return RatingResponseDto.from(saved);
  }

  async update(
    ratingId: number,
    memberId: number,
    dto: UpdateRatingDto,
  ): Promise<RatingResponseDto> {
    const rating = await this.findOwnedRating(ratingId, memberId);
    rating.score = dto.score;
    rating.comment = dto.comment ?? null;
    return RatingResponseDto.from(await this.ratings.save(rating));
  }

  async delete(ratingId: number, memberId: number): Promise<void> {
    await this.ratings.remove(await this.findOwnedRating(ratingId, memberId));
  }

  private async findOwnedRating(
    ratingId: number,
    memberId: number,
  ): Promise<Rating> {
    const rating = await this.ratings.findOne({
      where: { ratingId },
      relations: { member: true },
    });
    if (!rating)
      throw new ApiException(
        404,
        "RATING404_1",
        "해당 평점을 찾을 수 없습니다.",
      );
    // MySQL BIGINT IDs may be materialized as strings by the driver.
    if (String(rating.member.memberId) !== String(memberId)) {
      throw new ApiException(
        403,
        "RATING403_1",
        "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.",
      );
    }
    return rating;
  }
}
