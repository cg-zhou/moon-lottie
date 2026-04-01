import type { CSSProperties, ForwardRefExoticComponent, Ref, RefAttributes } from 'react'

export type MoonLottieAnimationData = Record<string, unknown>
export type MoonLottieRenderer = 'canvas'
export type MoonLottieRuntimePreference = 'auto' | 'wasm' | 'js'
export type MoonLottieRuntimeBackend = 'uninitialized' | 'wasm' | 'js'
export type MoonLottieBackground = 'transparent' | 'white' | 'black' | 'grid' | string
export type MoonLottieSegment = [number, number]
export type MoonLottieSegmentInput = MoonLottieSegment | MoonLottieSegment[]

export interface MoonLottieRendererSettings {
  viewportClassName?: string
  wrapperClassName?: string
  stageClassName?: string
  canvasClassName?: string
  className?: string
}

export interface MoonLottieAnimationMeta {
  version: string
  width: number
  height: number
  fps: number
  inPoint: number
  outPoint: number
  totalFrames: number
  aspectRatio: string
}

export interface MoonLottiePlayerState {
  currentFileName: string
  currentFileSize: number
  currentAnimationData: MoonLottieAnimationData | null
  currentAnimationMeta: MoonLottieAnimationMeta | null
  currentExpressionAnimationData: MoonLottieAnimationData | null
  currentExpressionMeta: MoonLottieAnimationMeta | null
  nativePlayer: unknown | null
  runtime: unknown | null
  backend: MoonLottieRuntimeBackend
  preference: MoonLottieRuntimePreference
  isPlaying: boolean
  currentFrame: number
}

export interface MoonLottieLoadOptions {
  animationData?: MoonLottieAnimationData
  path?: string
  src?: string
  name?: string
  autoplay?: boolean
  loop?: boolean
  speed?: number
  direction?: number
  background?: MoonLottieBackground
  renderer?: MoonLottieRenderer
  rendererSettings?: MoonLottieRendererSettings
  initialSegment?: MoonLottieSegment | null
  wasmPath?: string
  jsRuntimePath?: string
}

export interface MoonLottieLoadEvent {
  state: MoonLottiePlayerState
}

export interface MoonLottieErrorEvent {
  error: unknown
}

export interface MoonLottieRuntimeChangeEvent {
  runtime: unknown | null
  backend: MoonLottieRuntimeBackend
  preference: MoonLottieRuntimePreference
}

export interface MoonLottieStateEvent {
  state: MoonLottiePlayerState
}

export interface MoonLottieFrameEvent {
  currentFrame: number
  isPlaying?: boolean
  meta?: MoonLottieAnimationMeta | null
  useSubframes?: boolean
  activeSegment?: MoonLottieSegment | null
  state?: MoonLottiePlayerState
}

export interface MoonLottiePlaybackEvent {
  currentFrame: number
  isPlaying: boolean
  meta: MoonLottieAnimationMeta | null
  useSubframes: boolean
  activeSegment: MoonLottieSegment | null
}

export interface MoonLottiePlayerEventMap {
  load: MoonLottieLoadEvent
  error: MoonLottieErrorEvent
  runtimechange: MoonLottieRuntimeChangeEvent
  enterframe: MoonLottieFrameEvent
  enterFrame: MoonLottieFrameEvent
  complete: MoonLottiePlaybackEvent
  loopComplete: MoonLottiePlaybackEvent
  loopcomplete: MoonLottiePlaybackEvent
  play: MoonLottieStateEvent
  pause: MoonLottieStateEvent
  destroy: Record<string, never>
}

export type MoonLottieEventName = keyof MoonLottiePlayerEventMap

export interface MoonLottiePlayerInstance {
  whenReady(): Promise<MoonLottiePlayerState>
  loadAnimation(options?: MoonLottieLoadOptions): Promise<MoonLottiePlayerState>
  load(options?: string | MoonLottieLoadOptions): Promise<MoonLottiePlayerState>
  loadRemoteAnimation(filename: string): Promise<MoonLottiePlayerState>
  loadFile(file: File): Promise<MoonLottiePlayerState>
  switchRuntime(preference: MoonLottieRuntimePreference): Promise<MoonLottiePlayerState>
  render(): void
  seek(frame: number): void
  toggle(): void
  play(): void
  pause(): void
  stop(): void
  stepFrame(delta: number): void
  setSpeed(value: number): number
  setDirection(value: number): 1 | -1
  setLoop(value: boolean): boolean
  setBackground(value: MoonLottieBackground): MoonLottieBackground
  goToAndStop(value: number, isFrame?: boolean): void
  goToAndPlay(value: number, isFrame?: boolean): void
  playSegments(segments: MoonLottieSegmentInput, forceFlag?: boolean): MoonLottieSegment[]
  setSubframe(value: boolean): boolean
  getDuration(inFrames?: boolean): number
  resize(): void
  getCurrentFrame(): number
  getSpeed(): number
  getDirection(): number
  getLoop(): boolean
  getBackground(): MoonLottieBackground
  getSubframe(): boolean
  isLoaded(): boolean
  isPaused(): boolean
  getRuntime(): unknown | null
  getBackend(): MoonLottieRuntimeBackend
  getPreference(): MoonLottieRuntimePreference
  describePreference(preference: MoonLottieRuntimePreference): 'Auto' | 'Wasm' | 'JS'
  getState(): MoonLottiePlayerState | null
  getContainer(): HTMLElement
  getCanvas(): HTMLCanvasElement
  addEventListener<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): () => void
  addEventListener(type: string, listener: (event: unknown) => void): () => void
  removeEventListener<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): void
  removeEventListener(type: string, listener: (event: unknown) => void): void
  on<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): () => void
  on(type: string, listener: (event: unknown) => void): () => void
  off<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): void
  off(type: string, listener: (event: unknown) => void): void
  destroy(): void
}

export interface MoonLottiePlayerHandle {
  whenReady(): Promise<MoonLottiePlayerState> | undefined
  loadAnimation(options?: MoonLottieLoadOptions): Promise<MoonLottiePlayerState> | undefined
  load(options?: string | MoonLottieLoadOptions): Promise<MoonLottiePlayerState> | undefined
  loadRemoteAnimation(filename: string): Promise<MoonLottiePlayerState> | undefined
  loadFile(file: File): Promise<MoonLottiePlayerState> | undefined
  switchRuntime(preference: MoonLottieRuntimePreference): Promise<MoonLottiePlayerState> | undefined
  seek(frame: number): void
  toggle(): void
  play(): void
  pause(): void
  stop(): void
  destroy(): void
  stepFrame(delta: number): void
  setSpeed(value: number): number | undefined
  setDirection(value: number): 1 | -1 | undefined
  setLoop(value: boolean): boolean | undefined
  setBackground(value: MoonLottieBackground): MoonLottieBackground | undefined
  goToAndStop(value: number, isFrame?: boolean): void
  goToAndPlay(value: number, isFrame?: boolean): void
  playSegments(segments: MoonLottieSegmentInput, forceFlag?: boolean): MoonLottieSegment[] | undefined
  setSubframe(value: boolean): boolean | undefined
  resize(): void
  addEventListener<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): (() => void) | undefined
  addEventListener(type: string, listener: (event: unknown) => void): (() => void) | undefined
  removeEventListener<K extends MoonLottieEventName>(type: K, listener: (event: MoonLottiePlayerEventMap[K]) => void): void
  removeEventListener(type: string, listener: (event: unknown) => void): void
  getCurrentFrame(): number
  getDuration(inFrames?: boolean): number
  getRuntime(): unknown | null | undefined
  getBackend(): MoonLottieRuntimeBackend
  getPreference(): MoonLottieRuntimePreference
  describePreference(preference: MoonLottieRuntimePreference): 'Auto' | 'Wasm' | 'JS'
  getState(): MoonLottiePlayerState | null
  getPlayer(): MoonLottiePlayerInstance | null
}

export interface MoonLottiePlayerProps {
  src?: string
  path?: string
  animationData?: MoonLottieAnimationData
  name?: string
  lottieRef?: Ref<MoonLottiePlayerInstance | null>
  autoplay?: boolean
  loop?: boolean
  speed?: number
  direction?: number
  background?: MoonLottieBackground
  renderer?: MoonLottieRenderer
  rendererSettings?: MoonLottieRendererSettings
  initialSegment?: MoonLottieSegment | null
  wasmPath?: string
  jsRuntimePath?: string
  className?: string
  style?: CSSProperties
  onLoad?: (event: MoonLottieLoadEvent) => void
  onError?: (error: unknown) => void
  onDestroy?: (event: Record<string, never>) => void
  onRuntimeChange?: (event: MoonLottieRuntimeChangeEvent) => void
  onEnterFrame?: (event: MoonLottieFrameEvent) => void
  onComplete?: (event: MoonLottiePlaybackEvent) => void
  onLoopComplete?: (event: MoonLottiePlaybackEvent) => void
  onPlay?: (event: MoonLottieStateEvent) => void
  onPause?: (event: MoonLottieStateEvent) => void
}

declare const MoonLottiePlayer: ForwardRefExoticComponent<MoonLottiePlayerProps & RefAttributes<MoonLottiePlayerHandle>>

export default MoonLottiePlayer