import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { MemberService } from "../service/member.service";
import { EmailParamsDto, NicknameParamsDto } from "../dto/member-params.dto";
import { CreateMemberDto } from "../dto/create-member.dto";
import { success } from "../dto/api-response";
import { AuthGuard } from "../auth/auth.guard";
import { LoginMember } from "../auth/login-member.decorator";
import { MemberUpdateRequestDto } from "../dto/member-info.dto";

@Controller("members")
export class MemberController {
  constructor(private readonly members: MemberService) {}

  @Get("me")
  @UseGuards(AuthGuard)
  async getMyInfo(@LoginMember() memberId: number) {
    return success(
      await this.members.getMyInfo(memberId),
      "회원 정보를 조회했습니다.",
    );
  }

  @Patch("me")
  @UseGuards(AuthGuard)
  async updateMyInfo(
    @LoginMember() memberId: number,
    @Body() dto: MemberUpdateRequestDto,
  ) {
    return success(
      await this.members.updateMyInfo(memberId, dto),
      "회원 정보를 수정했습니다.",
    );
  }

  @Get("nickname/:nickname")
  checkNickname(@Param() params: NicknameParamsDto) {
    return this.members.checkNickname(params.nickname);
  }

  @Get("email/:email")
  checkEmail(@Param() params: EmailParamsDto) {
    return this.members.checkEmail(params.email);
  }

  @Post()
  @HttpCode(201)
  async signUp(@Body() dto: CreateMemberDto) {
    return success(
      await this.members.signUp(dto),
      "회원가입에 성공했습니다.",
      201,
    );
  }
}
