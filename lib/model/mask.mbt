pub(all) enum MaskMode {
  Add
  Subtract
  Intersect
  Lighten
  Darken
  Difference
  None
}

pub struct Mask {
  nm : String?
  inv : Bool
  pt : LottieProperty[BezierPath]
  o : LottieProperty[Double]
  mode : MaskMode
}

pub fn Mask::new(
  inv~ : Bool,
  pt~ : LottieProperty[BezierPath],
  o~ : LottieProperty[Double],
  mode~ : MaskMode,
  nm~ : String? = None
) -> Mask {
  { nm, inv, pt, o, mode }
}
