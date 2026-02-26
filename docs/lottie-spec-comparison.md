# Lottie 特性支持对照表 (Moon-Lottie vs. Lottie Spec)

本文档追踪 `moon-lottie` 引擎对 Lottie (Bodymovin) 规范的支持进度。

## 核心渲染能力

| 特性分类 | 特性名称 | 状态 | 备注 |
| :--- | :--- | :--- | :--- |
| **基础形状 (Shapes)** | 矩形 (Rectangle - `rc`) | ✅ 已支持 | |
| | 椭圆 (Ellipse - `el`) | ✅ 已支持 | |
| | 路径 (Path - `sh`) | ✅ 已支持 | 支持多贝塞尔曲线段 |
| | 组 (Group - `gr`) | ✅ 已支持 | 嵌套变换支持 |
| | 多边形/星形 (Polystar - `sr`) | ✅ 已支持 | 支持星形、多边形及圆角平滑 |
| **外观样式 (Styles)** | 纯色填充 (Fill - `fl`) | ✅ 已支持 | |
| | 纯色描边 (Stroke - `st`) | ✅ 已支持 | |
| | 渐变填充 (Gradient Fill - `gf`) | ✅ 已支持 | 支持线性与径向渐变 |
| | 渐变描边 (Gradient Stroke - `gs`) | ✅ 已支持 | 复用渐变渲染管线 |
| **变换 (Transform)** | 位置 (Position - `p`) | ✅ 已支持 | 支持分离 Px/Py |
| | 缩放 (Scale - `s`) | ✅ 已支持 | |
| | 旋转 (Rotation - `r`) | ✅ 已支持 | |
| | 锚点 (Anchor Point - `a`) | ✅ 已支持 | |
| | 不透明度 (Opacity - `o`) | ✅ 已支持 | 已支持层级嵌套的乘法透明度系数 |
| **修改器 (Modifiers)** | 修剪路径 (Trim Paths - `tm`) | ✅ 已支持 | 支持三阶贝塞尔精确切分 |
| | 中继器 (Repeater - `rp`) | ✅ 已支持 | 支持副本级联变换及复合模式 |
| | 合并路径 (Merge Paths - `mm`) | ✅ 已支持 | 基础模式完全支持；减去/相交/排除模式通过 evenodd 模拟渲染 |
| | 圆角修改器 (Rounding - `rd`) | 🟠 部分支持 | 已支持模型定义与解析 |
| **图层类型 (Layers)** | 形状图层 (Shape Layer) | ✅ 已支持 | |
| | 预合成图层 (Pre-comp Layer) | ✅ 已支持 | |
| | 固态层 (Solid Layer) | ✅ 已支持 | |
| | 图片层 (Image Layer) | 🟠 部分支持 | JS 预加载完成，Wasm 渲染待对接 |
| | 空对象图层 (Null Layer) | ✅ 已支持 | |
| **高级渲染** | 蒙版 (Masks) | ✅ 已支持 | 支持 Add, Subtract, Intersect |
| | 遮罩 (Track Mattes) | 🟠 部分支持 | 已支持 `Alpha` 模式 |
| | 混合模式 (Blend Modes) | ✅ 已支持 | |
| | 表达式 (Expressions) | ⚪ 建议烘焙 | 遵循工业化实践，暂不引入 JS 运行时以保证极致性能与跨平台一致性。推荐使用“烘焙”模式导出。 |

## 动画与插值

| 特性 | 状态 | 备注 |
| :--- | :--- | :--- |
| 线性插值 (Linear) | ✅ 已支持 | |
| 贝塞尔插值 (Bezier Easing) | ✅ 已支持 | 通过 `i` 和 `o` 控制时间进度 |
| 空间贝塞尔 (Spatial Bezier) | ✅ 已支持 | 通过 `ti` 和 `to` 控制运动路径 |
| 关键帧延迟 (Hold) | ✅ 已支持 | |

## 工程化与质量体系 (Engineering & Quality)

| 关键能力 | 状态 | 备注 |
| :--- | :--- | :--- |
| **L1 解析器分析 (L1 Reporter)** | ✅ 已支持 | 自动化未识别键检测，量化解析覆盖率 |
| **全环境 SVG 归一化 (Fidelity)** | ✅ 已支持 | 数值精度 (0.01) 与 ID 稳定，支持 Bit-for-bit 对比 |
| **金标回归测试集 (Golden Snapshots)** | ✅ 已支持 | 集成 Node.js 官方渲染抽帧对比流水线 |

## 关于表达式 (Expressions) 的专项决策

经评估，`moon-lottie` 暂不支持 JS 表达式，建议采取 **“烘焙导向 (Baking Oriented)”** 的处理策略，主要基于以下工程考量：

1.  **复杂度**：完整支持表达式不仅需要 JS 解释器，还需实现运行对象模型 (ROM) 寻址及复杂的空间坐标变换（如 `toComp`），其工作量相当于在动画库内嵌入一个小型脚本引擎。
2.  **Native 后端一致**：MoonBit 追求 Wasm 与 Native 双后端一致性。Native 环境通常缺乏 JS 运行时。为保持轻量化体积与跨平台表现的一致性，暂不引入 JS 引擎。
3.  **工业界最佳实践**：遵循 Telegram (TGS) 及高性能移动端动效标准，鼓励在导出阶段将表达式“烘焙”为关键帧，从而在运行时获得 $O(1)$ 的插值性能优势。

## 待办优先级 (Roadmap)

1. **Image Support**: 完善 FFI 以支持位图。
2. **Full Mask/Matte Modes**: 补充 Subtract, Intersect 等模式。
3. **Merge Paths (`mm`)**: 处理复杂路径合并布尔运算。
4. **Performance**: 引入 SIMD 加速矩阵与贝塞尔计算。
