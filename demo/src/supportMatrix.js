export const platformColumns = [
  { key: 'moon', label: 'Moon Lottie', highlight: true },
  { key: 'android', label: 'Android' },
  { key: 'iosCoreAnimation', label: 'iOS (Core Animation)' },
  { key: 'iosMainThread', label: 'iOS (Main Thread)' },
  { key: 'windows', label: 'Windows' },
  { key: 'webSvg', label: 'Web (SVG)' },
  { key: 'webCanvas', label: 'Web (Canvas)' },
  { key: 'webHtml', label: 'Web (HTML)' },
]

const supported = 'supported'
const unsupported = 'unsupported'
const unknown = 'unknown'

const yes = supported
const no = unsupported
const maybe = (symbol = '❔', detail = '') => ({ status: unknown, symbol, detail })
const yesWith = (detail) => ({ status: supported, detail })

export const supportSections = [
  {
    id: 'shapes',
    title: { zh: '形状', en: 'Shapes' },
    rows: [
      { feature: 'Shape', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Ellipse', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Rectangle', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Rounded Rectangle', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Polystar', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Group', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Repeater', android: yes, iosCoreAnimation: yes, iosMainThread: no, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Trim Path (individually)', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Trim Path (simultaneously)', android: yes, iosCoreAnimation: no, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: 'fills',
    title: { zh: '填充', en: 'Fills' },
    rows: [
      { feature: 'Color', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Opacity', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Fill Rule', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Radial Gradient', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Linear Gradient', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: 'strokes',
    title: { zh: '描边', en: 'Strokes' },
    rows: [
      { feature: 'Color', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Opacity', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Width', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Line Cap', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Line Join', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Miter Limit', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Dashes', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Gradient', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: 'transforms',
    title: { zh: '变换', en: 'Transforms' },
    rows: [
      { feature: 'Position', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Position (separated X/Y)', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Scale', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Rotation', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Anchor Point', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Opacity', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Parenting', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Auto Orient', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Skew', android: maybe('❓'), iosCoreAnimation: yes, iosMainThread: yes, windows: maybe('❓'), webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: 'interpolation',
    title: { zh: '插值', en: 'Interpolation' },
    rows: [
      { feature: 'Linear Interpolation', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Bezier Interpolation', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Hold Interpolation', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Spatial Bezier Interpolation', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Rove Across Time', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
    ],
  },
  {
    id: 'masks',
    title: { zh: '蒙版', en: 'Masks' },
    rows: [
      { feature: 'Mask Path', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Mask Opacity', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Add', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Subtract', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Intersect', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: no, webCanvas: no, webHtml: no, moon: yes },
      { feature: 'Lighten', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Darken', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Difference', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Expansion', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: no, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Feather', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: no, webCanvas: no, webHtml: no, moon: no },
    ],
  },
  {
    id: 'mattes',
    title: { zh: '遮罩轨道', en: 'Mattes' },
    rows: [
      { feature: 'Alpha Matte', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Alpha Inverted Matte', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Luma Matte', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: maybe(), webCanvas: maybe(), webHtml: maybe(), moon: no },
      { feature: 'Luma Inverted Matte', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: maybe(), webCanvas: maybe(), webHtml: maybe(), moon: no },
    ],
  },
  {
    id: 'merge-paths',
    title: { zh: '合并路径', en: 'Merge Paths' },
    rows: [
      { feature: 'Merge', android: yesWith('KitKat+'), iosCoreAnimation: no, iosMainThread: no, windows: yes, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Add', android: yesWith('KitKat+'), iosCoreAnimation: no, iosMainThread: no, windows: yes, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Subtract', android: yesWith('KitKat+'), iosCoreAnimation: no, iosMainThread: no, windows: yes, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Intersect', android: yesWith('KitKat+'), iosCoreAnimation: no, iosMainThread: no, windows: yes, webSvg: no, webCanvas: no, webHtml: no, moon: no },
      { feature: 'Exclude Intersection', android: yesWith('KitKat+'), iosCoreAnimation: no, iosMainThread: no, windows: yes, webSvg: no, webCanvas: no, webHtml: no, moon: no },
    ],
  },
  {
    id: 'layer-effects',
    title: { zh: '图层效果', en: 'Layer Effects' },
    rows: [
      { feature: 'Fill', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Stroke', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Tint', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Tritone', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Levels Individual Controls', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: maybe(), webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Gaussian blur', android: yesWith('4.1+'), iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: maybe(), webCanvas: maybe(), webHtml: maybe(), moon: no },
      { feature: 'Drop Shadows', android: yesWith('4.1+'), iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: maybe(), webCanvas: maybe(), webHtml: maybe(), moon: no },
    ],
  },
  {
    id: 'text',
    title: { zh: '文本', en: 'Text' },
    rows: [
      { feature: 'Glyphs', android: yes, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Fonts', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Transform', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Fill', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Stroke', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Tracking', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Anchor point grouping', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Text Path', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Per-character 3D', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Range selector (Units)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Based on)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Amount)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Shape)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Ease High)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Ease Low)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Range selector (Randomize order)', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'expression selector', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
    ],
  },
  {
    id: 'other',
    title: { zh: '其它', en: 'Other' },
    rows: [
      { feature: 'Expressions', android: no, iosCoreAnimation: no, iosMainThread: no, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yesWith('JS host') },
      { feature: 'Images', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Precomps', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Time Stretch', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: no },
      { feature: 'Time remap', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: no, webSvg: yes, webCanvas: yes, webHtml: yes, moon: yes },
      { feature: 'Markers', android: yes, iosCoreAnimation: yes, iosMainThread: yes, windows: yes, webSvg: yes, webCanvas: yes, webHtml: yes, moon: maybe('❔', 'parsed only') },
    ],
  },
]
