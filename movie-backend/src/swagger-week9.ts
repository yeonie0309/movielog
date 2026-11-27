import type {
  OpenAPIObject,
  SchemaObject,
} from "@nestjs/swagger/dist/interfaces/open-api-spec.interface";

const date = "2026-11-28T00:00:00.000Z";
const rating = {
  ratingId: 1,
  movieId: 550,
  score: 5,
  comment: "다시 보고 싶은 영화입니다.",
  createdAt: date,
  updatedAt: date,
};
const member = {
  email: "reader@example.com",
  nickname: "영화조아",
  createdAt: date,
};
const id: SchemaObject = {
  type: "integer",
  minimum: 1,
  maximum: Number.MAX_SAFE_INTEGER,
  example: 550,
};
const nickname: SchemaObject = {
  type: "string",
  minLength: 2,
  maxLength: 12,
  example: "영화조아",
};
const email: SchemaObject = {
  type: "string",
  format: "email",
  maxLength: 254,
  example: "reader@example.com",
};
const score: SchemaObject = {
  type: "integer",
  minimum: 1,
  maximum: 5,
  example: 5,
};
const comment: SchemaObject = {
  type: "string",
  nullable: true,
  maxLength: 500,
  example: "다시 보고 싶은 영화입니다.",
};
type Failure = [number, string, string];
type Entry = {
  path: string;
  method: "get" | "post" | "patch" | "delete";
  tag: string;
  summary: string;
  protected?: boolean;
  status?: number;
  result: unknown;
  message?: string;
  raw?: boolean;
  body?: { properties: Record<string, SchemaObject>; required: string[] };
  errors?: Failure[];
};
const missingMember: Failure = [
  404,
  "MEMBER404_1",
  "해당 회원을 찾을 수 없습니다.",
];
const ratingErrors: Failure[] = [
  [403, "RATING403_1", "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다."],
  [404, "RATING404_1", "해당 평점을 찾을 수 없습니다."],
];
const entries: Entry[] = [
  {
    path: "/members",
    method: "post",
    tag: "회원",
    summary: "회원가입 (공개)",
    status: 201,
    result: { memberId: 1, email: member.email, nickname: member.nickname },
    message: "회원가입에 성공했습니다.",
    body: {
      required: ["email", "nickname", "password"],
      properties: {
        email,
        nickname,
        password: {
          type: "string",
          minLength: 8,
          writeOnly: true,
          example: "Sample123!",
          description: "대문자·소문자·숫자·!@#$%^&* 포함, UTF-8 72바이트 이하",
        },
      },
    },
    errors: [
      [409, "MEMBER4091", "이미 사용 중인 이메일입니다."],
      [409, "MEMBER4092", "이미 사용 중인 닉네임입니다."],
    ],
  },
  {
    path: "/auth/login",
    method: "post",
    tag: "인증",
    summary: "이메일·비밀번호 로그인 (공개)",
    result: { nickname: member.nickname, accessToken: "<로그인 응답의 JWT>" },
    message: "로그인에 성공했습니다.",
    body: {
      required: ["email", "password"],
      properties: {
        email,
        password: {
          type: "string",
          minLength: 1,
          maxLength: 1024,
          writeOnly: true,
          example: "Sample123!",
        },
      },
    },
    errors: [[401, "AUTH401_1", "이메일 또는 비밀번호가 올바르지 않습니다."]],
  },
  {
    path: "/members/nickname/{nickname}",
    method: "get",
    tag: "회원",
    summary: "닉네임 사용 가능 여부 (공개)",
    result: { available: true },
    raw: true,
  },
  {
    path: "/members/email/{email}",
    method: "get",
    tag: "회원",
    summary: "이메일 사용 가능 여부 (공개)",
    result: { available: true },
    raw: true,
  },
  {
    path: "/members/me",
    method: "get",
    tag: "회원",
    summary: "로그인한 내 정보 조회",
    protected: true,
    result: member,
    message: "회원 정보를 조회했습니다.",
    errors: [missingMember],
  },
  {
    path: "/members/me",
    method: "patch",
    tag: "회원",
    summary: "내 닉네임 변경",
    protected: true,
    result: member,
    message: "회원 정보를 수정했습니다.",
    body: { required: ["nickname"], properties: { nickname } },
    errors: [
      missingMember,
      [409, "MEMBER409_1", "이미 사용 중인 닉네임입니다."],
    ],
  },
  {
    path: "/members/{memberId}/ratings",
    method: "get",
    tag: "평점",
    summary: "회원별 평점 최신순 조회 (공개)",
    result: [rating],
    raw: true,
    errors: [missingMember],
  },
  {
    path: "/ratings",
    method: "post",
    tag: "평점",
    summary: "내 평점 등록",
    protected: true,
    status: 201,
    result: rating,
    message: "평점 등록에 성공했습니다.",
    body: {
      required: ["movieId", "score"],
      properties: { movieId: id, score, comment },
    },
    errors: [
      missingMember,
      [409, "RATING409_1", "이미 이 영화에 평점을 남기셨습니다."],
    ],
  },
  {
    path: "/ratings/{ratingId}",
    method: "patch",
    tag: "평점",
    summary: "내가 작성한 평점 수정",
    protected: true,
    result: rating,
    message: "평점 수정에 성공했습니다.",
    body: { required: ["score"], properties: { score, comment } },
    errors: ratingErrors,
  },
  {
    path: "/ratings/{ratingId}",
    method: "delete",
    tag: "평점",
    summary: "내가 작성한 평점 삭제",
    protected: true,
    result: null,
    message: "평점을 삭제했습니다.",
    errors: ratingErrors,
  },
];

function schema(value: unknown): SchemaObject {
  if (value === null) return { nullable: true, example: null };
  if (Array.isArray(value))
    return {
      type: "array",
      items: value.length ? schema(value[0]) : {},
      example: value,
    };
  if (typeof value === "object") {
    const fields = value as Record<string, unknown>;
    return {
      type: "object",
      required: Object.keys(fields),
      properties: Object.fromEntries(
        Object.entries(fields).map(([key, item]) => [key, schema(item)]),
      ),
    };
  }
  return {
    type:
      typeof value === "number"
        ? "integer"
        : typeof value === "boolean"
          ? "boolean"
          : "string",
    example: value,
  };
}

// Enrich generated Nest routes. Existing public raw JSON responses are documented as-is.
export function enrichWeek9Swagger(document: OpenAPIObject) {
  for (const entry of entries) {
    const operation = document.paths[entry.path]?.[entry.method];
    if (!operation) continue; // Partial test modules contain only their own controllers.
    operation.tags = [entry.tag];
    operation.summary = entry.summary;
    operation.description = entry.protected
      ? "Bearer JWT 필수. 사용자 ID는 토큰에서 추출하며 body에 memberId를 받지 않습니다."
      : "공개 API. Authorization 헤더 없이 호출할 수 있습니다.";
    operation.security = entry.protected ? [{ bearer: [] }] : [];
    operation.parameters = [...entry.path.matchAll(/\{(\w+)\}/g)].map(
      (match) => ({
        name: match[1],
        in: "path",
        required: true,
        schema:
          match[1] === "nickname"
            ? nickname
            : match[1] === "email"
              ? email
              : { ...id, example: 1 },
      }),
    );
    if (entry.path === "/members/{memberId}/ratings") {
      operation.description +=
        " page/size 미지정 시 전체 배열. page는 0부터, 기본 size=10. 빈 목록은 []입니다.";
      operation.parameters.push(
        {
          name: "page",
          in: "query",
          required: false,
          schema: { type: "integer", minimum: 0, maximum: 1000000, example: 0 },
        },
        {
          name: "size",
          in: "query",
          required: false,
          schema: { type: "integer", minimum: 1, maximum: 100, example: 10 },
        },
      );
    }
    if (entry.body)
      operation.requestBody = {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              additionalProperties: false,
              ...entry.body,
            },
          },
        },
      };
    const status = entry.status ?? 200;
    const response = entry.raw
      ? entry.result
      : {
          isSuccess: true,
          code: "COMMON" + status,
          message: entry.message,
          result: entry.result,
        };
    operation.responses = {
      [status]: {
        description: entry.message ?? "조회 성공 (원본 JSON 형식)",
        content: {
          "application/json": { schema: schema(response), example: response },
        },
      },
    };
    const failures: Failure[] = [
      [400, "COMMON400", "요청 입력 검증에 실패했습니다."],
      ...(entry.errors ?? []),
    ];
    if (entry.protected)
      failures.push(
        [401, "AUTH401_2", "로그인이 필요한 요청입니다."],
        [401, "AUTH401_3", "유효하지 않은 토큰입니다."],
        [401, "AUTH401_4", "토큰이 만료되었습니다. 다시 로그인해주세요."],
      );
    failures.push([500, "COMMON500", "서버 내부 오류가 발생했습니다."]);
    for (const [errorStatus, code, message] of failures) {
      const previous = operation.responses[errorStatus];
      const previousContent =
        previous && "content" in previous
          ? previous.content?.["application/json"]
          : undefined;
      const value = { isSuccess: false, code, message, result: null };
      operation.responses[errorStatus] = {
        description: [
          previous && "description" in previous ? previous.description : "",
          code + " · " + message,
        ]
          .filter(Boolean)
          .join(" / "),
        content: {
          "application/json": {
            schema: schema(value),
            examples: {
              ...(previousContent?.examples ?? {}),
              [code]: { summary: message, value },
            },
          },
        },
      };
    }
  }
  // Favorite and transaction endpoints retain week 8 response examples.
  for (const path of ["/favorites", "/favorites/{movieId}", "/movie-records"]) {
    const item = document.paths[path];
    if (!item) continue;
    for (const method of ["get", "post", "delete"] as const) {
      const op = item[method];
      if (!op) continue;
      op.tags = [path === "/movie-records" ? "영화 기록" : "즐겨찾기"];
      op.description =
        "Bearer JWT 필수. Authorize에 토큰만 입력합니다. 사용자 ID는 토큰에서 추출합니다.";
    }
  }
}
