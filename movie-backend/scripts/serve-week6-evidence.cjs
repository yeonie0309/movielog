// Local-only request UI: no secrets, no simulated responses, no filesystem browsing.
const { createServer } = require("node:http");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const page = path.resolve(__dirname, "../docs/week6-request-console.html");
const report = path.resolve(
  __dirname,
  "../../evidence/week6-backend/live-api-results.json",
);
createServer((req, res) => {
  if (req.url !== "/" && req.url !== "/report.json") {
    res.writeHead(404);
    res.end();
    return;
  }
  res.setHeader(
    "Content-Type",
    req.url === "/"
      ? "text/html; charset=utf-8"
      : "application/json; charset=utf-8",
  );
  res.setHeader("Cache-Control", "no-store");
  res.end(readFileSync(req.url === "/" ? page : report));
}).listen(5173, "127.0.0.1", () =>
  console.log(
    "Week 6 real request console: http://localhost:5173 (local only)",
  ),
);
