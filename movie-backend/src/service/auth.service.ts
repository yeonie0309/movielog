import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { JwtService } from "@nestjs/jwt";
import { Repository } from "typeorm";
import * as bcrypt from "bcrypt";
import { Member } from "../entity/member.entity";
import { LoginRequestDto } from "../dto/login-request.dto";
import { LoginResponseDto } from "../dto/login-response.dto";
import { ApiException } from "../dto/api-response";

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
    private readonly jwt: JwtService,
  ) {}

  async login(dto: LoginRequestDto): Promise<LoginResponseDto> {
    const member = await this.members.findOne({
      where: { email: dto.email },
      select: { memberId: true, email: true, nickname: true, password: true },
    });
    // bcrypt ignores bytes past 72; a longer input must not match a 72-byte password.
    if (
      Buffer.byteLength(dto.password, "utf8") > 72 ||
      !member ||
      !(await bcrypt.compare(dto.password, member.password))
    ) {
      throw new ApiException(
        401,
        "AUTH401_1",
        "이메일 또는 비밀번호가 올바르지 않습니다.",
      );
    }
    const accessToken = await this.jwt.signAsync({
      sub: String(member.memberId),
      email: member.email,
    });
    return { nickname: member.nickname, accessToken };
  }
}
