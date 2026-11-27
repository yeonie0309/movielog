// Workbook-only servers bind loopback. Memory mode never connects to MySQL.
require("reflect-metadata");
const fs = require("node:fs");
async function main() {
  let app;
  if (process.argv.includes("--memory")) {
    const ctx = await require("../test/helpers/memory-app.cjs").memoryApp();
    app = ctx.app;
    const member = await ctx.members.save(
      ctx.members.create({
        email: "swagger-fixture@example.com",
        nickname: "문서실습회원",
        password: "not-a-real-login-password",
      }),
    );
    fs.writeFileSync(
      "/private/tmp/movielog-week9-swagger-auth.local.json",
      JSON.stringify({
        accessToken: ctx.jwt.sign({
          sub: String(member.memberId),
          email: member.email,
        }),
        purpose: "Isolated disposable memory DB Swagger fixture only",
      }),
      { mode: 0o600 },
    );
  } else {
    const { NestFactory } = require("@nestjs/core");
    const { AppModule } = require("../dist/app.module");
    app = await NestFactory.create(AppModule, { logger: false });
    require("../dist/configure-app").configureApp(app);
    require("../dist/swagger").configureSwagger(app);
  }
  const port = process.argv.includes("--memory") ? 3019 : 3009;
  await app.listen(port, "127.0.0.1");
  console.log(
    "Week9 " +
      (port === 3019 ? "isolated memory DB" : "real MySQL") +
      " API http://127.0.0.1:" +
      port +
      "/swagger-ui",
  );
  async function stop() {
    await app.close();
    if (port === 3019)
      fs.rmSync("/private/tmp/movielog-week9-swagger-auth.local.json", {
        force: true,
      });
    process.exit(0);
  }
  process.once("SIGINT", stop);
  process.once("SIGTERM", stop);
}
main().catch((e) => {
  console.error(e.name + ": " + e.message);
  process.exitCode = 1;
});
