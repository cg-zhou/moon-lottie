///|
pub fn point_on_cubic_bezier(
  p0 : Vector2,
  p1 : Vector2,
  p2 : Vector2,
  p3 : Vector2,
  t : Double,
) -> Vector2 {
  let t1 = 1.0 - t
  let t1_2 = t1 * t1
  let t1_3 = t1_2 * t1
  let t_2 = t * t
  let t_3 = t_2 * t

  // B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
  let x = t1_3 * p0.x +
    3.0 * t1_2 * t * p1.x +
    3.0 * t1 * t_2 * p2.x +
    t_3 * p3.x
  let y = t1_3 * p0.y +
    3.0 * t1_2 * t * p1.y +
    3.0 * t1 * t_2 * p2.y +
    t_3 * p3.y
  { x, y }
}

///|
pub fn get_cubic_bezier_length(
  p0 : Vector2,
  p1 : Vector2,
  p2 : Vector2,
  p3 : Vector2,
  intervals : Int,
) -> Double {
  let mut length = 0.0
  let mut prev_pt = p0
  for i = 1; i <= intervals; i = i + 1 {
    let t = i.to_double() / intervals.to_double()
    let pt = point_on_cubic_bezier(p0, p1, p2, p3, t)
    let dx = pt.x - prev_pt.x
    let dy = pt.y - prev_pt.y
    length = length + (dx * dx + dy * dy).sqrt()
    prev_pt = pt
  }
  length
}

///|
pub fn split_cubic_bezier(
  p0 : Vector2,
  p1 : Vector2,
  p2 : Vector2,
  p3 : Vector2,
  t : Double,
) -> (Vector2, Vector2, Vector2, Vector2, Vector2, Vector2, Vector2) {
  let p01 = Vector2::new(p0.x + (p1.x - p0.x) * t, p0.y + (p1.y - p0.y) * t)
  let p12 = Vector2::new(p1.x + (p2.x - p1.x) * t, p1.y + (p2.y - p1.y) * t)
  let p23 = Vector2::new(p2.x + (p3.x - p2.x) * t, p2.y + (p3.y - p2.y) * t)
  let p012 = Vector2::new(
    p01.x + (p12.x - p01.x) * t,
    p01.y + (p12.y - p01.y) * t,
  )
  let p123 = Vector2::new(
    p12.x + (p23.x - p12.x) * t,
    p12.y + (p23.y - p12.y) * t,
  )
  let p0123 = Vector2::new(
    p012.x + (p123.x - p012.x) * t,
    p012.y + (p123.y - p012.y) * t,
  )
  (p0, p01, p012, p0123, p123, p23, p3)
}
