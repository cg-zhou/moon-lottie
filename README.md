# MoonBit Lottie

A high-performance Lottie animation player for MoonBit, targeting Wasm and Native.

🎬 **[Live Demo](https://lottie.cg-zhou.top/)**

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
- ✅ **Rich Model**: `Color`, `BlendMode`, `MatteMode`, `FillRule`, `LineCap`, `LineJoin` — migrated from [lottie-rs](https://github.com/zimond/lottie-rs).

## Quick Start
```bash
# Run tests
moon test

# Build and serve the demo locally
moon build --target wasm-gc
cd demo && npx serve .
```

## Directory Structure
- `lib/math/`: Vector, matrix, bezier, and interpolation utilities.
- `lib/model/`: Lottie data model (animation, layer, shape, color, enums).
- `lib/parser/`: Lottie JSON parser with unknown-key reporting.
- `lib/runtime/`: Property evaluator (keyframe interpolation, easing).
- `lib/renderer/`: SVG and Wasm canvas renderers.
- `samples/`: Lottie JSON test fixtures.
- `test/`: Regression snapshots and snapshot generation tool.
- `demo/`: Web-based interactive inspection tool.

## License
MIT
