# 项目完成度

本文档对照项目申报书，快照当前 Moon Lottie 的核心交付物状态。

## 1. 核心功能

| 申报项 | 状态 | 证明点 |
| --- | --- | --- |
| **协议解析** | 已完成 | [特性列表](https://lottie.cg-zhou.top/features) 支持基础 Lottie JSON 转换 |
| **几何渲染** | 已完成 | [特性列表](https://lottie.cg-zhou.top/features) 支持基本形状、填充、描边与渐变渲染 |
| **动画逻辑** | 已完成 | 支持关键帧插值、时间轴求值与图层变换 |
| **多端支持** | 已交付 | 提供 Web (Canvas)、SVG 导出与 CLI 终端渲染 |
| **表达式** | 部分支持 | 目前在网页端提供 JS 宿主辅助模式 |

## 2. 交付形式

| 交付名称 | 类型 | 说明 |
| --- | --- | --- |
| **[在线预览器](https://lottie.cg-zhou.top)** | 网站 | 支持调速、上传、对比，实时预览渲染效果 |
| **[moon_lottie](https://mooncakes.io/docs/cg-zhou/moon_lottie)** | MoonBit 包 | Moon Lottie 核心渲染引擎库 |
| **[bezier_easing](https://mooncakes.io/docs/cg-zhou/bezier_easing)** | MoonBit 包 | 三次贝塞尔曲线缓动函数计算库 |
| **[drawille](https://mooncakes.io/docs/cg-zhou/drawille)** | MoonBit 包 | 用于终端图形渲染的 Unicode Braille 字符库 ![snapshot](https://cdn.jsdelivr.net/gh/cg-zhou/moon-drawille@main/snapshot.png) |
| **[@moon-lottie/core](https://www.npmjs.com/package/@moon-lottie/core)** | npm 包 | 浏览器侧命令式播放器封装与 Web Component |
| **[@moon-lottie/react](https://www.npmjs.com/package/@moon-lottie/react)** | npm 包 | 面向 React 生态的轻量化组件封装 |
| **CLI 工具** | 命令行 | 支持 `moon-lottie` 导出 SVG 与终端播放 |

## 3. 验收指标

- **工程质量**: 建立 `lib` (核心), `cmd` (入口), `packages` (封装) 的明确边界。
- **稳定性**: 通过 174 条 `moon test` 核心单元测试。
- **验证手段**: 建立 80+ 样例库，并支持像素级截图回归对比工具。
