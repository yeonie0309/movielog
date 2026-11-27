require("reflect-metadata");
const path = require("node:path");
const { Test } = require("@nestjs/testing");
const { TypeOrmModule, getRepositoryToken } = require("@nestjs/typeorm");
const { JwtModule, JwtService } = require("@nestjs/jwt");
const { DataSource, getMetadataArgsStorage } = require("typeorm");
const dist = path.resolve(__dirname, "../../dist");
const { Member } = require(path.join(dist, "entity/member.entity"));
const { Rating } = require(path.join(dist, "entity/rating.entity"));
const { Favorite } = require(path.join(dist, "entity/favorite.entity"));
const { configureApp } = require(path.join(dist, "configure-app"));
const { configureSwagger } = require(path.join(dist, "swagger"));

async function memoryApp() {
  // SQLite AUTOINCREMENT requires INTEGER. Only generated PK metadata is adapted.
  // Same production classes, relations, UNIQUE indexes, services and guards are used.
  // Restoration prevents leaking this test-only compatibility adjustment.
  const columns = getMetadataArgsStorage().columns.filter(
    (c) =>
      [Member, Rating, Favorite].includes(c.target) &&
      c.options.primary &&
      c.options.type === "bigint",
  );
  const originals = columns.map((c) => c.options.type);
  columns.forEach((c) => {
    c.options.type = "integer";
  });
  let fixture;
  try {
    fixture = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: "sqljs",
          autoSave: false,
          entities: [Member, Rating, Favorite],
          synchronize: true,
          retryAttempts: 0,
        }),
        TypeOrmModule.forFeature([Member, Rating, Favorite]),
        JwtModule.register({
          global: true,
          secret: "week9-memory-tests-only-not-production",
          signOptions: { expiresIn: 3600 },
        }),
      ],
      controllers: ["auth", "member", "rating", "favorite", "movie-record"].map(
        (name) => {
          const exported = require(
            path.join(dist, "controller/" + name + ".controller"),
          );
          return Object.values(exported)[0];
        },
      ),
      providers: ["auth", "member", "rating", "favorite", "movie-record"].map(
        (name) => {
          const exported = require(
            path.join(dist, "service/" + name + ".service"),
          );
          return Object.values(exported)[0];
        },
      ),
    }).compile();
  } finally {
    columns.forEach((c, i) => {
      c.options.type = originals[i];
    });
  }
  const app = fixture.createNestApplication({ logger: false });
  configureApp(app);
  const document = configureSwagger(app);
  await app.init();
  const db = fixture.get(DataSource);
  return {
    app,
    document,
    db,
    jwt: fixture.get(JwtService),
    members: fixture.get(getRepositoryToken(Member)),
    ratings: fixture.get(getRepositoryToken(Rating)),
    favorites: fixture.get(getRepositoryToken(Favorite)),
    Member,
    Rating,
    Favorite,
  };
}
module.exports = { memoryApp };
