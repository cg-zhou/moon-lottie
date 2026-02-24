pub struct Transform {
  anchor : LottieProperty[Array[Double]]
  position : LottieProperty[Array[Double]]
  scale : LottieProperty[Array[Double]]
  rotation : LottieProperty[Double]
  opacity : LottieProperty[Double]
  skew : LottieProperty[Double]?
  skew_axis : LottieProperty[Double]?
}

pub fn Transform::new(
  anchor~ : LottieProperty[Array[Double]],
  position~ : LottieProperty[Array[Double]],
  scale~ : LottieProperty[Array[Double]],
  rotation~ : LottieProperty[Double],
  opacity~ : LottieProperty[Double],
  skew? : LottieProperty[Double],
  skew_axis? : LottieProperty[Double]
) -> Transform {
  { anchor, position, scale, rotation, opacity, skew, skew_axis }
}
