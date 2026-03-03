///|
test "Vector2::add" {
  let v1 = @math.Vector2::new(1.0, 2.0)
  let v2 = @math.Vector2::new(3.0, 4.0)
  let v3 = v1.add(v2)
  if v3.x != 4.0 || v3.y != 6.0 {
    fail("Vector2::add failed")
  }
}

///|
test "Vector2::new/zero/sub/scale/length/dot/lerp" {
  let zero = @math.Vector2::zero()
  if zero.x != 0.0 || zero.y != 0.0 {
    fail("Vector2::zero failed")
  }

  let v1 = @math.Vector2::new(3.0, 4.0)
  let v2 = @math.Vector2::new(1.0, 1.0)
  let sub = v1.sub(v2)
  if sub.x != 2.0 || sub.y != 3.0 {
    fail("Vector2::sub failed")
  }

  let scaled = v2.scale(2.5)
  if scaled.x != 2.5 || scaled.y != 2.5 {
    fail("Vector2::scale failed")
  }

  if (v1.length() - 5.0).abs() > 0.000001 {
    fail("Vector2::length failed")
  }

  if v1.dot(v2) != 7.0 {
    fail("Vector2::dot failed")
  }

  let lerped = v2.lerp(v1, 0.5)
  if lerped.x != 2.0 || lerped.y != 2.5 {
    fail("Vector2::lerp failed")
  }
}

///|
test "Matrix::multiply" {
  let m1 = @math.Matrix::identity()
  let m2 = @math.Matrix::identity().translate(10.0, 20.0)
  let m3 = m1.multiply(m2)
  if m3.e != 10.0 || m3.f != 20.0 {
    fail("Matrix::multiply failed")
  }
}

///|
test "Matrix::new/scale/rotate/transform_point" {
  let m = @math.Matrix::new(1.0, 0.0, 0.0, 1.0, 0.0, 0.0).scale(2.0, 3.0)
  let (sx, sy) = m.transform_point(1.0, 1.0)
  if sx != 2.0 || sy != 3.0 {
    fail("Matrix::scale or Matrix::transform_point failed")
  }

  let r = @math.Matrix::identity().rotate(3.141592653589793 / 2.0)
  let (rx, ry) = r.transform_point(1.0, 0.0)
  if rx.abs() > 0.000001 || (ry - 1.0).abs() > 0.000001 {
    fail("Matrix::rotate failed")
  }
}

///|
test "Bezier::point_on_cubic_bezier" {
  let p0 = @math.Vector2::new(0.0, 0.0)
  let p1 = @math.Vector2::new(1.0, 0.0)
  let p2 = @math.Vector2::new(1.0, 1.0)
  let p3 = @math.Vector2::new(0.0, 1.0)

  let p = @math.point_on_cubic_bezier(p0, p1, p2, p3, 0.5)
  // At t=0.5, the point should be roughly at (0.75, 0.5)
  if p.x < 0.74 || p.x > 0.76 || p.y < 0.49 || p.y > 0.51 {
    fail("Bezier interpolation incorrect")
  }
}

///|
test "Bezier::get_cubic_bezier_length and split_cubic_bezier" {
  let p0 = @math.Vector2::new(0.0, 0.0)
  let p1 = @math.Vector2::new(0.0, 0.0)
  let p2 = @math.Vector2::new(10.0, 0.0)
  let p3 = @math.Vector2::new(10.0, 0.0)
  let length = @math.get_cubic_bezier_length(p0, p1, p2, p3, 20)
  if (length - 10.0).abs() > 0.001 {
    fail("get_cubic_bezier_length failed")
  }

  let (_, _, _, mid, _, _, _) = @math.split_cubic_bezier(p0, p1, p2, p3, 0.5)
  if (mid.x - 5.0).abs() > 0.001 || mid.y.abs() > 0.001 {
    fail("split_cubic_bezier failed")
  }
}

///|
/// Cubic bezier with fixed endpoints (0,0) and (1,1),
/// where p1 and p2 are control-point x values.
///|
fn cubic01(p1 : Double, p2 : Double, t : Double) -> Double {
  let t1 = 1.0 - t
  3.0 * t1 * t1 * t * p1 + 3.0 * t1 * t * t * p2 + t * t * t
}

///|
test "Interpolation::lerp_double/lerp_array/lerp_vec2_array/sqrt" {
  if @math.lerp_double(10.0, 20.0, 0.25) != 12.5 {
    fail("lerp_double failed")
  }
  let arr = @math.lerp_array([1.0, 3.0], [5.0, 7.0], 0.5)
  if arr.length() != 2 || arr[0] != 3.0 || arr[1] != 5.0 {
    fail("lerp_array failed")
  }
  let vec_arr = @math.lerp_vec2_array([[0.0, 0.0]], [[10.0, 20.0]], 0.5)
  if vec_arr.length() != 1 || vec_arr[0][0] != 5.0 || vec_arr[0][1] != 10.0 {
    fail("lerp_vec2_array failed")
  }
  if @math.sqrt(9.0) != 3.0 {
    fail("sqrt failed")
  }
}

///|
test "Bezier::solve_cubic_bezier_easing precision" {
  let x1 = 0.42
  let y1 = 0.0
  let x2 = 0.58
  let y2 = 1.0
  let ts = [0.1, 0.25, 0.5, 0.75, 0.9]
  for t in ts {
    let x = cubic01(x1, x2, t)
    let expected = cubic01(y1, y2, t)
    let got = @math.solve_cubic_bezier_easing(x1, y1, x2, y2, x)
    if (got - expected).abs() > 0.0005 {
      fail("solve_cubic_bezier_easing precision failed")
    }
  }
}

///|
test "Bezier::solve_cubic_bezier_easing linear identity" {
  let xs = [0.0, 0.1, 0.3, 0.5, 0.9, 1.0]
  for x in xs {
    let y = @math.solve_cubic_bezier_easing(0.0, 0.0, 1.0, 1.0, x)
    if (x - y).abs() > 0.000001 {
      fail("linear easing should be identity")
    }
  }
}

///|
test "Bezier::solve_cubic_bezier_easing clamps invalid control x" {
  let y_clamped = @math.solve_cubic_bezier_easing(-0.2, 0.1, 1.2, 0.9, 0.5)
  let y_expected = @math.solve_cubic_bezier_easing(0.0, 0.1, 1.0, 0.9, 0.5)
  if (y_clamped - y_expected).abs() > 0.000001 {
    fail("invalid control x should behave like clamped control points")
  }
}
