import { ValidationPipe, type INestApplication } from "@nestjs/common";

export function configureApp(
  app: INestApplication,
  env: NodeJS.ProcessEnv = process.env,
) {
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );
  if (env.CORS_DISABLED !== "true") {
    app.enableCors({
      origin: (env.CORS_ORIGINS ?? "http://localhost:5173")
        .split(",")
        .map((value) => value.trim()),
      methods: ["GET", "POST", "PATCH", "DELETE"],
      allowedHeaders: ["Content-Type", "Authorization"],
      credentials: false,
    });
  }
}
