import { Type } from "class-transformer";
import { IsInt, Max, Min } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreateFavoriteDto {
  @ApiProperty({ example: 550, minimum: 1, maximum: Number.MAX_SAFE_INTEGER })
  @IsInt({ message: "영화 ID는 정수여야 합니다." })
  @Min(1, { message: "영화 ID는 양수여야 합니다." })
  @Max(Number.MAX_SAFE_INTEGER)
  movieId: number;
}

export class FavoriteMovieParamsDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(Number.MAX_SAFE_INTEGER)
  movieId: number;
}
