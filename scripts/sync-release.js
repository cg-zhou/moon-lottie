import fs from 'fs';
import path from 'path';

const SRC_DIR = path.resolve('_build');
const TARGET_DIR = path.resolve('packages/moon-lottie/runtime');

const MAPPINGS = [
    {
        src: 'wasm-gc/release/build/cmd/player_runtime/player_runtime.wasm',
        dest: 'moon-lottie.wasm'
    },
    {
        src: 'js/release/build/cmd/player_runtime/player_runtime.js',
        dest: 'moon-lottie.js'
    }
];

console.log('[Release Sync] Starting...');

if (!fs.existsSync(TARGET_DIR)) {
    fs.mkdirSync(TARGET_DIR, { recursive: true });
}

let success = true;
MAPPINGS.forEach(mapping => {
    const srcPath = path.join(SRC_DIR, mapping.src);
    const destPath = path.join(TARGET_DIR, mapping.dest);

    if (fs.existsSync(srcPath)) {
        fs.copyFileSync(srcPath, destPath);
        console.log(`[Release Sync] Copied: ${mapping.src} -> ${mapping.dest}`);
    } else {
        console.error(`[Release Sync] Missing source: ${srcPath}`);
        success = false;
    }
});

if (success) {
    console.log('[Release Sync] Finished successfully.');
} else {
    console.error('[Release Sync] Finished with errors.');
    process.exit(1);
}
