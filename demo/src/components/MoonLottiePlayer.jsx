import React, { forwardRef, useEffect, useImperativeHandle, useRef, useState } from "react"

function normalizeSpeed(value) {
  const parsed = Number(value)
  if (!Number.isFinite(parsed)) return 1
  return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10))
}

function normalizeDirection(value) {
  return Number(value) < 0 ? -1 : 1
}

function getSourceOptions({ src, path, animationData, name }) {
  if (animationData) {
    return {
      animationData,
      name: name || "animation.json",
    }
  }

  const resolvedPath = path || src
  if (!resolvedPath) {
    return null
  }

  return {
    path: resolvedPath,
    name: name || resolvedPath,
  }
}

const MoonLottiePlayer = forwardRef(function MoonLottiePlayer(
  {
    src,
    path,
    animationData,
    name,
    lottieRef,
    autoplay = true,
    loop = true,
    speed = 1,
    direction = 1,
    background = "transparent",
    renderer = "canvas",
    rendererSettings,
    initialSegment,
    className = "",
    onLoad,
    onError,
    onDestroy,
    onRuntimeChange,
    onEnterFrame,
    onComplete,
    onLoopComplete,
    onPlay,
    onPause,
  },
  ref,
) {
  const containerRef = useRef(null)
  const playerRef = useRef(null)
  const listenersCleanupRef = useRef([])
  const [isReady, setIsReady] = useState(false)

  useImperativeHandle(ref, () => ({
    whenReady: () => playerRef.current?.whenReady(),
    loadAnimation: (options) => playerRef.current?.loadAnimation(options),
    load: (options) => playerRef.current?.load(options),
    play: () => playerRef.current?.play(),
    pause: () => playerRef.current?.pause(),
    stop: () => playerRef.current?.stop(),
    destroy: () => playerRef.current?.destroy(),
    setSpeed: (value) => playerRef.current?.setSpeed(value),
    setDirection: (value) => playerRef.current?.setDirection(value),
    setLoop: (value) => playerRef.current?.setLoop(value),
    setBackground: (value) => playerRef.current?.setBackground(value),
    goToAndStop: (value, isFrame = false) => playerRef.current?.goToAndStop(value, isFrame),
    goToAndPlay: (value, isFrame = false) => playerRef.current?.goToAndPlay(value, isFrame),
    playSegments: (segments, forceFlag = false) => playerRef.current?.playSegments(segments, forceFlag),
    setSubframe: (value) => playerRef.current?.setSubframe(value),
    resize: () => playerRef.current?.resize(),
    addEventListener: (type, listener) => playerRef.current?.addEventListener(type, listener),
    removeEventListener: (type, listener) => playerRef.current?.removeEventListener(type, listener),
    getCurrentFrame: () => playerRef.current?.getCurrentFrame() ?? 0,
    getDuration: (inFrames = false) => playerRef.current?.getDuration(inFrames) ?? 0,
    getPlayer: () => playerRef.current,
  }), [])

  useEffect(() => {
    if (!lottieRef) return
    if (typeof lottieRef === "function") {
      lottieRef(playerRef.current)
      return () => lottieRef(null)
    }
    lottieRef.current = playerRef.current
    return () => {
      lottieRef.current = null
    }
  }, [lottieRef, isReady])

  useEffect(() => {
    let disposed = false
    const sourceOptions = getSourceOptions({ src, path, animationData, name })

    async function mountPlayer() {
      if (!containerRef.current) return

      const playerEntry = `${import.meta.env.BASE_URL}player/index.js`
      const mod = await import(/* @vite-ignore */ playerEntry)
      if (disposed || !containerRef.current) return

      const player = mod.loadAnimation({
        container: containerRef.current,
        ...sourceOptions,
        autoplay,
        loop,
        speed: normalizeSpeed(speed),
        direction: normalizeDirection(direction),
        background,
        renderer,
        rendererSettings,
        initialSegment,
      })

      playerRef.current = player
      await player.whenReady?.()
      if (disposed) return
      setIsReady(true)

      const cleanups = [
        player.addEventListener("load", (event) => {
          onLoad?.(event)
        }),
        player.addEventListener("error", (event) => {
          onError?.(event.error || event)
        }),
        player.addEventListener("runtimechange", (event) => {
          onRuntimeChange?.(event)
        }),
        player.addEventListener("enterframe", (event) => {
          onEnterFrame?.(event)
        }),
        player.addEventListener("complete", (event) => {
          onComplete?.(event)
        }),
        player.addEventListener("loopComplete", (event) => {
          onLoopComplete?.(event)
        }),
        player.addEventListener("play", (event) => {
          onPlay?.(event)
        }),
        player.addEventListener("pause", (event) => {
          onPause?.(event)
        }),
        player.addEventListener("destroy", (event) => {
          onDestroy?.(event)
        }),
      ]

      listenersCleanupRef.current = cleanups
    }

    mountPlayer().catch((error) => {
      if (!disposed) {
        onError?.(error)
      }
    })

    return () => {
      disposed = true
      listenersCleanupRef.current.forEach((cleanup) => cleanup?.())
      listenersCleanupRef.current = []
      playerRef.current?.destroy()
      playerRef.current = null
      setIsReady(false)
    }
  }, [src, path, animationData, name, renderer, rendererSettings, initialSegment])

  useEffect(() => {
    if (!playerRef.current || !isReady) return
    playerRef.current.setSpeed(normalizeSpeed(speed))
  }, [speed, isReady])

  useEffect(() => {
    if (!playerRef.current || !isReady) return
    playerRef.current.setDirection(normalizeDirection(direction))
  }, [direction, isReady])

  useEffect(() => {
    if (!playerRef.current || !isReady) return
    playerRef.current.setLoop(loop)
  }, [loop, isReady])

  useEffect(() => {
    if (!playerRef.current || !isReady) return
    playerRef.current.setBackground(background)
  }, [background, isReady])

  return <div ref={containerRef} className={["moon-lottie-react-player", className].filter(Boolean).join(" ")} />
})

export default MoonLottiePlayer