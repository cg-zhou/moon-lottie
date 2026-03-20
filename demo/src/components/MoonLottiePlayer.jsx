import React, { forwardRef, useEffect, useImperativeHandle, useRef, useState } from "react"

function normalizeSpeed(value) {
  const parsed = Number(value)
  if (!Number.isFinite(parsed)) return 1
  return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10))
}

function normalizeDirection(value) {
  return Number(value) < 0 ? -1 : 1
}

const MoonLottiePlayer = forwardRef(function MoonLottiePlayer(
  {
    src,
    autoplay = true,
    loop = true,
    speed = 1,
    direction = 1,
    background = "transparent",
    className = "",
    onLoad,
    onError,
    onRuntimeChange,
    onEnterFrame,
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
    play: () => playerRef.current?.play(),
    pause: () => playerRef.current?.pause(),
    stop: () => playerRef.current?.stop(),
    setSpeed: (value) => playerRef.current?.setSpeed(value),
    setDirection: (value) => playerRef.current?.setDirection(value),
    setLoop: (value) => playerRef.current?.setLoop(value),
    setBackground: (value) => playerRef.current?.setBackground(value),
    getCurrentFrame: () => playerRef.current?.getCurrentFrame() ?? 0,
    getDuration: (inFrames = false) => playerRef.current?.getDuration(inFrames) ?? 0,
    getPlayer: () => playerRef.current,
  }), [])

  useEffect(() => {
    let disposed = false

    async function mountPlayer() {
      if (!containerRef.current) return

      const playerEntry = `${import.meta.env.BASE_URL}player/index.js`
      const mod = await import(/* @vite-ignore */ playerEntry)
      if (disposed || !containerRef.current) return

      const player = mod.loadAnimation({
        container: containerRef.current,
        path: src,
        autoplay,
        loop,
        speed: normalizeSpeed(speed),
        direction: normalizeDirection(direction),
        background,
      })

      playerRef.current = player

      const cleanups = [
        player.addEventListener("load", (event) => {
          onLoad?.(event)
          setIsReady(true)
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
        player.addEventListener("play", (event) => {
          onPlay?.(event)
        }),
        player.addEventListener("pause", (event) => {
          onPause?.(event)
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
  }, [src])

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