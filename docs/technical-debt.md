# 技术债与待办检查 (Technical Debt & Verification)

记录在快速迭代中“简化”或“忽略”的细节, 必须在进入下一个大阶段前清空。

## 活跃的技术债 (Active Debt)

- [x] **Parser 完整性验证**: `lib/parser/parser_test.mbt` 中的 `parse_shape_layer` 测试目前已实现全字段断言 (v, fr, w, h, nm, data)。
- [x] **路径数据读取**: `Path` 解析已支持直接读取 `{v, i, o, c}` (Case 2) 结构, 解决了非包装属性导致解析失败的问题。
- [x] **隐藏字段与父级绑定**: 已实现 `hd` 隐藏字段解析及渲染跳过, 以及 `parent` 字段图层级联变换。
- [x] **预合成与图片支持**: 已初步实现 `PreComp` 和 `Image` 的渲染逻辑。
- [ ] **路径插值 (Path Morphing)**: 当前 `evaluate_path_property` 虽定义了线性插值逻辑, 但受限于 LottieKeyframe 结构（缺少 `end_value`）, 暂退回到静态取值。需重构属性模型以支持关键帧间的形状过渡。
- [ ] **空间贝塞尔插值 (Spatial Bezier)**: 当前 `evaluate_vec_property` 仅支持时间轴上的 Easing, 尚未实现位置属性的 `ti` / `to` 空间插值。
- [ ] **多维独立分量插值**: 某些 Lottie 属性 (如 Position) 可能被拆分为独立的 X 和 Y 分量, 评价器需支持此逻辑。
- [ ] **错误处理**: 当前解析器遇到不匹配类型会直接抛出空值或默认值, 缺乏明确的错误位置报告。

## 验证协议 (Verification Protocol)

1. **全字段闭环**: 每一个 `model` 增加的字段, 必须在 `parser` 中有对应的解析逻辑, 并在 `test` 中有显式断言。
2. **不允许 `_` 忽略**: 在测试断言中, 严禁使用 `_` 忽略掉 Spec 中的关键字段。
3. **性能基准**: 复杂的插值计算必须包含基准测试 (Benchmark)。
