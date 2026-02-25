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
| | 表达式 (Expressions) | ❌ 未支持 | 待调研 Wasm 桥接方案 |

## 动画与插值

| 特性 | 状态 | 备注 |
| :--- | :--- | :--- |
| 线性插值 (Linear) | ✅ 已支持 | |
| 贝塞尔插值 (Bezier Easing) | ✅ 已支持 | 通过 `i` 和 `o` 控制时间进度 |
| 空间贝塞尔 (Spatial Bezier) | ✅ 已支持 | 通过 `ti` 和 `to` 控制运动路径 |
| 关键帧延迟 (Hold) | ✅ 已支持 | |

## 待办优先级 (Roadmap)

1. **Image Support**: 完善 FFI 以支持位图。
2. **Full Mask/Matte Modes**: 补充 Subtract, Intersect 等模式。
3. **Merge Paths (`mm`)**: 处理复杂路径合并布尔运算。
4. **Performance**: 引入 SIMD 加速矩阵与贝塞尔计算。
