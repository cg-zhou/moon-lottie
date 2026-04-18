# 项目架构 (Architecture)

Moon Lottie 采用分层架构，确保核心引擎的跨平台一致性与前端封装的灵活性。

## 1. 核心分层

```mermaid
flowchart TB
  subgraph moonbit [MoonBit Core]
    parser[lib/parser\n解析器]
    model[lib/model\n数据模型]
    runtime[lib/runtime\n动画状态机]
    renderer[lib/renderer\n渲染后端]
  end

  subgraph runtimeOutputs [Runtime Layer]
    playerRuntime[cmd/player_runtime\n浏览器 Runtime]
    cli[cmd/cli\n命令行工具]
  end

  subgraph browser [Wrapper Layer]
    bridge[JS Bridge\n资源管理与调度]
    core["<u>@moon-lottie/core</u><br/><u>播放器内核</u>"]
    react["<u>@moon-lottie/react</u><br/><u>React 组件</u>"]
    site["<u>Demo Site</u><br/><u>在线演示</u>"]
  end

  parser[lib/parser\n解析器] --> model[lib/model\n数据模型]
  model --> runtime[lib/runtime\n动画状态机]
  runtime --> renderer[lib/renderer\n渲染核心]
  renderer --> playerRuntime[player_runtime\n播放器运行时]
  playerRuntime --> bridge --> core --> react
  core --> site
  renderer --> cli["<u>CLI</u><br/><u>ASCII 渲染 / SVG 导出</u>"]

  click cli "https://mooncakes.io/docs/cg-zhou/moon_lottie" "cg-zhou/moon_lottie"
  click core "https://www.npmjs.com/package/@moon-lottie/core" "npm: @moon-lottie/core"
  click react "https://www.npmjs.com/package/@moon-lottie/react" "npm: @moon-lottie/react"
  click site "https://lottie.cg-zhou.top" "Moon Lottie Preview"
```

## 2. 职责定义

- **MoonBit Core**: 包含 [cg-zhou/moon_lottie](https://mooncakes.io/docs/cg-zhou/moon_lottie)、[cg-zhou/bezier_easing](https://mooncakes.io/docs/cg-zhou/bezier_easing) 等核心库，承担 JSON 解析、属性插值计算与跨平台渲染指令生成，另外制作了 [cg-zhou/drawille](https://mooncakes.io/docs/cg-zhou/drawille) 用于实现 ASCII 渲染。
- **Runtime Layer**: 产出不同环境的接入点：
  - 浏览器端通过 Wasm-GC 提供高性能路径。
  - 命令行通过 [CLI](https://mooncakes.io/docs/cg-zhou/moon_lottie) 提供 ASCII 渲染与 SVG 导出。
- **Wrapper Layer**: 提供 [@moon-lottie/core](https://www.npmjs.com/package/@moon-lottie/core) 与 [@moon-lottie/react](https://www.npmjs.com/package/@moon-lottie/react)，为前端开发者提供了 React 和 Web Component API，并提供了封装示例。

## 3. 设计策略

- **双运行时并存**: 同时支持 Wasm-GC（首选）与 JS Fallback，确保移动端兼容。
- **解耦设计**: 核心引擎不依赖特定框架或 DOM，可独立用于服务端或终端渲染。
- **渲染分工**: Canvas 用于高性能播放；SVG 主要用于资源导出。
