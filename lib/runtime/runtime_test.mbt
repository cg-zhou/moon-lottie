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
fn get_pt_at(v : Array[Array[Double]], i : Int, j : Int) -> Double {
  if i >= 0 && i < v.length() && j >= 0 && j < v[i].length() {
    v[i][j]
  } else {
    0.0
  }
}
