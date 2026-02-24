pub enum ShapeData {
  Group(Array[Shape])
  Rect(RectShape)
  Ellipse(EllipseShape)
  Path(PathShape)
  Fill(FillShape)
  Stroke(StrokeShape)
  Transform(Transform)
}

pub struct Shape {
  nm : String?
  ty : String
  d : Int?
  data : ShapeData
}

pub struct RectShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
  r : LottieProperty[Double]        // Roundness
}

pub struct EllipseShape {
  p : LottieProperty[Array[Double]] // Position
  s : LottieProperty[Array[Double]] // Size
}

pub struct PathShape {
  ks : LottieProperty[BezierPath]
}

pub struct BezierPath {
  v : Array[Array[Double]] // Vertices
  i : Array[Array[Double]] // In tangents
  o : Array[Array[Double]] // Out tangents
  c : Bool                // Closed
}

pub struct FillShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double]        // Opacity
}

pub struct StrokeShape {
  c : LottieProperty[Array[Double]] // Color
  o : LottieProperty[Double]        // Opacity
  w : LottieProperty[Double]        // Width
}
