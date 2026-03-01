# 技术债与待办检查 (Technical Debt & Verification)

记录在快速迭代中“简化”或“忽略”的细节, 必须在进入下一个大阶段前清空。

## 活跃的技术债 (Active Debt)

- [x] **Parser 完整性验证**: `lib/parser/parser_test.mbt` 中的 `parse_shape_layer` 测试目前已实现全字段断言 (v, fr, w, h, nm, data)。
- [x] **路径数据读取**: `Path` 解析已支持直接读取 `{v, i, o, c}` (Case 2) 结构, 解决了非包装属性导致解析失败的问题。
- [x] **隐藏字段与父级绑定**: 已实现 `hd` 字段解析及渲染逻辑跳过, 以及 `parent` 字段图层级联变换。
- [x] **颜色 FFI 桥接与渲染**: 重构为数值型颜色传递 (`r, g, b, opacity/width`), 解决了字符串编码导致的 Canvas 渲染失效问题。
- [x] **路径与插值优化**: 完善了 `Path` 属性的关键帧插值 (`evaluate_path_property`), 修正了模型使其支持 `end_value` 过渡动画。
- [x] **空间贝塞尔插值 (Spatial Bezier)**: 已在 `evaluate_vec_property` 中实现基于 `ti` / `to` 的三阶贝塞尔空间插值。
- [x] **多维独立分量插值**: 评价器已支持解析和计算独立的 X (`px`) 和 Y (`py`) 位置属性。
- [x] **遮罩与蒙版基础支持 (Masks/Matte)**: 已支持 `Add` 模式的遮罩剪切 (`Clipping Path`)，以及基于 `destination-in` 的 Alpha Track Matte 渲染。
- [ ] **高阶混合模式 (BlendModes/LumaMatte)**: 需实现真正的 Luma Matte (亮度叠加) 以及图层混合模式 (`bm` 字段)。
- [ ] **路径变形动画 (Morphing)**: 确保两个贝塞尔路径点数一致时的插值正确性 (目前 evaluate_path_property 已有基础实现)。
- [ ] **性能优化 (SIMD)**: 探索在矩阵运算中使用 MoonBit SIMD 以加速关键帧密集的动画。
- [x] **错误处理**: 解析器已全面引入 `raise LottieError` 机制，提供明确的错误类型反馈，解决了空值默认填充导致的调试困难。
- [x] **色彩渐变 (Gradients)**: 已支持线性渐变 (`gf`) 和径向渐变 (`gs`) 的解析与 FFI 渲染，通过多步 FFI 调用规避了 `Array` 传递的限制。
- [x] **高级几何修改器 (Advanced Modifiers)**: 已实现路径修整 (Trim Paths)、星形/多边形 (Polystar) 及中继器 (Repeater) 的解析与渲染逻辑。
- [x] **Trim Paths 精确切分**: 采用 De Casteljau 算法实现了对三阶贝塞尔曲线在任意百分比位置的精确切分与路径保留。
- [x] **Polystar 与圆角生成**: 实现了星形与多边形的动态生成，并支持基于 Lottie 标准曲率魔数的内/外圆角平滑。
- [x] **Repeater 复合绘制**: 实现了中继器的多副本偏移、缩放、旋转级联变换，并支持 Above/Below 两种复合模式。
- [x] **子合成与资产系统 (PreComps/Assets)**: 已解析并实现 `PreComp` 的递归渲染逻辑以及 `Solid` 纯色层支持。
- [x] **线条样式样式对标 (Stroke Styles)**: 全面支持 Line Cap, Line Join 和 Miter Limit 的解析与渲染。
- [x] **模型架构对齐 (MergePaths/Rounding)**: 已补齐 `Merge Paths` 与 `Rounding` 的数据模型及解析支持。
- [x] **路径合并逻辑 (MergePaths Logic)**: 实现了基础的 `Merge/Add` 模式支持，并为 `Subtract/Intersect/Exclude` 提供了基于 `evenodd` 的渲染回退。
- [x] **SVG 渲染器状态栈 (Renderer State Stack)**: 已修复嵌套透明度与剪解路径导致的 SVG 标签不匹配问题，实现 `gc` (Group Counter) 计数。
- [ ] **表达式支持 (Expressions/JS Engine)**: Wasm 端拟采用 JS FFI 转发 eval，Native 端暂不支持（考虑 Baking 方案）。
- [x] **图像加载与渲染 (Image Layer)**: 对齐 `lottie-rs` 媒体源解析语义（`u + p` / data URL），并在 Demo 端同时按 `asset.id` 与解析后的 `src` 建立索引，打通 Wasm -> JS 的 `draw_image` 闭环。
- [x] **多模式遮罩 (Masks Modes)**: 已实现 `Add`, `Subtract`, `Intersect` 模式，通过 SvgRenderer 的 State Stack 方案适配复杂遮罩逻辑。- [ ] **特效控制器与变量系统 (Effects/Variables)**: `ripple.json` 与 `lights.json` 等依赖 `ef` 字段进行驱动。需在 `Layer` 模型中增加特效解析，并将 Effects 注册到 `Evaluator` 上下文中。
- [ ] **表达式执行上下文 (Expression Context)**: 表达式如 `layer('A').effect('B')('C')` 需要全局寻址能力。需在 `Player` 层级维护图层与特效的索引表。
- [x] **SVG 抽帧回测系统 (SVG Regressions)**: 建立了 `SvgRenderer` 指令后端，并成功跑通了官方 `starfish.json` (24KB) 的 300 帧全量路径渲染测试。
- [ ] **大型 JSON 加载方案**: 当前 `starfish.json` 采用硬编码字符串拼接，未来需重构为通过 `#embed` 或 `test/fixtures` 自动构建加载。
- [x] **变换属性容错**: 修正了 `evaluate_transform` 等评估器对非标尺度数组（如 [1] vs [1, 1, 1]）的兼容性。
- [x] **SVG 归一化与 ID 稳定化**: 已实现 `fmt()` 辅助函数（精度 0.01）及 `lottie-id` 占位符，解决了跨环境下的字符串不匹配问题，支持 bit-for-bit 回归测试。
- [x] **L1 Parser 探测器 (Unknown Keys Reporter)**: 实现了 `report_unknown_keys` 工具，可自动识别 JSON 中未被模型定义的字段，量化 Spec 覆盖率。
- [x] **构建稳定性修复 (Config Corruption)**: 解决了 `Native` 目标下由于 `nocturnejs` 配置冲突导致的构建崩溃，统一了 `moon.pkg.json` 规范。

## 验证协议 (Verification Protocol)

1. **全字段闭环**: 每一个 `model` 增加的字段, 必须在 `parser` 中有对应的解析逻辑, 并在 `test` 中有显式断言。
2. **不允许 `_` 忽略**: 在测试断言中, 严禁使用 `_` 忽略掉 Spec 中的关键字段。
3. **性能基准**: 复杂的插值计算必须包含基准测试 (Benchmark)。
