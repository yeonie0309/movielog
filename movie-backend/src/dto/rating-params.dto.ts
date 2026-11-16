import { Type } from "class-transformer";
import { IsInt, Max, Min } from "class-validator";

export class RatingIdParamsDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(Number.MAX_SAFE_INTEGER)
  ratingId: number;
}
