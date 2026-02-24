pub enum BezierValue {
  Single(Double)
  Multi(Array[Double])
}

pub struct Bezier {
  pub x : BezierValue
  pub y : BezierValue
}

pub struct LottieKeyframe[T] {
  pub frame : Int
  pub start_value : T
  pub in_tangent : Bezier?
  pub out_tangent : Bezier?
  pub value_in_tangent : Array[Double]?
  pub value_out_tangent : Array[Double]?
  pub hold : Int?
}

pub enum PropertyValue[T] {
  Static(T)
  Animated(Array[LottieKeyframe[T]])
}

pub struct LottieProperty[T] {
  pub animated : Int
  pub value : PropertyValue[T]
  pub expression : String?
}

pub fn LottieProperty::new_static[T](value : T) -> LottieProperty[T] {
  { animated: 0, value: PropertyValue::Static(value), expression: None }
}

pub fn LottieProperty::new_animated[T](
  keyframes : Array[LottieKeyframe[T]]
) -> LottieProperty[T] {
  { animated: 1, value: PropertyValue::Animated(keyframes), expression: None }
}
