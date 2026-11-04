import { Type } from "class-transformer";
import { IsInt, Max, Min } from "class-validator";

export class MemberIdParamsDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(Number.MAX_SAFE_INTEGER)
  memberId: number;
}

export class RatingParamsDto extends MemberIdParamsDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(Number.MAX_SAFE_INTEGER)
  ratingId: number;
}
