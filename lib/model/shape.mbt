///|
pub enum ShapeData {
  Group(Array[Shape])
  Rect(RectShape)
  Ellipse(EllipseShape)
  Path(PathShape)
  Fill(FillShape)
  Stroke(StrokeShape)
  GradientFill(GradientFillShape)
  GradientStroke(GradientStrokeShape)
  Transform(Transform)
  TrimPath(TrimPath)
  Polystar(PolystarShape)
  Repeater(Repeater)
  MergePaths(MergePaths)
  Rounding(Rounding)
}

///|
pub fn ShapeData::new_group(items : Array[Shape]) -> ShapeData {
  ShapeData::Group(items)
}

///|
pub fn ShapeData::new_rect(rect : RectShape) -> ShapeData {
  ShapeData::Rect(rect)
}

///|
pub fn ShapeData::new_ellipse(ellipse : EllipseShape) -> ShapeData {
  ShapeData::Ellipse(ellipse)
}

///|
pub fn ShapeData::new_path(path : PathShape) -> ShapeData {
  ShapeData::Path(path)
}

///|
pub fn ShapeData::new_fill(fill : FillShape) -> ShapeData {
  ShapeData::Fill(fill)
}

///|
pub fn ShapeData::new_stroke(stroke : StrokeShape) -> ShapeData {
  ShapeData::Stroke(stroke)
}

///|
pub fn ShapeData::new_gradient_fill(fill : GradientFillShape) -> ShapeData {
  ShapeData::GradientFill(fill)
}

///|
pub fn ShapeData::new_gradient_stroke(
  stroke : GradientStrokeShape,
) -> ShapeData {
  ShapeData::GradientStroke(stroke)
}

///|
pub fn ShapeData::new_transform(transform : Transform) -> ShapeData {
  ShapeData::Transform(transform)
}

///|
pub fn ShapeData::new_trim_path(trim : TrimPath) -> ShapeData {
  ShapeData::TrimPath(trim)
}

///|
pub fn ShapeData::new_polystar(polystar : PolystarShape) -> ShapeData {
  ShapeData::Polystar(polystar)
}

///|
pub fn ShapeData::new_repeater(repeater : Repeater) -> ShapeData {
  ShapeData::Repeater(repeater)
}

///|
pub fn ShapeData::new_merge_paths(merge : MergePaths) -> ShapeData {
  ShapeData::MergePaths(merge)
}

///|
pub fn ShapeData::new_rounding(rounding : Rounding) -> ShapeData {
  ShapeData::Rounding(rounding)
}

///|
pub struct Shape {
  nm : String?
  ty : String
  d : Int?
  hd : Bool?
  data : ShapeData
}

///|
pub fn Shape::new(
  ty~ : String,
  data~ : ShapeData,
  nm? : String? = None,
  d? : Int? = None,
  hd? : Bool? = None,
) -> Shape {
  { nm, ty, d, hd, data }
}

///|
pub struct RectShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
  r : LottieProperty[Double] // Roundness
}

///|
pub fn RectShape::new(
  p~ : LottieProperty[Array[Double]],
  s~ : LottieProperty[Array[Double]],
  r~ : LottieProperty[Double],
) -> RectShape {
  { p, s, r }
}

///|
pub struct EllipseShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
}

///|
pub fn EllipseShape::new(
  p~ : LottieProperty[Array[Double]],
  s~ : LottieProperty[Array[Double]],
) -> EllipseShape {
  { p, s }
}

///|
pub struct PathShape {
  ks : LottieProperty[BezierPath]
}

///|
pub fn PathShape::new(ks~ : LottieProperty[BezierPath]) -> PathShape {
  { ks, }
}

///|
pub struct BezierPath {
  v : Array[Array[Double]] // Vertices
  i : Array[Array[Double]] // In tangents
  o : Array[Array[Double]] // Out tangents
  c : Bool // Closed
}

///|
pub fn BezierPath::new(
  v~ : Array[Array[Double]],
  i~ : Array[Array[Double]],
  o~ : Array[Array[Double]],
  c~ : Bool,
) -> BezierPath {
  { v, i, o, c }
}

///|
pub fn BezierPath::new_rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> BezierPath {
  let hw = w / 2.0
  let hh = h / 2.0
  BezierPath::new(
    v=[[x - hw, y - hh], [x + hw, y - hh], [x + hw, y + hh], [x - hw, y + hh]],
    i=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    o=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    c=true,
  )
}

///|
pub struct FillShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double] // Opacity
}

///|
pub fn FillShape::new(
  c~ : LottieProperty[Array[Double]],
  o~ : LottieProperty[Double],
) -> FillShape {
  { c, o }
}

///|
pub struct StrokeShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double] // Opacity
  w : LottieProperty[Double] // Width
  lc : Int // Line Cap
  lj : Int // Line Join
  ml : Double // Miter Limit
}

///|
pub fn StrokeShape::new(
  c~ : LottieProperty[Array[Double]],
  o~ : LottieProperty[Double],
  w~ : LottieProperty[Double],
  lc? : Int = 1,
  lj? : Int = 1,
  ml? : Double = 0.0,
) -> StrokeShape {
  { c, o, w, lc, lj, ml }
}

///|
pub enum GradientType {
  Linear
  Radial
}

///|
pub fn GradientType::from_int(v : Int) -> GradientType {
  if v == 1 { GradientType::Linear } else { GradientType::Radial }
}

///|
pub struct GradientColors {
  p : Int // Number of colors
  k : LottieProperty[Array[Double]] // Stops and Colors
}

///|
pub fn GradientColors::new(
  p~ : Int,
  k~ : LottieProperty[Array[Double]],
) -> GradientColors {
  { p, k }
}

///|
pub struct GradientFillShape {
  t : GradientType
  o : LottieProperty[Double]
  s : LottieProperty[Array[Double]] // Start point
  e : LottieProperty[Array[Double]] // End point
  g : GradientColors
}

///|
pub fn GradientFillShape::new(
  t~ : Int,
  o~ : LottieProperty[Double],
  s~ : LottieProperty[Array[Double]],
  e~ : LottieProperty[Array[Double]],
  g~ : GradientColors,
) -> GradientFillShape {
  let ty = GradientType::from_int(t)
  { t: ty, o, s, e, g }
}

///|
pub struct GradientStrokeShape {
  t : GradientType
  o : LottieProperty[Double]
  s : LottieProperty[Array[Double]] // Start point
  e : LottieProperty[Array[Double]] // End point
  g : GradientColors
  w : LottieProperty[Double] // Stroke width
  lc : Int // Line Cap
  lj : Int // Line Join
  ml : Double // Miter Limit
}

///|
pub fn GradientStrokeShape::new(
  t~ : Int,
  o~ : LottieProperty[Double],
  s~ : LottieProperty[Array[Double]],
  e~ : LottieProperty[Array[Double]],
  g~ : GradientColors,
  w~ : LottieProperty[Double],
  lc? : Int = 1,
  lj? : Int = 1,
  ml? : Double = 0.0,
) -> GradientStrokeShape {
  let ty = GradientType::from_int(t)
  { t: ty, o, s, e, g, w, lc, lj, ml }
}

///|
pub struct TrimPath {
  s : LottieProperty[Double] // Start
  e : LottieProperty[Double] // End
  o : LottieProperty[Double] // Offset
  m : Int // Trim Multiple Shapes: 1=Simultaneously, 2=Individually
}

///|
pub fn TrimPath::new(
  s~ : LottieProperty[Double],
  e~ : LottieProperty[Double],
  o~ : LottieProperty[Double],
  m? : Int = 1,
) -> TrimPath {
  { s, e, o, m }
}

///|
pub struct PolystarShape {
  pt : LottieProperty[Double] // Points
  p : LottieProperty[Array[Double]] // Position
  r : LottieProperty[Double] // Rotation
  ir : LottieProperty[Double] // Inner Radius
  ir_round : LottieProperty[Double] // Inner Roundness
  or : LottieProperty[Double] // Outer Radius
  or_round : LottieProperty[Double] // Outer Roundness
  sy : Int // Star Type: 1=Star, 2=Polygon
}

///|
pub fn PolystarShape::new(
  pt~ : LottieProperty[Double],
  p~ : LottieProperty[Array[Double]],
  r~ : LottieProperty[Double],
  ir~ : LottieProperty[Double],
  ir_round~ : LottieProperty[Double],
  or~ : LottieProperty[Double],
  or_round~ : LottieProperty[Double],
  sy~ : Int,
) -> PolystarShape {
  { pt, p, r, ir, ir_round, or, or_round, sy }
}

///|
pub struct Repeater {
  c : LottieProperty[Double] // Copies
  o : LottieProperty[Double] // Offset
  m : Int // Composite: 1=Above, 2=Below
  tr : Transform // Transform
}

///|
pub fn Repeater::new(
  c~ : LottieProperty[Double],
  o~ : LottieProperty[Double],
  m? : Int = 1,
  tr~ : Transform,
) -> Repeater {
  { c, o, m, tr }
}

///|
pub enum MergeMode {
  Merge
  Add
  Subtract
  Intersect
  Exclude
}

///|
pub struct MergePaths {
  mm : MergeMode
}

///|
pub fn MergePaths::new(mm : Int) -> MergePaths {
  let mode = match mm {
    1 => MergeMode::Merge
    2 => MergeMode::Add
    3 => MergeMode::Subtract
    4 => MergeMode::Intersect
    5 => MergeMode::Exclude
    _ => MergeMode::Merge
  }
  { mm: mode }
}

///|
pub struct Rounding {
  r : LottieProperty[Double]
}

///|
pub fn Rounding::new(r~ : LottieProperty[Double]) -> Rounding {
  { r, }
}
