import { IsEmail, IsNotEmpty, IsString, MaxLength } from "class-validator";

export class LoginRequestDto {
  @IsEmail({}, { message: "이메일 형식이 올바르지 않습니다." })
  @MaxLength(254)
  email: string;

  // Older accounts must be able to use passwords predating today's signup rules.
  @IsString()
  @IsNotEmpty({ message: "비밀번호를 입력해주세요." })
  @MaxLength(1024)
  password: string;
}
