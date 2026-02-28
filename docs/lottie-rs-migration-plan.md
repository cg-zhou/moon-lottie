# 从 `zimond/lottie-rs` 迁移到 `moon-lottie` 的任务清单

> 目标：补强基础设施层，提升渲染错误可定位性，并系统化迁移 `lottie-rs` 中可复用能力。

## 1) 迁移范围与依赖顺序

按依赖关系建议顺序：`math -> model -> parser -> runtime -> renderer -> regression/tooling`。

| 顺序 | 源仓库目录（lottie-rs） | 目标仓库目录（moon-lottie） | 说明 |
| :-- | :-- | :-- | :-- |
| 1 | `src/math/`（或等价模块） | `lib/math/` | 向量/矩阵/贝塞尔/插值等基础能力，作为后续模块前置依赖 |
| 2 | `src/model/`（或等价模块） | `lib/model/` | 动画结构体、图层、形状、属性、枚举 |
| 3 | `src/parser/`（或等价模块） | `lib/parser/` | JSON 到模型的解析、容错、错误定位 |
| 4 | `src/runtime/`（或等价模块） | `lib/runtime/` | 关键帧求值、插值器、时间轴采样 |
| 5 | `src/renderer/`（或等价模块） | `lib/renderer/` | SVG/Canvas 渲染管线与 Player 协调层 |
| 6 | `tests/`、`examples/`（或等价目录） | `lib/**/**_test.mbt`、`test/regression/`、`scripts/` | 回归测试、快照工具、对齐验证 |

## 2) 任务列表（可执行 Checklist）

### A. 基线与映射
- [ ] 建立目录映射表：逐项记录 `lottie-rs` 源目录 -> `moon-lottie` 目标目录。
- [ ] 产出符号级迁移清单：类型、函数、常量、错误类型。
- [ ] 识别不可直接迁移项（语言特性/运行时差异）并登记替代方案。

### B. 基础层（math/model）
- [ ] 对齐 `lib/math/`：补齐向量、矩阵、贝塞尔、插值算法差异。
- [ ] 对齐 `lib/model/`：补齐枚举、Layer/Shape/Transform/Mask 字段缺口。
- [ ] 为新增/变更模型补充单元测试（字段断言 + 默认值/异常输入）。

### C. 解析层（parser）
- [ ] 对齐 `lib/parser/` 的字段覆盖率与容错行为。
- [ ] 强化错误定位信息（字段路径、图层名、帧上下文）。
- [x] 增加未知字段报告与覆盖率统计输出（用于定位渲染错误根因）。

### D. 运行时层（runtime）
- [ ] 对齐关键帧求值器与插值器语义（linear/bezier/spatial/hold）。
- [ ] 对齐变换链路（position/scale/rotation/opacity/anchor）求值细节。
- [ ] 增加关键帧采样测试（0%、25%、50%、75%、100%）。

### E. 渲染层（renderer）
- [ ] 对齐 `lib/renderer/` 的图层合成、蒙版/遮罩、混合模式行为。
- [ ] 补齐渲染诊断信息（当前图层、shape 索引、属性来源）以便排障。
- [ ] 为典型失败样例建立最小复现测试（优先 frame=0 + 关键帧）。

### F. 回归与工具链
- [ ] 将 `lottie-rs` 可复用测试样例映射到 `samples/` 与 `test/regression/`。
- [ ] 生成/更新快照并记录差异原因（解析差异、插值差异、渲染差异）。
- [ ] 在文档中持续更新任务状态与剩余阻塞项。

## 3) 现阶段完成情况（基于仓库当前文档与代码状态）

- [x] 已具备基础模块骨架：`lib/math`、`lib/model`、`lib/parser`、`lib/runtime`、`lib/renderer`。
- [x] 已迁移并落地部分核心模型能力（如 `Color`、`BlendMode`、`MatteMode`、`FillRule`、`LineCap`、`LineJoin`）。
- [x] 已具备 SVG 回归测试体系与样例集（`test/regression/`）。
- [ ] 基础设施层的“渲染错误可定位性”仍不足（错误上下文、依赖链追踪、定位信息需加强）。
- [ ] 仍有特性缺口需补齐（如文档中提到的 Effects/表达式相关能力与部分渲染一致性问题）。

本轮变更（2026-02-28）：
- [x] parser 未知字段覆盖率统计：新增 `report_unknown_keys_with_coverage` 与 `UnknownKeyReport`（`lib/parser/parser.mbt`）。
- [x] 测试补充：`lib/parser/reporter_test.mbt` 增加未知字段路径与覆盖率计数断言（`moon test -p cg-zhou/moon-lottie/lib/parser` 通过）。

## 4) 交付定义（DoD）

- [ ] 每个迁移项都能追溯到：源位置、目标位置、测试用例、状态。
- [ ] 每个新增能力至少包含：单测 + 回归样例（如适用）。
- [ ] 回归失败可定位到具体层级：parser/runtime/renderer 及对应字段或图层。
- [ ] 本文档状态与代码实现保持同步更新。

## 5) 给后续 AI Agent 的提示词（可直接复制）

你现在是 `moon-lottie` 迁移执行 Agent。请严格按以下步骤执行，并在每一步后更新本任务文档中的 checklist 状态：

1. **读取与建模依赖**
   - 读取 `docs/lottie-rs-migration-plan.md`。
   - 扫描 `lib/math`, `lib/model`, `lib/parser`, `lib/runtime`, `lib/renderer`, `test/regression`。
   - 建立迁移依赖图，确保按 `math -> model -> parser -> runtime -> renderer -> tests` 顺序执行。

2. **对比与迁移**
   - 对照 `zimond/lottie-rs` 对应目录，先做目录级差异，再细化到文件/符号级差异。
   - 每次只迁移一小组强相关改动，避免大批量不可验证变更。
   - 对不可直接迁移的实现，给出 MoonBit 等价实现，并在文档中标注原因。

3. **测试生成与验证**
   - 为每个迁移点补充或更新最小测试：
     - 模型/解析：字段断言与异常输入。
     - 运行时：关键帧采样断言。
     - 渲染：最小回归快照或路径哈希断言。
   - 优先运行受影响模块的定向测试，再运行必要的集成回归测试。

4. **排障与可观测性增强（重点）**
   - 迁移或补充用于定位渲染错误的基础设施：
     - 错误上下文（layer/shape/property/frame）。
     - 关键计算链路日志或可调试输出（默认关闭，可开关）。
     - 失败样例最小复现脚本/测试入口。

5. **状态回写与交付**
   - 每完成一项任务，立即更新本文档 checklist（`[ ]` -> `[x]`），并追加简短变更说明（文件路径 + 测试结果）。
   - 若阻塞，记录“阻塞原因/所需输入/建议下一步”。
   - 最终输出：已完成项、未完成项、风险项、下一步优先级。

执行要求：
- 始终最小化改动；
- 始终按依赖顺序迁移；
- 始终为迁移点补测试；
- 始终更新本文档状态，保证可追踪。
