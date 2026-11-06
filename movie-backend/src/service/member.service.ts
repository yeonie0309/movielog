import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Not, QueryFailedError, Repository } from "typeorm";
import { Member } from "../entity/member.entity";
import { CheckResponseDto } from "../dto/check-response.dto";
import * as bcrypt from "bcrypt";
import { CreateMemberDto } from "../dto/create-member.dto";
import { ApiException } from "../dto/api-response";
import {
  MemberInfoResponseDto,
  MemberUpdateRequestDto,
} from "../dto/member-info.dto";

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

  private async findMember(memberId: number): Promise<Member> {
    const member = await this.members.findOneBy({ memberId });
    if (!member)
      throw new ApiException(
        404,
        "MEMBER404_1",
        "해당 회원을 찾을 수 없습니다.",
      );
    return member;
  }

  async getMyInfo(memberId: number): Promise<MemberInfoResponseDto> {
    return MemberInfoResponseDto.from(await this.findMember(memberId));
  }

  async updateMyInfo(
    memberId: number,
    dto: MemberUpdateRequestDto,
  ): Promise<MemberInfoResponseDto> {
    const member = await this.findMember(memberId);
    if (
      await this.members.exists({
        where: { nickname: dto.nickname, memberId: Not(memberId) },
      })
    ) {
      throw new ApiException(
        409,
        "MEMBER409_1",
        "이미 사용 중인 닉네임입니다.",
      );
    }
    try {
      await this.members.update({ memberId }, { nickname: dto.nickname });
    } catch (error) {
      // Preserve signup's existing code while translating this update's UNIQUE race.
      if (
        error instanceof QueryFailedError &&
        error.driverError.errno === 1062
      ) {
        throw new ApiException(
          409,
          "MEMBER409_1",
          "이미 사용 중인 닉네임입니다.",
        );
      }
      throw error;
    }
    member.nickname = dto.nickname;
    return MemberInfoResponseDto.from(member);
  }
}
