pub enum BezierValue {
  Single(Double)
  Multi(Array[Double])
}

pub struct Bezier {
  x : BezierValue
  y : BezierValue
}

pub struct LottieKeyframe[T] {
  frame : Int
  start_value : T
  in_tangent : Bezier?
  out_tangent : Bezier?
  value_in_tangent : Array[Double]?
  value_out_tangent : Array[Double]?
  hold : Int?
}

pub enum PropertyValue[T] {
  Static(T)
  Animated(Array[LottieKeyframe[T]])
}

pub struct LottieProperty[T] {
  animated : Int
  value : PropertyValue[T]
  expression : String?
}

pub fn LottieProperty::new_static[T](value : T) -> LottieProperty[T] {
  { animated: 0, value: PropertyValue::Static(value), expression: None }
}

pub fn LottieProperty::new_animated[T](
  keyframes : Array[LottieKeyframe[T]]
) -> LottieProperty[T] {
  { animated: 1, value: PropertyValue::Animated(keyframes), expression: None }
}
