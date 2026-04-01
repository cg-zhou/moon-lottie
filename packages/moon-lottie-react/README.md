# @moon-lottie/react

The **React** wrapper for [@moon-lottie/core](https://www.npmjs.com/package/@moon-lottie/core).

## Installation

```bash
npm install @moon-lottie/core @moon-lottie/react
```

## Basic Usage

```jsx
import { MoonLottiePlayer } from '@moon-lottie/react'

function App() {
  return (
    <MoonLottiePlayer
      src="/animation.json"
      autoplay
      loop
      wasmPath="/runtime/moon-lottie-runtime.wasm"
      jsRuntimePath="/runtime/moon-lottie-runtime.js"
    />
  )
}
```

## Ref API

```jsx
import { useEffect, useRef } from 'react'
import { MoonLottiePlayer } from '@moon-lottie/react'

function App() {
  const playerRef = useRef(null)

  useEffect(() => {
    playerRef.current?.whenReady()?.then(() => {
      playerRef.current?.playSegments([[0, 30], [45, 90]], true)
    })
  }, [])

  return (
    <MoonLottiePlayer
      ref={playerRef}
      src="/animation.json"
      wasmPath="/runtime/moon-lottie-runtime.wasm"
      jsRuntimePath="/runtime/moon-lottie-runtime.js"
    />
  )
}
```

Common handle methods:

- `whenReady()`
- `play()` / `pause()` / `stop()` / `toggle()`
- `seek(frame)`
- `goToAndPlay(value, isFrame)` / `goToAndStop(value, isFrame)`
- `playSegments(segments, forceFlag)`
- `switchRuntime('auto' | 'wasm' | 'js')`
- `getState()` / `getBackend()` / `getPreference()`

## Props

Common props:

- `src` / `path`
- `animationData`
- `autoplay`
- `loop`
- `speed`
- `direction`
- `background`
- `rendererSettings`
- `initialSegment`
- `wasmPath`
- `jsRuntimePath`
- `className`
- `style`

## Events

React callback props:

- `onLoad`
- `onError`
- `onRuntimeChange`
- `onEnterFrame`
- `onPlay`
- `onPause`
- `onComplete`
- `onLoopComplete`
- `onDestroy`

## Notes

- The current public renderer is `canvas`.
- Runtime preference defaults to `auto`, which tries Wasm first and falls back to JS.
- If you need direct imperative control outside React, use `loadAnimation` from `@moon-lottie/core`.
