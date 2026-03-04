# Lottie 一致性测试基准 (Compliance & Snapshot Benchmark)

本文件用于追踪 `moon-lottie` 与官方 `lottie-web` 的渲染对齐进度。测试采用 SVG 抽帧对比作为“金标准”，并补充像素级帧对比（渲染结果对比，而非 SVG 文本对比）。

## 对齐等级定义 (Compliance Stages)

- **L1 (结构)**: Parser 无损解析，能够重构完整的图层树与资产库。验证指标：JSON 解析无 Panic 且核心字段无缺失。
- **L2 (静态)**: 静态帧（帧 0）的绘图指令完全对齐。验证指标：SVG 路径数据 (Path Data) 与 Hash 匹配。
- **L3 (动态)**: 关键帧插值与属性驱动在时间轴上表现正确。验证指标：关键帧采样点（如 25%, 50%, 75%）的 SVG 序列匹配。
- **L4 (高级)**: 表达式、高级几何修改器及复杂遮罩逻辑闭环。验证指标：逻辑驱动后的最终路径产物匹配。

## 测试状态矩阵 (Status Matrix)

| 动画文件 (Fixtures) | L1 (结构) | L2 (静态) | L3 (动态) | L4 (高级) | 进度 / 瓶颈 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [starfish.json](../samples/starfish.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | 待全量回归验证 |
| [bacon.json](../samples/bacon.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | 待全量回归验证 |
| [ripple.json](../samples/ripple.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | 关键瓶颈：L4 (表达式) 驱动缺失 |
| [lights.json](../samples/lights.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | 关键瓶颈：L4 (表达式) 驱动缺失 |
| [adrock.json](../samples/adrock.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | - |
| [monster.json](../samples/monster.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | - |
| [dalek.json](../samples/dalek.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | - |
| [navidad.json](../samples/navidad.json) | ⏳ Pending | ⏳ Pending | ⏳ Pending | ⏳ Pending | - |

## 待建立的自动化工具

- [ ] **SVG Hash 对比脚本**: 自动运行 `moon test` 并对比 `lib/renderer/__snapshot__` 中的 Hash 值。
- [x] **像素级帧 Diff 工具**: `test/snapshot_tool/compare_frames.js`，将 SVG 渲染为像素后按帧比较并输出 diff PNG。
- [x] **用例配置驱动帧对比工具**: `scripts/snapshot_tool/regression_test.js`，读取 `文件名 + [sim=0.99] + 多帧` 配置，导出 moon/offical PNG、diff 图和一致性比例。支持每行指定相似度要求，默认读取 `cases.txt`。
- [ ] **官方 Trace 提取服务**: 使用 Node.js 脚本批量导出官方渲染指令流。

## 用例配置驱动帧对比脚本

```bash
cd scripts/snapshot_tool
npm run compare:cases -- --cases /path/to/cases.txt --min-similarity 0.99
```

`cases.txt` 每行格式示例：

```txt
1_1_Super_Mario.json 23 46
```

执行后会在当前目录创建 `frame_compare_tmp_*` 临时目录，输出：

- `1_1_Super_Mario_23.png`（moon-lottie）
- `1_1_Super_Mario_23_official.png`（lottie-web）
- `1_1_Super_Mario_23_diff.png`（差异图）

## 活跃瓶颈分析 (Hot Issues)

1. **Effects 变量池**: Parser 尚未支持 `ef` 数组，导致依赖 Effect 控制器的动画全部失效（如 `ripple`, `lights`）。
2. **表达式寻址**: 表达式引擎需要能够通过 `thisComp.layer('name')` 访问到外部对象。
3. **数学精度**: 空间贝塞尔插值 (Spatial Bezier) 在长路径下与 JS 端的浮点数累积误差。
