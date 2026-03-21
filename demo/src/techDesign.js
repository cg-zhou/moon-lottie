export const architectureDiagram = String.raw`
flowchart TD
  Site[React 主站壳层] --> Playground[在线演示界面]
  Site --> Matrix[特性支持矩阵]
  Site --> Design[底层技术设计]

  Playground --> MainJS[Wasm 启动与界面驱动]
  MainJS --> Wasm[MoonBit 引擎 .wasm]
  MainJS --> HostModules[Canvas / 蒙版 / 遮罩辅助模块]
  MainJS --> ExprHost[类 AE 表达式宿主]

  Wasm --> Parser[Lottie JSON 解析器]
  Wasm --> Model[核心数据模型]
  Wasm --> Runtime[时间轴与属性求值器]
  Wasm --> Renderer[平台无关渲染器]
  Renderer --> CanvasFFI[JS Canvas 绑定层]
  CanvasFFI --> BrowserCanvas[浏览器 Canvas 2D]
`

export const renderPipelineDiagram = String.raw`
flowchart LR
  JSON[Lottie JSON] --> Loader[资源加载]
  Loader --> WasmInit[Wasm 实例化]
  WasmInit --> Parse[MoonBit 解析]
  Parse --> Eval[时间轴求值]
  Eval --> Draw[渲染指令]
  Draw --> Host[JS Canvas FFI]
  Host --> Output[Canvas 帧输出]
`
