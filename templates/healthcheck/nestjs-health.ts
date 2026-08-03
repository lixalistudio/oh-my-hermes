import { Controller, Get } from "@nestjs/common";

// Copy to: src/health/health.controller.ts
// Register in a module: controllers: [HealthController]
// Returns HTTP 200 with { status, version, timestamp } when healthy.
// Better Stack and health-check skill poll this endpoint.

@Controller("api/health")
export class HealthController {
  @Get()
  getHealth() {
    return {
      status: "ok",
      version: process.env.npm_package_version ?? "1.0.0",
      timestamp: new Date().toISOString(),
    };
  }
}
