const { test, mock } = require("node:test");
const assert = require("node:assert/strict");
require("reflect-metadata");
const { FavoriteService } = require("../dist/service/favorite.service");
const { RatingService } = require("../dist/service/rating.service");

const codeIs = (code) => (error) => error.getResponse().code === code;
test("favorite unit: 새 영화는 한 번 저장하고 movieId를 반환한다", async () => {
  // given
  const repository = {
    exists: mock.fn(async () => false),
    create: mock.fn((v) => v),
    save: mock.fn(async (v) => ({
      ...v,
      favoriteId: 1,
      createdAt: new Date(),
    })),
  };
  const service = new FavoriteService(repository, {
    findOneBy: async () => ({ memberId: 1 }),
  });
  // when
  const result = await service.create(1, { movieId: 550 });
  // then
  assert.equal(result.movieId, 550);
  assert.equal(repository.save.mock.callCount(), 1);
});
test("favorite unit: 중복이면 FAVORITE409_1, save를 호출하지 않는다", async () => {
  const repository = {
    exists: mock.fn(async () => true),
    create: mock.fn((v) => v),
    save: mock.fn(async (v) => v),
  };
  const service = new FavoriteService(repository, {
    findOneBy: async () => ({ memberId: 1 }),
  });
  await assert.rejects(
    service.create(1, { movieId: 550 }),
    codeIs("FAVORITE409_1"),
  );
  assert.equal(repository.save.mock.callCount(), 0);
});
test("rating unit: 같은 영화 중복 평점이면 RATING409_1, save를 호출하지 않는다", async () => {
  const repository = {
    exists: mock.fn(async () => true),
    create: mock.fn((v) => v),
    save: mock.fn(async (v) => v),
  };
  const service = new RatingService(repository, {
    findOneBy: async () => ({ memberId: 1 }),
  });
  await assert.rejects(
    service.create(1, { movieId: 550, score: 5 }),
    codeIs("RATING409_1"),
  );
  assert.equal(repository.save.mock.callCount(), 0);
});
test("rating unit: 다른 회원의 평점을 수정하면 RATING403_1, 원본과 DB를 바꾸지 않는다", async () => {
  const row = {
    ratingId: 10,
    member: { memberId: 2 },
    score: 3,
    comment: "원본",
  };
  const repository = {
    findOne: mock.fn(async () => row),
    save: mock.fn(async (v) => v),
  };
  const service = new RatingService(repository, {});
  await assert.rejects(
    service.update(10, 1, { score: 5, comment: "변경" }),
    codeIs("RATING403_1"),
  );
  assert.equal(repository.save.mock.callCount(), 0);
  assert.equal(row.score, 3);
  assert.equal(row.comment, "원본");
});
