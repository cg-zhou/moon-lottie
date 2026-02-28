# MoonBit Lottie

A high-performance Lottie animation player for MoonBit, targeting Wasm and Native.

## Stats

[![Tests](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Passed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-passed.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/coverage.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Total Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Source Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-source.json)](https://github.com/cg-zhou/moon-lottie/actions)

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

## Demo

The demo is published at: https://cg-zhou.github.io/moon-lottie/

## Directory Structure
- `lib/`: Core logic (Parser, Model, Renderer).
- `samples/`: Lottie JSON test fixtures.
- `test/`:
  - `snapshot_tool/`: Reference generator using lottie-web.
  - `snapshots/`: Baseline SVG snapshots.
- `demo/`: Web-based inspection tool.

## License
MIT
