export type MoonLottieAnimationData = Record<string, unknown>
export type MoonLottieRenderer = 'canvas'
export type MoonLottieOfficialRenderer = 'canvas' | 'svg'
export type MoonLottieRendererMode = 'wasm' | 'official'
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
  container?: HTMLElement
  animationData?: MoonLottieAnimationData
  path?: string | null
  src?: string | null
  name?: string | null
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
  onError?: (error: unknown) => void
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

export interface MoonLottieViewportTransform {
  scale: number
  offsetX: number
  offsetY: number
  dpr: number
}

export interface MoonLottieSampleEntry {
  file: string
  label: string
}

export interface MoonLottieAnimationSource {
  filename: string
  text: string
  size: number
  path: string | null
}

export interface MoonLottiePlaybackControllerState {
  currentFrame: number
  isPlaying: boolean
  meta: MoonLottieAnimationMeta | null
  useSubframes: boolean
  activeSegment: MoonLottieSegment | null
}

export interface MoonLottiePlaybackControllerOptions {
  requestAnimationFrameFn?: (callback: FrameRequestCallback) => number
  cancelAnimationFrameFn?: (handle: number) => void
  getMeta?: () => MoonLottieAnimationMeta | null
  getSpeed?: () => number
  getDirection?: () => number
  getLoop?: () => boolean
  canRender?: () => boolean
  onRenderFrame?: (frame: number) => void
  onFrameChange?: (detail: MoonLottiePlaybackControllerState) => void
  onPlayStateChange?: (detail: MoonLottiePlaybackControllerState) => void
}

export interface MoonLottiePlaybackController {
  start(options?: { initialFrame?: number; autoplay?: boolean }): void
  play(): void
  pause(): void
  toggle(): void
  stop(): void
  seek(frame: number, options?: { render?: boolean }): void
  playSegments(segments: MoonLottieSegmentInput, forceFlag?: boolean): MoonLottieSegment[]
  setSubframe(value: boolean): boolean
  stepFrame(delta: number): void
  render(): void
  destroy(): void
  getCurrentFrame(): number
  isPlaying(): boolean
  getDirection(): number
  getLoop(): boolean
  getSubframe(): boolean
  addEventListener(type: 'enterFrame' | 'play' | 'pause' | 'loopComplete' | 'complete', listener: (detail: MoonLottiePlaybackControllerState) => void): () => void
  addEventListener(type: string, listener: (detail: unknown) => void): () => void
  removeEventListener(type: string, listener: (detail: unknown) => void): void
}

export interface MoonLottieRuntimeManagerOptions {
  loadWasmRuntime?: () => Promise<unknown>
  loadJsRuntime?: () => Promise<unknown>
  onRuntimeChanged?: (detail: MoonLottieRuntimeChangeEvent) => void
  storageKey?: string
  queryKey?: string
}

export interface MoonLottieRuntimeManager {
  initialize(): Promise<unknown>
  switchRuntime(preference: MoonLottieRuntimePreference): Promise<unknown>
  getRuntime(): unknown | null
  getBackend(): MoonLottieRuntimeBackend
  getPreference(): MoonLottieRuntimePreference
  describePreference(preference: MoonLottieRuntimePreference): 'Auto' | 'Wasm' | 'JS'
}

export interface MoonLottieOfficialPlayerControllerOptions {
  container?: HTMLElement | null
  getLottie?: () => unknown
  defaultRenderer?: MoonLottieOfficialRenderer
}

export interface MoonLottieOfficialPlayerController {
  load(animationData: MoonLottieAnimationData): unknown | null
  seek(frame: number): void
  destroy(): void
  setRenderer(value: MoonLottieOfficialRenderer): void
  getRenderer(): MoonLottieOfficialRenderer
  getPlayer(): unknown | null
}

export interface MoonLottieViewportInfoElements {
  filename?: HTMLElement | null
  filesize?: HTMLElement | null
  size?: HTMLElement | null
  fps?: HTMLElement | null
  totalFrames?: HTMLElement | null
  duration?: HTMLElement | null
  version?: HTMLElement | null
}

export interface MoonLottieViewportPresenterOptions {
  viewport: HTMLElement
  canvas: HTMLCanvasElement
  wasmWrapper?: HTMLElement | null
  officialWrapper?: HTMLElement | null
  wasmStage?: HTMLElement | null
  officialStage?: HTMLElement | null
  officialContainer?: HTMLElement | null
  seekBar?: HTMLInputElement | null
  resizeCanvasForDpr: typeof resizeCanvasForDpr
  viewportTransform: MoonLottieViewportTransform
  getCompareEnabled?: () => boolean
  requestRender?: () => void
  updateCurrentFileLabel?: () => void
  infoElements?: MoonLottieViewportInfoElements
}

export interface MoonLottieViewportPresenter {
  applyAnimationMetadata(meta: MoonLottieAnimationMeta, context?: { currentFileName?: string; currentFileSize?: number }): void
  scheduleViewportRefresh(contextFactory?: () => { currentFileName?: string; currentFileSize?: number }): void
  getLastMetadata(): MoonLottieAnimationMeta | null
}

export interface MoonLottieExpressionHost {
  evaluateDouble(expression: string, frame: number, layerIndex: number, compId: string, value: number): number
  evaluateVec(expression: string, frame: number, layerIndex: number, compId: string, value: number[]): number[]
  evaluatePath(expression: string, frame: number, layerIndex: number, compId: string, value: unknown): unknown
}

export interface MoonLottieExpressionModuleOptions {
  getAnimationData?: () => MoonLottieAnimationData | null
  getPlaybackMeta?: () => MoonLottieAnimationMeta | null
}

export interface MoonLottieExpressionModule {
  evaluate_double(expression: string, frame: number, layerIndex: number, compId: string, value: number): number
  evaluate_vec(expression: string, frame: number, layerIndex: number, compId: string, value: unknown): unknown
  evaluate_path(expression: string, frame: number, layerIndex: number, compId: string, value: unknown): unknown
}

export interface MoonLottieCanvasRuntimeBridgeOptions {
  canvas: HTMLCanvasElement
  viewportTransform: MoonLottieViewportTransform
  getRuntimeAnimationJson?: () => string
  getImageAssets?: () => Array<HTMLImageElement | null>
  getExpressionAnimationData?: () => MoonLottieAnimationData | null
  getExpressionMeta?: () => MoonLottieAnimationMeta | null
  getCanvasContext?: () => CanvasRenderingContext2D | null
  wasmPath?: string
  jsRuntimePath?: string
}

export interface MoonLottieCanvasRuntimeBridge {
  expressionModule: MoonLottieExpressionModule
  loadWasmRuntime(): Promise<unknown>
  loadJsRuntime(): Promise<unknown>
  renderFrame(runtime: { update_player?: (player: unknown, frame: number) => void } | null, nativePlayer: unknown, frame: number): void
}

export interface MoonLottieCreatePlayerOptions {
  loadWasmRuntime?: () => Promise<unknown>
  loadJsRuntime?: () => Promise<unknown>
  officialPlayerController?: MoonLottieOfficialPlayerController
  viewportPresenter?: MoonLottieViewportPresenter
  getAnimationPlaybackMeta?: (animationData: MoonLottieAnimationData) => MoonLottieAnimationMeta
  animationUsesExpressions?: (animationData: MoonLottieAnimationData) => boolean
  setStatusMessage?: (message: string) => void
  setExpressionHost?: (host: MoonLottieExpressionHost | null) => void
  setRuntimeAnimationJson?: (json: string) => void
  setFullAnimationJson?: (json: string) => void
  setImageAssets?: (assets: Array<HTMLImageElement | null>) => void
  getSpeed?: () => number
  getDirection?: () => number
  getLoop?: () => boolean
  getCompareEnabled?: () => boolean
  renderFrame?: (frame: number, state: MoonLottiePlayerState) => void
  createNativePlayer?: (runtime: unknown, state: MoonLottiePlayerState) => unknown
  onRuntimeChanged?: (detail: MoonLottieRuntimeChangeEvent) => void
  onStateChange?: (state: MoonLottiePlayerState) => void
  onFrameChange?: (detail: MoonLottieFrameEvent) => void
  onPlayStateChange?: (detail: MoonLottieStateEvent) => void
}

export interface MoonLottieInternalPlayer {
  initialize(): Promise<MoonLottiePlayerState>
  switchRuntime(preference: MoonLottieRuntimePreference): Promise<MoonLottiePlayerState>
  loadFromText(jsonText: string, context?: { filename?: string; size?: number }): Promise<MoonLottiePlayerState>
  loadFromUrl(url: string, options?: { filename?: string }): Promise<MoonLottiePlayerState>
  loadRemoteAnimation(filename: string): Promise<MoonLottiePlayerState>
  loadFile(file: File): Promise<MoonLottiePlayerState>
  restartCurrentAnimation(): Promise<MoonLottiePlayerState>
  refreshCompare(): MoonLottiePlayerState
  scheduleViewportRefresh(): void
  render(): void
  seek(frame: number): void
  stop(): void
  toggle(): void
  play(): void
  pause(): void
  playSegments(segments: MoonLottieSegmentInput, forceFlag?: boolean): MoonLottieSegment[]
  setSubframe(value: boolean): boolean
  stepFrame(delta: number): void
  isPlaying(): boolean
  getCurrentFrame(): number
  getSubframe(): boolean
  getRuntime(): unknown | null
  getBackend(): MoonLottieRuntimeBackend
  getPreference(): MoonLottieRuntimePreference
  describePreference(preference: MoonLottieRuntimePreference): 'Auto' | 'Wasm' | 'JS'
  getState(): MoonLottiePlayerState
  getNativePlayer(): unknown | null
  addEventListener(type: string, listener: (detail: unknown) => void): () => void
  removeEventListener(type: string, listener: (detail: unknown) => void): void
  destroy(): void
}

export interface MoonLottieElementEventMap extends HTMLElementEventMap {
  load: CustomEvent<MoonLottieLoadEvent>
  error: CustomEvent<MoonLottieErrorEvent>
  runtimechange: CustomEvent<MoonLottieRuntimeChangeEvent>
  enterframe: CustomEvent<MoonLottieFrameEvent>
  enterFrame: CustomEvent<MoonLottieFrameEvent>
  play: CustomEvent<MoonLottieStateEvent>
  pause: CustomEvent<MoonLottieStateEvent>
  complete: CustomEvent<MoonLottiePlaybackEvent>
  loopComplete: CustomEvent<MoonLottiePlaybackEvent>
  destroy: CustomEvent<Record<string, never>>
}

export class MoonLottieElement extends HTMLElement {
  static get observedAttributes(): string[]
  whenReady(): Promise<MoonLottiePlayerState | null>
  load(source: string | MoonLottieLoadOptions): Promise<MoonLottiePlayerState>
  loadAnimation(options?: MoonLottieLoadOptions): Promise<MoonLottiePlayerState>
  play(): void
  pause(): void
  stop(): void
  setSpeed(speed: number): void
  setDirection(direction: number): void
  setLoop(loop: boolean): void
  setBackground(background: MoonLottieBackground): void
  goToAndStop(value: number, isFrame?: boolean): void
  goToAndPlay(value: number, isFrame?: boolean): void
  playSegments(segments: MoonLottieSegmentInput, forceFlag?: boolean): MoonLottieSegment[]
  setSubframe(value: boolean): boolean | undefined
  resize(): void
  getCurrentFrame(): number
  getDuration(inFrames?: boolean): number
  getSubframe(): boolean
  getPlayer(): MoonLottiePlayerInstance | null
  destroy(): void
  addEventListener<K extends keyof MoonLottieElementEventMap>(type: K, listener: (this: MoonLottieElement, ev: MoonLottieElementEventMap[K]) => void, options?: boolean | AddEventListenerOptions): void
  addEventListener(type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void
}

export function createBrowserPlayer(options: MoonLottieLoadOptions & { container: HTMLElement }): MoonLottiePlayerInstance
export function createMoonLottieWeb(options: MoonLottieLoadOptions & { container: HTMLElement }): MoonLottiePlayerInstance
export function loadAnimation(options: MoonLottieLoadOptions & { container: HTMLElement }): MoonLottiePlayerInstance
export function loadMoonLottieWebAnimation(options: MoonLottieLoadOptions & { container: HTMLElement }): MoonLottiePlayerInstance
export function defineMoonLottieElement(tagName?: string): CustomElementConstructor | undefined
export function createPlaybackController(options?: MoonLottiePlaybackControllerOptions): MoonLottiePlaybackController
export function createRuntimeManager(options?: MoonLottieRuntimeManagerOptions): MoonLottieRuntimeManager
export function animationUsesExpressions(node: unknown): boolean
export function getAnimationPlaybackMeta(animationData: MoonLottieAnimationData): MoonLottieAnimationMeta
export function getPreferredRendererMode(animationData: MoonLottieAnimationData, options?: { hasLottieWeb?: boolean }): MoonLottieRendererMode
export function setExpressionHost(host: MoonLottieExpressionHost | null): void
export function createExpressionModule(options?: MoonLottieExpressionModuleOptions): MoonLottieExpressionModule
export function normalizeDevicePixelRatio(dpr: number): number
export function getCanvasPixelSize(width: number, height: number, dpr?: number): {
  cssWidth: number
  cssHeight: number
  dpr: number
  pixelWidth: number
  pixelHeight: number
}
export function resizeCanvasForDpr(canvas: HTMLCanvasElement, width: number, height: number, dpr?: number): {
  cssWidth: number
  cssHeight: number
  dpr: number
  pixelWidth: number
  pixelHeight: number
}
export function applyDprTransform(ctx: CanvasRenderingContext2D, a: number, b: number, c: number, d: number, e: number, f: number, dpr?: number): void
export function cloneAnimationData<T>(animationData: T): T
export function loadAnimationSourceFromUrl(url: string, options?: { filename?: string }): Promise<MoonLottieAnimationSource>
export function createRuntimeAnimationData<T>(animationData: T): T
export function loadRemoteAnimationSource(filename: string): Promise<MoonLottieAnimationSource>
export function loadSampleIndex(): Promise<MoonLottieSampleEntry[]>
export function preloadAssets(json: MoonLottieAnimationData, options?: { onStatusMessage?: (message: string) => void }): Promise<Array<HTMLImageElement | null>>
export function readFileAnimationSource(file: File): Promise<MoonLottieAnimationSource>
export function createOfficialPlayerController(options?: MoonLottieOfficialPlayerControllerOptions): MoonLottieOfficialPlayerController
export function createViewportPresenter(options: MoonLottieViewportPresenterOptions): MoonLottieViewportPresenter
export function createPlayer(options?: MoonLottieCreatePlayerOptions): MoonLottieInternalPlayer
export function createCanvasRuntimeBridge(options: MoonLottieCanvasRuntimeBridgeOptions): MoonLottieCanvasRuntimeBridge
