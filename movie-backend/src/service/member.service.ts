import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { CheckResponseDto } from "../dto/check-response.dto";
import * as bcrypt from "bcrypt";
import { CreateMemberDto } from "../dto/create-member.dto";
import { ApiException } from "../dto/api-response";

@Injectable()
export class MemberService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async checkNickname(nickname: string): Promise<CheckResponseDto> {
    return new CheckResponseDto(
      !(await this.members.exists({ where: { nickname } })),
    );
  }

  async checkEmail(email: string): Promise<CheckResponseDto> {
    return new CheckResponseDto(
      !(await this.members.exists({ where: { email } })),
    );
  }

  async signUp(dto: CreateMemberDto) {
    if (await this.members.exists({ where: { email: dto.email } })) {
      throw new ApiException(409, "MEMBER4091", "이미 사용 중인 이메일입니다.");
    }
    if (await this.members.exists({ where: { nickname: dto.nickname } })) {
      throw new ApiException(409, "MEMBER4092", "이미 사용 중인 닉네임입니다.");
    }
    const saved = await this.members.save(
      this.members.create({
        email: dto.email,
        nickname: dto.nickname,
        password: await bcrypt.hash(dto.password, 10),
      }),
    );
    // Explicit projection: select:false alone does not protect an entity returned by save().
    return {
      memberId: Number(saved.memberId),
      email: saved.email,
      nickname: saved.nickname,
    };
  }
}
