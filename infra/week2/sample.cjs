// Run only inside the disposable app container. Never print credentials.
const fs = require('node:fs');
const mysql = require('node:module').createRequire('/app/package.json')('mysql2/promise');
const cpu = () => fs.readFileSync('/proc/stat', 'utf8').split('\n')[0].trim().split(/\s+/).slice(1).map(Number);
(async () => {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST, port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  });
  let previous = cpu();
  for (let i = 0; i < 600; i++) {
    await new Promise(resolve => setTimeout(resolve, 2000));
    const next = cpu();
    // guest/guest_nice are included in user/nice; exclude them from total.
    const deltas = next.slice(0, 8).map((value, index) => value - previous[index]);
    const total = deltas.reduce((a, b) => a + b, 0);
    const [rows] = await connection.query("SHOW GLOBAL STATUS WHERE Variable_name IN ('Threads_connected', 'Threads_running')");
    const status = Object.fromEntries(rows.map(row => [row.Variable_name, Number(row.Value)]));
    fs.appendFileSync('/tmp/infra2-samples.jsonl', JSON.stringify({
      at: Date.now(), cpuPercent: total ? 100 * (1 - deltas[3] / total) : 0, ...status,
    }) + '\n');
    previous = next;
  }
  await connection.end();
})().catch(error => { console.error('Sampler failed:', error.code || error.name); process.exitCode = 1; });
