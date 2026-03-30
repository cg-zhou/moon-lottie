import fs from 'fs';
import path from 'path';

const SRC_DIR = path.resolve('_build');
const TARGET_DIR = path.resolve('packages/moon-lottie/runtime');

const MAPPINGS = [
    {
        sources: [
            'wasm-gc/release/build/cmd/player_runtime/player_runtime.wasm',
            'wasm-gc/debug/build/cmd/player_runtime/player_runtime.wasm'
        ],
        dest: 'moon-lottie-runtime.wasm'
    },
    {
        sources: [
            'js/release/build/cmd/player_runtime/player_runtime.js',
            'js/debug/build/cmd/player_runtime/player_runtime.js'
        ],
        dest: 'moon-lottie-runtime.js'
    }
];

const LEGACY_FILES = ['moon-lottie.wasm', 'moon-lottie.js'];

console.log('[Release Sync] Starting...');

if (!fs.existsSync(TARGET_DIR)) {
    fs.mkdirSync(TARGET_DIR, { recursive: true });
}

for (const legacyFile of LEGACY_FILES) {
    const legacyPath = path.join(TARGET_DIR, legacyFile);
    if (fs.existsSync(legacyPath)) {
        fs.rmSync(legacyPath, { force: true });
        console.log(`[Release Sync] Removed legacy file: ${legacyFile}`);
    }
}

let success = true;
MAPPINGS.forEach(mapping => {
    const srcPath = mapping.sources
        .map(source => path.join(SRC_DIR, source))
        .find(candidate => fs.existsSync(candidate));
    const destPath = path.join(TARGET_DIR, mapping.dest);

    if (srcPath) {
        fs.copyFileSync(srcPath, destPath);
        console.log(`[Release Sync] Copied: ${path.relative(SRC_DIR, srcPath)} -> ${mapping.dest}`);
    } else {
        console.error(`[Release Sync] Missing source candidates: ${mapping.sources.map(source => path.join(SRC_DIR, source)).join(', ')}`);
        success = false;
    }
});

if (success) {
    console.log('[Release Sync] Finished successfully.');
} else {
    console.error('[Release Sync] Finished with errors.');
    process.exit(1);
}
