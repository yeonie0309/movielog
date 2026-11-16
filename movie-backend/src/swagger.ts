import type { INestApplication } from "@nestjs/common";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

export function configureSwagger(app: INestApplication) {
  const config = new DocumentBuilder()
    .setTitle("MovieLog 8주차 API")
    .setDescription(
      "공개 회원가입·로그인·중복 확인·회원별 평점 조회와 Bearer 인증이 필요한 내 정보·평점 쓰기·즐겨찾기·영화 기록을 구분합니다. 요청에 memberId를 보내지 않습니다.",
    )
    .setVersion("8.0")
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  const favorite = {
    favoriteId: 1,
    movieId: 550,
    createdAt: "2026-11-17T00:00:00.000Z",
  };
  const rating = {
    ratingId: 1,
    movieId: 238,
    score: 5,
    comment: "다시 보고 싶은 영화입니다.",
    createdAt: "2026-11-17T00:00:00.000Z",
    updatedAt: "2026-11-17T00:00:00.000Z",
  };
  const examples = [
    {
      path: "/favorites",
      method: "post" as const,
      status: 201,
      result: favorite,
      message: "즐겨찾기를 등록했습니다.",
    },
    {
      path: "/favorites",
      method: "get" as const,
      status: 200,
      result: [favorite],
      message: "내 즐겨찾기 목록을 조회했습니다.",
    },
    {
      path: "/favorites/{movieId}",
      method: "get" as const,
      status: 200,
      result: { isFavorite: true },
      message: "즐겨찾기 여부를 조회했습니다.",
    },
    {
      path: "/favorites/{movieId}",
      method: "delete" as const,
      status: 200,
      result: null,
      message: "즐겨찾기를 해제했습니다.",
    },
    {
      path: "/movie-records",
      method: "post" as const,
      status: 201,
      result: { rating, favorite: { ...favorite, movieId: 238 } },
      message: "영화 기록을 저장했습니다.",
    },
  ];
  for (const entry of examples) {
    const operation = document.paths[entry.path]?.[entry.method];
    if (!operation) continue;
    operation.security = [{ bearer: [] }];
    operation.responses = {
      [entry.status]: {
        description: entry.message,
        content: {
          "application/json": {
            example: {
              isSuccess: true,
              code: `COMMON${entry.status}`,
              message: entry.message,
              result: entry.result,
            },
          },
        },
      },
      400: { description: "입력 검증 실패 · COMMON400" },
      401: {
        description: "AUTH401_2 토큰 누락 / AUTH401_3 무효 / AUTH401_4 만료",
        content: {
          "application/json": {
            example: {
              isSuccess: false,
              code: "AUTH401_2",
              message: "로그인이 필요합니다.",
              result: null,
            },
          },
        },
      },
    };
    if (entry.method === "post") {
      operation.responses[409] = {
        description:
          "FAVORITE409_1 즐겨찾기 중복. 영화 기록은 RATING409_1 평점 중복도 반환합니다.",
        content: {
          "application/json": {
            example: {
              isSuccess: false,
              code: "FAVORITE409_1",
              message: "이미 이 영화를 즐겨찾기하셨습니다.",
              result: null,
            },
          },
        },
      };
      operation.responses[404] = { description: "MEMBER404_1 회원 없음" };
    }
    if (entry.method === "delete") {
      operation.responses[404] = {
        description: "FAVORITE404_1 해제할 즐겨찾기 없음",
        content: {
          "application/json": {
            example: {
              isSuccess: false,
              code: "FAVORITE404_1",
              message: "즐겨찾기한 영화를 찾을 수 없습니다.",
              result: null,
            },
          },
        },
      };
    }
    if (entry.path.includes("{movieId}")) {
      operation.parameters = [
        {
          name: "movieId",
          in: "path",
          required: true,
          schema: {
            type: "integer",
            minimum: 1,
            maximum: Number.MAX_SAFE_INTEGER,
          },
          example: 550,
        },
      ];
    }
  }
  document.paths["/movie-records"].post!.requestBody = {
    required: true,
    content: {
      "application/json": {
        schema: {
          type: "object",
          additionalProperties: false,
          required: ["movieId", "score", "addToFavorites"],
          properties: {
            movieId: {
              type: "integer",
              minimum: 1,
              maximum: Number.MAX_SAFE_INTEGER,
              example: 238,
            },
            score: { type: "integer", minimum: 1, maximum: 5, example: 5 },
            comment: {
              type: "string",
              nullable: true,
              maxLength: 500,
              example: "다시 보고 싶은 영화입니다.",
            },
            addToFavorites: { type: "boolean", example: true },
          },
        },
      },
    },
  };
  // Mark existing protected operations while leaving public operations without security.
  for (const path of ["/members/me", "/ratings", "/ratings/{ratingId}"]) {
    const item = document.paths[path];
    if (!item) continue;
    for (const method of ["get", "post", "patch", "delete"] as const) {
      if (item[method]) item[method]!.security = [{ bearer: [] }];
    }
  }
  SwaggerModule.setup("docs", app, document, {
    swaggerOptions: { persistAuthorization: false },
  });
  return document;
}
