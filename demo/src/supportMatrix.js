export const platformColumns = [
  { key: "moon", label: "Moon Lottie", highlight: true },
  { key: "android", label: "Android" },
  { key: "iosCoreAnimation", label: "iOS（Core Animation）" },
  { key: "iosMainThread", label: "iOS（主线程）" },
  { key: "windows", label: "Windows" },
  { key: "webSvg", label: "网页（SVG）" },
  { key: "webCanvas", label: "网页（Canvas）" },
  { key: "webHtml", label: "网页（HTML）" },
]

export const statusSymbols = {
  supported: "👍",
  unsupported: "⛔️",
  unknown: "❔",
}

const supported = "supported"
const unsupported = "unsupported"
const unknown = "unknown"

const yes = supported
const no = unsupported
const maybe = (detail = "") => ({ status: unknown, detail })
const yesWith = (detail) => ({ status: supported, detail })
const noWith = (detail) => ({ status: unsupported, detail })

const row = (feature, official, moon = maybe()) => ({ feature, ...official, moon })

const officialAllSupported = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: yes,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialAllUnsupported = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: no,
  webCanvas: no,
  webHtml: no,
}

const officialWebOnlySupported = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialAllSupportedExceptWindows = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialAllSupportedExceptIosMainThread = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: no,
  windows: yes,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialAllSupportedExceptIosCoreAnimation = {
  android: yes,
  iosCoreAnimation: no,
  iosMainThread: yes,
  windows: yes,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialTransformAutoOrient = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialTransformSkew = {
  android: maybe(),
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: maybe(),
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialMaskIntersect = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: no,
  webCanvas: no,
  webHtml: no,
}

const officialMaskExpansion = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: no,
  webCanvas: yes,
  webHtml: yes,
}

const officialMattesAlphaInverted = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialMattesLuma = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: maybe(),
  webCanvas: maybe(),
  webHtml: maybe(),
}

const officialMergePaths = {
  android: yesWith("KitKat+"),
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: yes,
  webSvg: no,
  webCanvas: no,
  webHtml: no,
}

const officialLayerEffectsLevels = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: maybe(),
  webCanvas: yes,
  webHtml: yes,
}

const officialLayerEffectsBlur = {
  android: yesWith("Android 4.1+"),
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: maybe(),
  webCanvas: maybe(),
  webHtml: maybe(),
}

const officialLayerEffectsDropShadow = {
  android: yesWith("Android 4.1+"),
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: maybe(),
  webCanvas: maybe(),
  webHtml: maybe(),
}

const officialTextGlyphs = {
  android: yes,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialTextBasic = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialTextWebOnly = {
  android: no,
  iosCoreAnimation: no,
  iosMainThread: no,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

const officialOtherTime = {
  android: yes,
  iosCoreAnimation: yes,
  iosMainThread: yes,
  windows: no,
  webSvg: yes,
  webCanvas: yes,
  webHtml: yes,
}

export const supportSections = [
  {
    id: "shapes",
    title: "形状",
    rows: [
      row("形状", officialAllSupported, yes),
      row("椭圆", officialAllSupported, yes),
      row("矩形", officialAllSupported, yes),
      row("圆角矩形", officialAllSupported, yes),
      row("多角星", { ...officialAllSupported, windows: no }, yes),
      row("组", officialAllSupported, yes),
      row("重复器", officialAllSupportedExceptIosMainThread, yes),
      row("修剪路径（单独）", { ...officialAllSupported, windows: no }, yes),
      row("修剪路径（同时）", officialAllSupportedExceptIosCoreAnimation, yes),
    ],
  },
  {
    id: "fills",
    title: "填充",
    rows: [
      row("颜色", officialAllSupported, yes),
      row("不透明度", officialAllSupported, yes),
      row("填充规则", officialAllSupported, yes),
      row("径向渐变", officialAllSupported, yes),
      row("线性渐变", officialAllSupported, yes),
    ],
  },
  {
    id: "strokes",
    title: "描边",
    rows: [
      row("颜色", officialAllSupported, yes),
      row("不透明度", officialAllSupported, yes),
      row("宽度", officialAllSupported, yes),
      row("线帽", officialAllSupported, yes),
      row("线段连接", officialAllSupported, yes),
      row("斜接限制", officialAllSupported, yes),
      row("虚线", officialAllSupported, yes),
      row("渐变", officialAllSupported, yesWith("已覆盖 Gradient Stroke")),
    ],
  },
  {
    id: "transforms",
    title: "变换",
    rows: [
      row("位置", officialAllSupported, yes),
      row("位置（分离 X/Y）", officialAllSupported, yesWith("支持分离 X/Y 位置属性")),
      row("缩放", officialAllSupported, yes),
      row("旋转", officialAllSupported, yes),
      row("锚点", officialAllSupported, yes),
      row("不透明度", officialAllSupported, yes),
      row("父子层级", officialAllSupported, yesWith("支持父层级变换继承")),
      row("自动朝向", officialTransformAutoOrient, yes),
      row("倾斜", officialTransformSkew, yes),
    ],
  },
  {
    id: "interpolation",
    title: "插值",
    rows: [
      row("线性插值", officialAllSupported, yes),
      row("贝塞尔插值", officialAllSupported, yes),
      row("保持插值", officialAllSupported, yes),
      row("空间贝塞尔插值", officialAllSupported, yes),
      row("时间漫游", officialAllSupported, yes),
    ],
  },
  {
    id: "masks",
    title: "蒙版",
    rows: [
      row("蒙版路径", officialAllSupported, yes),
      row("蒙版不透明度", officialAllSupported, yes),
      row("相加", officialAllSupported, yes),
      row("相减", officialAllSupported, yes),
      row("相交", officialMaskIntersect, yesWith("已由现有 parser_test / svg_test 覆盖相交蒙版解析与渲染")),
      row("变亮", officialAllUnsupported, no),
      row("变暗", officialAllUnsupported, no),
      row("差值", officialAllUnsupported, no),
      row("扩展", officialMaskExpansion, yesWith("已由 parser_test / snapshot_test 覆盖蒙版扩展")),
      row("羽化", officialAllUnsupported, no),
    ],
  },
  {
    id: "mattes",
    title: "遮罩",
    rows: [
      row("Alpha 遮罩", officialAllSupported, yes),
      row("Alpha 反相遮罩", officialMattesAlphaInverted, yes),
      row("亮度遮罩", officialMattesLuma, no),
      row("亮度反相遮罩", officialMattesLuma, no),
    ],
  },
  {
    id: "mergePaths",
    title: "合并路径",
    rows: [
      row("合并", officialMergePaths, noWith("当前实现与 lottie-web Web 渲染器一致，将 Merge Paths 视为 no-op")),
      row("相加", officialMergePaths, noWith("当前实现与 lottie-web Web 渲染器一致，将 Merge Paths 视为 no-op")),
      row("相减", officialMergePaths, noWith("当前实现与 lottie-web Web 渲染器一致，将 Merge Paths 视为 no-op")),
      row("相交", officialMergePaths, noWith("当前实现与 lottie-web Web 渲染器一致，将 Merge Paths 视为 no-op")),
      row("排除相交", officialMergePaths, noWith("当前实现与 lottie-web Web 渲染器一致，将 Merge Paths 视为 no-op")),
    ],
  },
  {
    id: "layerEffects",
    title: "图层效果",
    rows: [
      row("填充", officialWebOnlySupported, yesWith("已解析并渲染 ADBE Fill")),
      row("描边", officialWebOnlySupported, noWith("已由 parser_test 核对：当前仅解析/渲染 ADBE Fill，未支持 ADBE Stroke")),
      row("色调", officialWebOnlySupported, noWith("已由 parser_test 核对：当前未解析/渲染 Tint")),
      row("三色调", officialWebOnlySupported, noWith("已由 parser_test 核对：当前未解析/渲染 Tritone")),
      row("色阶（独立控制）", officialLayerEffectsLevels, noWith("已由 parser_test 核对：当前未解析/渲染 Levels")),
      row("高斯模糊", officialLayerEffectsBlur, noWith("已由 parser_test 核对：当前未解析/渲染 Gaussian Blur")),
      row("投影", officialLayerEffectsDropShadow, noWith("已由 parser_test 核对：当前未解析/渲染 Drop Shadow")),
    ],
  },
  {
    id: "text",
    title: "文本",
    rows: [
      row("字形", officialTextGlyphs, yes),
      row("字体", officialTextBasic, yes),
      row("变换", officialTextBasic, yes),
      row("填充", officialTextBasic, yes),
      row("描边", officialTextBasic, yes),
      row("字距", officialTextBasic, yes),
      row("锚点分组", officialTextWebOnly, yes),
      row("路径文字", officialTextWebOnly, no),
      row("逐字符 3D", officialTextWebOnly, no),
      row("范围选择器（单位）", officialTextWebOnly, yes),
      row("范围选择器（基于）", officialTextWebOnly, yes),
      row("范围选择器（数量）", officialTextWebOnly, yes),
      row("范围选择器（形状）", officialTextWebOnly, yes),
      row("范围选择器（缓动高）", officialTextWebOnly, yes),
      row("范围选择器（缓动低）", officialTextWebOnly, yes),
      row("范围选择器（随机顺序）", officialTextWebOnly, yes),
      row("表达式选择器", officialTextWebOnly, no),
    ],
  },
  {
    id: "other",
    title: "其它",
    rows: [
      row("表达式", officialWebOnlySupported, yesWith("JS 宿主 MVP")),
      row("图片", officialAllSupported, yes),
      row("预合成", officialAllSupported, yes),
      row("时间拉伸", officialOtherTime, noWith("已由 player_debug_test 核对：layer.sr 当前仍被忽略")),
      row("时间重映射", officialOtherTime, yes),
      row("标记", officialAllSupported, noWith("已由 parser_test 核对：Animation 模型预留了 markers，但解析器仍未读取 markers")),
    ],
  },
]
