# Lottie 术语与缩写对照表 (Glossary)

为了防止在代码实现和测试中出现“简化”导致的精度失损或逻辑遗漏, 本项目强制要求对照此表进行字段实现。

| 缩写 | 全称 | 类型 | 描述 |
| :--- | :--- | :--- | :--- |
| `v` | version | String | Lottie 版本号 |
| `fr` | frameRate | Number | 帧率 (每秒帧数) |
| `ip` | inPoint | Number | 入点 (开始帧) |
| `op` | outPoint | Number | 出点 (结束帧) |
| `w` | width | Number | 画布宽度 |
| `h` | height | Number | 画布高度 |
| `nm` | name | String | 对象的显示名称 |
| `ks` | transform | Object | 变换属性 (Keyframe Structure) |
| `ty` | type | Int/String | 类型标识符 |
| `layers` | layers | Array | 动画层 |
| `it` | items | Array | Shape 组内的元素列表 |
| `ks` | transform | Object | 变换 (Anchor, Pos, Scale, Rot, Opacity) |
| `o` | opacity | Object/Num | 透明度/不透明度 (0-100) |
| `c` | color | Vector/Array | 颜色属性 (RGB 0-1) |
| `w` | width | Number/Object | 描边宽度 |
| `s` | size | Vector | 矩形/椭圆的大小 |
| `p` | position | Vector | 位置 |
| `r` | roundedness | Number | 矩形的圆角半径 |
| `d` | direction | Number | 路径方向 (1: 顺时针, 2: 逆时针) |
| `hd` | hidden | Boolean | 指示元素是否被隐藏 |
| `parent` | parent | Int | 引用父层的 `ind` (Index) |
| `ind` | index | Int | 图层在合成中的索引标识 |
| `assets` | assets | Array | 动画引用的外部资源列表 (图片/预合成) |
| `refId` | referenceId | String | 引用资产的 ID |
```
