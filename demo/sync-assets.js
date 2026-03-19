import fs from 'fs';
import path from 'path';

// 源目录和目标目录
const WASM_SOURCE = path.join('..', '_build', 'wasm-gc', 'debug', 'build', 'cmd', 'main', 'main.wasm');
const SAMPLES_SOURCE = path.join('..', 'samples');
const TARGET_DIR = './';

function copyFileSync(src, dest) {
  try {
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, dest);
      console.log(`[Sync] Copied: ${src} -> ${dest}`);
    } else {
      console.warn(`[Sync] Source not found: ${src}`);
    }
  } catch (err) {
    console.error(`[Sync] Error copying ${src}:`, err.message);
  }
}

function copyFolderSync(src, dest) {
  try {
    if (!fs.existsSync(src)) {
      console.warn(`[Sync] Source folder not found: ${src}`);
      return;
    }
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    const entries = fs.readdirSync(src, { withFileTypes: true });
    for (let entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);

      if (entry.isDirectory()) {
        copyFolderSync(srcPath, destPath);
      } else if (entry.isFile() && entry.name.endsWith('.json')) {
        fs.copyFileSync(srcPath, destPath);
      }
    }
    console.log(`[Sync] Synced JSON samples from ${src}`);
  } catch (err) {
    console.error(`[Sync] Error syncing folder ${src}:`, err.message);
  }
}

// 执行同步
console.log('[Sync] Starting assets synchronization...');

// 1. 同步 WASM
copyFileSync(WASM_SOURCE, path.join(TARGET_DIR, 'main.wasm'));

// 2. 同步 Samples (JSON 文件)
copyFolderSync(SAMPLES_SOURCE, path.join(TARGET_DIR, 'samples'));

console.log('[Sync] Finished.');
