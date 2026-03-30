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
- **工具链**：提供可用于命令行批量导出 SVG 帧的 CLI 工具。

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `lib/` | **核心库**：包含解析、建模和与平台无关的渲染逻辑。 |
| `cmd/player_runtime` | 浏览器环境所需的 Wasm-GC / JS 桥接层。 |
| `cmd/svg_cli` | 用于批量导出 SVG 的命令行工具。 |
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
1. 构建运行时：
   ```bash
   moon build --target wasm-gc
   moon build --target js
   ```
2. 启动开发服务：
   ```bash
   npm run dev:site
   ```

### 构建与部署
```bash
# 执行完整构建流程（包含包构建、主站及示例集成）
npm run build:deploy
```

构建产物位于 `deploy-dist/` 目录，其部署结构如下：
- 主站 (Site): `/`
- 独立示例 (Examples): `/examples/moon-lottie-core/` 与 `/examples/moon-lottie-react/`

## 使用指南

### Web SDK (即将发布)
目前 `packages/*` 下的 SDK 均在仓库工作区内直接开发。

**React 接入示例：**
```jsx
import MoonLottiePlayer from '@moon-lottie/react'

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

### SVG 导出 CLI
在终端直接将 Lottie 动画导出为逐帧 SVG：
```bash
# 从 JSON 文件导出所有动画帧
moon run cmd/svg_cli -- input.json -o ./output_frames
```

## 功能与路线图

Moon-lottie 旨在实现全量的 Lottie 规范支持。目前已完成的功能包括：

- ✅ **形状 (Shapes)**：椭圆、矩形、多角星、路径（支持 Trim Path 与圆角）。
- ✅ **合成 (Compositing)**：图层蒙版 (Mask)、轨道遮罩 (Matte) 以及预合成嵌套。
- ✅ **资源 (Assets)**：完整的图片图层支持。
- ✅ **表达式 (Expressions)**：支持基于 JS 宿主的表达式求值。
- 🚧 **虚线 (TODO: Dashes)**：虚线描边正在开发中。

更详细的支持情况请参考：[特性支持](https://lottie.cg-zhou.top/features)。
