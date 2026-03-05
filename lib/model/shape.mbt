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
  name : String?
  shape_type : String
  direction : Int?
  hidden : Bool?
  data : ShapeData
}

///|
pub fn Shape::new(
  shape_type~ : String,
  data~ : ShapeData,
  name? : String? = None,
  direction? : Int? = None,
  hidden? : Bool? = None,
) -> Shape {
  { name, shape_type, direction, hidden, data }
}

///|
pub struct RectShape {
  position : LottieProperty[Array[Double]]
  size : LottieProperty[Array[Double]]
  roundness : LottieProperty[Double]
}

///|
pub fn RectShape::new(
  position~ : LottieProperty[Array[Double]],
  size~ : LottieProperty[Array[Double]],
  roundness~ : LottieProperty[Double],
) -> RectShape {
  { position, size, roundness }
}

///|
pub struct EllipseShape {
  position : LottieProperty[Array[Double]]
  size : LottieProperty[Array[Double]]
}

///|
pub fn EllipseShape::new(
  position~ : LottieProperty[Array[Double]],
  size~ : LottieProperty[Array[Double]],
) -> EllipseShape {
  { position, size }
}

///|
pub struct PathShape {
  path : LottieProperty[BezierPath]
}

///|
pub fn PathShape::new(path~ : LottieProperty[BezierPath]) -> PathShape {
  { path, }
}

///|
pub struct BezierPath {
  vertices : Array[Array[Double]]
  in_tangents : Array[Array[Double]]
  out_tangents : Array[Array[Double]]
  closed : Bool
}

///|
pub fn BezierPath::new(
  vertices~ : Array[Array[Double]],
  in_tangents~ : Array[Array[Double]],
  out_tangents~ : Array[Array[Double]],
  closed~ : Bool,
) -> BezierPath {
  { vertices, in_tangents, out_tangents, closed }
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
    vertices=[[x - hw, y - hh], [x + hw, y - hh], [x + hw, y + hh], [x - hw, y + hh]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    closed=true,
  )
}

///|
pub struct FillShape {
  color : LottieProperty[Array[Double]]
  opacity : LottieProperty[Double]
}

///|
pub fn FillShape::new(
  color~ : LottieProperty[Array[Double]],
  opacity~ : LottieProperty[Double],
) -> FillShape {
  { color, opacity }
}

///|
pub struct DashItem {
  name : String
  value : LottieProperty[Double]
}

///|
pub fn DashItem::new(
  name~ : String,
  value~ : LottieProperty[Double],
) -> DashItem {
  { name, value }
}

///|
pub struct StrokeShape {
  color : LottieProperty[Array[Double]]
  opacity : LottieProperty[Double]
  width : LottieProperty[Double]
  line_cap : Int
  line_join : Int
  miter_limit : Double
  dashes : Array[DashItem]
}

///|
pub fn StrokeShape::new(
  color~ : LottieProperty[Array[Double]],
  opacity~ : LottieProperty[Double],
  width~ : LottieProperty[Double],
  line_cap? : Int = 1,
  line_join? : Int = 1,
  miter_limit? : Double = 0.0,
  dashes? : Array[DashItem] = [],
) -> StrokeShape {
  { color, opacity, width, line_cap, line_join, miter_limit, dashes }
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
  color_count : Int
  color_stops : LottieProperty[Array[Double]]
}

///|
pub fn GradientColors::new(
  color_count~ : Int,
  color_stops~ : LottieProperty[Array[Double]],
) -> GradientColors {
  { color_count, color_stops }
}

///|
pub struct GradientFillShape {
  gradient_type : GradientType
  opacity : LottieProperty[Double]
  start_point : LottieProperty[Array[Double]]
  end_point : LottieProperty[Array[Double]]
  gradient_colors : GradientColors
}

///|
pub fn GradientFillShape::new(
  gradient_type~ : Int,
  opacity~ : LottieProperty[Double],
  start_point~ : LottieProperty[Array[Double]],
  end_point~ : LottieProperty[Array[Double]],
  gradient_colors~ : GradientColors,
) -> GradientFillShape {
  let ty = GradientType::from_int(gradient_type)
  { gradient_type: ty, opacity, start_point, end_point, gradient_colors }
}

///|
pub struct GradientStrokeShape {
  gradient_type : GradientType
  opacity : LottieProperty[Double]
  start_point : LottieProperty[Array[Double]]
  end_point : LottieProperty[Array[Double]]
  gradient_colors : GradientColors
  width : LottieProperty[Double]
  line_cap : Int
  line_join : Int
  miter_limit : Double
  dashes : Array[DashItem]
}

///|
pub fn GradientStrokeShape::new(
  gradient_type~ : Int,
  opacity~ : LottieProperty[Double],
  start_point~ : LottieProperty[Array[Double]],
  end_point~ : LottieProperty[Array[Double]],
  gradient_colors~ : GradientColors,
  width~ : LottieProperty[Double],
  line_cap? : Int = 1,
  line_join? : Int = 1,
  miter_limit? : Double = 0.0,
  dashes? : Array[DashItem] = [],
) -> GradientStrokeShape {
  let ty = GradientType::from_int(gradient_type)
  {
    gradient_type: ty,
    opacity,
    start_point,
    end_point,
    gradient_colors,
    width,
    line_cap,
    line_join,
    miter_limit,
    dashes,
  }
}

///|
pub struct TrimPath {
  start : LottieProperty[Double]
  end : LottieProperty[Double]
  offset : LottieProperty[Double]
  multiple : Int
}

///|
pub fn TrimPath::new(
  start~ : LottieProperty[Double],
  end~ : LottieProperty[Double],
  offset~ : LottieProperty[Double],
  multiple? : Int = 1,
) -> TrimPath {
  { start, end, offset, multiple }
}

///|
pub struct PolystarShape {
  points : LottieProperty[Double]
  position : LottieProperty[Array[Double]]
  rotation : LottieProperty[Double]
  inner_radius : LottieProperty[Double]
  inner_roundness : LottieProperty[Double]
  outer_radius : LottieProperty[Double]
  outer_roundness : LottieProperty[Double]
  star_type : Int
}

///|
pub fn PolystarShape::new(
  points~ : LottieProperty[Double],
  position~ : LottieProperty[Array[Double]],
  rotation~ : LottieProperty[Double],
  inner_radius~ : LottieProperty[Double],
  inner_roundness~ : LottieProperty[Double],
  outer_radius~ : LottieProperty[Double],
  outer_roundness~ : LottieProperty[Double],
  star_type~ : Int,
) -> PolystarShape {
  {
    points,
    position,
    rotation,
    inner_radius,
    inner_roundness,
    outer_radius,
    outer_roundness,
    star_type,
  }
}

///|
pub struct Repeater {
  copies : LottieProperty[Double]
  offset : LottieProperty[Double]
  composite : Int
  transform : Transform
  start_opacity : LottieProperty[Double]
  end_opacity : LottieProperty[Double]
}

///|
pub fn Repeater::new(
  copies~ : LottieProperty[Double],
  offset~ : LottieProperty[Double],
  composite? : Int = 1,
  transform~ : Transform,
  start_opacity? : LottieProperty[Double] = LottieProperty::new_static(100.0),
  end_opacity? : LottieProperty[Double] = LottieProperty::new_static(100.0),
) -> Repeater {
  { copies, offset, composite, transform, start_opacity, end_opacity }
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
  merge_mode : MergeMode
}

///|
pub fn MergePaths::new(merge_mode : Int) -> MergePaths {
  let mode = match merge_mode {
    1 => MergeMode::Merge
    2 => MergeMode::Add
    3 => MergeMode::Subtract
    4 => MergeMode::Intersect
    5 => MergeMode::Exclude
    _ => MergeMode::Merge
  }
  { merge_mode: mode }
}

///|
pub struct Rounding {
  radius : LottieProperty[Double]
}

///|
pub fn Rounding::new(radius~ : LottieProperty[Double]) -> Rounding {
  { radius, }
}
