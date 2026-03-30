# @moon-lottie/react

The **React** wrapper for [@moon-lottie/core](https://www.npmjs.com/package/@moon-lottie/core).

## Installation

```bash
npm install @moon-lottie/core @moon-lottie/react
```

## Usage

```jsx
import MoonLottiePlayer from '@moon-lottie/react'

function App() {
  return (
    <MoonLottiePlayer
      src="/animation.json"
      autoplay
      loop
      // You can point to custom or CDN hosted runtime
      wasmPath="https://unpkg.com/@moon-lottie/core/runtime/moon-lottie.wasm"
    />
  )
}
```

## Features

- **Blazing Fast**: Leverages MoonBit Engine (Wasm-GC).
- **Ref Support**: Access the underlying player via `useRef`.
- **Props-driven**: Control playback and segments via React props.
- **Wasm-GC optimized**: Pre-checks for Wasm-GC support and falls back to JS automatically.
