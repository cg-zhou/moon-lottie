export const platformColumns = [
  { key: "moon", label: "MoonLottie", highlight: true },
  { key: "android", label: "Android" },
  { key: "iosCoreAnimation", label: "iOS（Core Animation）" },
  { key: "iosMainThread", label: "iOS（主线程）" },
  { key: "windows", label: "Windows" },
  { key: "webSvg", label: "网页（SVG）" },
  { key: "webCanvas", label: "网页（Canvas）" },
  { key: "webHtml", label: "网页（HTML）" },
];

export const statusSymbols = {
  supported: "👍",
  unsupported: "⛔️",
  unknown: "❔",
};

const supported = "supported";
const unsupported = "unsupported";
const unknown = "unknown";

const yes = supported;
const no = unsupported;
const maybe = (symbol = "❔", detail = "") => ({ status: unknown, symbol, detail });
const yesWith = (detail) => ({ status: supported, detail });

export const supportSections = [
  {
    id: "shapes",
    title: "形状",
    rows: [
      { feature: "形状", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "椭圆", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "矩形", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "圆角矩形", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "多角星", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "组", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "重复器", android: yes, iosCoreAnimation: yes, iosMainThread: no, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "修剪路径（单独）", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "修剪路径（同时）", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: "fills",
    title: "填充",
    rows: [
      { feature: "颜色", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "不透明度", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "填充规则", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "径向渐变", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "线性渐变", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: "strokes",
    title: "描边",
    rows: [
      { feature: "不透明度", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "颜色", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "宽度", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "线帽", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "线段连接", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "斜接限制", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "虚线", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: "transforms",
    title: "变换",
    rows: [
      { feature: "锚点", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "位置", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "缩放", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "旋转", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "不透明度", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "倾斜", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "倾斜轴", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "自动朝向", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: "general",
    title: "通用特性",
    rows: [
      { feature: "蒙版", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "轨道遮罩", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "图片", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "标记", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: maybe("❔", "解析器持续完善中") },
      { feature: "表达式", android: yes, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: no, moon: yesWith("JS 宿主 MVP") },
    ],
  },
];
