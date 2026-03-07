///|
test "evaluate_double_linear" {
  let k1 = @model.LottieKeyframe::new(frame=0, start_value=0.0)
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=100.0)

  let prop = @model.LottieProperty::new_animated([k1, k2])

  let v0 = @runtime.evaluate_double_property(prop, 0.0)
  let v25 = @runtime.evaluate_double_property(prop, 25.0)
  let v50 = @runtime.evaluate_double_property(prop, 50.0)
  let v75 = @runtime.evaluate_double_property(prop, 75.0)
  let v100 = @runtime.evaluate_double_property(prop, 100.0)

  if v0 != 0.0 {
    fail("v0 mismatch")
  }
  if (v25 - 25.0).abs() > 0.001 {
    fail("v25 mismatch")
  }
  if (v50 - 50.0).abs() > 0.001 {
    fail("v50 mismatch")
  }
  if (v75 - 75.0).abs() > 0.001 {
    fail("v75 mismatch")
  }
  if v100 != 100.0 {
    fail("v100 mismatch")
  }
}

///|
test "evaluate_double_easing" {
  // Simple easing: fast start, slow end
  // Out tangent: (0.1, 1.0) -> high slope at start
  // In tangent: (0.9, 1.0) -> flat at end
  let ot = @model.Bezier::new(
    @model.BezierValue::new_single(0.1),
    @model.BezierValue::new_single(1.0),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_single(0.9),
    @model.BezierValue::new_single(1.0),
  )

  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=0.0,
    in_tangent=Some(it),
    out_tangent=Some(ot),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=100.0)

  let prop = @model.LottieProperty::new_animated([k1, k2])

  let v50 = @runtime.evaluate_double_property(prop, 50.0)
  // With this easing, at 50% time, progress should be much higher than 50%
  if v50 <= 50.0 {
    fail("Easing should result in v50 > 50.0")
  }
}

///|
test "evaluate_double_hold" {
  let k1 = @model.LottieKeyframe::new(frame=0, start_value=10.0, hold=Some(1))
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=20.0)
  let prop = @model.LottieProperty::new_animated([k1, k2])

  let v0 = @runtime.evaluate_double_property(prop, 0.0)
  let v25 = @runtime.evaluate_double_property(prop, 25.0)
  let v50 = @runtime.evaluate_double_property(prop, 50.0)
  let v75 = @runtime.evaluate_double_property(prop, 75.0)
  let v100 = @runtime.evaluate_double_property(prop, 100.0)

  inspect(v0, content="10")
  inspect(v25, content="10")
  inspect(v50, content="10")
  inspect(v75, content="10")
  inspect(v100, content="20")
}

///|
test "evaluate_double_preserves_fractional_keyframe_timing" {
  let k1 = @model.LottieKeyframe::new(frame=0.0, start_value=0.0)
  let k2 = @model.LottieKeyframe::new(frame=0.5, start_value=100.0)
  let prop = @model.LottieProperty::new_animated([k1, k2])

  let v = @runtime.evaluate_double_property(prop, 0.25)
  if (v - 50.0).abs() > 0.001 {
    fail("fractional keyframe timing should interpolate at the exact subframe position")
  }
}

///|
test "evaluate_path_property_easing" {
  let ot = @model.Bezier::new(
    @model.BezierValue::new_single(0.1),
    @model.BezierValue::new_single(1.0),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_single(0.9),
    @model.BezierValue::new_single(1.0),
  )
  let p0 = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [10.0, 0.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0]],
    closed=false,
  )
  let p1 = @model.BezierPath::new(
    vertices=[[100.0, 0.0], [110.0, 0.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0]],
    closed=false,
  )
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=p0,
    end_value=Some(p1),
    in_tangent=Some(it),
    out_tangent=Some(ot),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=p1)
  let prop = @model.LottieProperty::new_animated([k1, k2])
  let v = @runtime.evaluate_path_property(prop, 50.0)
  if get_pt_at(v.vertices, 0, 0) <= 50.0 {
    fail("Path easing should advance farther than linear interpolation at frame 50")
  }
}

///|
test "evaluate_vec_property_multidimensional_easing_components" {
  let ot = @model.Bezier::new(
    @model.BezierValue::new_multi([0.0, 0.1]),
    @model.BezierValue::new_multi([0.0, 1.0]),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_multi([1.0, 0.9]),
    @model.BezierValue::new_multi([1.0, 1.0]),
  )
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=[0.0, 0.0],
    in_tangent=Some(it),
    out_tangent=Some(ot),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=[100.0, 100.0])
  let prop = @model.LottieProperty::new_animated([k1, k2])
  let v = @runtime.evaluate_vec_property(prop, 50.0)
  if v.length() != 2 {
    fail("Unexpected vector length")
  }
  if (v[0] - 50.0).abs() > 0.001 {
    fail("First component should follow linear easing component")
  }
  if v[1] <= 50.0 {
    fail("Second component should follow its own easing curve")
  }
}

///|
test "evaluate_vec_property_spatial_bezier_applies_temporal_easing" {
  // Verify that temporal easing (o/i handles) IS applied before evaluating the
  // spatial bezier arc-length position, matching lottie-web behaviour.
  // With easing out=(0.1,1.0)/in=(0.9,1.0), the eased t at frame 50 of 100 is
  // ~0.875, so the position lands near 87.5 (well past the midpoint 50).
  let ot = @model.Bezier::new(
    @model.BezierValue::new_single(0.1),
    @model.BezierValue::new_single(1.0),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_single(0.9),
    @model.BezierValue::new_single(1.0),
  )
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=[0.0, 0.0],
    in_tangent=Some(it),
    out_tangent=Some(ot),
    value_out_tangent=Some([0.0, 0.0]),
    value_in_tangent=Some([0.0, 0.0]),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=[100.0, 100.0])
  let prop = @model.LottieProperty::new_animated([k1, k2])
  let v = @runtime.evaluate_vec_property(prop, 50.0)
  if v.length() != 2 {
    fail("Unexpected vector length")
  }
  // Easing (0.1,1.0)/(0.9,1.0) gives eased_t ≈ 0.875 at raw t=0.5, so the
  // position should be near 87.5, well past the midpoint 50.
  if v[0] < 80.0 || v[1] < 80.0 {
    fail(
      "Temporal easing should be applied to spatial bezier keyframes: expected v > 80, got \{v[0]}",
    )
  }
}

///|
test "evaluate_vec_property_spatial_bezier_arc_length_parameterization" {
  // Verify that arc-length parameterization is used for spatial bezier keyframes
  // (matching lottie-web). With a bezier that curves through [200,200] as a
  // control point, arc-length gives a more uniform distribution: at t=0.5 the
  // position is ~75, not 125 (which would be the direct cubic parameter result).
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=[0.0, 0.0],
    value_out_tangent=Some([200.0, 200.0]),
    value_in_tangent=Some([0.0, 0.0]),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=[100.0, 100.0])
  let prop = @model.LottieProperty::new_animated([k1, k2])
  let v25 = @runtime.evaluate_vec_property(prop, 25.0)
  let v50 = @runtime.evaluate_vec_property(prop, 50.0)
  if v25.length() != 2 || v50.length() != 2 {
    fail("Unexpected vector length")
  }
  // Arc-length at 25%: ~37.5 (more than 25 because curve bows outward early)
  if v25[0] <= 25.0 || v25[1] <= 25.0 {
    fail(
      "Arc-length should produce non-linear values at frame 25: expected >25, got \{v25[0]}",
    )
  }
  // Arc-length at 50%: ~75 (NOT 125 which would be the direct cubic result)
  if v50[0] < 60.0 || v50[0] > 90.0 || v50[1] < 60.0 || v50[1] > 90.0 {
    fail(
      "Arc-length at 50% should be ~75, not 125 (direct cubic): got \{v50[0]}",
    )
  }
}

///|
test "evaluate_path_property_multidimensional_easing_components" {
  let ot = @model.Bezier::new(
    @model.BezierValue::new_multi([0.0, 0.1]),
    @model.BezierValue::new_multi([0.0, 1.0]),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_multi([1.0, 0.9]),
    @model.BezierValue::new_multi([1.0, 1.0]),
  )
  let p0 = @model.BezierPath::new(
    vertices=[[0.0, 0.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  let p1 = @model.BezierPath::new(
    vertices=[[100.0, 100.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=p0,
    end_value=Some(p1),
    in_tangent=Some(it),
    out_tangent=Some(ot),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=p1)
  let prop = @model.LottieProperty::new_animated([k1, k2])
  let v = @runtime.evaluate_path_property(prop, 50.0)
  let vx = get_pt_at(v.vertices, 0, 0)
  let vy = get_pt_at(v.vertices, 0, 1)
  if (vx - 50.0).abs() > 0.001 {
    fail("Path x component should follow linear easing component")
  }
  if vy <= 50.0 {
    fail("Path y component should follow its own easing curve")
  }
}

///|
/// When a path keyframe has no `end_value` (e), interpolation should use the
/// next keyframe's `start_value` — matching lottie-web's behavior.
/// Previously the evaluator incorrectly held at the current keyframe's start_value.
test "evaluate_path_property_no_end_value_uses_next_start" {
  let p0 = @model.BezierPath::new(
    vertices=[[0.0, 0.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  let p1 = @model.BezierPath::new(
    vertices=[[100.0, 100.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  // Keyframe at t=0 with NO end_value (no 'e' field, matching typical lottie JSON)
  let k1 = @model.LottieKeyframe::new(frame=0, start_value=p0)
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=p1)
  let prop = @model.LottieProperty::new_animated([k1, k2])

  // At frame 50 (midpoint) with no easing, result should be interpolated to 50,50
  let v = @runtime.evaluate_path_property(prop, 50.0)
  let vx = get_pt_at(v.vertices, 0, 0)
  let vy = get_pt_at(v.vertices, 0, 1)
  if (vx - 50.0).abs() > 0.001 {
    fail(
      "Path x should interpolate to 50 (not hold at 0) when end_value is absent, got \{vx}",
    )
  }
  if (vy - 50.0).abs() > 0.001 {
    fail(
      "Path y should interpolate to 50 (not hold at 0) when end_value is absent, got \{vy}",
    )
  }
}

///|
/// Path keyframe easing tangents (o/i fields) should be parsed and applied when
/// interpolating path properties — matching lottie-web's ShapeProperty behavior.
test "evaluate_path_property_easing_tangents" {
  let ot = @model.Bezier::new(
    @model.BezierValue::new_single(0.1),
    @model.BezierValue::new_single(1.0),
  )
  let it = @model.Bezier::new(
    @model.BezierValue::new_single(0.9),
    @model.BezierValue::new_single(1.0),
  )
  let p0 = @model.BezierPath::new(
    vertices=[[0.0, 0.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  let p1 = @model.BezierPath::new(
    vertices=[[100.0, 100.0]],
    in_tangents=[[0.0, 0.0]],
    out_tangents=[[0.0, 0.0]],
    closed=false,
  )
  // k1 has no end_value — interpolation uses k2.start_value, with easing
  let k1 = @model.LottieKeyframe::new(
    frame=0,
    start_value=p0,
    in_tangent=Some(it),
    out_tangent=Some(ot),
  )
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=p1)
  let prop = @model.LottieProperty::new_animated([k1, k2])

  // Easing (0.1,1.0)/(0.9,1.0) is fast-in/slow-out; at raw t=0.5 the eased t>0.5
  let v = @runtime.evaluate_path_property(prop, 50.0)
  let vx = get_pt_at(v.vertices, 0, 0)
  if vx <= 50.0 {
    fail("Eased path should advance past 50 at raw t=0.5, got \{vx}")
  }
}

///|
fn get_pt_at(v : Array[Array[Double]], i : Int, j : Int) -> Double {
  if i >= 0 && i < v.length() && j >= 0 && j < v[i].length() {
    v[i][j]
  } else {
    0.0
  }
}
