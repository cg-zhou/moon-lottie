export const architectureDiagram = String.raw`
flowchart TD
  Site[React Demo Shell] --> Playground[Playground Interface]
  Site --> Matrix[Feature Support Matrix]
  Site --> Design[Technical Architecture]

  Playground --> MainJS[Wasm Bootstrap & UI Driver]
  MainJS --> Wasm[MoonBit Engine .wasm]
  MainJS --> HostModules[Canvas / Mask / Matte Helpers]
  MainJS --> ExprHost[AE-like Expression Host]

  Wasm --> Parser[Lottie JSON Parser]
  Wasm --> Model[Core Data Model]
  Wasm --> Runtime[Timeline & Property Evaluator]
  Wasm --> Renderer[Platform Agnostic Renderer]
  Renderer --> CanvasFFI[JS Canvas Bindings]
  CanvasFFI --> BrowserCanvas[Browser Canvas 2D]
`

export const renderPipelineDiagram = String.raw`
flowchart LR
  JSON[Lottie JSON] --> Loader[Resource Loader]
  Loader --> WasmInit[Wasm Instantiate]
  WasmInit --> Parse[MoonBit Parser]
  Parse --> Eval[Timeline Evaluator]
  Eval --> Draw[Renderer Commands]
  Draw --> Host[JS Canvas FFI]
  Host --> Output[Canvas Frame]
`

export const expressionFlowDiagram = String.raw`
sequenceDiagram
  participant MW as MoonBit Engine
  participant H as JS Bridge
  participant EH as Expression Host
  participant JS as JS Runtime

  MW->>H: Request Expression Value
  H->>EH: Forward Payload
  EH->>JS: Execute with AE Context
  JS-->>EH: Return Result
  EH-->>H: Serialize Value
  H-->>MW: Inject into Timeline
`

export const hostModules = [
  {
    title: 'MoonBit Engine',
    description: 'The core library containing the Lottie specification logic, independent of platform bindings.',
    items: [
      'lib/parser: Optimized JSON schema decoding',
      'lib/model: Strictly typed Lottie data structures',
      'lib/runtime: Timeline sampling and property graph',
      'lib/renderer: Platform-neutral draw command emission'
    ],
  },
  {
    title: 'Web Platform Bindings',
    description: 'Bridges the Wasm engine to browser APIs using efficient FFI calls.',
    items: [
      'demo/main.js: Wasm lifecycle and state synchronization',
      'demo/canvas_dpr.js: High-density display management',
      'demo/canvas_mask_expansion.js: Complex path masking logic',
      'demo/canvas_matte.js: Offscreen buffer orchestration'
    ],
  },
  {
    title: 'JS Expression Bridge',
    description: 'A hybrid execution environment that fulfills AE-style scripting requirements.',
    items: [
      'demo/expression_host.js: AE context mock (thisComp / thisLayer)',
      'lib/runtime/evaluator.mbt: Expression handler mounting',
      'Serialization: Low-latency value exchange between Wasm and JS'
    ],
  },
  {
    title: 'Project Portal',
    description: 'The front-facing developer documentation and interactive demo shell.',
    items: [
      'demo/src/App.jsx: SPA navigation and routing logic',
      'demo/src/supportMatrix.js: Feature compliance metadata',
      'demo/src/components/PlaygroundWorkbench.jsx: React-native playground host'
    ],
  },
]

export const designDecisions = [
  {
    title: 'Full Separation of Core/Host',
    description: 'By keeping strictly to MoonBit for core logic, we ensure the engine can be ported to iOS/Android native Canvas without rewriting the model or timeline logic.',
  },
  {
    title: 'Evaluation Over Interpretation',
    description: 'The engine evaluates the entire property graph every frame, allowing for deterministic results regardless of host system performance variations.',
  },
  {
    title: 'Deferred Expression Host',
    description: 'Current JS-based expression execution is a strategic compromise. Our roadmap includes transitioning to a pure Wasm execution model for full sandboxing.',
  },
  {
    title: 'Iterative Site Architecture',
    description: 'Transitioned from a flat demo to a structured React shell to support long-term documentation and SDK distribution goals.',
  },
]

export const technicalRisks = [
  {
    title: 'Host-Dependent Expressions',
    description: 'While functional, expressions still rely on the browser’s JS runtime, creating a dependency that limits usage in non-JS environments.',
  },
  {
    title: 'Wasm js-stringbuiltins Support',
    description: 'Usage of newer Wasm proposals like js-stringbuiltins might require polyfills or fallbacks on older Android WebView environments.',
  },
  {
    title: 'Text Rendering Complexity',
    description: 'Lottie text features (kerning, custom fonts, glyph paths) are platform-intensive and require further work for full spec compliance.',
  },
  {
    title: 'Tooling Maturity',
    description: 'The transition from demo to library/SDK requires robust automated testing against the full Airbnb sample suite.',
  },
]
