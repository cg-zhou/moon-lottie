///|
pub(all) enum MaskMode {
  Add
  Subtract
  Intersect
  Lighten
  Darken
  Difference
  None
} derive(Show, Eq)

///|
pub struct Mask {
  name : String?
  inverted : Bool
  path : LottieProperty[BezierPath]
  opacity : LottieProperty[Double]
  mode : MaskMode
}

///|
pub fn Mask::new(
  inverted~ : Bool,
  path~ : LottieProperty[BezierPath],
  opacity~ : LottieProperty[Double],
  mode~ : MaskMode,
  name? : String? = None,
) -> Mask {
  { name, inverted, path, opacity, mode }
}
