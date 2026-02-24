///| Find the keyframe for a given frame
fn[T] find_keyframe(
  keyframes : Array[@model.LottieKeyframe[T]],
  frame : Double
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
      let progress = (frame - k1.frame.to_double()) / (k2.frame.to_double() - k1.frame.to_double())
      return (i, progress)
    }
  }
  
  (len - 1, 0.0)
}

pub fn evaluate_double_property(
  prop : @model.LottieProperty[Double],
  frame : Double
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
      
      // Handle easing
      let eased_t = match (k1.out_tangent, k1.in_tangent) {
        (Some(ot), Some(it)) => {
          let x1 = match ot.x { Single(v) => v; Multi(arr) => arr[0] }
          let y1 = match ot.y { Single(v) => v; Multi(arr) => arr[0] }
          let x2 = match it.x { Single(v) => v; Multi(arr) => arr[0] }
          let y2 = match it.y { Single(v) => v; Multi(arr) => arr[0] }
          @math.solve_cubic_bezier_easing(x1, y1, x2, y2, t)
        }
        _ => t
      }
      
      @math.lerp_double(k1.start_value, k2.start_value, eased_t)
    }
  }
}

pub fn evaluate_vec_property(
  prop : @model.LottieProperty[Array[Double]],
  frame : Double
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
          let x1 = match ot.x { Single(v) => v; Multi(arr) => arr[0] }
          let y1 = match ot.y { Single(v) => v; Multi(arr) => arr[0] }
          let x2 = match it.x { Single(v) => v; Multi(arr) => arr[0] }
          let y2 = match it.y { Single(v) => v; Multi(arr) => arr[0] }
          @math.solve_cubic_bezier_easing(x1, y1, x2, y2, t)
        }
        _ => t
      }
      
      @math.lerp_array(k1.start_value, k2.start_value, eased_t)
    }
  }
}
