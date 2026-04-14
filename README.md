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
- **Toolchain**: A unified CLI for server-side SVG exporting and terminal animation playback.

## Project Structure

| Path | Description |
| --- | --- |
| `lib/` | **The Core**: Parsing, modeling, and platform-agnostic rendering. |
| `cmd/player_runtime` | Wasm-GC and JS bridge for browser environments. |
| `cmd/cli` | Unified CLI for SVG export and console rendering. |
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
1. Preparation:
   ```bash
   moon update
   npm install
   ```
2. Start development server:
   ```bash
   # Automatically builds MoonBit core and syncs products
   npm run dev
   ```

### Build & Deploy
```bash
# Full build process (core compilation, package sync, site, and examples)
npm run build:deploy
```

Build artifacts will be generated in `deploy-dist/` with the following structure:
- Site (Preview & Features): `/`
- Core SDK Example: `/examples/moon-lottie-core/`
- React SDK Example: `/examples/moon-lottie-react/`
- Unified Runtimes: `/runtime/js/` and `/runtime/wasm/`

## Usage Guide

### Web SDK (Alpha)
SDKs are located in `packages/*`.

**React Integration:**
```jsx
import { MoonLottiePlayer } from '@moon-lottie/react'

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

### Moon Lottie CLI
Export animations to SVG frames or render them directly in the terminal:
```bash
# Print basic animation info
moon run cmd/cli -- ./samples/5_fireworks.json

# Play the animation in the terminal
moon run cmd/cli -- play ./samples/5_fireworks.json

# Export frames as SVG files
moon run cmd/cli -- svg ./samples/5_fireworks.json -o ./output_frames
```

## Features & Roadmap

Moon-lottie aims for full Lottie spec coverage. Current capabilities include:

- ✅ **Shapes**: Ellipse, Rect, Polystar, Path (with Trim Path & Rounding support).
- ✅ **Compositing**: Layer masks, track mattes, and nested pre-compositions.
- ✅ **Assets**: Full image layer support.
- ✅ **Expressions**: JS-hosted expression evaluation.
- ✅ **Strokes**: Line caps, line joins, and dashed strokes across renderers.

For detail coverage, please refer to our [Feature Matrix](https://lottie.cg-zhou.top/features).

MIT
