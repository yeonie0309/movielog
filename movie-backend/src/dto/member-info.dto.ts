import { IsNotEmpty, IsString, Length } from "class-validator";
import { Member } from "../entity/member.entity";

export class MemberUpdateRequestDto {
  @IsString()
  @IsNotEmpty({ message: "닉네임을 입력해주세요." })
  @Length(2, 12, { message: "닉네임은 2자 이상 12자 이하여야 합니다." })
  nickname: string;
}

export class MemberInfoResponseDto {
  email: string;
  nickname: string;
  createdAt: Date;

  static from(member: Member): MemberInfoResponseDto {
    return {
      email: member.email,
      nickname: member.nickname,
      createdAt: member.createdAt,
    };
  }
}
