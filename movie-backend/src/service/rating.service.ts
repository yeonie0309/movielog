import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { Rating } from "../entity/rating.entity";
import { RatingResponseDto } from "../dto/rating-response.dto";
import { RatingsQueryDto } from "../dto/ratings-query.dto";

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
      throw new NotFoundException("존재하지 않는 유저입니다.");
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
}
