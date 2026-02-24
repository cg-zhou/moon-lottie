test "Vector2::add" {
  let v1 = @math.Vector2::new(1.0, 2.0)
  let v2 = @math.Vector2::new(3.0, 4.0)
  let v3 = v1.add(v2)
  if v3.x != 4.0 || v3.y != 6.0 {
    fail("Vector2::add failed")
  }
}

test "Matrix::multiply" {
  let m1 = @math.Matrix::identity()
  let m2 = @math.Matrix::identity().translate(10.0, 20.0)
  let m3 = m1.multiply(m2)
  if m3.e != 10.0 || m3.f != 20.0 {
    fail("Matrix::multiply failed")
  }
}

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
