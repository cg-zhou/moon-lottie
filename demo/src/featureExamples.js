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
    p: rawProperty(p),
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
    p: rawProperty(p),
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

  if (masksProperties?.length) {
    layer.hasMask = true
    layer.masksProperties = masksProperties
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

function animation(name, layers, { assets = [], markers = [] } = {}) {
  return {
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
  return animation("mask", [
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
  return animation("track-matte", [
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
const ANCHOR_EXAMPLE = buildAnchorPointExample()
const POSITION_EXAMPLE = buildPositionExample()
const SCALE_EXAMPLE = buildScaleExample()
const ROTATION_EXAMPLE = buildRotationExample()
const TRANSFORM_OPACITY_EXAMPLE = buildTransformOpacityExample()
const SKEW_EXAMPLE = buildSkewExample()
const SKEW_AXIS_EXAMPLE = buildSkewAxisExample()
const AUTO_ORIENT_EXAMPLE = buildAutoOrientExample()
const MASK_EXAMPLE = buildMaskExample()
const TRACK_MATTE_EXAMPLE = buildTrackMatteExample()
const IMAGE_EXAMPLE = buildImageExample()
const MARKER_EXAMPLE = buildMarkerExample()
const EXPRESSION_EXAMPLE = buildExpressionExample()

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
}
