const { before, after, beforeEach, test } = require("node:test");
const assert = require("node:assert/strict");
const { Test } = require("@nestjs/testing");
const { JwtModule, JwtService } = require("@nestjs/jwt");
const { getRepositoryToken } = require("@nestjs/typeorm");
const { DataSource, QueryFailedError } = require("typeorm");
const request = require("supertest");
const { Favorite } = require("../dist/entity/favorite.entity");
const { Member } = require("../dist/entity/member.entity");
const { Rating } = require("../dist/entity/rating.entity");
const {
  FavoriteController,
} = require("../dist/controller/favorite.controller");
const {
  MovieRecordController,
} = require("../dist/controller/movie-record.controller");
const { FavoriteService } = require("../dist/service/favorite.service");
const { MovieRecordService } = require("../dist/service/movie-record.service");
const { configureApp } = require("../dist/configure-app");
const { configureSwagger } = require("../dist/swagger");
let app, jwt, favorites, ratings, next, failFavorite;
const matches = (row, where) =>
  Object.entries(where).every(([key, value]) =>
    key === "member"
      ? row.member.memberId === value.memberId
      : row[key] === value,
  );
const memberRepo = {
  findOneBy: async ({ memberId }) =>
    memberId === 1 || memberId === 2 ? { memberId } : null,
};
const favoriteRepo = {
  exists: async ({ where }) => favorites.some((row) => matches(row, where)),
  create: (value) => ({ ...value }),
  save: async (value) => {
    if (failFavorite) throw failFavorite;
    const row = { ...value, favoriteId: next++, createdAt: new Date() };
    favorites.push(row);
    return row;
  },
  find: async ({ where, order }) => {
    assert.equal(order.favoriteId, "DESC");
    return favorites
      .filter((row) => matches(row, where))
      .sort((a, b) => b.favoriteId - a.favoriteId);
  },
  delete: async (where) => {
    const old = favorites.length;
    favorites = favorites.filter((row) => !matches(row, where));
    return { affected: old - favorites.length };
  },
};
const ratingRepo = {
  exists: async ({ where }) => ratings.some((row) => matches(row, where)),
  create: (value) => ({ ...value }),
  save: async (value) => {
    const row = {
      ...value,
      ratingId: next++,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    ratings.push(row);
    return row;
  },
};
const dataSource = {
  transaction: async (callback) => {
    const beforeFavorites = [...favorites],
      beforeRatings = [...ratings];
    try {
      return await callback({
        getRepository: (entity) =>
          entity === Member
            ? memberRepo
            : entity === Rating
              ? ratingRepo
              : favoriteRepo,
      });
    } catch (error) {
      favorites = beforeFavorites;
      ratings = beforeRatings;
      throw error;
    }
  },
};
before(async () => {
  const module = await Test.createTestingModule({
    imports: [
      JwtModule.register({
        global: true,
        secret: "week8-tests-only-at-least-32-characters",
      }),
    ],
    controllers: [FavoriteController, MovieRecordController],
    providers: [
      FavoriteService,
      MovieRecordService,
      { provide: getRepositoryToken(Member), useValue: memberRepo },
      { provide: getRepositoryToken(Favorite), useValue: favoriteRepo },
      { provide: DataSource, useValue: dataSource },
    ],
  }).compile();
  app = module.createNestApplication();
  configureApp(app);
  configureSwagger(app);
  await app.init();
  jwt = module.get(JwtService);
});
after(async () => app?.close());
beforeEach(() => {
  favorites = [];
  ratings = [];
  next = 1;
  failFavorite = null;
});
const token = (id = 1) =>
  "Bearer " +
  jwt.sign({ sub: String(id), email: "test@example.com" }, { expiresIn: 3600 });
const call = (method, path, id = 1) =>
  request(app.getHttpServer())[method](path).set("Authorization", token(id));
test("all five operations reject missing authentication", async () => {
  for (const [method, path] of [
    ["post", "/favorites"],
    ["get", "/favorites"],
    ["get", "/favorites/550"],
    ["delete", "/favorites/550"],
    ["post", "/movie-records"],
  ]) {
    const response = await request(app.getHttpServer())[method](path);
    assert.equal(response.status, 401);
    assert.equal(response.body.code, "AUTH401_2");
  }
});
test("create, duplicate, own ordered list, status and delete contracts", async () => {
  assert.equal(
    (await call("get", "/favorites/550")).body.result.isFavorite,
    false,
  );
  const first = await call("post", "/favorites").send({ movieId: 550 });
  assert.equal(first.status, 201);
  assert.equal(typeof first.body.result.favoriteId, "number");
  assert.ok(first.body.result.createdAt);
  assert.equal(
    (await call("post", "/favorites").send({ movieId: 550 })).body.code,
    "FAVORITE409_1",
  );
  await call("post", "/favorites").send({ movieId: 238 });
  assert.deepEqual(
    (await call("get", "/favorites")).body.result.map((r) => r.movieId),
    [238, 550],
  );
  assert.equal(
    (await call("get", "/favorites/550")).body.result.isFavorite,
    true,
  );
  const removed = await call("delete", "/favorites/550");
  assert.equal(removed.status, 200);
  assert.equal(removed.body.result, null);
  assert.equal(
    (await call("delete", "/favorites/550")).body.code,
    "FAVORITE404_1",
  );
});
test("members can favorite same movie and cannot list or delete each others relation", async () => {
  await call("post", "/favorites").send({ movieId: 550 });
  assert.deepEqual((await call("get", "/favorites", 2)).body.result, []);
  assert.equal(
    (await call("get", "/favorites/550", 2)).body.result.isFavorite,
    false,
  );
  assert.equal((await call("delete", "/favorites/550", 2)).status, 404);
  assert.equal(
    (await call("post", "/favorites", 2).send({ movieId: 550 })).status,
    201,
  );
  assert.equal(favorites.length, 2);
});
test("favorite body and path validation reject invalid or unsafe IDs and memberId injection", async () => {
  for (const movieId of [0, -1, 1.5, "550", null, Number.MAX_SAFE_INTEGER + 1])
    assert.equal(
      (await call("post", "/favorites").send({ movieId })).status,
      400,
    );
  assert.equal(
    (await call("post", "/favorites").send({ movieId: 550, memberId: 2 }))
      .status,
    400,
  );
  for (const value of ["0", "-1", "1.5", "bad", "9007199254740992"])
    assert.equal((await call("get", "/favorites/" + value)).status, 400);
});
test("movie records commit both rows or rating only with favorite null", async () => {
  const both = await call("post", "/movie-records").send({
    movieId: 238,
    score: 5,
    comment: "좋아요",
    addToFavorites: true,
  });
  assert.equal(both.status, 201);
  assert.equal(both.body.result.rating.score, 5);
  assert.equal(both.body.result.favorite.movieId, 238);
  const only = await call("post", "/movie-records").send({
    movieId: 550,
    score: 4,
    addToFavorites: false,
  });
  assert.equal(only.status, 201);
  assert.equal(only.body.result.favorite, null);
  assert.equal(only.body.result.rating.comment, null);
});
test("movie record validates score, comment, boolean and unexpected properties", async () => {
  const valid = { movieId: 238, score: 5, addToFavorites: true };
  for (const patch of [
    { score: 0 },
    { score: 6 },
    { score: 1.5 },
    { score: "5" },
    { comment: 23 },
    { comment: "a".repeat(501) },
    { addToFavorites: "false" },
    { addToFavorites: null },
    { memberId: 2 },
  ])
    assert.equal(
      (await call("post", "/movie-records").send({ ...valid, ...patch }))
        .status,
      400,
    );
  assert.equal(
    (await call("post", "/movie-records").send({ movieId: 238, score: 5 }))
      .status,
    400,
  );
});
test("preexisting favorite or rating does not add partial movie record rows", async () => {
  await call("post", "/favorites").send({ movieId: 238 });
  assert.equal(
    (
      await call("post", "/movie-records").send({
        movieId: 238,
        score: 5,
        addToFavorites: true,
      })
    ).body.code,
    "FAVORITE409_1",
  );
  assert.equal(ratings.length, 0);
  await call("post", "/movie-records").send({
    movieId: 550,
    score: 4,
    addToFavorites: false,
  });
  assert.equal(
    (
      await call("post", "/movie-records").send({
        movieId: 550,
        score: 5,
        addToFavorites: true,
      })
    ).body.code,
    "RATING409_1",
  );
  assert.equal(favorites.length, 1);
});
test("second write UNIQUE failure propagates and is mapped without SQL or parameter leakage", async () => {
  failFavorite = new QueryFailedError(
    "private SQL",
    ["private parameter"],
    Object.assign(new Error("private driver message"), {
      errno: 1062,
      sqlMessage:
        "Duplicate entry 'private-value' for key 'favorite.uk_favorite_member_movie'",
    }),
  );
  const response = await call("post", "/movie-records").send({
    movieId: 238,
    score: 5,
    addToFavorites: true,
  });
  assert.equal(response.status, 409);
  assert.equal(response.body.code, "FAVORITE409_1");
  assert.equal(ratings.length, 0);
  assert.equal(favorites.length, 0);
  assert.ok(!JSON.stringify(response.body).includes("private"));
});
test("unexpected second write failure returns generic 500 and propagates rollback", async () => {
  failFavorite = new Error("private internals");
  const response = await call("post", "/movie-records").send({
    movieId: 238,
    score: 5,
    addToFavorites: true,
  });
  assert.equal(response.status, 500);
  assert.equal(response.body.code, "COMMON500");
  assert.equal(ratings.length, 0);
  assert.ok(!JSON.stringify(response.body).includes("private"));
});
test("Swagger lists protected operations, required record fields and response examples", async () => {
  const doc = configureSwagger(app);
  for (const [path, method] of [
    ["/favorites", "post"],
    ["/favorites", "get"],
    ["/favorites/{movieId}", "get"],
    ["/favorites/{movieId}", "delete"],
    ["/movie-records", "post"],
  ])
    assert.deepEqual(doc.paths[path][method].security, [{ bearer: [] }]);
  assert.deepEqual(
    doc.paths["/movie-records"].post.requestBody.content["application/json"]
      .schema.required,
    ["movieId", "score", "addToFavorites"],
  );
  assert.equal(
    doc.paths["/favorites"].post.responses[409].content["application/json"]
      .example.code,
    "FAVORITE409_1",
  );
});
