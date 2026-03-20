import fs from "fs";
import path from "path";

const WASM_SOURCE_DEBUG = path.join("..", "_build", "wasm-gc", "debug", "build", "cmd", "main", "main.wasm");
const WASM_SOURCE_RELEASE = path.join("..", "_build", "wasm-gc", "release", "build", "cmd", "main", "main.wasm");
const JS_SOURCE_DEBUG = path.join("..", "_build", "js", "debug", "build", "cmd", "main", "main.js");
const JS_SOURCE_RELEASE = path.join("..", "_build", "js", "release", "build", "cmd", "main", "main.js");
const SAMPLES_SOURCE = path.join("..", "samples");
const TARGET_DIR = "./public";

function copyFileSync(src, dest) {
  try {
    if (fs.existsSync(src)) {
      if (!fs.existsSync(path.dirname(dest))) {
        fs.mkdirSync(path.dirname(dest), { recursive: true });
      }
      fs.copyFileSync(src, dest);
      console.log(`[Sync] Copied: ${src} -> ${dest}`);
    }
  } catch (err) {
    console.error(`[Sync] Error copying ${src}:`, err.message);
  }
}

function copyFolderSync(src, dest) {
  try {
    if (!fs.existsSync(src)) return;
    if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (let entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);
      if (entry.isDirectory()) copyFolderSync(srcPath, destPath);
      else if (entry.isFile() && entry.name.endsWith(".json")) fs.copyFileSync(srcPath, destPath);
    }
  } catch (err) {
    console.error(`[Sync] Error syncing folder ${src}:`, err.message);
  }
}

console.log("[Sync] Starting...");
if (fs.existsSync(WASM_SOURCE_RELEASE)) copyFileSync(WASM_SOURCE_RELEASE, path.join(TARGET_DIR, "main.wasm"));
else copyFileSync(WASM_SOURCE_DEBUG, path.join(TARGET_DIR, "main.wasm"));
if (fs.existsSync(JS_SOURCE_RELEASE)) copyFileSync(JS_SOURCE_RELEASE, path.join(TARGET_DIR, "moonbit-js", "main.js"));
else copyFileSync(JS_SOURCE_DEBUG, path.join(TARGET_DIR, "moonbit-js", "main.js"));
copyFolderSync(SAMPLES_SOURCE, path.join(TARGET_DIR, "samples"));
console.log("[Sync] Finished.");
