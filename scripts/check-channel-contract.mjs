import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const root = process.argv[2]
  ? pathToFileURL(resolve(process.argv[2]) + "/")
  : new URL("../", import.meta.url);
const manifest = JSON.parse(await readFile(new URL("release-channel.json", root), "utf8"));
const readme = await readFile(new URL("README.md", root), "utf8");

assert.deepEqual(manifest, {
  schemaVersion: 1,
  lifecycle: "active-release-channel",
  owner: "Cortex maintainer",
  sourceRepository: "makekosmos/cortex",
  channelRepository: "makekosmos/desktop",
  artifact: "public Windows installers and updater metadata",
  releaseUnit: "one Kosmos Desktop release",
  assets: {
    installer: "Kosmos-Setup-<version>.exe",
    blockmap: "Kosmos-Setup-<version>.exe.blockmap",
    updater: "latest.yml",
  },
  verification: {
    repository: "makekosmos/cortex",
    path: "desktop/scripts/verify-release-channel.mjs",
    command: "bun desktop/scripts/verify-release-channel.mjs",
  },
});

for (const marker of [
  "Lifecycle: active release channel",
  "makekosmos/cortex",
  "Owner: Cortex maintainer",
  "Artifact: public Windows installers and updater metadata",
  "Release unit: one Kosmos Desktop release",
  "does not accept product source",
  "cortex/desktop/scripts/verify-release-channel.mjs",
  "bun run check",
]) {
  assert.ok(readme.includes(marker), `README is missing: ${marker}`);
}

console.log("Desktop release-channel contract is valid");
