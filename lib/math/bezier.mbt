pub fn point_on_cubic_bezier(
  p0 : Vector2,
  p1 : Vector2,
  p2 : Vector2,
  p3 : Vector2,
  t : Double
) -> Vector2 {
  let t1 = 1.0 - t
  let t1_2 = t1 * t1
  let t1_3 = t1_2 * t1
  let t_2 = t * t
  let t_3 = t_2 * t
  
  // B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
  let x = t1_3 * p0.x + 3.0 * t1_2 * t * p1.x + 3.0 * t1 * t_2 * p2.x + t_3 * p3.x
  let y = t1_3 * p0.y + 3.0 * t1_2 * t * p1.y + 3.0 * t1 * t_2 * p2.y + t_3 * p3.y
  { x, y }
}

pub fn get_cubic_bezier_length(
  p0 : Vector2,
  p1 : Vector2,
  p2 : Vector2,
  p3 : Vector2,
  intervals : Int
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
