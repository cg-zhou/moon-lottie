///|
/// Find the keyframe for a given frame
fn[T] find_keyframe(
  keyframes : Array[@model.LottieKeyframe[T]],
  frame : Double,
) -> (Int, Double) {
  let len = keyframes.length()
  if len == 0 {
    return (-1, 0.0)
  }

  if frame <= keyframes[0].frame.to_double() {
    return (0, 0.0)
  }

  if frame >= keyframes[len - 1].frame.to_double() {
    return (len - 1, 0.0)
  }

  for i = 0; i < len - 1; i = i + 1 {
    let k1 = keyframes[i]
    let k2 = keyframes[i + 1]
    if frame >= k1.frame.to_double() && frame < k2.frame.to_double() {
      let progress = (frame - k1.frame.to_double()) /
        (k2.frame.to_double() - k1.frame.to_double())
      return (i, progress)
    }
  }

  (len - 1, 0.0)
}

///|
pub fn evaluate_text_document_property(
  prop : @model.LottieProperty[@model.TextDocument],
  frame : Double,
) -> @model.TextDocument {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, _t) = find_keyframe(keyframes, frame)
      if idx < 0 {
        // Return a dummy document
        return {
          s: 0.0,
          f: "",
          t: "",
          j: 0,
          tr: 0.0,
          lh: 0.0,
          ls: 0.0,
          fc: [0.0, 0.0, 0.0],
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
      let (idx, t) = find_keyframe(keyframes, frame)
      if idx < 0 {
        return 0.0
      }
      let k1 = keyframes[idx]
      if t <= 0.0 || idx >= keyframes.length() - 1 {
        return k1.start_value
      }

      let k2 = keyframes[idx + 1]

      // Easing solve
      let eased_t = match (k1.out_tangent, k1.in_tangent) {
        (Some(ot), Some(it)) => {
          let x1 = match ot.x {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let y1 = match ot.y {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let x2 = match it.x {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let y2 = match it.y {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          @math.solve_cubic_bezier_easing(x1, y1, x2, y2, t)
        }
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
pub fn evaluate_vec_property(
  prop : @model.LottieProperty[Array[Double]],
  frame : Double,
) -> Array[Double] {
  match prop.value {
    Static(v) => v
    Animated(keyframes) => {
      let (idx, t) = find_keyframe(keyframes, frame)
      if idx < 0 {
        return []
      }
      let k1 = keyframes[idx]
      if t <= 0.0 || idx >= keyframes.length() - 1 {
        return k1.start_value
      }

      let k2 = keyframes[idx + 1]

      // For simplicity, we use the first component of the tangents for multidimensional easing
      // Lottie can have multidimensional easing but it's often synchronized.
      let eased_t = match (k1.out_tangent, k1.in_tangent) {
        (Some(ot), Some(it)) => {
          let x1 = match ot.x {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let y1 = match ot.y {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let x2 = match it.x {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          let y2 = match it.y {
            Single(v) => v
            Multi(arr) => arr[0]
          }
          @math.solve_cubic_bezier_easing(x1, y1, x2, y2, t)
        }
        _ => t
      }

      let next_val = match k1.end_value {
        Some(v) => v
        None => k2.start_value
      }

      match (k1.value_out_tangent, k1.value_in_tangent) {
        (Some(to), Some(ti)) =>
          if k1.start_value.length() >= 2 &&
            next_val.length() >= 2 &&
            to.length() >= 2 &&
            ti.length() >= 2 {
            let res = []
            for i = 0; i < k1.start_value.length(); i = i + 1 {
              let p0 = k1.start_value[i]
              let p3 = next_val[i]
              // Check if tangents have the component. If not, fallback to p0/p3.
              let p1 = if i < to.length() { p0 + to[i] } else { p0 }
              let p2 = if i < ti.length() { p3 + ti[i] } else { p3 }
              let val = (1.0 - eased_t) * (1.0 - eased_t) * (1.0 - eased_t) * p0 +
                3.0 * (1.0 - eased_t) * (1.0 - eased_t) * eased_t * p1 +
                3.0 * (1.0 - eased_t) * eased_t * eased_t * p2 +
                eased_t * eased_t * eased_t * p3
              res.push(val)
            }
            res
          } else {
            @math.lerp_array(k1.start_value, next_val, eased_t)
          }
        _ => @math.lerp_array(k1.start_value, next_val, eased_t)
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
      let (idx, t) = find_keyframe(keyframes, frame)
      if idx < 0 {
        return @model.BezierPath::new(v=[], i=[], o=[], c=false)
      }
      let kf = keyframes[idx]
      if t <= 0.0 {
        return kf.start_value
      }

      let next_val = match kf.end_value {
        Some(v) => v
        None => return kf.start_value
      }

      if t >= 1.0 {
        return next_val
      }

      // Path interpolation
      let start_v = kf.start_value.v
      let end_v = next_val.v
      if start_v.length() != end_v.length() {
        return kf.start_value
      }

      let res_v = []
      let res_i = []
      let res_o = []
      for i = 0; i < start_v.length(); i = i + 1 {
        res_v.push([
          start_v[i][0] + (end_v[i][0] - start_v[i][0]) * t,
          start_v[i][1] + (end_v[i][1] - start_v[i][1]) * t,
        ])
        res_i.push([
          kf.start_value.i[i][0] +
          (next_val.i[i][0] - kf.start_value.i[i][0]) * t,
          kf.start_value.i[i][1] +
          (next_val.i[i][1] - kf.start_value.i[i][1]) * t,
        ])
        res_o.push([
          kf.start_value.o[i][0] +
          (next_val.o[i][0] - kf.start_value.o[i][0]) * t,
          kf.start_value.o[i][1] +
          (next_val.o[i][1] - kf.start_value.o[i][1]) * t,
        ])
      }
      @model.BezierPath::new(v=res_v, i=res_i, o=res_o, c=kf.start_value.c)
    }
  }
}

///|
pub fn evaluate_transform(
  transform : @model.Transform,
  frame : Double,
) -> @math.Matrix {
  let a = evaluate_vec_property(transform.anchor, frame)
  let p = if transform.s == Some(true) {
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
