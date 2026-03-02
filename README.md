# MoonBit Lottie

[English](./README.md) | [简体中文](./README_zh.md)

A Lottie animation player implemented in MoonBit.

🎬 **[Live Demo](https://lottie.cg-zhou.top)**

## Stats

[![Passed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-passed.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Total Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Source Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-source.json)](https://github.com/cg-zhou/moon-lottie/actions)

## Features
- ✅ **Core Feature Support**: Supports common shapes (Rect, Ellipse, Path), Fill, Stroke, Gradient, and Trim Path.
- ✅ **Layer & Composition**: Full support for layer transforms, nested pre-compositions, Masks, and Matte.
- ✅ **Developer Friendly**: Automatically identifies and reports unsupported Lottie fields for easier debugging.
- ✅ **Flexible Rendering**: Provides SVG string output and direct Canvas rendering for Wasm platforms.
- **TODO**: More features are under active development.

## Quick Start
```bash
# Run tests
moon test

# Build and serve the demo locally
moon build --target wasm-gc
cd demo && npx serve .
```

## License
MIT
