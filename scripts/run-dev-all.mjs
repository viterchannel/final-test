import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");

function loadEnvFile() {
  const envPath = path.join(root, ".env");
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const index = trimmed.indexOf("=");
    if (index === -1) continue;
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim().replace(/^["']|["']$/g, "");
    if (!process.env[key]) process.env[key] = value;
  }
}

function run(name, args, env) {
  const child = spawn("pnpm", args, {
    cwd: root,
    env: { ...process.env, ...env },
    stdio: ["ignore", "pipe", "pipe"],
  });

  child.stdout.on("data", (chunk) => process.stdout.write(`[${name}] ${chunk}`));
  child.stderr.on("data", (chunk) => process.stderr.write(`[${name}] ${chunk}`));
  child.on("exit", (code) => {
    if (code !== 0) {
      console.error(`[${name}] exited with code ${code}`);
      process.exitCode = code ?? 1;
    }
  });
  return child;
}

loadEnvFile();

const apiTarget = process.env.VITE_API_PROXY_TARGET || "http://127.0.0.1:8080";
const apiDomain = process.env.EXPO_PUBLIC_DOMAIN || "localhost:8080";

const processes = [
  run("api", ["--filter", "@workspace/api-server", "dev"], {
    PORT: process.env.API_PORT || "8080",
    NODE_ENV: "development",
  }),
  run("admin", ["--filter", "@workspace/admin", "dev"], {
    PORT: process.env.ADMIN_PORT || "5173",
    BASE_PATH: "/admin/",
    VITE_API_PROXY_TARGET: apiTarget,
  }),
  run("vendor", ["--filter", "@workspace/vendor-app", "dev"], {
    PORT: process.env.VENDOR_PORT || "5174",
    BASE_PATH: "/vendor/",
    VITE_API_PROXY_TARGET: apiTarget,
  }),
  run("rider", ["--filter", "@workspace/rider-app", "dev"], {
    PORT: process.env.RIDER_PORT || "5175",
    BASE_PATH: "/rider/",
    VITE_API_PROXY_TARGET: apiTarget,
  }),
  run("mobile-web", ["--filter", "@workspace/ajkmart", "dev:web"], {
    PORT: process.env.MOBILE_WEB_PORT || "19006",
    EXPO_PUBLIC_DOMAIN: apiDomain,
    // ajkmart's dev:web hardcodes EXPO_PUBLIC_DOMAIN=$REPLIT_DEV_DOMAIN; shadow it.
    REPLIT_DEV_DOMAIN: process.env.REPLIT_DEV_DOMAIN || apiDomain,
    REPLIT_EXPO_DEV_DOMAIN: process.env.REPLIT_EXPO_DEV_DOMAIN || apiDomain,
    REPL_ID: process.env.REPL_ID || "local",
  }),
];

console.log("AJKMart dev services started:");
console.log("API: http://localhost:8080/api");
console.log("Admin: http://localhost:5173/admin/");
console.log("Vendor: http://localhost:5174/vendor/");
console.log("Rider: http://localhost:5175/rider/");
console.log("Customer web: http://localhost:19006");

function shutdown() {
  for (const child of processes) child.kill("SIGTERM");
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);