# MoonBit Lottie

A high-performance Lottie animation player for MoonBit, targeting Wasm and Native.

## Features
- ✅ **Industrial Parser**: Robust Lottie JSON ingestion with L1 reporting.
- ✅ **Deterministic Renderer**: SVG-based regression testing suite.
- ✅ **Cross-platform**: Support for Web (Wasm) and Native targets.

## Quick Start
```bash
# Run tests
moon test

# Build Demo
moon build --target wasm-gc
cd demo && npx serve .
```

## Directory Structure
- `lib/`: Core logic (Parser, Model, Renderer).
- `samples/`: Lottie JSON test fixtures.
- `test/`:
  - `snapshot_tool/`: Reference generator using lottie-web.
  - `snapshots/`: Baseline SVG snapshots.
- `demo/`: Web-based inspection tool.

## License
MIT
