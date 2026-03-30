import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const currentDir = path.dirname(fileURLToPath(import.meta.url));

test("public sample index entries resolve to existing sample files", () => {
  const repoRoot = path.resolve(currentDir, "..");
  const sampleIndexPath = path.join(repoRoot, "demo", "public", "sample_index.json");

  assert.equal(fs.existsSync(sampleIndexPath), true, "expected demo/public/sample_index.json to be generated");

  const sampleIndex = JSON.parse(fs.readFileSync(sampleIndexPath, "utf8"));
  assert.ok(sampleIndex.length > 0, "expected generated sample index to include samples");

  const missingEntries = sampleIndex
    .map((entry) => entry.file)
    .filter((file, index, files) => files.indexOf(file) === index)
    .filter((file) => !fs.existsSync(path.join(repoRoot, "samples", file)));

  assert.deepEqual(missingEntries, []);
});
