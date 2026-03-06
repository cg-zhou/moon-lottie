///|
/// Find the keyframe for a given frame
fn[T] find_keyframe(
  keyframes : Array[@model.LottieKeyframe[T]],
  frame : Double,
  expression? : String? = None,
) -> (Int, Double) {
  let len = keyframes.length()
  if len == 0 {
    return (-1, 0.0)
  }

  let mut f = frame

  // Simple loopOut('cycle') and loopOut('pingpong') support
  match expression {
    Some(e) =>
      if len > 1 && e.contains("loopOut") {
        let is_cycle = e.contains("cycle")
        let is_pingpong = e.contains("pingpong")
        if is_cycle || is_pingpong {
          let first = keyframes[0].frame
          let last = keyframes[len - 1].frame
          let duration = last - first
          if f > last && duration > 0.0 {
            let offset = f - first
            if is_cycle {
              f = first + (offset - (offset / duration).floor() * duration)
            } else if is_pingpong {
              let cycle = (offset / duration).floor().to_int()
              let t_in_cycle = offset - (offset / duration).floor() * duration
              if cycle % 2 == 1 {
                f = last - t_in_cycle
              } else {
                f = first + t_in_cycle
              }
            }
          }
        }
      }
    None => ()
  }

  if f <= keyframes[0].frame {
    return (0, 0.0)
  }

  if f >= keyframes[len - 1].frame {
    return (len - 1, 0.0)
  }

  for i = 0; i < len - 1; i = i + 1 {
    let k1 = keyframes[i]
    let k2 = keyframes[i + 1]
    if f >= k1.frame && f < k2.frame {
      let progress = (f - k1.frame) / (k2.frame - k1.frame)
      return (i, progress)
    }
  }

  (len - 1, 0.0)
}

///|
fn bezier_component(value : @model.BezierValue, index : Int) -> Double {
  match value {
    Single(v) => v
    Multi(arr) =>
      if index >= 0 && index < arr.length() {
        arr[index]
      } else if arr.length() > 0 {
        arr[0]
      } else {
        0.0
      }
  }
}

///|
fn bezier_value_length(value : @model.BezierValue) -> Int {
  match value {
    Single(_) => 1
    Multi(arr) => arr.length()
  }
}

///|
fn easing_component_index(
  out_tangent : @model.Bezier,
  in_tangent : @model.Bezier,
  component : Int,
) -> Int {
  let out_len = if bezier_value_length(out_tangent.x) > bezier_value_length(out_tangent.y) {
    bezier_value_length(out_tangent.x)
  } else {
    bezier_value_length(out_tangent.y)
  }
  let in_len = if bezier_value_length(in_tangent.x) > bezier_value_length(in_tangent.y) {
    bezier_value_length(in_tangent.x)
  } else {
    bezier_value_length(in_tangent.y)
  }
  let dims = if out_len > in_len { out_len } else { in_len }
  if dims <= 1 {
    0
  } else if component >= dims {
    dims - 1
  } else {
    component
  }
}

///|
fn solve_eased_t_for_component(
  out_tangent : @model.Bezier,
  in_tangent : @model.Bezier,
  t : Double,
  component : Int,
) -> Double {
  let idx = easing_component_index(out_tangent, in_tangent, component)
  let x1 = bezier_component(out_tangent.x, idx)
  let y1 = bezier_component(out_tangent.y, idx)
  let x2 = bezier_component(in_tangent.x, idx)
  let y2 = bezier_component(in_tangent.y, idx)
  @math.solve_cubic_bezier_easing(x1, y1, x2, y2, t)
}

///|
fn lerp_array_with_component_easing(
  a : Array[Double],
  b : Array[Double],
  out_tangent : @model.Bezier,
  in_tangent : @model.Bezier,
  t : Double,
) -> Array[Double] {
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  let res = []
  for i = 0; i < len; i = i + 1 {
    let eased_t = solve_eased_t_for_component(out_tangent, in_tangent, t, i)
    res.push(a[i] + (b[i] - a[i]) * eased_t)
  }
  res
}

///|
fn lerp_array_with_optional_component_easing(
  a : Array[Double],
  b : Array[Double],
  out_tangent : @model.Bezier?,
  in_tangent : @model.Bezier?,
  t : Double,
) -> Array[Double] {
  match (out_tangent, in_tangent) {
    (Some(ot), Some(it)) => lerp_array_with_component_easing(a, b, ot, it, t)
    _ => @math.lerp_array(a, b, t)
  }
}

///|
fn lerp_vec2_array_with_component_easing(
  a : Array[Array[Double]],
  b : Array[Array[Double]],
  out_tangent : @model.Bezier,
  in_tangent : @model.Bezier,
  t : Double,
) -> Array[Array[Double]] {
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  let res = []
  for i = 0; i < len; i = i + 1 {
    let inner_len = if a[i].length() < b[i].length() {
      a[i].length()
    } else {
      b[i].length()
    }
    let inner = []
    for j = 0; j < inner_len; j = j + 1 {
      let eased_t = solve_eased_t_for_component(out_tangent, in_tangent, t, j)
      inner.push(a[i][j] + (b[i][j] - a[i][j]) * eased_t)
    }
    res.push(inner)
  }
  res
}

///|
pub fn evaluate_text_document_property(
  prop : @model.LottieProperty[@model.TextDocument],
  frame : Double,
) -> @model.TextDocument {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, _t) = find_keyframe(
        keyframes,
        frame,
        expression=prop.expression,
      )
      if idx < 0 {
        // Return a dummy document
        return {
          size: 0.0,
          font: "",
          text: "",
          justify: 0,
          tracking: 0.0,
          line_height: 0.0,
          baseline_shift: 0.0,
          fill_color: [0.0, 0.0, 0.0],
        }
      }
      keyframes[idx].start_value
    }
  }
}

///|
pub fn evaluate_double_property(
  prop : @model.LottieProperty[Double],
  frame : Double,
) -> Double {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, t) = find_keyframe(keyframes, frame, expression=prop.expression)
      if idx < 0 {
        return 0.0
      }
      let k1 = keyframes[idx]
      if k1.hold == Some(1) {
        return k1.start_value
      }
      if t <= 0.0 || idx >= keyframes.length() - 1 {
        return k1.start_value
      }

      let k2 = keyframes[idx + 1]

      // Easing solve
      let eased_t = match (k1.out_tangent, k1.in_tangent) {
        (Some(ot), Some(it)) => solve_eased_t_for_component(ot, it, t, 0)
        _ => t
      }

      let next_val = match k1.end_value {
        Some(v) => v
        None => k2.start_value
      }
      @math.lerp_double(k1.start_value, next_val, eased_t)
    }
  }
}

///|
///|
/// Evaluate a spatial bezier keyframe using arc-length parameterization,
/// matching lottie-web's behavior. The eased progress `perc` is used as a
/// fraction of the total arc length along the bezier curve, then linearly
/// interpolated between sampled curve points.
fn evaluate_spatial_bezier_arc_length(
  start_val : Array[Double],
  end_val : Array[Double],
  to : Array[Double],
  ti : Array[Double],
  perc : Double,
) -> Array[Double] {
  let n = 150
  let len = start_val.length()
  // Build arc-length-sampled data: (point, partial_length_from_previous)
  let points : Array[(Array[Double], Double)] = []
  let mut last_point : Array[Double]? = None
  let mut total_length = 0.0
  for k = 0; k < n; k = k + 1 {
    let t = k.to_double() / (n - 1).to_double()
    let point = []
    let mut dist_sq = 0.0
    for i = 0; i < len; i = i + 1 {
      let p0 = start_val[i]
      let p3 = end_val[i]
      let p1 = p0 + (if i < to.length() { to[i] } else { 0.0 })
      let p2 = p3 + (if i < ti.length() { ti[i] } else { 0.0 })
      let coord = (1.0 - t) * (1.0 - t) * (1.0 - t) * p0 +
        3.0 * (1.0 - t) * (1.0 - t) * t * p1 +
        3.0 * (1.0 - t) * t * t * p2 +
        t * t * t * p3
      point.push(coord)
      match last_point {
        Some(lp) => {
          let diff = coord - lp[i]
          dist_sq += diff * diff
        }
        None => ()
      }
    }
    let partial_length = dist_sq.sqrt()
    total_length += partial_length
    points.push((point, partial_length))
    last_point = Some(point)
  }
  if perc <= 0.0 {
    return points[0].0
  }
  if perc >= 1.0 {
    return points[n - 1].0
  }
  let target = total_length * perc
  let mut added_length = 0.0
  for j = 0; j < n - 1; j = j + 1 {
    added_length += points[j].1
    if target == 0.0 {
      return points[j].0
    }
    let next_partial = points[j + 1].1
    if target >= added_length && target < added_length + next_partial {
      let segment_perc = if next_partial > 0.0 {
        (target - added_length) / next_partial
      } else {
        0.0
      }
      let result = []
      for k = 0; k < len; k = k + 1 {
        result.push(
          points[j].0[k] +
          (points[j + 1].0[k] - points[j].0[k]) * segment_perc,
        )
      }
      return result
    }
  }
  points[n - 1].0
}

///|
pub fn evaluate_vec_property(
  prop : @model.LottieProperty[Array[Double]],
  frame : Double,
) -> Array[Double] {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, t) = find_keyframe(keyframes, frame, expression=prop.expression)
      if idx < 0 {
        return []
      }
      let k1 = keyframes[idx]
      if k1.hold == Some(1) {
        return k1.start_value
      }
      if t <= 0.0 || idx >= keyframes.length() - 1 {
        return k1.start_value
      }

      let k2 = keyframes[idx + 1]

      let next_val = match k1.end_value {
        Some(v) => v
        None => k2.start_value
      }

      match (k1.out_tangent, k1.in_tangent, k1.value_out_tangent, k1.value_in_tangent) {
        (_, _, Some(to), Some(ti)) =>
          if k1.start_value.length() >= 2 &&
            next_val.length() >= 2 &&
            to.length() >= 2 &&
            ti.length() >= 2 {
            // Apply temporal easing first (if temporal handles are present),
            // then use arc-length parameterization for the spatial bezier,
            // matching lottie-web's behavior.
            let eased_t = match (k1.out_tangent, k1.in_tangent) {
              (Some(ot), Some(it)) =>
                solve_eased_t_for_component(ot, it, t, 0)
              _ => t
            }
            evaluate_spatial_bezier_arc_length(
              k1.start_value,
              next_val,
              to,
              ti,
              eased_t,
            )
          } else {
            lerp_array_with_optional_component_easing(
              k1.start_value,
              next_val,
              k1.out_tangent,
              k1.in_tangent,
              t,
            )
          }
        (_, _, _, _) =>
          lerp_array_with_optional_component_easing(
            k1.start_value,
            next_val,
            k1.out_tangent,
            k1.in_tangent,
            t,
          )
      }
    }
  }
}

///|
pub fn evaluate_path_property(
  prop : @model.LottieProperty[@model.BezierPath],
  frame : Double,
) -> @model.BezierPath {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, t) = find_keyframe(keyframes, frame, expression=prop.expression)
      if idx < 0 {
        return @model.BezierPath::new(vertices=[], in_tangents=[], out_tangents=[], closed=false)
      }
      let kf = keyframes[idx]
      if kf.hold == Some(1) {
        return kf.start_value
      }
      if t <= 0.0 {
        return kf.start_value
      }

      let next_val = match kf.end_value {
        Some(v) => v
        None => return kf.start_value
      }

      let eased_t = match (kf.out_tangent, kf.in_tangent) {
        (Some(ot), Some(it)) => solve_eased_t_for_component(ot, it, t, 0)
        _ => t
      }

      if eased_t >= 1.0 {
        return next_val
      }

      // Path interpolation
      let start_v = kf.start_value.vertices
      let end_v = next_val.vertices
      if start_v.length() != end_v.length() {
        return kf.start_value
      }

      let (res_v, res_i, res_o) = match (kf.out_tangent, kf.in_tangent) {
        (Some(ot), Some(it)) => (
          lerp_vec2_array_with_component_easing(start_v, end_v, ot, it, t),
          lerp_vec2_array_with_component_easing(
            kf.start_value.in_tangents,
            next_val.in_tangents,
            ot,
            it,
            t,
          ),
          lerp_vec2_array_with_component_easing(
            kf.start_value.out_tangents,
            next_val.out_tangents,
            ot,
            it,
            t,
          ),
        )
        _ => (
          @math.lerp_vec2_array(start_v, end_v, eased_t),
          @math.lerp_vec2_array(kf.start_value.in_tangents, next_val.in_tangents, eased_t),
          @math.lerp_vec2_array(kf.start_value.out_tangents, next_val.out_tangents, eased_t),
        )
      }
      @model.BezierPath::new(vertices=res_v, in_tangents=res_i, out_tangents=res_o, closed=kf.start_value.closed)
    }
  }
}

///|
pub fn evaluate_transform(
  transform : @model.Transform,
  frame : Double,
) -> @math.Matrix {
  let a = evaluate_vec_property(transform.anchor, frame)
  let p = if transform.split == Some(true) {
    let x = match transform.px {
      Some(prop) => evaluate_double_property(prop, frame)
      None => 0.0
    }
    let y = match transform.py {
      Some(prop) => evaluate_double_property(prop, frame)
      None => 0.0
    }
    [x, y]
  } else {
    evaluate_vec_property(transform.position, frame)
  }
  let s = evaluate_vec_property(transform.scale, frame)
  let r = evaluate_double_property(transform.rotation, frame)

  // Matrix transform construction
  let m = @math.Matrix::identity()

  // Safely get components
  let ax = if a.length() > 0 { a[0] } else { 0.0 }
  let ay = if a.length() > 1 { a[1] } else { 0.0 }

  let px = if p.length() > 0 { p[0] } else { 0.0 }
  let py = if p.length() > 1 { p[1] } else { 0.0 }

  let sx = if s.length() > 0 { s[0] } else { 100.0 }
  let sy = if s.length() > 1 { s[1] } else { 100.0 }

  // 1. Translate to position
  let m1 = m.translate(px, py)

  // 2. Rotate
  let m2 = m1.rotate(r * 3.141592653589793 / 180.0)

  // 3. Scale
  let m3 = m2.scale(sx / 100.0, sy / 100.0)

  // 4. Anchor offset
  m3.translate(-ax, -ay)
}
