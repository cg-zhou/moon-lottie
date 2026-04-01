///|
pub fn lerp_double(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
pub fn lerp_array(
  a : Array[Double],
  b : Array[Double],
  t : Double,
) -> Array[Double] {
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  let res = []
  for i = 0; i < len; i = i + 1 {
    res.push(a[i] + (b[i] - a[i]) * t)
  }
  res
}

///|
pub fn lerp_vec2_array(
  a : Array[Array[Double]],
  b : Array[Array[Double]],
  t : Double,
) -> Array[Array[Double]] {
  // Same tolerant zip semantics as lottie-rs Vec<Bezier>::lerp:
  // interpolate pairwise items only up to the common outer/inner lengths.
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  let res = []
  for i = 0; i < len; i = i + 1 {
    res.push(lerp_array(a[i], b[i], t))
  }
  res
}

///| Lottie Cubic Bezier Easing Solver

///| Lottie easing uses a cubic bezier where P0=(0,0), P3=(1,1)

///| P1 and P2 are defined by 'o' and 'i' tangents.

///|
/// We need to find t such that BezierX(t) = target_x, then return BezierY(t).
pub fn solve_cubic_bezier_easing(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  target_x : Double,
) -> Double {
  if target_x <= 0.0 {
    return 0.0
  }
  if target_x >= 1.0 {
    return 1.0
  }

  let safe_x1 = if x1 < 0.0 { 0.0 } else if x1 > 1.0 { 1.0 } else { x1 }
  let safe_x2 = if x2 < 0.0 { 0.0 } else if x2 > 1.0 { 1.0 } else { x2 }
  let easing = @bezier_easing.bezier(safe_x1, y1, safe_x2, y2)
  easing(target_x)
}
