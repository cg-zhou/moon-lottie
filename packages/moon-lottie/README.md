# moon-lottie

High-performance Lottie animation player powered by **MoonBit**.

## Features

- **Blazing Fast**: Core logic written in MoonBit, compiled to Wasm-GC for native-like performance.
- **Lightweight**: Zero external dependencies in the core runtime.
- **Cross-Platform**: Seamlessly switches between Wasm-GC and fallback JS runtimes.
- **Ready to Use**: Includes imperative API and Web Component support.

## Installation

```bash
npm install moon-lottie
```

## Basic Usage (Imperative API)

```javascript
import { loadAnimation } from 'moon-lottie'

const player = loadAnimation({
  container: document.getElementById('lottie-container'),
  path: '/path/to/animation.json',
  autoplay: true,
  loop: true,
  // Path to the included wasm runtime
  wasmPath: '/node_modules/moon-lottie/runtime/moon-lottie.wasm'
})

await player.whenReady()
player.play()
```

## Web Component Usage

```javascript
import 'moon-lottie/web-component'
```

```html
<moon-lottie 
  src="/animation.json" 
  autoplay="true" 
  loop="true">
</moon-lottie>
```

## Advanced

For React users, check out `moon-lottie-react`.
For MoonBit developers, see [README.mbt.md](https://github.com/cg-zhou/moon-lottie/blob/main/README.mbt.md).
