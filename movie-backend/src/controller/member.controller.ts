import { Controller, Get, Param } from "@nestjs/common";
import { MemberService } from "../service/member.service";
import { EmailParamsDto, NicknameParamsDto } from "../dto/member-params.dto";

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
}
