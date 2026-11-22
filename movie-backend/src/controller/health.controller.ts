import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";
import { DataSource } from "typeorm";

// ALB readiness: a running process must also be able to reach its database.
@Controller("health")
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  @Get()
  async check() {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      await Promise.race([
        this.dataSource.query("SELECT 1"),
        new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error("Readiness timeout")), 2000);
        }),
      ]);
      return { status: "ok", version: process.env.APP_VERSION ?? "development" };
    } catch {
      // Database addresses, credentials and driver errors must not reach clients.
      throw new ServiceUnavailableException("Service is not ready");
    } finally {
      if (timer) clearTimeout(timer);
    }
  }
}
