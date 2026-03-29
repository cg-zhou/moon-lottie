import React, { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { Button, Descriptions, Empty, Input, Radio, Switch, Tag } from "antd"
import {
  animationUsesExpressions,
  createCanvasRuntimeBridge,
  createOfficialPlayerController,
  createPlayer,
  createViewportPresenter,
  getAnimationPlaybackMeta,
  loadSampleIndex,
  resizeCanvasForDpr,
  setExpressionHost,
} from "@moon-lottie/browser-player"

function readPageAspectRatio() {
  const viewport = window.visualViewport
  const width = viewport?.width || window.innerWidth || 1
  const height = viewport?.height || window.innerHeight || 1
  return width > 0 && height > 0 ? width / height : 16 / 9
}

function formatFileSize(size) {
  if (!Number.isFinite(size) || size <= 0) return "-"
  return `${(size / 1024).toFixed(2)} KB`
}

function ensureLottieScriptLoaded() {
  if (window.lottie?.loadAnimation) {
    return Promise.resolve(window.lottie)
  }

  return new Promise((resolve, reject) => {
    const existing = document.querySelector('script[data-moon-lottie-official="true"]')
    if (existing) {
      existing.addEventListener("load", () => resolve(window.lottie), { once: true })
      existing.addEventListener("error", () => reject(new Error("加载 lottie.min.js 失败")), { once: true })
      return
    }

    const script = document.createElement("script")
    script.src = `${import.meta.env.BASE_URL}lottie.min.js`
    script.async = true
    script.dataset.moonLottieOfficial = "true"
    script.onload = () => resolve(window.lottie)
    script.onerror = () => reject(new Error("加载 lottie.min.js 失败"))
    document.head.appendChild(script)
  })
}

function isEditableTarget(target) {
  return target instanceof HTMLInputElement
    || target instanceof HTMLTextAreaElement
    || target instanceof HTMLSelectElement
    || target?.isContentEditable
}

function IconifyIcon({ name, size = 18 }) {
  return <iconify-icon icon={name} width={size} height={size} aria-hidden="true" />
}

const PlaybackTransport = React.memo(function PlaybackTransport({ controllerRef, isPlaying, onStepAnimation }) {
  return (
    <div className="playground-control-cluster">
      <Button className="playground-transport-btn" type="default" title="上一个动画" onClick={() => onStepAnimation(-1)} aria-label="上一个动画" icon={<IconifyIcon name="solar:rewind-back-bold" size={16} />}>
      </Button>
      <Button className="playground-transport-btn" type="default" title="上一帧" onClick={() => controllerRef.current?.stepFrame(-1)} aria-label="上一帧" icon={<IconifyIcon name="solar:alt-arrow-left-bold" size={16} />}>
      </Button>
      <Button className="playground-primary-play-btn" type="default" title={isPlaying ? "暂停" : "播放"} onClick={() => controllerRef.current?.toggle()} aria-label="播放或暂停" icon={<IconifyIcon name={isPlaying ? "solar:pause-bold" : "solar:play-bold"} size={18} />}>
      </Button>
      <Button className="playground-transport-btn" type="default" title="下一帧" onClick={() => controllerRef.current?.stepFrame(1)} aria-label="下一帧" icon={<IconifyIcon name="solar:alt-arrow-right-bold" size={16} />}>
      </Button>
      <Button className="playground-transport-btn" type="default" title="下一个动画" onClick={() => onStepAnimation(1)} aria-label="下一个动画" icon={<IconifyIcon name="solar:rewind-forward-bold" size={16} />}>
      </Button>
    </div>
  )
})

const SpeedControls = React.memo(function SpeedControls({ currentSpeed, setCurrentSpeed }) {
  return (
    <div className="playground-control-cluster">
      <Radio.Group className="playground-speed-group" value={currentSpeed} buttonStyle="solid" onChange={(event) => setCurrentSpeed(event.target.value)}>
        {[0.5, 1, 1.5, 2].map((speed) => (
          <Radio.Button key={speed} value={speed} className="playground-speed-radio">
            {speed}x
          </Radio.Button>
        ))}
      </Radio.Group>
    </div>
  )
})

const BackgroundSelector = React.memo(function BackgroundSelector({ currentBackground, setCurrentBackground }) {
  return (
    <div className="playground-toolbar-picker">
      <Radio.Group className="playground-bg-group" value={currentBackground} buttonStyle="solid" onChange={(event) => setCurrentBackground(event.target.value)}>
        {[
          ["white", "白色", "playground-bg-swatch--white"],
          ["grid", "网格", "playground-bg-swatch--grid"],
          ["black", "黑色", "playground-bg-swatch--black"],
        ].map(([value, label, swatchClass]) => (
          <Radio.Button key={value} value={value} className="playground-bg-radio">
            <span className="playground-bg-radio__content">
              <span className={`playground-bg-swatch ${swatchClass}`} aria-hidden="true" />
              <span className="playground-bg-radio__label">{label}</span>
            </span>
          </Radio.Button>
        ))}
      </Radio.Group>
    </div>
  )
})

const RendererToggle = React.memo(function RendererToggle({ label, value, onChange }) {
  return (
    <label className="playground-renderer-toggle" aria-label={`${label} 渲染器`}>
      <span className="playground-renderer-toggle__label">{label}</span>
      <Radio.Group
        size="small"
        value={value}
        buttonStyle="solid"
        onChange={(event) => onChange(event.target.value)}
      >
        <Radio.Button value="canvas">canvas</Radio.Button>
        <Radio.Button value="svg">svg</Radio.Button>
      </Radio.Group>
    </label>
  )
})

export default function Playground({ active = true }) {
  const workbenchRef = useRef(null)
  const canvasRef = useRef(null)
  const moonSvgContainerRef = useRef(null)
  const viewportRef = useRef(null)
  const wasmWrapperRef = useRef(null)
  const officialWrapperRef = useRef(null)
  const wasmStageRef = useRef(null)
  const officialStageRef = useRef(null)
  const officialContainerRef = useRef(null)
  const fileInputRef = useRef(null)
  const seekBarRef = useRef(null)
  const viewportResizeObserverRef = useRef(null)
  const controllerRef = useRef(null)
  const runtimeBridgeRef = useRef(null)
  const officialControllerRef = useRef(null)
  const viewportPresenterRef = useRef(null)
  const viewportTransformRef = useRef({ scale: 1, offsetX: 0, offsetY: 0, dpr: 1 })
  const runtimeJsonRef = useRef("")
  const imageAssetsRef = useRef([])
  const lastRequestedSampleRef = useRef("")
  const stateRef = useRef({
    currentFileName: "",
    currentFileSize: 0,
    currentAnimationData: null,
    currentAnimationMeta: null,
    currentExpressionAnimationData: null,
    currentExpressionMeta: null,
    nativePlayer: null,
    runtime: null,
  })
  const animationSnapshotRef = useRef(null)
  const compareEnabledRef = useRef(true)
  const currentSpeedRef = useRef(1)
  const resumePlaybackOnActivateRef = useRef(false)

  const [sampleEntries, setSampleEntries] = useState([])
  const [playlistQuery, setPlaylistQuery] = useState("")
  const [playlistOpen, setPlaylistOpen] = useState(false)
  const [detailsOpen, setDetailsOpen] = useState(false)
  const [dropActive, setDropActive] = useState(false)
  const [compareEnabled, setCompareEnabled] = useState(true)
  const [currentSpeed, setCurrentSpeed] = useState(1)
  const [currentBackground, setCurrentBackground] = useState("white")
  const [moonRenderer, setMoonRenderer] = useState("canvas")
  const [officialRenderer, setOfficialRenderer] = useState("svg")
  const [runtimeBackend, setRuntimeBackend] = useState("uninitialized")
  const [statusMessage, setStatusMessage] = useState("初始化 MoonLottie 运行时...")
  const [currentFileName, setCurrentFileName] = useState("")
  const [currentFileSize, setCurrentFileSize] = useState(0)
  const [currentAnimationData, setCurrentAnimationData] = useState(null)
  const [currentAnimationMeta, setCurrentAnimationMeta] = useState(null)
  const [currentExpressionAnimationData, setCurrentExpressionAnimationData] = useState(null)
  const [currentExpressionMeta, setCurrentExpressionMeta] = useState(null)
  const [currentFrame, setCurrentFrame] = useState(0)
  const [isPlaying, setIsPlaying] = useState(false)
  const [statusColor, setStatusColor] = useState("#c7cdd8")
  const [pageAspectRatio, setPageAspectRatio] = useState(() => readPageAspectRatio())

  compareEnabledRef.current = compareEnabled
  currentSpeedRef.current = currentSpeed

  function syncPlayerState(state) {
    stateRef.current = {
      currentFileName: state?.currentFileName || "",
      currentFileSize: state?.currentFileSize || 0,
      currentAnimationData: state?.currentAnimationData || null,
      currentAnimationMeta: state?.currentAnimationMeta || null,
      currentExpressionAnimationData: state?.currentExpressionAnimationData || null,
      currentExpressionMeta: state?.currentExpressionMeta || null,
      nativePlayer: state?.nativePlayer || null,
      runtime: state?.runtime || null,
    }
    if (stateRef.current.currentFileName) {
      lastRequestedSampleRef.current = stateRef.current.currentFileName
    }
    setCurrentFileName(stateRef.current.currentFileName)
    setCurrentFileSize(stateRef.current.currentFileSize)
    setCurrentAnimationData(stateRef.current.currentAnimationData)
    setCurrentAnimationMeta(stateRef.current.currentAnimationMeta)
    setCurrentExpressionAnimationData(stateRef.current.currentExpressionAnimationData)
    setCurrentExpressionMeta(stateRef.current.currentExpressionMeta)
    if (
      stateRef.current.currentAnimationData
      && (
        animationSnapshotRef.current?.animationData !== stateRef.current.currentAnimationData
        || animationSnapshotRef.current?.filename !== stateRef.current.currentFileName
        || animationSnapshotRef.current?.size !== stateRef.current.currentFileSize
      )
    ) {
      animationSnapshotRef.current = {
        filename: stateRef.current.currentFileName,
        size: stateRef.current.currentFileSize,
        animationData: stateRef.current.currentAnimationData,
      }
    }
  }

  function renderCurrentFrame() {
    const runtime = stateRef.current.runtime
    const player = stateRef.current.nativePlayer
    if (runtime && player) {
      runtimeBridgeRef.current?.renderFrame(runtime, player, controllerRef.current?.getCurrentFrame() || 0)
    }
    officialControllerRef.current?.seek(controllerRef.current?.getCurrentFrame() || 0)
  }

  function updateStatus(message, color = null) {
    setStatusMessage(message)
    if (color) {
      setStatusColor(color)
    }
  }

  async function initAnimationList() {
    const entries = await loadSampleIndex()
    setSampleEntries(entries)
    const lastSelected = localStorage.getItem("moon-lottie-last-anim")
    const preferred = entries.find((entry) => entry.file === lastSelected) || entries[0]
    if (preferred) {
      await loadRemoteAnimation(preferred.file)
    }
  }

  async function loadRemoteAnimation(filename) {
    if (!controllerRef.current) return
    lastRequestedSampleRef.current = filename
    try {
      localStorage.setItem("moon-lottie-last-anim", filename)
      const state = await controllerRef.current.loadRemoteAnimation(filename)
      syncPlayerState(state)
      updateStatus(`已加载: ${filename}`, "#34c759")
      return true
    } catch (error) {
      updateStatus(`加载失败: ${error.message}`, "#ff3b30")
      return false
    }
  }

  async function handleFile(file) {
    if (!controllerRef.current) return
    try {
      const state = await controllerRef.current.loadFile(file)
      syncPlayerState(state)
      setPlaylistOpen(false)
      updateStatus(`已加载本地文件: ${file.name}`, "#34c759")
    } catch {
      updateStatus("无效的 JSON 文件", "#ff3b30")
    }
  }

  function scheduleViewportRefresh() {
    controllerRef.current?.scheduleViewportRefresh()
  }

  function updateCompareMode(nextCompareEnabled) {
    setCompareEnabled(nextCompareEnabled)
    compareEnabledRef.current = nextCompareEnabled
    if (stateRef.current.currentAnimationData) {
      const state = controllerRef.current?.refreshCompare()
      if (state) {
        syncPlayerState(state)
      }
    }
  }

  const stepAnimation = useCallback(async (delta) => {
    if (sampleEntries.length === 0) {
      return
    }

    const anchorFile = lastRequestedSampleRef.current || currentFileName
    let currentIndex = sampleEntries.findIndex((entry) => entry.file === anchorFile)
    if (currentIndex < 0) {
      currentIndex = sampleEntries.findIndex((entry) => entry.file === currentFileName)
    }
    if (currentIndex < 0) {
      currentIndex = 0
    }

    for (let attempts = 0; attempts < sampleEntries.length; attempts += 1) {
      const nextIndex = (currentIndex + delta + sampleEntries.length) % sampleEntries.length
      currentIndex = nextIndex
      const nextEntry = sampleEntries[nextIndex]
      if (nextEntry && await loadRemoteAnimation(nextEntry.file)) {
        return
      }
    }

    updateStatus("没有可加载的动画样例", "#ff3b30")
  }, [currentFileName, sampleEntries, lastRequestedSampleRef])

  useEffect(() => {
    function updatePageAspectRatio() {
      setPageAspectRatio((previousRatio) => {
        const nextRatio = readPageAspectRatio()
        return Math.abs(previousRatio - nextRatio) < 0.001 ? previousRatio : nextRatio
      })
    }

    const visualViewport = window.visualViewport
    window.addEventListener("resize", updatePageAspectRatio)
    visualViewport?.addEventListener("resize", updatePageAspectRatio)

    return () => {
      window.removeEventListener("resize", updatePageAspectRatio)
      visualViewport?.removeEventListener("resize", updatePageAspectRatio)
    }
  }, [])

  useEffect(() => {
    scheduleViewportRefresh()
  }, [pageAspectRatio])

  useEffect(() => {
    let disposed = false
    let currentMoonSvgMarkup = ""
    const clearMoonSvgFrame = () => {
      currentMoonSvgMarkup = ""
      moonSvgContainerRef.current?.replaceChildren()
    }

    async function init() {
      await ensureLottieScriptLoaded().catch(() => null)
      if (disposed) return

      const canvas = canvasRef.current
      const moonSvgContainer = moonSvgContainerRef.current
      const viewport = viewportRef.current
      const wasmWrapper = wasmWrapperRef.current
      const officialWrapper = officialWrapperRef.current
      const wasmStage = wasmStageRef.current
      const officialStage = officialStageRef.current
      const officialContainer = officialContainerRef.current
      const seekBar = seekBarRef.current
      if (!canvas || !moonSvgContainer || !viewport || !wasmWrapper || !officialWrapper || !wasmStage || !officialStage || !officialContainer || !seekBar) {
        return
      }

      const ctx = canvas.getContext("2d")
      const parser = new DOMParser()
      const renderMoonSvgFrame = (runtime, nativePlayer, frame) => {
        if (!runtime || !nativePlayer) {
          clearMoonSvgFrame()
          return
        }
        const svgMarkup = runtime.render_svg_frame(nativePlayer, frame)
        if (svgMarkup === currentMoonSvgMarkup) {
          return
        }
        currentMoonSvgMarkup = svgMarkup
        const parsed = parser.parseFromString(svgMarkup, "image/svg+xml")
        const svgElement = parsed.documentElement
        if (svgElement?.tagName.toLowerCase() !== "svg") {
          clearMoonSvgFrame()
          return
        }
        moonSvgContainer.replaceChildren(document.importNode(svgElement, true))
      }
      const renderMoonCanvasFrame = (runtime, nativePlayer, frame) => {
        clearMoonSvgFrame()
        baseRuntimeBridge.renderFrame(runtime, nativePlayer, frame)
      }

      officialControllerRef.current = createOfficialPlayerController({
        container: officialContainer,
        getLottie: () => window.lottie,
        defaultRenderer: officialRenderer,
      })

      viewportPresenterRef.current = createViewportPresenter({
        viewport,
        canvas,
        wasmWrapper,
        officialWrapper,
        wasmStage,
        officialStage,
        officialContainer,
        seekBar,
        resizeCanvasForDpr,
        viewportTransform: viewportTransformRef.current,
        getCompareEnabled: () => compareEnabledRef.current,
        requestRender: () => renderCurrentFrame(),
        updateCurrentFileLabel: () => {},
        infoElements: {},
      })

      const baseRuntimeBridge = createCanvasRuntimeBridge({
        canvas,
        viewportTransform: viewportTransformRef.current,
        getRuntimeAnimationJson: () => runtimeJsonRef.current,
        getImageAssets: () => imageAssetsRef.current,
        getExpressionAnimationData: () => stateRef.current.currentExpressionAnimationData,
        getExpressionMeta: () => stateRef.current.currentExpressionMeta,
        getCanvasContext: () => ctx,
        jsRuntimePath: `${import.meta.env.BASE_URL}runtime/js/moon-lottie-runtime.js`,
      })

      runtimeBridgeRef.current = {
        ...baseRuntimeBridge,
        renderFrame: moonRenderer === "svg" ? renderMoonSvgFrame : renderMoonCanvasFrame,
      }

      controllerRef.current = createPlayer({
        loadWasmRuntime: runtimeBridgeRef.current.loadWasmRuntime,
        loadJsRuntime: runtimeBridgeRef.current.loadJsRuntime,
        officialPlayerController: officialControllerRef.current,
        viewportPresenter: viewportPresenterRef.current,
        getAnimationPlaybackMeta,
        animationUsesExpressions,
        setStatusMessage: (message) => updateStatus(message),
        setExpressionHost,
        setRuntimeAnimationJson: (value) => {
          runtimeJsonRef.current = value
        },
        setImageAssets: (assets) => {
          imageAssetsRef.current = assets
        },
        getSpeed: () => currentSpeedRef.current,
        getCompareEnabled: () => compareEnabledRef.current,
        renderFrame: () => {
          renderCurrentFrame()
        },
        createNativePlayer: (runtime) => moonRenderer === "svg"
          ? runtime.create_svg_animation_from_js()
          : runtime.create_player_from_js(),
        onRuntimeChanged: ({ runtime, backend }) => {
          window.moonLottie = runtime
          window.moonLottieBackend = backend
          setRuntimeBackend(backend)
        },
        onStateChange: (state) => {
          syncPlayerState(state)
        },
        onFrameChange: ({ currentFrame: nextFrame }) => {
          setCurrentFrame((previousFrame) => (previousFrame === nextFrame ? previousFrame : nextFrame))
        },
        onPlayStateChange: ({ isPlaying: nextIsPlaying }) => {
          setIsPlaying(nextIsPlaying)
        },
      })

      try {
        updateStatus("初始化 MoonLottie 运行时...")
        const state = await controllerRef.current.initialize()
        if (disposed) return
        syncPlayerState(state)
        setRuntimeBackend(controllerRef.current.getBackend())
        updateStatus(controllerRef.current.getBackend() === "wasm"
          ? "已就绪，当前使用 Wasm 后端"
          : "已就绪，当前使用 JS 兼容后端", "#34c759")
        const snapshot = animationSnapshotRef.current
        if (snapshot?.animationData) {
          const restoredState = await controllerRef.current.loadFromText(
            JSON.stringify(snapshot.animationData),
            {
              filename: snapshot.filename,
              size: snapshot.size,
            },
          )
          if (disposed) return
          syncPlayerState(restoredState)
          updateStatus(`已切换 MoonLottie 渲染器: ${moonRenderer}`, "#34c759")
          renderCurrentFrame()
        } else {
          await initAnimationList()
        }
      } catch (error) {
        if (!disposed) {
          updateStatus(`错误: ${error.message}`, "#ff3b30")
        }
      }

      if (typeof ResizeObserver === "function") {
        viewportResizeObserverRef.current = new ResizeObserver(() => {
          scheduleViewportRefresh()
        })
        viewportResizeObserverRef.current.observe(viewport)
      }
    }

    init()

    function handleWindowResize() {
      scheduleViewportRefresh()
    }

    function handleKeydown(event) {
      if (isEditableTarget(event.target)) {
        return
      }

      if (event.code === "Space") {
        controllerRef.current?.toggle()
        event.preventDefault()
      } else if (event.code === "Escape") {
        setPlaylistOpen(false)
        setDetailsOpen(false)
      } else if (event.code === "ArrowLeft") {
        controllerRef.current?.stepFrame(-1)
        event.preventDefault()
      } else if (event.code === "ArrowRight") {
        controllerRef.current?.stepFrame(1)
        event.preventDefault()
      } else if (event.code === "ArrowUp") {
        stepAnimation(-1)
        event.preventDefault()
      } else if (event.code === "ArrowDown") {
        stepAnimation(1)
        event.preventDefault()
      }
    }

    function handleDragOver(event) {
      event.preventDefault()
      setDropActive(true)
    }

    function handleDragLeave(event) {
      if (event.clientX === 0 && event.clientY === 0) {
        setDropActive(false)
      }
    }

    function handleDrop(event) {
      event.preventDefault()
      setDropActive(false)
      const file = event.dataTransfer.files?.[0]
      if (file) {
        handleFile(file)
      }
    }

    window.addEventListener("resize", handleWindowResize)
    window.addEventListener("keydown", handleKeydown)
    window.addEventListener("dragover", handleDragOver)
    window.addEventListener("dragleave", handleDragLeave)
    window.addEventListener("drop", handleDrop)

    return () => {
      disposed = true
      viewportResizeObserverRef.current?.disconnect()
      viewportResizeObserverRef.current = null
      window.removeEventListener("resize", handleWindowResize)
      window.removeEventListener("keydown", handleKeydown)
      window.removeEventListener("dragover", handleDragOver)
      window.removeEventListener("dragleave", handleDragLeave)
      window.removeEventListener("drop", handleDrop)
      controllerRef.current?.destroy()
      officialControllerRef.current?.destroy()
      clearMoonSvgFrame()
      controllerRef.current = null
      officialControllerRef.current = null
    }
  }, [moonRenderer])

  useEffect(() => {
    if (!controllerRef.current || !currentAnimationData) return
    scheduleViewportRefresh()
    renderCurrentFrame()
  }, [compareEnabled])

  useEffect(() => {
    if (!officialControllerRef.current) return
    officialControllerRef.current.setRenderer(officialRenderer)
    if (currentAnimationData && compareEnabled) {
      const state = controllerRef.current?.refreshCompare()
      if (state) {
        syncPlayerState(state)
      }
    }
  }, [compareEnabled, currentAnimationData, officialRenderer])

  useEffect(() => {
    if (!controllerRef.current || !currentAnimationData) return

    if (active) {
      scheduleViewportRefresh()
      renderCurrentFrame()
      if (resumePlaybackOnActivateRef.current) {
        controllerRef.current.play()
        resumePlaybackOnActivateRef.current = false
      }
      return
    }

    resumePlaybackOnActivateRef.current = controllerRef.current.isPlaying()
    controllerRef.current.pause()
  }, [active, currentAnimationData])

  const filteredSamples = useMemo(() => {
    const query = playlistQuery.trim().toLowerCase()
    return sampleEntries.filter((entry) => {
      const searchText = `${entry.label} ${entry.file}`.toLowerCase()
      return !query || searchText.includes(query)
    })
  }, [playlistQuery, sampleEntries])

  const infoRuntime = runtimeBackend === "uninitialized"
    ? "未初始化"
    : (runtimeBackend === "wasm" ? "Wasm" : "JS")
  const frameDisplay = `${Math.floor(Math.max(0, currentFrame - (currentAnimationMeta?.inPoint || 0)))} / ${Math.floor(currentAnimationMeta?.totalFrames || 0)}`
  const seekMin = currentAnimationMeta?.inPoint || 0
  const seekMax = (currentAnimationMeta?.inPoint || 0) + (currentAnimationMeta?.totalFrames || 0)
  const detailItems = [
    ["名称", currentFileName || "-"],
    ["大小", formatFileSize(currentFileSize)],
    ["资源版本", currentAnimationMeta?.version || "-"],
    ["持续时间", currentAnimationMeta?.fps > 0 ? `${(currentAnimationMeta.totalFrames / currentAnimationMeta.fps).toFixed(2)} 秒` : "-"],
    ["帧率", currentAnimationMeta?.fps ? `${currentAnimationMeta.fps.toFixed(2)} 帧/秒` : "-"],
    ["总帧数", Number.isFinite(currentAnimationMeta?.totalFrames) ? Math.floor(currentAnimationMeta.totalFrames) : "-"],
    ["设计尺寸", currentAnimationMeta ? `${currentAnimationMeta.width} x ${currentAnimationMeta.height}` : "-"],
    ["运行时", infoRuntime],
    ["状态", statusMessage || "-"],
  ]

  return (
    <div
      ref={workbenchRef}
      className={`playground-workbench${playlistOpen || detailsOpen ? " playground-workbench--overlay-open" : ""}`}
      style={{ "--playground-page-aspect": `${pageAspectRatio}` }}
    >
      <header className="playground-top-toolbar">
        <div className="playground-toolbar-group playground-toolbar-group--grow">
          <Button className="playground-icon-btn" type="default" title="打开播放列表" onClick={() => setPlaylistOpen(true)} aria-label="打开播放列表" icon={<IconifyIcon name="solar:hamburger-menu-bold" size={16} />} />
          <Button className="playground-action-btn" type="primary" onClick={() => fileInputRef.current?.click()} icon={<IconifyIcon name="solar:folder-with-files-bold" size={16} />}>
            打开
          </Button>
          <input ref={fileInputRef} type="file" accept=".json" hidden onChange={(event) => {
            const file = event.target.files?.[0]
            if (file) {
              handleFile(file)
            }
            event.target.value = ""
          }} />
          <div className="playground-current-file">
            <p className="playground-current-file__label">当前文件 <span className="playground-status-dot" style={{ background: statusColor }} /></p>
            <p className="playground-current-file__name">{currentFileName || "选择一个样例或打开本地 JSON"}</p>
          </div>
        </div>
        <div className="playground-toolbar-group playground-toolbar-group--right">
          <BackgroundSelector currentBackground={currentBackground} setCurrentBackground={setCurrentBackground} />
          <label className="playground-toolbar-switch" aria-label="对比模式">
            <span className="playground-toolbar-switch__label">对比</span>
            <Switch checked={compareEnabled} onChange={updateCompareMode} />
          </label>
          <Button className={`playground-toggle-btn ${detailsOpen ? "is-active" : ""}`} type={detailsOpen ? "primary" : "default"} onClick={() => setDetailsOpen((value) => !value)} icon={<IconifyIcon name="solar:info-circle-bold" size={16} />}>
            详情
          </Button>
        </div>
      </header>

      <div className={`playground-backdrop ${playlistOpen ? "is-open" : ""}`} onClick={() => setPlaylistOpen(false)} />
      <aside className={`playground-drawer ${playlistOpen ? "is-open" : ""}`} aria-hidden={playlistOpen ? "false" : "true"}>
        <div className="playground-drawer-header">
          <h2 className="playground-drawer-title">播放列表</h2>
          <Button className="playground-icon-btn" type="default" title="收起播放列表" onClick={() => setPlaylistOpen(false)} aria-label="收起播放列表" icon={<IconifyIcon name="solar:alt-arrow-left-bold" size={16} />} />
        </div>
        <div className="playground-search-wrap">
          <Input className="playground-search-input" type="search" placeholder="检索样例名称" value={playlistQuery} onChange={(event) => setPlaylistQuery(event.target.value)} allowClear prefix={<IconifyIcon name="solar:magnifer-bold" size={16} />} />
        </div>
        <div className="playground-playlist-list">
          {filteredSamples.length === 0 ? (
            <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="没有匹配的样例。" className="playground-playlist-empty" />
          ) : filteredSamples.map((entry) => (
            <Button
              key={entry.file}
              type={entry.file === currentFileName ? "primary" : "text"}
              className={`playground-playlist-item ${entry.file === currentFileName ? "is-active" : ""}`}
              block
              onClick={() => {
                setPlaylistOpen(false)
                loadRemoteAnimation(entry.file)
              }}
            >
              <span className="playground-playlist-item__title">{entry.label}</span>
              <span className="playground-playlist-item__meta">{entry.file}</span>
            </Button>
          ))}
        </div>
      </aside>

      <div className={`playground-backdrop ${detailsOpen ? "is-open" : ""}`} onClick={() => setDetailsOpen(false)} />
      <aside className={`playground-details ${detailsOpen ? "is-open" : ""}`} aria-hidden={detailsOpen ? "false" : "true"}>
        <div className="playground-panel-header">
          <h2 className="playground-drawer-title">动画详情</h2>
          <Button className="playground-icon-btn" type="default" title="收起详情" onClick={() => setDetailsOpen(false)} aria-label="收起详情" icon={<IconifyIcon name="solar:alt-arrow-right-bold" size={16} />} />
        </div>
        <div className="playground-panel-body">
          <Descriptions column={1} size="small" className="playground-descriptions">
            {detailItems.map(([label, value]) => (
              <Descriptions.Item key={label} label={label}>
                <span className="playground-info-value">{value}</span>
              </Descriptions.Item>
            ))}
          </Descriptions>
        </div>
      </aside>

      <div className="playground-player-shell">
        <div ref={viewportRef} className={`playground-viewport ${currentBackground === "white" ? "bg-white" : currentBackground === "black" ? "bg-black" : ""}`}>
          <section ref={wasmWrapperRef} className="playground-canvas-wrapper">
            <div className="playground-canvas-head">
              <Tag className="playground-canvas-tag" color="blue" icon={<IconifyIcon name="solar:stars-bold" size={14} />}>
                MoonLottie
              </Tag>
              <RendererToggle label="渲染器" value={moonRenderer} onChange={setMoonRenderer} />
            </div>
            <div ref={wasmStageRef} className="playground-canvas-stage">
              <canvas ref={canvasRef} style={{ display: moonRenderer === "canvas" ? "block" : "none" }} />
              <div ref={moonSvgContainerRef} className="playground-official-container playground-svg-container" style={{ display: moonRenderer === "svg" ? "block" : "none" }} />
            </div>
          </section>
          <section ref={officialWrapperRef} className="playground-canvas-wrapper" style={{ display: compareEnabled ? "flex" : "none" }}>
            <div className="playground-canvas-head">
              <Tag className="playground-canvas-tag" icon={<IconifyIcon name="mdi:animation-play-outline" size={14} />}>
                官方 lottie-web
              </Tag>
              <RendererToggle label="渲染器" value={officialRenderer} onChange={setOfficialRenderer} />
            </div>
            <div ref={officialStageRef} className="playground-canvas-stage">
              <div ref={officialContainerRef} className="playground-official-container" />
            </div>
          </section>
        </div>

        <footer className="playground-control-bar">
          <PlaybackTransport controllerRef={controllerRef} isPlaying={isPlaying} onStepAnimation={stepAnimation} />
          <div className="playground-progress-wrap">
            <input
              ref={seekBarRef}
              className="playground-seek-bar"
              type="range"
              min={seekMin}
              max={seekMax || 1}
              value={currentFrame}
              onChange={(event) => controllerRef.current?.seek(parseFloat(event.target.value))}
            />
            <span className="playground-frame-info">{frameDisplay}</span>
          </div>
          <SpeedControls currentSpeed={currentSpeed} setCurrentSpeed={setCurrentSpeed} />
        </footer>
      </div>

      <div className={`playground-drop-overlay ${dropActive ? "is-open" : ""}`} aria-hidden={dropActive ? "false" : "true"}>
        <div className="playground-drop-card">
          <h2>打开本地 JSON</h2>
          <p>把文件拖到这里即可直接预览，不会上传到服务器。</p>
        </div>
      </div>
    </div>
  )
}
