///|
pub struct Transform {
  anchor : LottieProperty[Array[Double]]
  position : LottieProperty[Array[Double]]
  px : LottieProperty[Double]? // Split X
  py : LottieProperty[Double]? // Split Y
  s : Bool? // Split components
  scale : LottieProperty[Array[Double]]
  rotation : LottieProperty[Double]
  opacity : LottieProperty[Double]
  skew : LottieProperty[Double]?
  skew_axis : LottieProperty[Double]?
}

///|
pub fn Transform::new(
  anchor~ : LottieProperty[Array[Double]],
  position~ : LottieProperty[Array[Double]],
  scale~ : LottieProperty[Array[Double]],
  rotation~ : LottieProperty[Double],
  opacity~ : LottieProperty[Double],
  px? : LottieProperty[Double]? = None,
  py? : LottieProperty[Double]? = None,
  s? : Bool? = None,
  skew? : LottieProperty[Double]? = None,
  skew_axis? : LottieProperty[Double]? = None,
) -> Transform {
  { anchor, position, px, py, s, scale, rotation, opacity, skew, skew_axis }
}

///|
pub fn Transform::new_default() -> Transform {
  {
    anchor: LottieProperty::new_static([0.0, 0.0]),
    position: LottieProperty::new_static([0.0, 0.0]),
    px: None,
    py: None,
    s: None,
    scale: LottieProperty::new_static([100.0, 100.0]),
    rotation: LottieProperty::new_static(0.0),
    opacity: LottieProperty::new_static(100.0),
    skew: None,
    skew_axis: None,
  }
}
