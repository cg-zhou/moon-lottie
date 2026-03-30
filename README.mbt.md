# MoonBit Lottie (Core Library)

[English](./README.md) | [简体中文](./README_zh.md) | [MoonBit Package](./README.mbt.md)

Moon Lottie is a Lottie animation rendering engine developed in [MoonBit](https://www.moonbitlang.com/). It provides a complete, cross-platform animation solution—from low-level JSON parsing to high-performance Wasm and JS rendering.

## Project Layers

- **Core Engine**: Typed Lottie model, parser, and rendering logic written in native MoonBit.
- **Runtime**: High-performance execution via Wasm-GC and fallback JS.
- **Frontend SDKs**: Modern wrappers for Vanilla JS, React, and Web Components.
- **Toolchain**: A CLI tool for server-side or local frame-by-frame SVG exporting.

## Features

- **Typed Lottie Model**: A comprehensive and type-safe representation of the Lottie specification.
- **High-Performance Parser**: Fast JSON parsing with unknown-key reporting for spec compliance tracking.
- **Flexible Rendering**:
  - `SvgRenderer`: Frame-by-frame SVG string generation.
  - `CanvasRenderer`: High-performance rendering for browser Canvas.
- **Expression Support**: Pluggable expression evaluation via host-provided handlers.

## Package Layout

| Module | Description |
| --- | --- |
| `lib/model` | Data structures for animations, layers, shapes, paths, and properties. |
| `lib/parser` | JSON to Model parsing and compatibility reporting. |
| `lib/runtime` | Property interpolation and expression engine integration. |
| `lib/renderer` | Rendering backends (Canvas, SVG) and the `Player` controller. |

## Quick Start (MoonBit)

### Installation

Add this package to your `moon.mod.json`:

```bash
moon update
```

### Basic Usage

Render the first frame of a Lottie animation to an SVG string:

```moonbit
import "cg-zhou/moon-lottie/lib/parser" @parser
import "cg-zhou/moon-lottie/lib/renderer" @renderer
import "moonbitlang/core/json"

fn render_svg(json_text : String) -> String raise {
  // 1. Parse JSON into typed Animation model
  let animation = @parser.parse_animation(@json.parse(json_text))
  
  // 2. Initialize the SVG Renderer
  let svg = @renderer.SvgRenderer::new(
    animation.width.to_double(),
    animation.height.to_double(),
  )
  
  // 3. Create a Player and render a specific frame
  let player = @renderer.Player::new(animation, svg)
  player.set_frame(animation.in_point)
  player.render()
  
  svg.get_output()
}
```

## Known Gaps

- 🚧 **Dashes (TODO)**: Dashed strokes are not implemented in the MoonBit renderer yet.
- **Auto-orient**: Not yet implemented.
- **Marker Support**: Under active development.
- **Expressions**: Current implementation relies on JS host hooks for evaluation.

For full repository details, SDK usage, and CLI instructions, please refer to the main [README.md](./README.md).

For detailed feature coverage, see the [Feature Matrix](https://lottie.cg-zhou.top/features).