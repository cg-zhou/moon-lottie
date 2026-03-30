export interface MoonLottiePlayerHandle {
  whenReady(): Promise<unknown> | undefined
  loadAnimation(options: unknown): unknown
  load(options: unknown): unknown
  loadRemoteAnimation(filename: string): unknown
  loadFile(file: File): unknown
  switchRuntime(preference: string): unknown
  seek(frame: number): unknown
  toggle(): unknown
  play(): unknown
  pause(): unknown
  stop(): unknown
  destroy(): unknown
  stepFrame(delta: number): unknown
  setSpeed(value: number): unknown
  setDirection(value: number): unknown
  setLoop(value: boolean): unknown
  setBackground(value: string): unknown
  goToAndStop(value: number, isFrame?: boolean): unknown
  goToAndPlay(value: number, isFrame?: boolean): unknown
  playSegments(segments: number[] | number[][], forceFlag?: boolean): unknown
  setSubframe(value: boolean): unknown
  resize(): unknown
  addEventListener(type: string, listener: (event: unknown) => void): unknown
  removeEventListener(type: string, listener: (event: unknown) => void): unknown
  getCurrentFrame(): number
  getDuration(inFrames?: boolean): number
  getRuntime(): unknown
  getBackend(): string
  getPreference(): string
  describePreference(preference: string): string
  getState(): unknown
  getPlayer(): unknown
}

export interface MoonLottiePlayerProps {
  src?: string
  path?: string
  animationData?: unknown
  name?: string
  lottieRef?: unknown
  autoplay?: boolean
  loop?: boolean
  speed?: number
  direction?: number
  background?: string
  renderer?: string
  rendererSettings?: unknown
  initialSegment?: unknown
  wasmPath?: string
  jsRuntimePath?: string
  className?: string
  style?: Record<string, string | number>
  onLoad?: (event: unknown) => void
  onError?: (error: unknown) => void
  onDestroy?: (event: unknown) => void
  onRuntimeChange?: (event: unknown) => void
  onEnterFrame?: (event: unknown) => void
  onComplete?: (event: unknown) => void
  onLoopComplete?: (event: unknown) => void
  onPlay?: (event: unknown) => void
  onPause?: (event: unknown) => void
}

declare const MoonLottiePlayer: (props: MoonLottiePlayerProps & { ref?: unknown }) => any

export default MoonLottiePlayer