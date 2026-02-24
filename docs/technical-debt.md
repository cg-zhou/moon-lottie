# 技术债与待办检查 (Technical Debt & Verification)

记录在快速迭代中“简化”或“忽略”的细节, 必须在进入下一个大阶段前清空。

## 活跃的技术债 (Active Debt)

- [x] **Parser 完整性验证**: `lib/parser/parser_test.mbt` 中的 `parse_shape_layer` 测试目前已实现全字段断言 (v, fr, w, h, nm, data)。
- [x] **路径数据读取**: `Path` 解析已支持直接读取 `{v, i, o, c}` (Case 2) 结构, 解决了非包装属性导致解析失败的问题。
- [ ] **错误处理**: 当前解析器遇到不匹配类型会直接抛出空值或默认值, 缺乏明确的错误位置报告。

## 验证协议 (Verification Protocol)

1. **全字段闭环**: 每一个 `model` 增加的字段, 必须在 `parser` 中有对应的解析逻辑, 并在 `test` 中有显式断言。
2. **不允许 `_` 忽略**: 在测试断言中, 严禁使用 `_` 忽略掉 Spec 中的关键字段。
3. **性能基准**: 复杂的插值计算必须包含基准测试 (Benchmark)。
