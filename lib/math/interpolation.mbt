pub fn lerp_double(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

pub fn lerp_array(a : Array[Double], b : Array[Double], t : Double) -> Array[Double] {
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  let res = []
  for i = 0; i < len; i = i + 1 {
    res.push(a[i] + (b[i] - a[i]) * t)
  }
  res
}

///| Lottie Cubic Bezier Easing Solver
///| Lottie easing uses a cubic bezier where P0=(0,0), P3=(1,1)
///| P1 and P2 are defined by 'o' and 'i' tangents.
///| We need to find t such that BezierX(t) = target_x, then return BezierY(t).
pub fn solve_cubic_bezier_easing(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  target_x : Double
) -> Double {
  if target_x <= 0.0 {
    return 0.0
  }
  if target_x >= 1.0 {
    return 1.0
  }

  // Binary search for t
  let mut low = 0.0
  let mut high = 1.0
  let mut t = 0.5
  
  for i = 0; i < 12; i = i + 1 {
    let x = sample_bezier(x1, x2, t)
    if (x - target_x).abs() < 0.001 {
      break
    }
    if x < target_x {
      low = t
    } else {
      high = t
    }
    t = (low + high) / 2.0
  }
  
  sample_bezier(y1, y2, t)
}

fn sample_bezier(p1 : Double, p2 : Double, t : Double) -> Double {
  let t1 = 1.0 - t
  // B(t) = 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3
  3.0 * t1 * t1 * t * p1 + 3.0 * t1 * t * t * p2 + t * t * t
}
