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
  pub nm : String?
  pub ty : String
  pub d : Int?
  pub data : ShapeData
}

pub struct RectShape {
  pub p : LottieProperty[Array[Double]] // Position
  pub s : LottieProperty[Array[Double]] // Size
  pub r : LottieProperty[Double]        // Roundness
}

pub struct EllipseShape {
  pub p : LottieProperty[Array[Double]] // Position
  pub s : LottieProperty[Array[Double]] // Size
}

pub struct PathShape {
  pub ks : LottieProperty[BezierPath]
}

pub struct BezierPath {
  pub v : Array[Array[Double]] // Vertices
  pub i : Array[Array[Double]] // In tangents
  pub o : Array[Array[Double]] // Out tangents
  pub c : Bool                // Closed
}

pub struct FillShape {
  pub c : LottieProperty[Array[Double]] // Color
  pub o : LottieProperty[Double]        // Opacity
}

pub struct StrokeShape {
  pub c : LottieProperty[Array[Double]] // Color
  pub o : LottieProperty[Double]        // Opacity
  pub w : LottieProperty[Double]        // Width
}
