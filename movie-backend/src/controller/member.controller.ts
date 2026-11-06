import { Body, Controller, Get, HttpCode, Param, Post } from "@nestjs/common";
import { MemberService } from "../service/member.service";
import { EmailParamsDto, NicknameParamsDto } from "../dto/member-params.dto";
import { CreateMemberDto } from "../dto/create-member.dto";
import { success } from "../dto/api-response";

@Controller("members")
export class MemberController {
  constructor(private readonly members: MemberService) {}

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
