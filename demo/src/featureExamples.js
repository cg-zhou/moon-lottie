const WIDTH = 240
const HEIGHT = 180
const FRAMES = 96
const CENTER = [WIDTH / 2, HEIGHT / 2, 0]

const COLORS = {
  ink: [0.07, 0.12, 0.22, 1],
  slate: [0.52, 0.59, 0.7, 1],
  blue: [0.16, 0.54, 0.95, 1],
  teal: [0.12, 0.76, 0.64, 1],
  coral: [0.95, 0.42, 0.36, 1],
  amber: [0.97, 0.73, 0.24, 1],
  violet: [0.56, 0.38, 0.9, 1],
  rose: [0.91, 0.36, 0.53, 1],
  panel: [0.94, 0.96, 1, 1],
  cloud: [0.87, 0.91, 0.97, 1],
  white: [1, 1, 1, 1],
}

const IMAGE_DATA_URI = "data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%23eef6ff'/%3E%3Ccircle cx='28' cy='28' r='14' fill='%233b82f6'/%3E%3Cpath d='M44 14l2.8 6.2 6.2 2.8-6.2 2.8L44 32l-2.8-6.2-6.2-2.8 6.2-2.8z' fill='%23f59e0b'/%3E%3Cpath d='M16 46h32' stroke='%230f172a' stroke-width='4' stroke-linecap='round'/%3E%3C/svg%3E"

function rawProperty(value) {
  if (value && typeof value === "object" && Object.prototype.hasOwnProperty.call(value, "k")) {
    return value
  }
  return { a: 0, k: value }
}

function transformProperty(value) {
  if (
    value &&
    typeof value === "object" &&
    (
      Object.prototype.hasOwnProperty.call(value, "k") ||
      Object.prototype.hasOwnProperty.call(value, "x") ||
      Object.prototype.hasOwnProperty.call(value, "y") ||
      Object.prototype.hasOwnProperty.call(value, "s")
    )
  ) {
    return value
  }
  return rawProperty(value)
}

function keyframe(t, s, e, extra = {}) {
  const start = Array.isArray(s) ? s : [s]
  const end = Array.isArray(e) ? e : [e]
  const dimensions = Math.max(start.length, end.length)

  return {
    i: {
      x: Array(dimensions).fill(0.667),
      y: Array(dimensions).fill(1),
    },
    o: {
      x: Array(dimensions).fill(0.333),
      y: Array(dimensions).fill(0),
    },
    t,
    s: start,
    e: end,
    ...extra,
  }
}

function linearKeyframe(t, s, e, extra = {}) {
  const start = Array.isArray(s) ? s : [s]
  const end = Array.isArray(e) ? e : [e]
  const dimensions = Math.max(start.length, end.length)

  return {
    i: {
      x: Array(dimensions).fill(1),
      y: Array(dimensions).fill(1),
    },
    o: {
      x: Array(dimensions).fill(0),
      y: Array(dimensions).fill(0),
    },
    t,
    s: start,
    e: end,
    ...extra,
  }
}

function pingPong(start, end, midpoint = FRAMES / 2, finalFrame = FRAMES) {
  return {
    a: 1,
    k: [
      keyframe(0, start, end),
      keyframe(midpoint, end, start),
      { t: finalFrame },
    ],
  }
}

function path(points, closed = true) {
  return {
    i: points.map(() => [0, 0]),
    o: points.map(() => [0, 0]),
    v: points,
    c: closed,
  }
}

function boxPoints(width, height, reversed = false) {
  const points = [
    [-width / 2, -height / 2],
    [width / 2, -height / 2],
    [width / 2, height / 2],
    [-width / 2, height / 2],
  ]

  return reversed ? [...points].reverse() : points
}

function rectPath(x, y, width, height) {
  return path(
    [
      [x - width / 2, y - height / 2],
      [x + width / 2, y - height / 2],
      [x + width / 2, y + height / 2],
      [x - width / 2, y + height / 2],
    ],
    true,
  )
}

function layerKs({
  p = CENTER,
  a = [0, 0, 0],
  s = [100, 100, 100],
  r = 0,
  o = 100,
  sk = 0,
  sa = 0,
} = {}) {
  return {
    o: rawProperty(o),
    r: rawProperty(r),
    p: transformProperty(p),
    a: rawProperty(a),
    s: rawProperty(s),
    sk: rawProperty(sk),
    sa: rawProperty(sa),
  }
}

function transformItem({
  p = [0, 0],
  a = [0, 0],
  s = [100, 100],
  r = 0,
  o = 100,
  sk = 0,
  sa = 0,
} = {}) {
  return {
    ty: "tr",
    p: transformProperty(p),
    a: rawProperty(a),
    s: rawProperty(s),
    r: rawProperty(r),
    o: rawProperty(o),
    sk: rawProperty(sk),
    sa: rawProperty(sa),
    nm: "Transform",
  }
}

function shapeGroup(items, transform = {}, name = "Shape 1") {
  return {
    ty: "gr",
    it: [...items, transformItem(transform)],
    nm: name,
    np: items.length,
    cix: 2,
    ix: 1,
    mn: "ADBE Vector Group",
    hd: false,
  }
}

function ellipse(size, position = [0, 0], name = "Ellipse Path 1") {
  return {
    d: 1,
    ty: "el",
    s: rawProperty(size),
    p: rawProperty(position),
    nm: name,
    mn: "ADBE Vector Shape - Ellipse",
    hd: false,
  }
}

function rect(size, position = [0, 0], round = 0, name = "Rectangle Path 1") {
  return {
    ty: "rc",
    d: 1,
    s: rawProperty(size),
    p: rawProperty(position),
    r: rawProperty(round),
    nm: name,
    mn: "ADBE Vector Shape - Rect",
    hd: false,
  }
}

function polystar({
  points = 5,
  position = [0, 0],
  rotation = 0,
  outerRadius = 42,
  innerRadius = 18,
  outerRoundness = 0,
  innerRoundness = 0,
  starType = 1,
  name = "Polystar Path 1",
} = {}) {
  return {
    ty: "sr",
    sy: starType,
    d: 1,
    pt: rawProperty(points),
    p: rawProperty(position),
    r: rawProperty(rotation),
    or: rawProperty(outerRadius),
    os: rawProperty(outerRoundness),
    ir: rawProperty(innerRadius),
    is: rawProperty(innerRoundness),
    nm: name,
    mn: "ADBE Vector Shape - Star",
    hd: false,
  }
}

function pathShape(points, closed = true, name = "Path 1") {
  return {
    ind: 0,
    ty: "sh",
    ix: 1,
    ks: rawProperty(path(points, closed)),
    nm: name,
    mn: "ADBE Vector Shape - Group",
    hd: false,
  }
}

function fill(color, opacity = 100, rule = 1) {
  return {
    ty: "fl",
    c: rawProperty(color),
    o: rawProperty(opacity),
    r: rule,
    nm: "Fill 1",
    mn: "ADBE Vector Graphic - Fill",
    hd: false,
  }
}

function gradientFill({
  type = 1,
  stops,
  start = [-40, 0],
  end = [40, 0],
  opacity = 100,
  rule = 1,
} = {}) {
  return {
    ty: "gf",
    o: rawProperty(opacity),
    r: rule,
    bm: 0,
    g: {
      p: stops.length,
      k: rawProperty(stops.flatMap(([offset, color]) => [offset, color[0], color[1], color[2]])),
    },
    s: rawProperty(start),
    e: rawProperty(end),
    t: type,
    nm: "Gradient Fill 1",
    mn: "ADBE Vector Graphic - G-Fill",
    hd: false,
  }
}

function stroke({
  color,
  opacity = 100,
  width = 4,
  lineCap = 1,
  lineJoin = 1,
  miter = 4,
  dashes,
} = {}) {
  const item = {
    ty: "st",
    c: rawProperty(color),
    o: rawProperty(opacity),
    w: rawProperty(width),
    lc: lineCap,
    lj: lineJoin,
    ml: miter,
    nm: "Stroke 1",
    mn: "ADBE Vector Graphic - Stroke",
    hd: false,
  }

  if (dashes) {
    item.d = dashes
  }

  return item
}

function gradientStroke({
  type = 1,
  stops,
  start = [-40, 0],
  end = [40, 0],
  opacity = 100,
  width = 8,
  lineCap = 2,
  lineJoin = 1,
  miter = 4,
} = {}) {
  return {
    ty: "gs",
    o: rawProperty(opacity),
    w: rawProperty(width),
    g: {
      p: stops.length,
      k: rawProperty(stops.flatMap(([offset, color]) => [offset, color[0], color[1], color[2]])),
    },
    s: rawProperty(start),
    e: rawProperty(end),
    t: type,
    lc: lineCap,
    lj: lineJoin,
    ml: miter,
    nm: "Gradient Stroke 1",
    mn: "ADBE Vector Graphic - G-Stroke",
    hd: false,
  }
}

function trim(start = 0, end = 100, offset = 0, mode = 1) {
  return {
    ty: "tm",
    s: rawProperty(start),
    e: rawProperty(end),
    o: rawProperty(offset),
    m: mode,
    nm: "Trim Paths 1",
    mn: "ADBE Vector Filter - Trim",
    hd: false,
  }
}

function repeater({
  copies,
  offset = 0,
  position = [0, 0],
  scale = [100, 100],
  rotation = 30,
  startOpacity = 100,
  endOpacity = 100,
} = {}) {
  return {
    ty: "rp",
    c: rawProperty(copies),
    o: rawProperty(offset),
    m: 1,
    tr: {
      ty: "tr",
      p: rawProperty(position),
      a: rawProperty([0, 0]),
      s: rawProperty(scale),
      r: rawProperty(rotation),
      so: rawProperty(startOpacity),
      eo: rawProperty(endOpacity),
      nm: "Transform",
    },
    nm: "Repeater 1",
    mn: "ADBE Vector Filter - Repeater",
    hd: false,
  }
}

function dashPattern({ dash, gap, offset = 0 }) {
  return [
    { n: "d", nm: "dash", v: rawProperty(dash) },
    { n: "g", nm: "gap", v: rawProperty(gap) },
    { n: "o", nm: "offset", v: rawProperty(offset) },
  ]
}

function mask(maskPath, mode = "a", name = "Mask 1") {
  return {
    inv: false,
    mode,
    pt: { k: maskPath },
    o: { k: 100 },
    x: { k: 0 },
    nm: name,
  }
}

function shapeLayer({
  name,
  groups,
  ks,
  ip = 0,
  op = FRAMES,
  st = 0,
  bm = 0,
  tt,
  td,
  parent,
  ef,
  masksProperties,
  autoOrient = 0,
} = {}) {
  const layer = {
    ddd: 0,
    ind: 0,
    ty: 4,
    nm: name,
    ks: layerKs(ks),
    ao: autoOrient,
    shapes: groups,
    ip,
    op,
    st,
    bm,
  }

  if (tt !== undefined) {
    layer.tt = tt
  }

  if (td !== undefined) {
    layer.td = td
  }

  if (parent !== undefined) {
    layer.parent = parent
  }

  if (masksProperties?.length) {
    layer.hasMask = true
    layer.masksProperties = masksProperties
  }

  if (ef?.length) {
    layer.ef = ef
  }

  return layer
}

function imageLayer({
  name,
  refId,
  ks,
  width,
  height,
  ip = 0,
  op = FRAMES,
} = {}) {
  return {
    ddd: 0,
    ind: 0,
    ty: 2,
    nm: name,
    refId,
    ks: layerKs(ks),
    ip,
    op,
    st: 0,
    bm: 0,
    w: width,
    h: height,
  }
}

function solidLayer({
  name,
  color,
  width,
  height,
  ks,
  ip = 0,
  op = FRAMES,
} = {}) {
  return {
    ddd: 0,
    ind: 0,
    ty: 1,
    nm: name,
    ks: layerKs(ks),
    ip,
    op,
    st: 0,
    bm: 0,
    sw: width,
    sh: height,
    sc: color,
  }
}

function precompLayer({
  name,
  refId,
  width = WIDTH,
  height = HEIGHT,
  ks,
  tm,
  ip = 0,
  op = FRAMES,
} = {}) {
  const layer = {
    ddd: 0,
    ind: 0,
    ty: 0,
    nm: name,
    refId,
    w: width,
    h: height,
    ks: layerKs(ks),
    ip,
    op,
    st: 0,
    bm: 0,
  }

  if (tm) {
    layer.tm = tm
  }

  return layer
}

function textDocument({
  text = "WAVE",
  font = "Moon Demo Bold",
  size = 58,
  justify = 0,
  tracking = 0,
  lineHeight = 72,
  baselineShift = 0,
  fillColor = COLORS.ink,
  strokeColor = COLORS.ink,
  strokeWidth = 0,
  strokeOverFill = true,
} = {}) {
  return {
    s: size,
    f: font,
    t: text,
    j: justify,
    tr: tracking,
    lh: lineHeight,
    ls: baselineShift,
    fc: fillColor,
    sc: strokeColor,
    sw: strokeWidth,
    of: strokeOverFill,
  }
}

function textAnimatorProperties({
  scale,
  position,
  rotation,
  opacity,
  tracking,
  fillColor,
  strokeColor,
  strokeWidth,
} = {}) {
  const properties = {}

  if (scale !== undefined) properties.s = rawProperty(scale)
  if (position !== undefined) properties.p = rawProperty(position)
  if (rotation !== undefined) properties.r = rawProperty(rotation)
  if (opacity !== undefined) properties.o = rawProperty(opacity)
  if (tracking !== undefined) properties.t = rawProperty(tracking)
  if (fillColor !== undefined) properties.fc = rawProperty(fillColor)
  if (strokeColor !== undefined) properties.sc = rawProperty(strokeColor)
  if (strokeWidth !== undefined) properties.sw = rawProperty(strokeWidth)

  return properties
}

function textSelector({
  basedOn = 1,
  shape = 2,
  rangeUnits = 1,
  randomize = 0,
  start = 0,
  end = 100,
  easeHigh = 0,
  easeLow = 0,
  amount = 100,
  offset = 0,
} = {}) {
  const selector = {
    b: basedOn,
    sh: shape,
    rn: randomize,
    s: rawProperty(start),
    e: rawProperty(end),
    ne: rawProperty(easeHigh),
    xe: rawProperty(easeLow),
    a: rawProperty(amount),
    o: rawProperty(offset),
  }

  if (rangeUnits !== 1) {
    selector.r = rangeUnits
  }

  return selector
}

function textAnimator(properties = {}, selector = {}) {
  return {
    a: textAnimatorProperties(properties),
    s: textSelector(selector),
  }
}

function textLayer({
  name,
  document,
  ks,
  animators = [],
  moreOptions,
  ip = 0,
  op = FRAMES,
} = {}) {
  const textData = {
    d: {
      k: [{ s: document, t: 0 }],
    },
    a: animators,
  }

  if (moreOptions) {
    textData.m = moreOptions
  }

  return {
    ddd: 0,
    ind: 0,
    ty: 5,
    nm: name,
    ks: layerKs(ks),
    t: textData,
    ip,
    op,
    st: 0,
    bm: 0,
  }
}

function glyphChar(ch, width, shapes, family = "Moon Demo", style = "Bold") {
  return {
    ch,
    size: 100,
    style,
    fFamily: family,
    w: width,
    data: {
      shapes,
    },
  }
}

function animation(name, layers, { assets = [], markers = [], fonts, chars } = {}) {
  const data = {
    v: "5.7.4",
    fr: 30,
    ip: 0,
    op: FRAMES,
    w: WIDTH,
    h: HEIGHT,
    nm: name,
    ddd: 0,
    assets,
    layers: layers.map((layer, index) => ({ ...layer, ind: index + 1 })),
    markers,
  }

  if (fonts) {
    data.fonts = fonts
  }

  if (chars) {
    data.chars = chars
  }

  return data
}

function formatJson(value) {
  return JSON.stringify(value, null, 2)
}

function createExample(description, snippet, animationData) {
  return {
    description,
    snippet: formatJson(snippet),
    animationData,
  }
}

function createStripeGroups(colors) {
  return colors.map((color, index) => {
    const x = -75 + index * 30
    return shapeGroup(
      [rect([22, 142], [0, 0], 8), fill(color)],
      { p: [x, 0] },
      `Stripe ${index + 1}`,
    )
  })
}

function glyphBox(x1, y1, x2, y2, name) {
  return pathShape(
    [
      [x1, y1],
      [x2, y1],
      [x2, y2],
      [x1, y2],
    ],
    true,
    name,
  )
}

const DEMO_GLYPH_FONT = {
  list: [
    {
      fName: "Moon Demo Bold",
      fFamily: "Moon Demo",
      fStyle: "Bold",
      ascent: 75,
    },
  ],
}

const DEMO_GLYPHS = [
  glyphChar("W", 82, [
    pathShape([[0, 0], [12, 100], [28, 44], [44, 100], [56, 0], [46, 0], [38, 58], [28, 24], [18, 58], [10, 0]], true, "Glyph W"),
  ]),
  glyphChar("A", 72, [
    glyphBox(0, 0, 12, 100, "A Left"),
    glyphBox(48, 0, 60, 100, "A Right"),
    glyphBox(12, 0, 48, 14, "A Top"),
    glyphBox(12, 44, 48, 58, "A Cross"),
  ]),
  glyphChar("V", 72, [
    pathShape([[0, 0], [16, 0], [36, 78], [56, 0], [72, 0], [44, 100], [28, 100]], true, "Glyph V"),
  ]),
  glyphChar("E", 68, [
    glyphBox(0, 0, 12, 100, "E Stem"),
    glyphBox(12, 0, 60, 14, "E Top"),
    glyphBox(12, 43, 50, 57, "E Mid"),
    glyphBox(12, 86, 60, 100, "E Bottom"),
  ]),
]

function buildShapeExample() {
  return animation("shape-path", [
    shapeLayer({
      name: "Freeform Shape",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            pathShape([[-44, -30], [0, -52], [48, -8], [24, 40], [-36, 34]]),
            fill(COLORS.blue),
            stroke({ color: COLORS.ink, width: 4, lineJoin: 2 }),
          ],
          {
            s: pingPong([96, 96], [106, 106]),
            r: pingPong(-6, 6),
          },
        ),
      ],
    }),
  ])
}

function buildEllipseExample() {
  return animation("ellipse", [
    shapeLayer({
      name: "Ellipse",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [ellipse([110, 76]), fill(COLORS.teal)],
          { s: pingPong([100, 76], [100, 126]) },
        ),
      ],
    }),
  ])
}

function buildRectangleExample() {
  return animation("rectangle", [
    shapeLayer({
      name: "Rectangle",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [rect([110, 64], [0, 0], 0), fill(COLORS.coral)],
          { s: pingPong([78, 100], [118, 100]) },
        ),
      ],
    }),
  ])
}

function buildRoundedRectExample() {
  return animation("rounded-rectangle", [
    shapeLayer({
      name: "Rounded Rectangle",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [rect([120, 64], [0, 0], 22), fill(COLORS.amber)],
          { r: pingPong(-8, 8) },
        ),
      ],
    }),
  ])
}

function buildPolystarExample() {
  return animation("polystar", [
    shapeLayer({
      name: "Polystar",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [polystar({ outerRadius: 48, innerRadius: 22 }), fill(COLORS.violet), stroke({ color: COLORS.ink, width: 3 })],
          { r: pingPong(0, 90) },
        ),
      ],
    }),
  ])
}

function buildGroupExample() {
  return animation("groups", [
    shapeLayer({
      name: "Grouped Face",
      ks: { p: CENTER },
      groups: [
        shapeGroup([ellipse([120, 120]), fill(COLORS.amber)], {}, "Head"),
        shapeGroup(
          [
            shapeGroup([ellipse([16, 16], [-24, -12]), fill(COLORS.ink)], {}, "Eye Left"),
            shapeGroup([ellipse([16, 16], [24, -12]), fill(COLORS.ink)], {}, "Eye Right"),
            shapeGroup([
              pathShape([[-24, 18], [0, 34], [24, 18]], false),
              stroke({ color: COLORS.ink, width: 8, lineCap: 2, lineJoin: 2 }),
            ], {}, "Smile"),
          ],
          {
            r: pingPong(-10, 10),
            s: pingPong([94, 94], [106, 106]),
          },
          "Face Group",
        ),
      ],
    }),
  ])
}

function buildRepeaterExample() {
  return animation("repeater", [
    shapeLayer({
      name: "Repeater",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            ellipse([18, 18], [0, -46]),
            fill(COLORS.blue),
            repeater({ copies: 10, rotation: 36 }),
          ],
          { r: pingPong(0, 180) },
        ),
      ],
    }),
  ])
}

function buildTrimSingleExample() {
  return animation("trim-single", [
    shapeLayer({
      name: "Trim Single",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-68, 26], [-24, -26], [18, 0], [66, -38]], false),
          trim(0, pingPong(4, 100)),
          stroke({ color: COLORS.blue, width: 10, lineCap: 2, lineJoin: 2 }),
        ]),
      ],
    }),
  ])
}

function buildTrimSimultaneousExample() {
  return animation("trim-simultaneous", [
    shapeLayer({
      name: "Trim Together",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-72, -12], [-34, -42], [0, -12], [34, -42], [72, -12]], false, "Path 1"),
          pathShape([[-72, 24], [-34, 56], [0, 24], [34, 56], [72, 24]], false, "Path 2"),
          trim(0, pingPong(6, 100)),
          stroke({ color: COLORS.violet, width: 8, lineCap: 2, lineJoin: 2 }),
        ]),
      ],
    }),
  ])
}

function buildFillColorExample() {
  return animation("fill-color", [
    shapeLayer({
      name: "Fill Color",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [ellipse([92, 92]), fill(pingPong(COLORS.blue, COLORS.coral))],
          { s: pingPong([94, 94], [106, 106]) },
        ),
      ],
    }),
  ])
}

function buildFillOpacityExample() {
  return animation("fill-opacity", [
    shapeLayer({
      name: "Fill Opacity",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [ellipse([92, 92]), fill(COLORS.teal, pingPong(18, 100))],
          { s: pingPong([98, 98], [108, 108]) },
        ),
      ],
    }),
  ])
}

function buildFillRuleExample() {
  return animation("fill-rule", [
    shapeLayer({
      name: "Fill Rule",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            pathShape(boxPoints(128, 128), true, "Outer"),
            pathShape(boxPoints(56, 56), true, "Inner"),
            fill(COLORS.blue, 100, 2),
          ],
          { r: pingPong(-8, 8) },
        ),
      ],
    }),
  ])
}

function buildRadialGradientExample() {
  return animation("radial-gradient", [
    shapeLayer({
      name: "Radial Gradient",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            ellipse([108, 108]),
            gradientFill({
              type: 2,
              stops: [
                [0, COLORS.amber],
                [1, COLORS.coral],
              ],
              start: [0, 0],
              end: [42, 42],
            }),
          ],
          { s: pingPong([92, 92], [108, 108]) },
        ),
      ],
    }),
  ])
}

function buildLinearGradientExample() {
  return animation("linear-gradient", [
    shapeLayer({
      name: "Linear Gradient",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            rect([130, 72], [0, 0], 18),
            gradientFill({
              type: 1,
              stops: [
                [0, COLORS.blue],
                [1, COLORS.teal],
              ],
              start: [-64, 0],
              end: [64, 0],
            }),
          ],
          { r: pingPong(-12, 12) },
        ),
      ],
    }),
  ])
}

function buildStrokeOpacityExample() {
  return animation("stroke-opacity", [
    shapeLayer({
      name: "Stroke Opacity",
      ks: { p: CENTER },
      groups: [shapeGroup([ellipse([96, 96]), stroke({ color: COLORS.blue, width: 10, opacity: pingPong(12, 100) })])],
    }),
  ])
}

function buildStrokeColorExample() {
  return animation("stroke-color", [
    shapeLayer({
      name: "Stroke Color",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          ellipse([100, 100]),
          stroke({ color: pingPong(COLORS.blue, COLORS.violet), width: 12 }),
        ]),
      ],
    }),
  ])
}

function buildStrokeWidthExample() {
  return animation("stroke-width", [
    shapeLayer({
      name: "Stroke Width",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-62, 22], [-24, -26], [20, -6], [64, -42]], false),
          stroke({ color: COLORS.teal, width: pingPong(3, 16), lineCap: 2, lineJoin: 2 }),
        ]),
      ],
    }),
  ])
}

function buildLineCapExample() {
  return animation("line-cap", [
    shapeLayer({
      name: "Line Cap",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-64, 0], [64, 0]], false),
          trim(18, pingPong(54, 96)),
          stroke({ color: COLORS.coral, width: 16, lineCap: 2 }),
        ]),
      ],
    }),
  ])
}

function buildLineJoinExample() {
  return animation("line-join", [
    shapeLayer({
      name: "Line Join",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            pathShape([[-58, 30], [0, -42], [58, 30]], false),
            stroke({ color: COLORS.violet, width: 18, lineJoin: 2, lineCap: 2 }),
          ],
          { r: pingPong(-8, 8) },
        ),
      ],
    }),
  ])
}

function buildMiterLimitExample() {
  return animation("miter-limit", [
    shapeLayer({
      name: "Miter Limit",
      ks: { p: CENTER },
      groups: [
        shapeGroup(
          [
            pathShape([[-54, 32], [0, -46], [54, 32]], false),
            stroke({ color: COLORS.ink, width: 18, lineJoin: 1, miter: 2 }),
          ],
          { r: pingPong(-6, 6) },
        ),
      ],
    }),
  ])
}

function buildDashExample() {
  return animation("dash-pattern", [
    shapeLayer({
      name: "Dash Pattern",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          ellipse([102, 102]),
          stroke({
            color: COLORS.teal,
            width: 10,
            lineCap: 2,
            dashes: dashPattern({ dash: 10, gap: 12, offset: pingPong(0, 36) }),
          }),
        ]),
      ],
    }),
  ])
}

function buildAnchorPointExample() {
  return animation("anchor-point", [
    shapeLayer({
      name: "Pivot Dot",
      ks: { p: [90, 60, 0] },
      groups: [shapeGroup([ellipse([12, 12]), fill(COLORS.ink)])],
    }),
    shapeLayer({
      name: "Anchor Rotation",
      ks: {
        p: CENTER,
        a: [-30, -30, 0],
        r: pingPong(0, 90),
      },
      groups: [shapeGroup([rect([60, 60], [0, 0], 10), fill(COLORS.blue)])],
    }),
  ])
}

function buildPositionExample() {
  return animation("position", [
    shapeLayer({
      name: "Position",
      ks: { p: pingPong([70, 90, 0], [170, 90, 0]) },
      groups: [shapeGroup([ellipse([34, 34]), fill(COLORS.teal)])],
    }),
  ])
}

function buildScaleExample() {
  return animation("scale", [
    shapeLayer({
      name: "Scale",
      ks: {
        p: CENTER,
        s: pingPong([56, 56, 100], [124, 124, 100]),
      },
      groups: [shapeGroup([polystar({ outerRadius: 42, innerRadius: 18 }), fill(COLORS.amber)])],
    }),
  ])
}

function buildRotationExample() {
  return animation("rotation", [
    shapeLayer({
      name: "Rotation",
      ks: {
        p: CENTER,
        r: pingPong(0, 180),
      },
      groups: [
        shapeGroup([
          rect([90, 18], [0, 0], 9),
          rect([18, 90], [0, 0], 9),
          fill(COLORS.coral),
        ]),
      ],
    }),
  ])
}

function buildTransformOpacityExample() {
  return animation("transform-opacity", [
    shapeLayer({
      name: "Transform Opacity",
      ks: {
        p: CENTER,
        o: pingPong(20, 100),
      },
      groups: [shapeGroup([pathShape([[0, -44], [40, 0], [0, 44], [-40, 0]]), fill(COLORS.violet)])],
    }),
  ])
}

function buildSkewExample() {
  return animation("skew", [
    shapeLayer({
      name: "Skew",
      ks: {
        p: CENTER,
        sk: 18,
        sa: 0,
        r: pingPong(-6, 6),
      },
      groups: [shapeGroup([rect([90, 64], [0, 0], 10), fill(COLORS.blue)])],
    }),
  ])
}

function buildSkewAxisExample() {
  return animation("skew-axis", [
    shapeLayer({
      name: "Skew Axis",
      ks: {
        p: CENTER,
        sk: 18,
        sa: 45,
        r: pingPong(-6, 6),
      },
      groups: [shapeGroup([rect([90, 64], [0, 0], 10), fill(COLORS.rose)])],
    }),
  ])
}

function buildAutoOrientExample() {
  return animation("auto-orient", [
    shapeLayer({
      name: "Guide",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-70, 40], [-20, -22], [18, -6], [72, -42]], false),
          stroke({
            color: COLORS.slate,
            width: 4,
            lineCap: 2,
            dashes: dashPattern({ dash: 6, gap: 8 }),
          }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Arrow",
      autoOrient: 1,
      ks: {
        p: {
          a: 1,
          k: [
            keyframe(0, [52, 130, 0], [188, 54, 0], { to: [46, -62, 0], ti: [-52, 24, 0] }),
            keyframe(48, [188, 54, 0], [52, 130, 0], { to: [-52, 24, 0], ti: [46, -62, 0] }),
            { t: FRAMES },
          ],
        },
      },
      groups: [
        shapeGroup([
          pathShape([[-18, 0], [10, 0]], false, "Shaft"),
          stroke({ color: COLORS.ink, width: 8, lineCap: 2 }),
          pathShape([[10, -10], [28, 0], [10, 10]]),
          fill(COLORS.ink),
        ]),
      ],
    }),
  ])
}

function buildMaskExample() {
  return animation("mask-path", [
    shapeLayer({
      name: "Mask Outline",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([118, 86], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
    shapeLayer({
      name: "Masked Stripes",
      ks: { p: CENTER },
      masksProperties: [mask(rectPath(0, 0, 112, 80), "a")],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.blue, COLORS.teal, COLORS.amber, COLORS.coral, COLORS.violet, COLORS.rose]),
          { p: pingPong([-18, 0], [18, 0]) },
          "Stripe Rail",
        ),
      ],
    }),
  ])
}

function buildTrackMatteExample() {
  return animation("matte-alpha", [
    shapeLayer({
      name: "Matte Circle",
      td: 1,
      ks: { p: pingPong([78, 90, 0], [162, 90, 0]) },
      groups: [shapeGroup([ellipse([88, 88]), fill(COLORS.white)])],
    }),
    shapeLayer({
      name: "Matted Content",
      tt: 1,
      ks: { p: CENTER },
      groups: [
        shapeGroup(createStripeGroups([COLORS.blue, COLORS.teal, COLORS.amber, COLORS.coral, COLORS.violet, COLORS.rose]), {}, "Matted Stripes"),
      ],
    }),
    shapeLayer({
      name: "Matte Frame",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([140, 104], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
  ])
}

function buildImageExample() {
  return animation(
    "image-layer",
    [
      shapeLayer({
        name: "Shadow",
        ks: { p: [120, 124, 0] },
        groups: [shapeGroup([ellipse([88, 18]), fill([0.78, 0.83, 0.91, 1], 70)])],
      }),
      imageLayer({
        name: "Inline Asset",
        refId: "img_0",
        width: 64,
        height: 64,
        ks: {
          p: [120, 84, 0],
          a: [32, 32, 0],
          s: pingPong([98, 98, 100], [122, 122, 100]),
          r: pingPong(-6, 6),
        },
      }),
    ],
    {
      assets: [
        {
          id: "img_0",
          w: 64,
          h: 64,
          u: "",
          p: IMAGE_DATA_URI,
          e: 1,
        },
      ],
    },
  )
}

function buildMarkerExample() {
  return animation(
    "markers",
    [
      shapeLayer({
        name: "Marker Pulse",
        ks: {
          p: CENTER,
          s: pingPong([76, 76, 100], [110, 110, 100]),
        },
        groups: [shapeGroup([ellipse([82, 82]), fill(COLORS.coral)])],
      }),
    ],
    {
      markers: [
        { tm: 0, cm: "intro", dr: 0 },
        { tm: 32, cm: "pulse", dr: 0 },
        { tm: 64, cm: "settle", dr: 0 },
      ],
    },
  )
}

function buildExpressionExample() {
  return animation("expression", [
    shapeLayer({
      name: "Expression Dot",
      ks: {
        p: {
          a: 0,
          k: [120, 90, 0],
          x: "var $bm_rt;\n$bm_rt = [120 + Math.sin(time * 4) * 42, 90 + Math.cos(time * 2) * 10, 0];",
        },
      },
      groups: [shapeGroup([ellipse([30, 30]), fill(COLORS.violet)])],
    }),
  ])
}

function buildGradientStrokeExample() {
  return animation("stroke-gradient", [
    shapeLayer({
      name: "Gradient Stroke",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          ellipse([112, 112]),
          trim(0, pingPong(18, 100), pingPong(0, 360)),
          gradientStroke({
            stops: [
              [0, COLORS.blue],
              [0.45, COLORS.teal],
              [1, COLORS.coral],
            ],
            start: [-64, -48],
            end: [64, 48],
            width: 14,
          }),
        ]),
      ],
    }),
  ])
}

function buildSeparatedPositionExample() {
  return animation("transform-separated-position", [
    shapeLayer({
      name: "Separated Position",
      ks: {
        p: {
          s: true,
          x: pingPong(58, 182),
          y: {
            a: 1,
            k: [
              keyframe(0, 126, 54),
              keyframe(48, 54, 126),
              { t: FRAMES },
            ],
          },
        },
      },
      groups: [
        shapeGroup([ellipse([34, 34]), fill(COLORS.coral)]),
      ],
    }),
  ])
}

function buildParentHierarchyExample() {
  return animation("transform-parent-hierarchy", [
    shapeLayer({
      name: "Orbit Parent",
      ks: {
        p: CENTER,
        r: pingPong(0, 180),
      },
      groups: [
        shapeGroup([
          ellipse([96, 96]),
          stroke({
            color: COLORS.slate,
            width: 4,
            opacity: 60,
            dashes: dashPattern({ dash: 7, gap: 9 }),
          }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Child Follower",
      ks: {
        p: [168, 90, 0],
      },
      parent: 1,
      groups: [
        shapeGroup([ellipse([26, 26]), fill(COLORS.amber), stroke({ color: COLORS.ink, width: 3 })]),
      ],
    }),
  ])
}

function buildInterpolationLinearExample() {
  return animation("interp-linear", [
    shapeLayer({
      name: "Linear Guide",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-76, 0], [76, 0]], false),
          stroke({ color: COLORS.cloud, width: 6, lineCap: 2 }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Linear Dot",
      ks: {
        p: {
          a: 1,
          k: [
            linearKeyframe(0, [44, 90, 0], [196, 90, 0]),
            { t: FRAMES },
          ],
        },
      },
      groups: [shapeGroup([ellipse([26, 26]), fill(COLORS.blue)])],
    }),
  ])
}

function buildInterpolationBezierExample() {
  return animation("interp-bezier", [
    shapeLayer({
      name: "Bezier Dot",
      ks: {
        p: {
          a: 1,
          k: [
            keyframe(0, [44, 90, 0], [196, 90, 0], {
              i: { x: [0.667], y: [1] },
              o: { x: [0.2], y: [0] },
            }),
            { t: FRAMES },
          ],
        },
      },
      groups: [shapeGroup([ellipse([26, 26]), fill(COLORS.violet)])],
    }),
  ])
}

function buildInterpolationHoldExample() {
  return animation("interp-hold", [
    shapeLayer({
      name: "Hold Markers",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-64, 0], [0, 0], [64, 0]], false),
          stroke({ color: COLORS.cloud, width: 8, lineCap: 2, dashes: dashPattern({ dash: 4, gap: 10 }) }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Hold Dot",
      ks: {
        p: {
          a: 1,
          k: [
            { t: 0, s: [58, 90, 0], h: 1 },
            { t: 32, s: [120, 54, 0], h: 1 },
            { t: 64, s: [182, 126, 0], h: 1 },
            { t: FRAMES, s: [182, 126, 0] },
          ],
        },
      },
      groups: [shapeGroup([rect([28, 28], [0, 0], 8), fill(COLORS.coral)])],
    }),
  ])
}

function buildInterpolationSpatialBezierExample() {
  return animation("interp-spatial-bezier", [
    shapeLayer({
      name: "Spatial Guide",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-72, 30], [-12, -42], [20, -10], [72, 34]], false),
          stroke({ color: COLORS.cloud, width: 6, lineCap: 2, dashes: dashPattern({ dash: 6, gap: 8 }) }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Spatial Dot",
      ks: {
        p: {
          a: 1,
          k: [
            keyframe(0, [48, 124, 0], [188, 56, 0], { to: [54, -68, 0], ti: [-58, 26, 0] }),
            keyframe(48, [188, 56, 0], [48, 124, 0], { to: [-58, 26, 0], ti: [54, -68, 0] }),
            { t: FRAMES },
          ],
        },
      },
      groups: [shapeGroup([ellipse([28, 28]), fill(COLORS.teal)])],
    }),
  ])
}

function buildInterpolationTimeRoamExample() {
  return animation("interp-time-roam", [
    shapeLayer({
      name: "Timing Track",
      ks: { p: CENTER },
      groups: [
        shapeGroup([
          pathShape([[-76, 0], [76, 0]], false),
          stroke({ color: COLORS.cloud, width: 6, lineCap: 2 }),
        ]),
      ],
    }),
    shapeLayer({
      name: "Timing Dot",
      ks: {
        p: {
          a: 1,
          k: [
            linearKeyframe(0, [44, 90, 0], [96, 90, 0]),
            linearKeyframe(12, [96, 90, 0], [176, 90, 0]),
            linearKeyframe(72, [176, 90, 0], [196, 90, 0]),
            { t: FRAMES },
          ],
        },
      },
      groups: [shapeGroup([ellipse([26, 26]), fill(COLORS.amber)])],
    }),
  ])
}

function buildMaskOpacityExample() {
  return animation("mask-opacity", [
    shapeLayer({
      name: "Opacity Frame",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([122, 86], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
    shapeLayer({
      name: "Opacity Masked Stripes",
      ks: { p: CENTER },
      masksProperties: [
        {
          ...mask(rectPath(0, 0, 112, 78), "a"),
          o: pingPong(20, 100),
        },
      ],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.blue, COLORS.teal, COLORS.amber, COLORS.coral]),
          { p: pingPong([-24, 0], [24, 0]) },
          "Opacity Rail",
        ),
      ],
    }),
  ])
}

function buildMaskAddExample() {
  return animation("mask-add", [
    shapeLayer({
      name: "Add Frame",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([122, 86], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
    shapeLayer({
      name: "Add Stripes",
      ks: { p: CENTER },
      masksProperties: [mask(rectPath(0, 0, 112, 78), "a")],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.teal, COLORS.blue, COLORS.violet, COLORS.amber]),
          { p: pingPong([-18, 0], [18, 0]) },
          "Add Rail",
        ),
      ],
    }),
  ])
}

function buildMaskSubtractExample() {
  return animation("mask-subtract", [
    shapeLayer({
      name: "Subtract Layer",
      ks: { p: CENTER },
      masksProperties: [mask(rectPath(0, 0, 82, 58), "s")],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.blue, COLORS.coral, COLORS.amber, COLORS.teal, COLORS.violet]),
          { p: pingPong([-10, 0], [10, 0]) },
          "Subtract Rail",
        ),
      ],
    }),
    shapeLayer({
      name: "Subtract Window",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([90, 66], [0, 0], 14), stroke({ color: COLORS.ink, width: 3 })])],
    }),
  ])
}

function buildMaskIntersectExample() {
  return animation("mask-intersect", [
    shapeLayer({
      name: "Intersect Layer",
      ks: { p: CENTER },
      masksProperties: [
        mask(rectPath(-18, 0, 84, 72), "a", "Mask Left"),
        mask(rectPath(18, 0, 84, 72), "i", "Mask Right"),
      ],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.blue, COLORS.teal, COLORS.coral, COLORS.amber, COLORS.violet]),
          { p: pingPong([-16, 0], [16, 0]) },
          "Intersect Rail",
        ),
      ],
    }),
    shapeLayer({
      name: "Intersect Guides",
      ks: { p: CENTER },
      groups: [
        shapeGroup([rect([84, 72], [-18, 0], 14), stroke({ color: COLORS.slate, width: 3 })]),
        shapeGroup([rect([84, 72], [18, 0], 14), stroke({ color: COLORS.ink, width: 3 })]),
      ],
    }),
  ])
}

function buildMaskExpansionExample() {
  return animation("mask-expansion", [
    shapeLayer({
      name: "Expansion Layer",
      ks: { p: CENTER },
      masksProperties: [
        {
          ...mask(rectPath(0, 0, 90, 62), "a"),
          x: pingPong(-22, 22),
        },
      ],
      groups: [
        shapeGroup(
          createStripeGroups([COLORS.blue, COLORS.teal, COLORS.amber, COLORS.coral]),
          { p: pingPong([-18, 0], [18, 0]) },
          "Expansion Rail",
        ),
      ],
    }),
    shapeLayer({
      name: "Expansion Frame",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([130, 94], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
  ])
}

function buildAlphaInvertedMatteExample() {
  return animation("matte-alpha-inverted", [
    shapeLayer({
      name: "Inverted Matte",
      td: 1,
      ks: { p: pingPong([84, 90, 0], [156, 90, 0]) },
      groups: [shapeGroup([ellipse([74, 74]), fill(COLORS.white)])],
    }),
    shapeLayer({
      name: "Inverted Content",
      tt: 2,
      ks: { p: CENTER },
      groups: [
        shapeGroup(createStripeGroups([COLORS.blue, COLORS.teal, COLORS.amber, COLORS.coral, COLORS.violet]), {}, "Inverted Stripes"),
      ],
    }),
    shapeLayer({
      name: "Inverted Frame",
      ks: { p: CENTER },
      groups: [shapeGroup([rect([140, 104], [0, 0], 18), stroke({ color: COLORS.ink, width: 3 })])],
    }),
  ])
}

function buildLayerFillEffectExample() {
  return animation("layer-fill-effect", [
    shapeLayer({
      name: "Layer Fill",
      ks: {
        p: CENTER,
        r: pingPong(-8, 8),
      },
      ef: [
        {
          ty: 21,
          mn: "ADBE Fill",
          en: 1,
          ef: [
            { mn: "ADBE Fill-0002", v: pingPong([0.16, 0.54, 0.95, 1], [0.95, 0.42, 0.36, 1]) },
            { mn: "ADBE Fill-0005", v: rawProperty(70) },
          ],
        },
      ],
      groups: [
        shapeGroup([ellipse([96, 96]), fill(COLORS.amber)]),
        shapeGroup([
          pathShape([[-26, -12], [0, -44], [26, -12], [0, 20]]),
          fill(COLORS.violet),
        ]),
      ],
    }),
  ])
}

function buildTextGlyphExample() {
  return animation("text-glyph", [
    textLayer({
      name: "Glyph Text",
      ks: {
        p: [36, 128, 0],
      },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.blue,
      }),
      animators: [
        textAnimator(
          { position: [0, pingPong(-8, 8), 0] },
          { start: 0, end: 100, shape: 2 },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextFontExample() {
  return animation("text-font", [
    textLayer({
      name: "Font Text",
      ks: {
        p: [44, 110, 0],
        r: pingPong(-4, 4),
      },
      document: textDocument({
        font: "Arial",
        text: "Moon Font",
        size: 44,
        fillColor: COLORS.teal,
      }),
    }),
  ])
}

function buildTextTransformExample() {
  return animation("text-transform", [
    textLayer({
      name: "Text Transform",
      ks: {
        p: pingPong([48, 130, 0], [184, 58, 0]),
        r: pingPong(-10, 10),
        s: pingPong([92, 92, 100], [114, 114, 100]),
      },
      document: textDocument({
        text: "MOVE",
        size: 60,
        fillColor: COLORS.coral,
      }),
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextFillExample() {
  return animation("text-fill", [
    textLayer({
      name: "Text Fill",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.blue,
      }),
      animators: [
        textAnimator(
          { fillColor: pingPong(COLORS.blue, COLORS.amber) },
          { start: 0, end: 100, shape: 2 },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextStrokeExample() {
  return animation("text-stroke", [
    textLayer({
      name: "Text Stroke",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.white,
        strokeColor: COLORS.ink,
        strokeWidth: 4,
      }),
      animators: [
        textAnimator(
          {
            strokeColor: pingPong(COLORS.violet, COLORS.coral),
            strokeWidth: pingPong(2, 8),
          },
          { start: 0, end: 100, shape: 2 },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextTrackingExample() {
  return animation("text-tracking", [
    textLayer({
      name: "Text Tracking",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.teal,
      }),
      animators: [
        textAnimator(
          { tracking: pingPong(0, 28) },
          { start: 0, end: 100, shape: 2 },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextAnchorGroupingExample() {
  return animation("text-anchor-grouping", [
    textLayer({
      name: "Text Anchor Grouping",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.violet,
      }),
      animators: [
        textAnimator(
          { rotation: pingPong(-28, 28), position: [0, pingPong(-10, 10), 0] },
          { start: 0, end: 100, shape: 2 },
        ),
      ],
      moreOptions: {
        g: 1,
        a: rawProperty([0, 0]),
      },
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextRangeUnitsExample() {
  return animation("text-range-units", [
    textLayer({
      name: "Text Range Units",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.blue,
      }),
      animators: [
        textAnimator(
          { position: [0, -22, 0], opacity: 10 },
          {
            start: 0,
            end: pingPong(10, 100),
            shape: 2,
            basedOn: 1,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextRangeBasedOnExample() {
  return animation("text-range-based-on", [
    textLayer({
      name: "Text Range Based On",
      ks: { p: [36, 128, 0] },
      document: textDocument({
        text: "WA VE",
        size: 60,
        fillColor: COLORS.teal,
      }),
      animators: [
        textAnimator(
          { position: [0, -18, 0], fillColor: COLORS.amber },
          {
            start: 0,
            end: pingPong(0, 100),
            shape: 2,
            basedOn: 3,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextRangeQuantityExample() {
  return animation("text-range-quantity", [
    textLayer({
      name: "Text Range Quantity",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.coral,
      }),
      animators: [
        textAnimator(
          { opacity: 0, position: [0, 20, 0] },
          {
            start: 1,
            end: pingPong(1, 4),
            shape: 2,
            rangeUnits: 2,
            basedOn: 1,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextRangeShapeExample() {
  return animation("text-range-shape", [
    textLayer({
      name: "Text Range Shape",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.amber,
      }),
      animators: [
        textAnimator(
          { scale: [130, 130, 100] },
          {
            start: 0,
            end: 100,
            offset: pingPong(-100, 100),
            shape: 3,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextEaseHighExample() {
  return animation("text-range-ease-high", [
    textLayer({
      name: "Text Ease High",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.blue,
      }),
      animators: [
        textAnimator(
          { position: [0, -24, 0] },
          {
            start: 0,
            end: 100,
            offset: pingPong(-100, 100),
            easeHigh: 80,
            shape: 2,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextEaseLowExample() {
  return animation("text-range-ease-low", [
    textLayer({
      name: "Text Ease Low",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.teal,
      }),
      animators: [
        textAnimator(
          { position: [0, 24, 0] },
          {
            start: 0,
            end: 100,
            offset: pingPong(-100, 100),
            easeLow: 80,
            shape: 2,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildTextRandomOrderExample() {
  return animation("text-range-random-order", [
    textLayer({
      name: "Text Random Order",
      ks: { p: [40, 128, 0] },
      document: textDocument({
        text: "WAVE",
        size: 64,
        fillColor: COLORS.violet,
      }),
      animators: [
        textAnimator(
          { opacity: 0, position: [0, -20, 0] },
          {
            start: 0,
            end: 100,
            offset: pingPong(-100, 100),
            randomize: 1,
            shape: 2,
          },
        ),
      ],
    }),
  ], {
    fonts: DEMO_GLYPH_FONT,
    chars: DEMO_GLYPHS,
  })
}

function buildPrecompExample() {
  return animation("other-precomp", [
    precompLayer({
      name: "Wave Precomp",
      refId: "comp_wave",
      ks: {
        p: CENTER,
        s: pingPong([90, 90, 100], [110, 110, 100]),
        r: pingPong(-8, 8),
      },
    }),
  ], {
    assets: [
      {
        id: "comp_wave",
        layers: [
          shapeLayer({
            name: "Precomp Dot",
            ks: {
              p: pingPong([64, 90, 0], [176, 90, 0]),
            },
            groups: [shapeGroup([ellipse([28, 28]), fill(COLORS.blue)])],
          }),
        ].map((layer, index) => ({ ...layer, ind: index + 1 })),
      },
    ],
  })
}

function buildTimeRemapExample() {
  return animation("other-time-remap", [
    precompLayer({
      name: "Time Remap",
      refId: "comp_time",
      tm: pingPong(0.3, 2.3),
      ks: { p: CENTER },
    }),
  ], {
    assets: [
      {
        id: "comp_time",
        layers: [
          shapeLayer({
            name: "Time Guide",
            ks: { p: CENTER },
            groups: [shapeGroup([pathShape([[-78, 0], [78, 0]], false), stroke({ color: COLORS.cloud, width: 6, lineCap: 2 })])],
          }),
          shapeLayer({
            name: "Time Dot",
            ks: {
              p: {
                a: 1,
                k: [
                  linearKeyframe(0, [44, 90, 0], [196, 90, 0]),
                  { t: 72 },
                ],
              },
            },
            groups: [shapeGroup([ellipse([26, 26]), fill(COLORS.coral)])],
            op: 72,
          }),
        ].map((layer, index) => ({ ...layer, ind: index + 1 })),
      },
    ],
  })
}

const SHAPE_EXAMPLE = buildShapeExample()
const ELLIPSE_EXAMPLE = buildEllipseExample()
const RECTANGLE_EXAMPLE = buildRectangleExample()
const ROUNDED_RECT_EXAMPLE = buildRoundedRectExample()
const POLYSTAR_EXAMPLE = buildPolystarExample()
const GROUP_EXAMPLE = buildGroupExample()
const REPEATER_EXAMPLE = buildRepeaterExample()
const TRIM_SINGLE_EXAMPLE = buildTrimSingleExample()
const TRIM_TOGETHER_EXAMPLE = buildTrimSimultaneousExample()
const FILL_COLOR_EXAMPLE = buildFillColorExample()
const FILL_OPACITY_EXAMPLE = buildFillOpacityExample()
const FILL_RULE_EXAMPLE = buildFillRuleExample()
const RADIAL_GRADIENT_EXAMPLE = buildRadialGradientExample()
const LINEAR_GRADIENT_EXAMPLE = buildLinearGradientExample()
const STROKE_OPACITY_EXAMPLE = buildStrokeOpacityExample()
const STROKE_COLOR_EXAMPLE = buildStrokeColorExample()
const STROKE_WIDTH_EXAMPLE = buildStrokeWidthExample()
const LINE_CAP_EXAMPLE = buildLineCapExample()
const LINE_JOIN_EXAMPLE = buildLineJoinExample()
const MITER_LIMIT_EXAMPLE = buildMiterLimitExample()
const DASH_EXAMPLE = buildDashExample()
const GRADIENT_STROKE_EXAMPLE = buildGradientStrokeExample()
const ANCHOR_EXAMPLE = buildAnchorPointExample()
const POSITION_EXAMPLE = buildPositionExample()
const SEPARATED_POSITION_EXAMPLE = buildSeparatedPositionExample()
const SCALE_EXAMPLE = buildScaleExample()
const ROTATION_EXAMPLE = buildRotationExample()
const TRANSFORM_OPACITY_EXAMPLE = buildTransformOpacityExample()
const PARENT_HIERARCHY_EXAMPLE = buildParentHierarchyExample()
const SKEW_EXAMPLE = buildSkewExample()
const SKEW_AXIS_EXAMPLE = buildSkewAxisExample()
const AUTO_ORIENT_EXAMPLE = buildAutoOrientExample()
const MASK_EXAMPLE = buildMaskExample()
const MASK_OPACITY_EXAMPLE = buildMaskOpacityExample()
const MASK_ADD_EXAMPLE = buildMaskAddExample()
const MASK_SUBTRACT_EXAMPLE = buildMaskSubtractExample()
const MASK_INTERSECT_EXAMPLE = buildMaskIntersectExample()
const MASK_EXPANSION_EXAMPLE = buildMaskExpansionExample()
const TRACK_MATTE_EXAMPLE = buildTrackMatteExample()
const TRACK_MATTE_INVERTED_EXAMPLE = buildAlphaInvertedMatteExample()
const IMAGE_EXAMPLE = buildImageExample()
const MARKER_EXAMPLE = buildMarkerExample()
const EXPRESSION_EXAMPLE = buildExpressionExample()
const LAYER_FILL_EFFECT_EXAMPLE = buildLayerFillEffectExample()
const INTERP_LINEAR_EXAMPLE = buildInterpolationLinearExample()
const INTERP_BEZIER_EXAMPLE = buildInterpolationBezierExample()
const INTERP_HOLD_EXAMPLE = buildInterpolationHoldExample()
const INTERP_SPATIAL_BEZIER_EXAMPLE = buildInterpolationSpatialBezierExample()
const INTERP_TIME_ROAM_EXAMPLE = buildInterpolationTimeRoamExample()
const TEXT_GLYPH_EXAMPLE = buildTextGlyphExample()
const TEXT_FONT_EXAMPLE = buildTextFontExample()
const TEXT_TRANSFORM_EXAMPLE = buildTextTransformExample()
const TEXT_FILL_EXAMPLE = buildTextFillExample()
const TEXT_STROKE_EXAMPLE = buildTextStrokeExample()
const TEXT_TRACKING_EXAMPLE = buildTextTrackingExample()
const TEXT_ANCHOR_GROUPING_EXAMPLE = buildTextAnchorGroupingExample()
const TEXT_RANGE_UNITS_EXAMPLE = buildTextRangeUnitsExample()
const TEXT_RANGE_BASED_ON_EXAMPLE = buildTextRangeBasedOnExample()
const TEXT_RANGE_QUANTITY_EXAMPLE = buildTextRangeQuantityExample()
const TEXT_RANGE_SHAPE_EXAMPLE = buildTextRangeShapeExample()
const TEXT_EASE_HIGH_EXAMPLE = buildTextEaseHighExample()
const TEXT_EASE_LOW_EXAMPLE = buildTextEaseLowExample()
const TEXT_RANDOM_ORDER_EXAMPLE = buildTextRandomOrderExample()
const PRECOMP_EXAMPLE = buildPrecompExample()
const TIME_REMAP_EXAMPLE = buildTimeRemapExample()

export const featureExampleMap = {
  shapes: {
    "形状": createExample(
      "支持基础形状图层与自定义路径（Path）。",
      {
        ty: 4,
        shapes: [
          {
            ty: "sh",
            ks: {
              k: {
                v: [[-44, -30], [0, -52], [48, -8], [24, 40], [-36, 34]],
              },
            },
          },
          { ty: "fl" },
          { ty: "st" },
        ],
      },
      SHAPE_EXAMPLE,
    ),
    "椭圆": createExample(
      "支持参数化绘制椭圆及其位置、尺寸属性。",
      {
        ty: "el",
        s: { k: [110, 76] },
        p: { k: [0, 0] },
      },
      ELLIPSE_EXAMPLE,
    ),
    "矩形": createExample(
      "支持参数化矩形图层及其尺寸、位置。 ",
      {
        ty: "rc",
        s: { k: [110, 64] },
        p: { k: [0, 0] },
        r: { k: 0 },
      },
      RECTANGLE_EXAMPLE,
    ),
    "圆角矩形": createExample(
      "支持矩形图层的圆角（Roundness）参数。",
      {
        ty: "rc",
        s: { k: [120, 64] },
        r: { k: 22 },
      },
      ROUNDED_RECT_EXAMPLE,
    ),
    "多角星": createExample(
      "支持多端点星形、多边形及其内外径控制。",
      {
        ty: "sr",
        pt: { k: 5 },
        or: { k: 48 },
        ir: { k: 22 },
      },
      POLYSTAR_EXAMPLE,
    ),
    "组": createExample(
      "支持将多个形状项包装在组中，共享变换属性。",
      {
        ty: "gr",
        it: [
          { ty: "gr", nm: "Eye Left" },
          { ty: "gr", nm: "Eye Right" },
          { ty: "gr", nm: "Smile" },
          { ty: "tr" },
        ],
      },
      GROUP_EXAMPLE,
    ),
    "重复器": createExample(
      "支持 Repeater 特性，通过阵列变换快速生成复杂图形。",
      {
        ty: "rp",
        c: { k: 10 },
        o: { k: 0 },
        tr: {
          r: { k: 36 },
        },
      },
      REPEATER_EXAMPLE,
    ),
    "修剪路径（单独）": createExample(
      "支持修剪路径（Trim Paths），控制单一描边的起止比例。",
      {
        ty: "tm",
        s: { k: 0 },
        e: { a: 1 },
      },
      TRIM_SINGLE_EXAMPLE,
    ),
    "修剪路径（同时）": createExample(
      "支持对组内所有路径执行同步裁切。",
      {
        shapes: [
          { ty: "sh", nm: "Path 1" },
          { ty: "sh", nm: "Path 2" },
          { ty: "tm" },
        ],
      },
      TRIM_TOGETHER_EXAMPLE,
    ),
  },
  fills: {
    "颜色": createExample(
      "支持单色填充及其色彩关键帧插值。",
      {
        ty: "fl",
        c: { a: 1 },
        o: { k: 100 },
      },
      FILL_COLOR_EXAMPLE,
    ),
    "不透明度": createExample(
      "支持填充图层独立的不透明度（Opacity）控制。",
      {
        ty: "fl",
        c: { k: COLORS.teal },
        o: { a: 1 },
      },
      FILL_OPACITY_EXAMPLE,
    ),
    "填充规则": createExample(
      "支持非零环绕（Non-Zero）与奇偶填充（Even-Odd）规则。",
      {
        shapes: [
          { ty: "sh", nm: "Outer" },
          { ty: "sh", nm: "Inner" },
          { ty: "fl", r: 2 },
        ],
      },
      FILL_RULE_EXAMPLE,
    ),
    "径向渐变": createExample(
      "支持平滑的径向渐变填充及其多色停靠点控制。",
      {
        ty: "gf",
        t: 2,
        g: {
          p: 2,
          k: { k: [0, 0.97, 0.73, 0.24, 1, 0.95, 0.42, 0.36] },
        },
      },
      RADIAL_GRADIENT_EXAMPLE,
    ),
    "线性渐变": createExample(
      "支持线性渐变填充，可自定义方向、长度与色彩过渡。",
      {
        ty: "gf",
        t: 1,
        s: { k: [-64, 0] },
        e: { k: [64, 0] },
      },
      LINEAR_GRADIENT_EXAMPLE,
    ),
  },
  strokes: {
    "不透明度": createExample(
      "支持描边专用不透明度关键帧。",
      {
        ty: "st",
        o: { a: 1 },
        w: { k: 10 },
      },
      STROKE_OPACITY_EXAMPLE,
    ),
    "颜色": createExample(
      "支持单一描边颜色的关键帧插值。",
      {
        ty: "st",
        c: { a: 1 },
        w: { k: 12 },
      },
      STROKE_COLOR_EXAMPLE,
    ),
    "宽度": createExample(
      "支持对描边宽度（Stroke Width）进行实时插值控制。",
      {
        ty: "st",
        w: { a: 1 },
        lc: 2,
      },
      STROKE_WIDTH_EXAMPLE,
    ),
    "线帽": createExample(
      "支持线条末端的平头（Butt）、圆头（Round）等形状。",
      {
        ty: "st",
        lc: 2,
        w: { k: 16 },
      },
      LINE_CAP_EXAMPLE,
    ),
    "线段连接": createExample(
      "支持折角的斜接（Miter）、圆角（Round）等连接样式。",
      {
        ty: "st",
        lj: 2,
        w: { k: 18 },
      },
      LINE_JOIN_EXAMPLE,
    ),
    "斜接限制": createExample(
      "支持对尖锐折角的斜接长度限制（Miter Limit）。",
      {
        ty: "st",
        lj: 1,
        ml: 2,
        w: { k: 18 },
      },
      MITER_LIMIT_EXAMPLE,
    ),
    "虚线": createExample(
      "支持自定义虚线与间隙（Dashes/Gaps）及其偏移效果。",
      {
        ty: "st",
        d: [
          { n: "d", v: { k: 10 } },
          { n: "g", v: { k: 12 } },
          { n: "o", v: { a: 1 } },
        ],
      },
      DASH_EXAMPLE,
    ),
    "渐变": createExample(
      "支持 Gradient Stroke，在描边上实现多色渐变过渡。",
      {
        ty: "gs",
        t: 1,
        g: {
          p: 3,
        },
      },
      GRADIENT_STROKE_EXAMPLE,
    ),
  },
  transforms: {
    "锚点": createExample(
      "支持定义图层旋转、缩放的参考原点。",
      {
        ks: {
          a: { k: [-30, -30, 0] },
          r: { a: 1 },
        },
      },
      ANCHOR_EXAMPLE,
    ),
    "位置": createExample(
      "支持图层级坐标变换与位置变化关键帧。",
      {
        ks: {
          p: { a: 1 },
        },
      },
      POSITION_EXAMPLE,
    ),
    "位置（分离 X/Y）": createExample(
      "支持分离 X/Y 位置通道，分别控制水平与垂直位移。",
      {
        ks: {
          p: {
            s: true,
            x: { a: 1 },
            y: { a: 1 },
          },
        },
      },
      SEPARATED_POSITION_EXAMPLE,
    ),
    "缩放": createExample(
      "支持二维/三维图层缩放关键帧。",
      {
        ks: {
          s: { a: 1 },
        },
      },
      SCALE_EXAMPLE,
    ),
    "旋转": createExample(
      "支持高精度的角度转换与旋转关键帧。",
      {
        ks: {
          r: { a: 1 },
        },
      },
      ROTATION_EXAMPLE,
    ),
    "不透明度": createExample(
      "支持图层整体不透明度的实时插值。",
      {
        ks: {
          o: { a: 1 },
        },
      },
      TRANSFORM_OPACITY_EXAMPLE,
    ),
    "父子层级": createExample(
      "支持父层级继承，子图层会跟随父图层的位移、旋转与缩放。",
      {
        parent: 1,
        ks: {
          p: { a: 1 },
          r: { a: 1 },
        },
      },
      PARENT_HIERARCHY_EXAMPLE,
    ),
    "倾斜": createExample(
      "支持对图层内容进行剪切变形（Skew）。",
      {
        ks: {
          sk: { k: 18 },
          sa: { k: 0 },
        },
      },
      SKEW_EXAMPLE,
    ),
    "倾斜轴": createExample(
      "支持设置倾斜时的参考轴（Skew Axis）。",
      {
        ks: {
          sk: { k: 18 },
          sa: { k: 45 },
        },
      },
      SKEW_AXIS_EXAMPLE,
    ),
    "自动朝向": createExample(
      "支持图层沿运动路径切线方向自动调整角度。",
      {
        ao: 1,
        ks: {
          p: { a: 1 },
        },
      },
      AUTO_ORIENT_EXAMPLE,
    ),
  },
  interpolation: {
    "线性插值": createExample(
      "支持线性插值，属性会以恒定速度在关键帧之间过渡。",
      {
        a: 1,
        k: [{ t: 0 }, { t: 48 }],
      },
      INTERP_LINEAR_EXAMPLE,
    ),
    "贝塞尔插值": createExample(
      "支持贝塞尔缓动曲线，获得更自然的加减速节奏。",
      {
        a: 1,
        k: [{ t: 0, i: { x: 0.667, y: 1 }, o: { x: 0.333, y: 0 } }],
      },
      INTERP_BEZIER_EXAMPLE,
    ),
    "保持插值": createExample(
      "支持保持插值（Hold），属性会在关键帧之间直接跳变。",
      {
        a: 1,
        k: [{ t: 0, h: 1 }, { t: 48 }],
      },
      INTERP_HOLD_EXAMPLE,
    ),
    "空间贝塞尔插值": createExample(
      "支持带空间切线的运动路径插值，轨迹更平滑。",
      {
        a: 1,
        k: [{ t: 0, to: [20, 0, 0], ti: [-20, 0, 0] }],
      },
      INTERP_SPATIAL_BEZIER_EXAMPLE,
    ),
    "时间漫游": createExample(
      "支持关键帧时间分布调整，可实现更灵活的时间节奏控制。",
      {
        a: 1,
        k: [{ t: 0 }, { t: 24 }, { t: 72 }],
      },
      INTERP_TIME_ROAM_EXAMPLE,
    ),
  },
  masks: {
    "蒙版路径": createExample(
      "支持传统的形状蒙版（Masks）路径裁切。",
      {
        hasMask: true,
        masksProperties: [
          {
            mode: "a",
            pt: { k: rectPath(0, 0, 112, 80) },
          },
        ],
      },
      MASK_EXAMPLE,
    ),
    "蒙版不透明度": createExample(
      "支持独立控制蒙版不透明度，动态调节裁切强度。",
      {
        hasMask: true,
        masksProperties: [
          {
            mode: "a",
            o: { a: 1 },
          },
        ],
      },
      MASK_OPACITY_EXAMPLE,
    ),
    "相加": createExample(
      "支持 Add 蒙版模式，保留蒙版轮廓内部区域。",
      {
        hasMask: true,
        masksProperties: [{ mode: "a" }],
      },
      MASK_ADD_EXAMPLE,
    ),
    "相减": createExample(
      "支持 Subtract 蒙版模式，从图层内容中扣除蒙版区域。",
      {
        hasMask: true,
        masksProperties: [{ mode: "s" }],
      },
      MASK_SUBTRACT_EXAMPLE,
    ),
    "相交": createExample(
      "支持 Intersect 蒙版模式，仅显示多个蒙版的重叠区域。",
      {
        hasMask: true,
        masksProperties: [{ mode: "i" }],
      },
      MASK_INTERSECT_EXAMPLE,
    ),
    "扩展": createExample(
      "支持蒙版扩展（Expansion），可向内或向外膨胀裁切边界。",
      {
        hasMask: true,
        masksProperties: [
          {
            mode: "a",
            x: { a: 1 },
          },
        ],
      },
      MASK_EXPANSION_EXAMPLE,
    ),
  },
  mattes: {
    "Alpha 遮罩": createExample(
      "支持图层间的 Alpha Track Matte（轨道遮罩）。",
      {
        layers: [
          { ty: 4, td: 1 },
          { ty: 4, tt: 1 },
        ],
      },
      TRACK_MATTE_EXAMPLE,
    ),
    "Alpha 反相遮罩": createExample(
      "支持 Alpha Inverted Track Matte，使用遮罩外部区域进行显示。",
      {
        layers: [
          { ty: 4, td: 1 },
          { ty: 4, tt: 2 },
        ],
      },
      TRACK_MATTE_INVERTED_EXAMPLE,
    ),
  },
  layerEffects: {
    "填充": createExample(
      "支持解析并渲染图层效果中的 Fill，用统一颜色覆盖整层内容。",
      {
        ef: [
          {
            ty: 21,
            nm: "Fill",
          },
        ],
      },
      LAYER_FILL_EFFECT_EXAMPLE,
    ),
  },
  text: {
    "字形": createExample(
      "支持字形（Glyph）文本资源，按轮廓路径渲染字符形状。",
      {
        ty: 5,
        t: {
          d: { k: [{ s: { t: "Moon" }, t: 0 }] },
        },
      },
      TEXT_GLYPH_EXAMPLE,
    ),
    "字体": createExample(
      "支持字体文本图层，可按字体信息直接排版和渲染。",
      {
        ty: 5,
        t: {
          d: { k: [{ s: { f: "Arial", t: "Moon" }, t: 0 }] },
        },
      },
      TEXT_FONT_EXAMPLE,
    ),
    "变换": createExample(
      "支持文本图层的位移、旋转、缩放等基础变换属性。",
      {
        ty: 5,
        ks: {
          p: { a: 1 },
          r: { a: 1 },
        },
      },
      TEXT_TRANSFORM_EXAMPLE,
    ),
    "填充": createExample(
      "支持文本填充颜色与透明度控制。",
      {
        ty: 5,
        t: {
          d: { k: [{ s: { fc: COLORS.blue }, t: 0 }] },
        },
      },
      TEXT_FILL_EXAMPLE,
    ),
    "描边": createExample(
      "支持文本描边颜色、宽度与透明度配置。",
      {
        ty: 5,
        t: {
          d: { k: [{ s: { sc: COLORS.ink, sw: 2 }, t: 0 }] },
        },
      },
      TEXT_STROKE_EXAMPLE,
    ),
    "字距": createExample(
      "支持调整字距（Tracking），控制字符之间的排版疏密。",
      {
        ty: 5,
        t: {
          d: { k: [{ s: { tr: 30 }, t: 0 }] },
        },
      },
      TEXT_TRACKING_EXAMPLE,
    ),
    "锚点分组": createExample(
      "支持按字符锚点分组执行动画，保持逐字变换的参考点一致。",
      {
        ty: 5,
        t: {
          m: { g: 1 },
        },
      },
      TEXT_ANCHOR_GROUPING_EXAMPLE,
    ),
    "范围选择器（单位）": createExample(
      "支持按百分比单位配置范围选择器，逐步影响字符集合。",
      {
        ty: 5,
        t: {
          a: [{ s: { b: 1 } }],
        },
      },
      TEXT_RANGE_UNITS_EXAMPLE,
    ),
    "范围选择器（基于）": createExample(
      "支持按字符、单词或行作为范围选择器的计算基础。",
      {
        ty: 5,
        t: {
          a: [{ s: { b: 3 } }],
        },
      },
      TEXT_RANGE_BASED_ON_EXAMPLE,
    ),
    "范围选择器（数量）": createExample(
      "支持以字符数量驱动的范围选择器，精确控制受影响范围。",
      {
        ty: 5,
        t: {
          a: [{ s: { e: { a: 1 } } }],
        },
      },
      TEXT_RANGE_QUANTITY_EXAMPLE,
    ),
    "范围选择器（形状）": createExample(
      "支持不同 Range Selector Shape，生成更丰富的逐字分布曲线。",
      {
        ty: 5,
        t: {
          a: [{ s: { sh: 3 } }],
        },
      },
      TEXT_RANGE_SHAPE_EXAMPLE,
    ),
    "范围选择器（缓动高）": createExample(
      "支持高端缓动（Ease High），强化范围末端的过渡效果。",
      {
        ty: 5,
        t: {
          a: [{ s: { ne: { a: 1 } } }],
        },
      },
      TEXT_EASE_HIGH_EXAMPLE,
    ),
    "范围选择器（缓动低）": createExample(
      "支持低端缓动（Ease Low），平滑范围起始位置的变化。",
      {
        ty: 5,
        t: {
          a: [{ s: { xe: { a: 1 } } }],
        },
      },
      TEXT_EASE_LOW_EXAMPLE,
    ),
    "范围选择器（随机顺序）": createExample(
      "支持随机顺序范围选择器，让字符按打散顺序参与动画。",
      {
        ty: 5,
        t: {
          a: [{ s: { rn: 1 } }],
        },
      },
      TEXT_RANDOM_ORDER_EXAMPLE,
    ),
  },
  general: {
    "蒙版": createExample(
      "支持传统的形状蒙版（Masks）及其与/或等叠加运算。",
      {
        hasMask: true,
        masksProperties: [
          {
            mode: "a",
            pt: { k: rectPath(0, 0, 112, 80) },
          },
        ],
      },
      MASK_EXAMPLE,
    ),
    "轨道遮罩": createExample(
      "支持图层间的轨道遮罩（Track Matte），跨图层实现镂空。",
      {
        layers: [
          { ty: 4, td: 1 },
          { ty: 4, tt: 1 },
        ],
      },
      TRACK_MATTE_EXAMPLE,
    ),
    "图片": createExample(
      "支持内联 Base64 或本地引用图片资源及其变换控制。",
      {
        assets: [
          {
            id: "img_0",
            w: 64,
            h: 64,
            p: "data:image/svg+xml;...",
            e: 1,
          },
        ],
        layer: {
          ty: 2,
          refId: "img_0",
        },
      },
      IMAGE_EXAMPLE,
    ),
    "表达式": createExample(
      "支持轻量级 JavaScript 表达式逻辑及其计算求值。",
      {
        ks: {
          p: {
            a: 0,
            k: [120, 90, 0],
            x: "var $bm_rt;\n$bm_rt = [120 + Math.sin(time * 4) * 42, 90 + Math.cos(time * 2) * 10, 0];",
          },
        },
      },
      EXPRESSION_EXAMPLE,
    ),
  },
  other: {
    "预合成": createExample(
      "支持预合成（Precomp）资源，可复用独立子时间线与图层集合。",
      {
        ty: 0,
        refId: "comp_0",
      },
      PRECOMP_EXAMPLE,
    ),
    "时间重映射": createExample(
      "支持时间重映射（Time Remap），可单独控制子动画的播放进度。",
      {
        ty: 0,
        tm: { a: 1 },
      },
      TIME_REMAP_EXAMPLE,
    ),
    "图片": createExample(
      "支持内联 Base64 或本地引用图片资源及其变换控制。",
      {
        assets: [
          {
            id: "img_0",
            w: 64,
            h: 64,
            p: "data:image/svg+xml;...",
            e: 1,
          },
        ],
        layer: {
          ty: 2,
          refId: "img_0",
        },
      },
      IMAGE_EXAMPLE,
    ),
    "表达式": createExample(
      "支持轻量级 JavaScript 表达式逻辑及其计算求值。",
      {
        ks: {
          p: {
            a: 0,
            k: [120, 90, 0],
            x: "var $bm_rt;\n$bm_rt = [120 + Math.sin(time * 4) * 42, 90 + Math.cos(time * 2) * 10, 0];",
          },
        },
      },
      EXPRESSION_EXAMPLE,
    ),
  },
}
