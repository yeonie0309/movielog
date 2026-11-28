const { test, before, after } = require("node:test");
const assert = require("node:assert/strict");
const { Controller, Get, Param, HttpException } = require("@nestjs/common");
const { Test } = require("@nestjs/testing");
const request = require("supertest");
const { configureApp } = require("../dist/configure-app");
const { configureMetrics } = require("../dist/observability/metrics");
class Probe {
  ok() {
    return { ok: true };
  }
  error() {
    throw new HttpException("denied", 403);
  }
  fail() {
    throw new Error("must-not-leak");
  }
  health() {
    return { ok: true };
  }
}
Controller()(Probe);
for (const [name, path] of [
  ["ok", "ratings/:id"],
  ["error", "forbidden"],
  ["fail", "failure"],
  ["health", "health"],
]) {
  Get(path)(
    Probe.prototype,
    name,
    Object.getOwnPropertyDescriptor(Probe.prototype, name),
  );
}
let app, registry;
before(async () => {
  const module = await Test.createTestingModule({
    controllers: [Probe],
  }).compile();
  app = module.createNestApplication({ logger: false });
  configureApp(app, { METRICS_ENABLED: "true" });
  registry = configureMetrics(app);
  await app.init();
});
after(async () => app?.close());
test("metrics: opt-in disabled preserves old app behavior", async () => {
  const module = await Test.createTestingModule({
    controllers: [Probe],
  }).compile();
  const plain = module.createNestApplication({ logger: false });
  try {
    configureApp(plain, {});
    await plain.init();
    await request(plain.getHttpServer()).get("/metrics").expect(404);
  } finally {
    await plain.close();
  }
});
test("metrics: repeated configuration reuses a per-app registry", () => {
  assert.equal(configureMetrics(app), registry);
});
test("metrics: route template prevents ID/query cardinality and secret leakage", async () => {
  await request(app.getHttpServer())
    .get("/ratings/550?email=private@example.com")
    .expect(200);
  await request(app.getHttpServer()).get("/ratings/551").expect(200);
  const response = await request(app.getHttpServer())
    .get("/metrics")
    .expect(200);
  assert.match(response.headers["content-type"], /text\/plain/);
  assert.match(
    response.text,
    /http_requests_total\{method="GET",route="\/ratings\/:id",status="200"\} 2/,
  );
  assert.ok(!response.text.includes("private@example.com"));
  assert.ok(!response.text.includes('route="/ratings/550"'));
});
test("metrics: records final filter status for HttpException and unexpected error", async () => {
  await request(app.getHttpServer()).get("/forbidden").expect(403);
  await request(app.getHttpServer()).get("/failure").expect(500);
  const text = (await request(app.getHttpServer()).get("/metrics")).text;
  assert.match(text, /route="\/forbidden",status="403"/);
  assert.match(text, /route="\/failure",status="500"/);
  assert.ok(!text.includes("must-not-leak"));
});
test("metrics: arbitrary 404s collapse and probes do not pollute application latency", async () => {
  await request(app.getHttpServer()).get("/health").expect(200);
  await request(app.getHttpServer()).get("/unknown-a").expect(404);
  await request(app.getHttpServer()).get("/unknown-b").expect(404);
  const text = (await request(app.getHttpServer()).get("/metrics")).text;
  assert.match(text, /route="\/unmatched",status="404"\} 2/);
  assert.ok(!text.includes('route="/health"'));
  assert.ok(!text.includes('route="/metrics"'));
  assert.ok(!text.includes("unknown-a"));
});
test("metrics: histogram has SLO 1s boundary, cumulative buckets and Node runtime series", async () => {
  const text = (await request(app.getHttpServer()).get("/metrics")).text;
  assert.match(text, /http_request_duration_seconds_bucket\{le="1",/);
  assert.match(text, /http_request_duration_seconds_count/);
  assert.match(text, /nodejs_heap_size_used_bytes/);
  assert.match(text, /process_cpu_user_seconds_total/);
});
