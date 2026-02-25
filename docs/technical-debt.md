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

## 验证协议 (Verification Protocol)

1. **全字段闭环**: 每一个 `model` 增加的字段, 必须在 `parser` 中有对应的解析逻辑, 并在 `test` 中有显式断言。
2. **不允许 `_` 忽略**: 在测试断言中, 严禁使用 `_` 忽略掉 Spec 中的关键字段。
3. **性能基准**: 复杂的插值计算必须包含基准测试 (Benchmark)。
