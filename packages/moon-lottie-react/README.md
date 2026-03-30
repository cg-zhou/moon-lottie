# moon-lottie-react

The official **React** wrapper for [moon-lottie](https://www.npmjs.com/package/moon-lottie).

## Installation

```bash
npm install moon-lottie moon-lottie-react
```

## Usage

```jsx
import MoonLottiePlayer from 'moon-lottie-react'

function App() {
  return (
    <MoonLottiePlayer
      src="/animation.json"
      autoplay
      loop
      wasmPath="/runtime/wasm/moon-lottie.wasm"
    />
  )
}
```

## Features

- **Ref Support**: Access the underlying player via `useRef`.
- **Props-driven**: Control playback and segments via React props.
- **Wasm-GC optimized**: Pre-checks for Wasm-GC support and falls back to JS automatically.
