const { test } = require('node:test');
const assert = require('node:assert/strict');
const { HealthController } = require('../dist/controller/health.controller');

test('readiness checks the database before returning success', async () => {
  const queries = [];
  const health = new HealthController({ query: async (sql) => queries.push(sql) });
  assert.deepEqual(await health.check(), { status: 'ok', version: process.env.APP_VERSION ?? 'development' });
  assert.deepEqual(queries, ['SELECT 1']);
});

test('readiness failure returns 503 without leaking database details', async () => {
  const health = new HealthController({ query: async () => { throw new Error('secret-db-password'); } });
  await assert.rejects(health.check(), (error) => {
    assert.equal(error.getStatus(), 503);
    assert.equal(JSON.stringify(error.getResponse()).includes('secret-db-password'), false);
    return true;
  });
});

test('an unresponsive database cannot hold readiness open indefinitely', async () => {
  const health = new HealthController({ query: () => new Promise(() => {}) });
  await assert.rejects(health.check(), (error) => error.getStatus() === 503);
});
