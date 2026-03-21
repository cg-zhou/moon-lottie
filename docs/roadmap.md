# Moon Lottie 计划

本文档用于收敛工作优先级，目标不是继续无限铺功能，而是把 moon-lottie 整理成一个“完成度高、展示清晰、路线明确”的项目。

## 1. 当前判断

### 1.1 当前项目状态
- 现有状态已经不再只是概念验证，而是一个已具备核心引擎、在线演示和双运行时路径的 MoonBit Lottie 项目。
- 已完成的主干包括：MoonBit 解析/求值/渲染主流程、浏览器 Canvas 播放链路、Wasm-GC 与 JS fallback、站点基础信息架构、截图/像素比对类验证工具雏形。
- 尚未完成但已经明确暴露出来的问题包括：特性边界说明不足、Playground 偏调试台而非播放器、移动端体验偏弱、SVG 输出尚未升格为正式能力、封装层与接入文档仍薄弱。
- 当前最大的风险，不是“做得不够多”，而是“重点过多、叙事不够收束”。

### 1.2 当前阶段目标
- 把现有成果整理成可展示、可解释、可验证的项目形态。
- 避免过早开启新的重型主线工程。
- 保留少量长期探索方向，但不让它们抢占主线资源。

### 1.3 本阶段核心策略
- 主线优先：优先提升现有项目完成度，而不是继续大面积扩展新功能。
- 体验优先：优先处理会直接影响演示、理解成本和跨设备使用的问题。
- 收束优先：把已经做出的能力讲清楚，比继续横向扩支线更重要。
- 长期资产优先：尽量把文档、演示、说明沉淀到网站和仓库中。

## 2. 当前真实进展

### 2.1 已经成立的部分
- MoonBit 核心引擎主干已经成立：`parser`、`runtime`、`renderer` 和 `player` 已经形成主流程。
- 浏览器播放链路已经成立：当前 Demo 已支持上传、播放、调速、背景切换、官方对比等基本能力。
- 双运行时方向已经成立：当前不仅有 Wasm-GC 路径，也有 JS fallback 路径。
- 站点已经不只是 Demo 页面，而是具备概览、特性、架构、路线等说明页的产品入口。
- 测试与验证不再是空白：已有 MoonBit 测试与浏览器截图/像素对比工具雏形。

### 2.2 还没有完成的部分
- 对“支持了什么、没支持什么、支持到什么程度”的说明仍然不够清楚。
- Playground 目前更像调试工作台，不够像一个轻量、移动端友好的播放器。
- SVG 渲染器已有雏形，但还没有整理成可以正式对外描述的输出能力。
- `Web Component`、`React` 薄封装已经进入最小可用实现阶段，但还没有形成稳定交付面，也还没有整理成独立包与正式接入文档。
- 表达式方向当前仍是 JS 宿主 MVP，SerenadeJS 还属于长期路线而不是现成能力。

### 2.3 当前状态快照

这一段用于记录当前仓库的真实状态，避免文档只剩“计划”而缺少“已经做到哪一步”的上下文。

#### 已完成的收敛工作
- Playground 页面做过一轮收口：恢复了原生数字输入箭头，改成 JS 驱动的动态布局与等比缩放，并把标题区与画布区拆开，整体比之前更清爽，也更接近“播放器”而不是“调试面板”。
- 已明确当前分层：MoonBit core -> browser player/runtime -> Web Component -> React thin wrapper -> demo site。这个分层已经成为后续工作的收口方向，而不是继续让 Playground 自己长成一套独立逻辑。
- 为浏览器播放层完成了一轮内部抽取，当前 `demo/public/player/` 下已经有可复用模块：
	- `event-emitter.js`
	- `playback-controller.js`
	- `runtime-manager.js`
	- `animation-source.js`
	- `official-player.js`
	- `viewport-presenter.js`
	- `create-player.js`
	- `canvas-runtime-bridge.js`
- 主站 Playground 已迁移到 `demo/src/components/Playground.jsx`，复用共享的 `createCanvasRuntimeBridge(...)` 与 `createPlayer(...)`。
- 为多实例场景补上了 Wasm 模块缓存，避免反复从原始字节重复 instantiate 导致内存压力过大。这一点对后续 Web Component、React 多实例和预览卡片都很关键。

#### 已落地的封装层雏形
- `Web Component` 最小可用版已经落地：`demo/public/player/moon-lottie-element.js`。
- 浏览器命令式播放器最小可用版已经落地：`demo/public/player/moon-lottie-web.js`，使用心智模型对齐 `lottie-web` 的 `loadAnimation(...)`。
- React 薄封装第一版已经落地：`demo/src/components/MoonLottiePlayer.jsx`。
- React 站点里已经接入一个真实预览卡片，用它直接消费 `public/player` 暴露出的 browser player API，而不是重新写一套 React 专用播放器逻辑。

#### 本轮修复过的具体问题
- 单实例播放器在早期封装阶段出现过同一个空指针问题：`viewport-presenter.js` 在单实例模式下仍访问了 compare-only DOM 节点的 `style`。
- 上述问题已经修复，当前 `viewport-presenter.js` 能处理 `officialContainer` 为 `null` 的场景。
- React 薄封装初版接入时，Vite 会在构建期错误解析 `/player/index.js`。
- 这一点也已经修复：改成运行时动态导入 public 目录入口，而不是让构建器把它当成源码依赖去解析。
- 当前 `demo` 目录下 `npm run build` 已通过，说明这轮抽取和薄封装至少在构建层面是闭合的。

#### 当前代码形态的判断
- 这轮工作仍然符合本路线文档的“优先级 4：封装与接入层”，但做法是先收边界、后拆包，而不是一上来就铺更多 npm 包工程。
- 现阶段已经有：
	- browser player 内核
	- Web Component 雏形
	- React thin wrapper 雏形
- 现阶段还没有：
	- 正式的 `moon-lottie-react` 独立包
	- 正式的 Web Component 发布包
	- 完整的接入文档与 API 文档
	- 全量对齐 `lottie-web` 的方法面

#### 仍待继续的事项
- Playground 现在虽然比之前更清爽，但还没有完全完成“轻量播放器化”，目前依然保留 iframe 结构，尚未完全并入 React 页面内部。
- browser player API 目前只覆盖了常见播放控制能力，后续仍需要继续向 `lottie-web` 靠拢，例如更完整的分段播放、子帧控制与更细的事件语义。
- React 薄封装已经能工作，但仍属于“最小可用版”，目标应该是覆盖最常见播放控制能力，而不是现在就扩成一个重量级 React 生态工程。
- 这一层的后续工作应继续受第 4 节“当前明确不做的事情”约束，避免因为封装层初步成立，就转向新的大规模支线开发。

#### 建议的后续起点
- 如果后续继续沿这条线推进，建议优先顺序仍然保持克制：
	- 先补 Playground 轻量化与移动端体验
	- 再补 browser player / Web Component / React wrapper 的接入说明
	- 然后再决定是否把现有实现拆成真正独立发布的包
- 如果需要快速恢复上下文，可以优先看这几个位置：
	- `demo/public/player/`
	- `demo/src/components/Playground.jsx`
	- `demo/src/components/MoonLottiePlayer.jsx`
	- `demo/src/App.jsx`

## 3. 优先级排序

### 3.1 优先级 1：核心稳定性
- 继续补齐解析器、时间轴和渲染器的正确性证据。
- 把“支持边界”说清楚，而不是只给出笼统的支持表述。
- 继续整理回归测试与可复现样例，降低后续迭代的不确定性。

### 3.2 优先级 2：产品体验
- 把 Playground 收敛成更轻量的播放器，而不是继续堆成更重的调试面板。
- 优先改善手机端和小屏设备上的播放控制体验。
- 在 Feature 页面中补充“这是什么、当前支持到什么程度、对应示例是什么”的说明。

### 3.3 优先级 3：输出能力
- 让 SVG 渲染器从“已有雏形”升级为“可正式描述的输出后端”。
- 视情况整理一条非 Web 使用路径，例如命令行或桌面侧的 SVG 导出。
- 继续保持 Wasm 与 JS 双运行时路径的一致性与可维护性。

### 3.4 优先级 4：封装与接入层
- 提供 `Web Component` 最小可用版，形成跨框架基础接入方式。
- 提供 `moon-lottie-react` 薄封装，先覆盖最常见播放控制能力。
- 补充更清晰的嵌入、安装与集成示例。

### 3.5 优先级 5：长期探索
- SerenadeJS 继续作为表达式后端路线保留，但不转成当前主线工程。
- Console / 文本模式播放、盲文或 ASCII 渲染实验可作为生态扩展方向。
- 这类方向有价值，但当前不应抢占前四项资源。

## 4. 当前明确不做的事情

- 不追求完整 AE 表达式兼容。
- 不把 SerenadeJS 做成独立长期维护项目。
- 不为了“看起来更丰满”而同时开启多个新的重型主线。
- 不急于扩展更多框架封装或新渲染后端，而忽略当前站点与引擎主干的完成度。

## 5. 任务分组建议

### 5.1 第一组：先收口主干
- 安卓访问问题与降级路径。
- Playground 轻量化与移动端友好化。
- 支持边界、Feature 说明与架构说明补全。

### 5.2 第二组：补强输出与验证
- SVG 输出能力整理。
- CLI / 桌面 SVG 导出可行性。
- 测试与回归说明整理。

### 5.3 第三组：封装与长期路线
- `Web Component` 最小可用版。
- `moon-lottie-react` 薄封装。
- SerenadeJS 路线页或最小验证结论。

## 6. 本阶段执行原则

- 不再为了“看起来更丰满”而随意开启新支线。
- 先处理减分项，再做加分项。
- 优先做能沉淀为长期资产的工作。
- 让 MoonBit 始终保持为项目的核心叙事中心。

## 7. 一句话版本

当前目标，不是继续横向铺新功能，而是把现有能力收口成一个“核心成立、体验更顺、边界清楚、路线克制”的 MoonBit 项目。