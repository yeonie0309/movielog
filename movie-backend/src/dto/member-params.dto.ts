import { IsEmail, IsString, Length } from "class-validator";

export class NicknameParamsDto {
  @IsString()
  @Length(2, 12)
  nickname: string;
}

export class EmailParamsDto {
  @IsEmail()
  @Length(3, 254)
  email: string;
}
