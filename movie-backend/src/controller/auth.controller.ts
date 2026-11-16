import { Body, Controller, HttpCode, Post } from "@nestjs/common";
import { AuthService } from "../service/auth.service";
import { LoginRequestDto } from "../dto/login-request.dto";
import { success } from "../dto/api-response";

@Controller("auth")
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post("login")
  @HttpCode(200)
  async login(@Body() dto: LoginRequestDto) {
    return success(await this.auth.login(dto), "로그인에 성공했습니다.");
  }
}
