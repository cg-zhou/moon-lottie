///|
test "evaluate_double_linear" {
  let k1 = @model.LottieKeyframe::new(frame=0, start_value=0.0)
  let k2 = @model.LottieKeyframe::new(frame=100, start_value=100.0)

  let prop = @model.LottieProperty::new_animated([k1, k2])

  let v0 = @runtime.evaluate_double_property(prop, 0.0)
  let v50 = @runtime.evaluate_double_property(prop, 50.0)
  let v100 = @runtime.evaluate_double_property(prop, 100.0)

  if v0 != 0.0 {
    fail("v0 mismatch")
  }
  if (v50 - 50.0).abs() > 0.001 {
    fail("v50 mismatch")
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
