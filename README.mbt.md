# MoonBit Lottie

Moon Lottie is a Lottie animation rendering engine developed in [MoonBit](https://www.moonbitlang.com/). It provides a complete, cross-platform animation solution—from low-level JSON parsing to high-performance Wasm and JS rendering.

## Project Layers

- **Core Engine**: Typed Lottie model, parser, and rendering logic written in native MoonBit.
- **Runtime Bridge**: JS and Wasm-GC entry packages for browser-side playback and SVG frame generation.
- **Toolchain**: A unified CLI for animation inspection, frame-by-frame SVG exporting, and Drawille console rendering.

## Features

- **Typed Lottie Model**: A comprehensive and type-safe representation of the Lottie specification.
- **High-Performance Parser**: Fast JSON parsing with unknown-key reporting for spec compliance tracking.
- **Integrated Runtime Entry**: Browser-facing runtime exports for JS and Wasm-GC hosts.
- **Flexible Rendering**:
  - `SvgRenderer`: Frame-by-frame SVG string generation.
  - `CanvasRenderer`: High-performance rendering for browser Canvas.
  - `DrawilleRenderer`: Terminal Braille/Drawille rendering for console playback.
- **Tooling Included**: Built-in CLI for local inspection, SVG export, and terminal playback.
- **Expression Support**: Pluggable expression evaluation via host-provided handlers.

## Package Layout

| Module | Description |
| --- | --- |
| `lib/math` | Foundational math helpers used by interpolation, transforms, and path processing. |
| `lib/model` | Data structures for animations, layers, shapes, paths, and properties. |
| `lib/parser` | JSON to Model parsing and compatibility reporting. |
| `lib/runtime` | Property interpolation and expression engine integration. |
| `lib/renderer` | Rendering backends (Canvas, SVG) and the `Player` controller. |
| `cmd/player_runtime` | JS / Wasm-GC runtime entry package for browser-side playback and SVG frame rendering. |
| `cmd/cli` | CLI entry package for animation inspection, SVG export, and terminal playback. |

## Quick Start (MoonBit)

### Installation

Add this module to your project:

```bash
moon add cg-zhou/moon_lottie
```

### Basic Usage

Render the first frame of a Lottie animation to an SVG string:

```moonbit
import "cg-zhou/moon_lottie/lib/parser" @parser
import "cg-zhou/moon_lottie/lib/renderer" @renderer
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

## CLI

Use the bundled CLI package to inspect or render a local Lottie JSON file:

```bash
moon run cmd/cli -- ./animation.json
moon run cmd/cli -- play ./animation.json
moon run cmd/cli -- svg ./animation.json -o ./output_frames
```

## Runtime Entry Package

`cmd/player_runtime` is the browser-facing entry package for JS and Wasm-GC hosts. It exposes player creation and update helpers for Canvas playback and SVG frame rendering, and expects host-provided bindings for loading animation JSON and evaluating expressions.

## Known Gaps

- **Marker Support**: Under active development.
- **Expressions**: Current implementation relies on JS host hooks for evaluation.

For full repository details, SDK usage, and CLI instructions, please refer to the main [README.md](./README.md).

For detailed feature coverage, see the [Feature Matrix](https://lottie.cg-zhou.top/features).
