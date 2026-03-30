# @moon-lottie/core

High-performance Lottie animation player powered by **MoonBit**.

## Features

- **Blazing Fast**: Core logic written in MoonBit, compiled to Wasm-GC for native-like performance.
- **Lightweight**: Zero external dependencies in the core runtime.
- **Cross-Platform**: Seamlessly switches between Wasm-GC and Pure JS runtimes.
- **Ready to Use**: Includes imperative API and Web Component support.

## Installation

```bash
npm install @moon-lottie/core
```

## Basic Usage (Imperative API)

```javascript
import { loadAnimation } from '@moon-lottie/core'

const player = loadAnimation({
  container: document.getElementById('lottie-container'),
  path: '/path/to/animation.json',
  autoplay: true,
  loop: true,
  // Auto-loaded from CDN if not provided locally
  wasmPath: 'https://unpkg.com/@moon-lottie/core/runtime/moon-lottie-runtime.wasm'
})

await player.whenReady()
player.play()
```

## Web Component Usage

```javascript
import '@moon-lottie/core/web-component'
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
