import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";

const pnpm = process.platform === "win32" ? process.env.ComSpec ?? "cmd.exe" : "pnpm";
const pnpmArgs = (args) =>
  process.platform === "win32" ? ["/d", "/s", "/c", "pnpm.cmd", ...args] : args;

execFileSync(pnpm, pnpmArgs(["--config.lockfile=false", "install", "--ignore-scripts"]), {
  stdio: "inherit",
});
execFileSync(pnpm, pnpmArgs(["--config.lockfile=false", "run", "check"]), {
  stdio: "inherit",
});

if (existsSync("pnpm-lock.yaml")) {
  throw new Error("No-lock policy failed: pnpm-lock.yaml was created");
}

for (const hook of [".githooks/pre-commit", ".githooks/pre-push"]) {
  const contents = readFileSync(hook, "utf8");
  if (!contents.includes("pnpm run check") || /\bbun\b/i.test(contents)) {
    throw new Error(`Hook policy failed: ${hook} must invoke pnpm run check`);
  }
}

console.log("pnpm no-lock policy passed");
