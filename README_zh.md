# MoonBit Lottie

[English](./README.md) | [简体中文](./README_zh.md) | [MoonBit 包说明](./README.mbt.md)

Moon Lottie 是一个基于 [MoonBit](https://www.moonbitlang.com/) 开发的 Lottie 动画渲染引擎。提供了一套完整的、跨平台的动画解决方案——从底层的 JSON 解析到浏览器端的高性能 Wasm 和 JS 渲染。

🎬 **[在线演示](https://lottie.cg-zhou.top)**

[![Passed](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/tests-passed.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Coverage](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/coverage.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Total Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-total.json)](https://github.com/cg-zhou/moon-lottie/actions)
[![Source Lines](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/cg-zhou/moon-lottie/badges/badges/lines-source.json)](https://github.com/cg-zhou/moon-lottie/actions)

## 项目分层

- **核心引擎**：基于原生 MoonBit 实现的类型化 Lottie 模型、解析器以及渲染逻辑。
- **运行时 (Runtime)**：支持 Wasm-GC 高性能构建以及 JS 兼容运行环境。
- **前端 SDK**：提供面向 Vanilla JS、React 以及 Web Component 的现代封装。
- **工具链**：提供统一的 CLI，可用于批量导出 SVG 帧以及在终端中直接播放动画。

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `lib/` | **核心库**：包含解析、建模和与平台无关的渲染逻辑。 |
| `cmd/player_runtime` | 浏览器环境所需的 Wasm-GC / JS 桥接层。 |
| `cmd/cli` | 统一 CLI 入口，支持 SVG 导出与终端渲染。 |
| `packages/` | 官方 JS/TS 封装（支持纯 JS、React 与 Web Component）。 |
| `demo/` | 项目主站（包含预览、Playground 与特性支持矩阵）。 |
| `packages/examples/` | 独立集成示例，用于验证 npm 包在真实项目中的接入效果。 |

## 快速开始

### 开发环境
- [MoonBit 工具链](https://www.moonbitlang.com/download/)
- [Node.js](https://nodejs.org/) 20+

### 安装与测试
```bash
moon update
npm install
moon test
```

### 本地开发
1. 环境准备：
   ```bash
   moon update
   npm install
   ```
2. 启动开发服务：
   ```bash
   # 内部会自动构建 MoonBit 核心并同步产物到各包
   npm run dev
   ```

### 构建与部署
```bash
# 执行完整构建流程（包含核心编译、包同步、主站及示例集成）
npm run build:deploy
```

构建产物位于 `deploy-dist/` 目录，其部署结构如下：
- 主站 (预览与特性): `/`
- Core SDK 示例: `/examples/moon-lottie-core/`
- React SDK 示例: `/examples/moon-lottie-react/`
- 统一运行时: `/runtime/js/` 与 `/runtime/wasm/`

## 使用指南

### Web SDK (Alpha)
SDKs 位于 `packages/*` 目录下。

**React 接入示例：**
```jsx
import { MoonLottiePlayer } from '@moon-lottie/react'

function App() {
  return (
    <MoonLottiePlayer
      src="/animation.json"
      autoplay
      wasmPath="/runtime/wasm/moon-lottie-runtime.wasm"
    />
  )
}
```

### Moon Lottie CLI
在终端中可以直接将 Lottie 动画导出为逐帧 SVG，或以 Braille 形式播放：
```bash
# 导出 SVG 帧
moon run cmd/cli -- export svg input.json -o ./output_frames

# 在终端中播放 Drawille/Braille 动画。
# 动画始终按 fit 方式缩放到给定宽高范围内，并保持原始宽高比。
moon run cmd/cli -- render console input.json --width 80 --height 40 --fps 30

# 抓取纯文本输出时可关闭 ANSI 颜色
moon run cmd/cli -- render console input.json --ansi off
```

## 功能与路线图

Moon-lottie 旨在实现全量的 Lottie 规范支持。目前已完成的功能包括：

- ✅ **形状 (Shapes)**：椭圆、矩形、多角星、路径（支持 Trim Path 与圆角）。
- ✅ **合成 (Compositing)**：图层蒙版 (Mask)、轨道遮罩 (Matte) 以及预合成嵌套。
- ✅ **资源 (Assets)**：完整的图片图层支持。
- ✅ **表达式 (Expressions)**：支持基于 JS 宿主的表达式求值。
- ✅ **描边 (Strokes)**：已支持 line cap、line join 与虚线描边。

更详细的支持情况请参考：[特性支持](https://lottie.cg-zhou.top/features)。
