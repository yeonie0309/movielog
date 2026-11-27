import type { INestApplication } from "@nestjs/common";
import type { Request, Response, NextFunction } from "express";
import {
  Registry,
  Counter,
  Histogram,
  collectDefaultMetrics,
} from "prom-client";

const installed = new WeakMap<INestApplication, Registry>();
const excluded = new Set(["/metrics", "/health"]);
const methods = new Set([
  "GET",
  "POST",
  "PATCH",
  "PUT",
  "DELETE",
  "OPTIONS",
  "HEAD",
]);

// A registry belongs to one app, preventing cross-app series and duplicate registration.
export function configureMetrics(app: INestApplication): Registry {
  const existing = installed.get(app);
  if (existing) return existing;
  const registry = new Registry();
  const requests = new Counter({
    name: "http_requests_total",
    help: "Completed application HTTP requests; health and metrics excluded",
    labelNames: ["method", "route", "status"],
    registers: [registry],
  });
  const duration = new Histogram({
    name: "http_request_duration_seconds",
    help: "Application response duration in seconds",
    labelNames: ["method", "route", "status"],
    buckets: [0.05, 0.1, 0.2, 0.3, 0.5, 0.8, 1, 1.5, 3, 5, 10],
    registers: [registry],
  });
  collectDefaultMetrics({ register: registry });
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = process.hrtime.bigint();
    let recorded = false;
    const record = () => {
      if (recorded || excluded.has(req.path)) return;
      recorded = true;
      // After finish the exception filter has set the actual HTTP status.
      // Never use originalUrl, IDs, queries, emails or arbitrary 404 paths as labels.
      const matched =
        typeof req.route?.path === "string" ? req.route.path : "/unmatched";
      if (matched.startsWith("/docs") || matched.startsWith("/swagger-ui"))
        return;
      const labels = {
        method: methods.has(req.method) ? req.method : "OTHER",
        route: matched,
        status: String(res.statusCode),
      };
      requests.inc(labels);
      duration.observe(labels, Number(process.hrtime.bigint() - start) / 1e9);
    };
    res.once("finish", record);
    next();
  });
  const adapter = app.getHttpAdapter();
  adapter.get("/metrics", async (_req: Request, res: Response) => {
    try {
      res.setHeader("Content-Type", registry.contentType);
      res.end(await registry.metrics());
    } catch {
      res.status(500).end("Metrics unavailable");
    }
  });
  app.enableShutdownHooks();
  installed.set(app, registry);
  return registry;
}
