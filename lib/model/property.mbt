///|
pub enum BezierValue {
  Single(Double)
  Multi(Array[Double])
}

///|
pub fn BezierValue::new_single(v : Double) -> BezierValue {
  BezierValue::Single(v)
}

///|
pub fn BezierValue::new_multi(v : Array[Double]) -> BezierValue {
  BezierValue::Multi(v)
}

///|
pub struct Bezier {
  x : BezierValue
  y : BezierValue
}

///|
pub fn Bezier::new(x : BezierValue, y : BezierValue) -> Bezier {
  { x, y }
}

///|
pub struct LottieKeyframe[T] {
  frame : Int
  start_value : T
  end_value : T?
  in_tangent : Bezier?
  out_tangent : Bezier?
  value_in_tangent : Array[Double]?
  value_out_tangent : Array[Double]?
  hold : Int?
}

///|
pub fn[T] LottieKeyframe::new(
  frame~ : Int,
  start_value~ : T,
  end_value? : T? = None,
  in_tangent? : Bezier? = None,
  out_tangent? : Bezier? = None,
  value_in_tangent? : Array[Double]? = None,
  value_out_tangent? : Array[Double]? = None,
  hold? : Int? = None,
) -> LottieKeyframe[T] {
  {
    frame,
    start_value,
    end_value,
    in_tangent,
    out_tangent,
    value_in_tangent,
    value_out_tangent,
    hold,
  }
}

///|
pub enum PropertyValue[T] {
  Static(T)
  Animated(Array[LottieKeyframe[T]])
}

///|
pub struct LottieProperty[T] {
  animated : Int
  value : PropertyValue[T]
  expression : String?
}

///|
pub fn[T] LottieProperty::new_static(value : T) -> LottieProperty[T] {
  { animated: 0, value: PropertyValue::Static(value), expression: None }
}

///|
pub fn[T] LottieProperty::new_animated(
  keyframes : Array[LottieKeyframe[T]],
) -> LottieProperty[T] {
  { animated: 1, value: PropertyValue::Animated(keyframes), expression: None }
}
