# MoonBit Lottie

[English](./README.md) | [简体中文](./README_zh.md) | [MoonBit Package](./README.mbt.md)

Moon Lottie is a Lottie animation rendering engine developed in [MoonBit](https://www.moonbitlang.com/). It provides a complete, cross-platform animation solution—from low-level JSON parsing to high-performance Wasm and JS rendering in the browser.

🎬 **[Live Demo](https://lottie.cg-zhou.top)**

[![Passed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-passed.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/coverage.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Total Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Source Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-source.json)](https://github.com/cg-zhou/moon-lottie/actions)

## Project Layers

- **Core Engine**: Typed Lottie model, parser, and rendering logic written in native MoonBit.
- **Runtime**: High-performance execution via Wasm-GC and fallback JS.
- **Frontend SDKs**: Modern wrappers for Vanilla JS, React, and Web Components.
- **Toolchain**: A CLI tool for server-side or local frame-by-frame SVG exporting.

## Project Structure

| Path | Description |
| --- | --- |
| `lib/` | **The Core**: Parsing, modeling, and platform-agnostic rendering. |
| `cmd/player_runtime` | Wasm-GC and JS bridge for browser environments. |
| `cmd/svg_cli` | CLI utility for SVG batch exporting. |
| `packages/` | Official wrappers for Vanilla JS, React, and Web Components. |
| `demo/` | The project site (Preview, Playground, and features). |
| `packages/examples/` | Standalone integration examples to verify SDK behavior. |

## Quick Start

### Development Environment
- [MoonBit toolchain](https://www.moonbitlang.com/download/)
- [Node.js](https://nodejs.org/) 20+

### Installation & Test
```bash
moon update
npm install
moon test
```

### Local Development
1. Build runtimes:
   ```bash
   moon build --target wasm-gc
   moon build --target js
   ```
2. Start development server:
   ```bash
   npm run dev:site
   ```

### Build & Deployment
```bash
# Full build pipeline (Packages + Site + Examples)
npm run build:deploy
```

Build artifacts will be generated in `deploy-dist/` with the following structure:
- Site: `/`
- Independent Examples: `/examples/moon-lottie-core/` and `/examples/moon-lottie-react/`

## Usage Guide

### Web SDK (Coming Soon)
SDKs in `packages/*` are currently under active development.

**React Integration Example:**
```jsx
import MoonLottiePlayer from '@moon-lottie/react'

function App() {
  return (
    <MoonLottiePlayer
      src="/animation.json"
      autoplay
      wasmPath="/runtime/wasm/moon-lottie-runtime.wasm"
    />
  )
}
```

### SVG Export CLI
Export animations to individual SVG frames directly from your terminal:
```bash
# Export all frames from a JSON file
moon run cmd/svg_cli -- input.json -o ./output_frames
```

## Features & Roadmap

Moon-lottie aims for full Lottie spec coverage. Current capabilities include:

- ✅ **Shapes**: Ellipse, Rect, Polystar, Path (with Trim Path & Rounding support).
- ✅ **Compositing**: Layer masks, track mattes, and nested pre-compositions.
- ✅ **Assets**: Full image layer support.
- ✅ **Expressions**: JS-hosted expression evaluation.
- 🚧 **Dashes (TODO)**: Dashed stroke implementation (in progress).

For detail coverage, please refer to our [Feature Matrix](https://lottie.cg-zhou.top/features).

MIT
