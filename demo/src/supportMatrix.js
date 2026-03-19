export const platformColumns = [
  { key: "moon", label: "Moon Lottie", highlight: true },
  { key: "android", label: "Android" },
  { key: "iosCoreAnimation", label: "iOS (Core Animation)" },
  { key: "iosMainThread", label: "iOS (Main Thread)" },
  { key: "windows", label: "Windows" },
  { key: "webSvg", label: "Web (SVG)" },
  { key: "webCanvas", label: "Web (Canvas)" },
  { key: "webHtml", label: "Web (HTML)" },
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
    title: { zh: "形状", en: "Shapes" },
    rows: [
      { feature: "Shape", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Ellipse", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Rectangle", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Rounded Rectangle", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Polystar", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Group", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Repeater", android: yes, iosCoreAnimation: yes, iosMainThread: no, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Trim Path (individually)", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Trim Path (simultaneously)", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: "fills",
    title: { zh: "填充", en: "Fills" },
    rows: [
      { feature: "Color", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Opacity", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Fill Rule", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Radial Gradient", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Linear Gradient", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: "strokes",
    title: { zh: "描边", en: "Strokes" },
    rows: [
      { feature: "Opacity", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Color", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Width", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Line Cap", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Line Join", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Miter Limit", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Dashes", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: "transforms",
    title: { zh: "变换", en: "Transforms" },
    rows: [
      { feature: "Anchor Point", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Position", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Scale", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Rotation", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Opacity", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Skew", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Skew Axis", android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Auto Orient", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: "general",
    title: { zh: "通用特性", en: "General" },
    rows: [
      { feature: "Masks", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Mattes", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Images", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: "Markers", android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: maybe("❔", "Parser ongoing") },
      { feature: "Expressions", android: yes, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: no, moon: yesWith("JS-Host MVP") },
    ],
  },
];
