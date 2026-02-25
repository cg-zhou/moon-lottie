pub enum ShapeData {
  Group(Array[Shape])
  Rect(RectShape)
  Ellipse(EllipseShape)
  Path(PathShape)
  Fill(FillShape)
  Stroke(StrokeShape)
  Transform(Transform)
}

pub fn ShapeData::new_group(items : Array[Shape]) -> ShapeData {
  ShapeData::Group(items)
}

pub fn ShapeData::new_rect(rect : RectShape) -> ShapeData {
  ShapeData::Rect(rect)
}

pub fn ShapeData::new_ellipse(ellipse : EllipseShape) -> ShapeData {
  ShapeData::Ellipse(ellipse)
}

pub fn ShapeData::new_path(path : PathShape) -> ShapeData {
  ShapeData::Path(path)
}

pub fn ShapeData::new_fill(fill : FillShape) -> ShapeData {
  ShapeData::Fill(fill)
}

pub fn ShapeData::new_stroke(stroke : StrokeShape) -> ShapeData {
  ShapeData::Stroke(stroke)
}

pub fn ShapeData::new_transform(transform : Transform) -> ShapeData {
  ShapeData::Transform(transform)
}

pub struct Shape {
  nm : String?
  ty : String
  d : Int?
  hd : Bool?
  data : ShapeData
}

pub fn Shape::new(
  ty~ : String,
  data~ : ShapeData,
  nm~ : String? = None,
  d~ : Int? = None,
  hd~ : Bool? = None
) -> Shape {
  { nm, ty, d, hd, data }
}

pub struct RectShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
  r : LottieProperty[Double]        // Roundness
}

pub fn RectShape::new(
  p~ : LottieProperty[Array[Double]],
  s~ : LottieProperty[Array[Double]],
  r~ : LottieProperty[Double]
) -> RectShape {
  { p, s, r }
}

pub struct EllipseShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
}

pub fn EllipseShape::new(
  p~ : LottieProperty[Array[Double]],
  s~ : LottieProperty[Array[Double]]
) -> EllipseShape {
  { p, s }
}

pub struct PathShape {
  ks : LottieProperty[BezierPath]
}

pub fn PathShape::new(ks~ : LottieProperty[BezierPath]) -> PathShape {
  { ks }
}

pub struct BezierPath {
  v : Array[Array[Double]] // Vertices
  i : Array[Array[Double]] // In tangents
  o : Array[Array[Double]] // Out tangents
  c : Bool                // Closed
}

pub fn BezierPath::new(
  v~ : Array[Array[Double]],
  i~ : Array[Array[Double]],
  o~ : Array[Array[Double]],
  c~ : Bool
) -> BezierPath {
  { v, i, o, c }
}

pub struct FillShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double]        // Opacity
}

pub fn FillShape::new(
  c~ : LottieProperty[Array[Double]],
  o~ : LottieProperty[Double]
) -> FillShape {
  { c, o }
}

pub struct StrokeShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double]        // Opacity
  w : LottieProperty[Double]        // Width
}

pub fn StrokeShape::new(
  c~ : LottieProperty[Array[Double]],
  o~ : LottieProperty[Double],
  w~ : LottieProperty[Double]
) -> StrokeShape {
  { c, o, w }
}
