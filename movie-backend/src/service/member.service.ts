import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { CheckResponseDto } from "../dto/check-response.dto";

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
}
