import { execSync } from "node:child_process";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const scriptsDir = __dirname;
const root = path.resolve(scriptsDir, "..");
const require = createRequire(import.meta.url);
const jsBezier = require("bezier-easing");

const output = execSync("moon run src/cmd/compare", {
  cwd: root,
  encoding: "utf8",
});

let maxDiff = 0;
let lines = 0;

for (const line of output.trim().split(/\r?\n/)) {
  if (!line) continue;
  const [x1s, y1s, x2s, y2s, xs, moonYs] = line.split(",");
  const x1 = Number(x1s);
  const y1 = Number(y1s);
  const x2 = Number(x2s);
  const y2 = Number(y2s);
  const x = Number(xs);
  const moonY = Number(moonYs);
  const easing = jsBezier(x1, y1, x2, y2);
  const jsY = easing(x);
  const diff = Math.abs(jsY - moonY);
  if (diff > maxDiff) maxDiff = diff;
  lines += 1;
}

console.log(`Compared ${lines} samples`);
console.log(`Max abs diff: ${maxDiff}`);
if (maxDiff > 1e-6) {
  console.error("Diff exceeds threshold 1e-6");
  process.exit(1);
}
console.log("MoonBit output matches JS within threshold.");
