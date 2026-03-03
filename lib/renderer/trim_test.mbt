///|
/// Looser tolerance for sampled arc-length tests (numerical approximation).
let trim_tolerance_loose = 0.02

///|
/// Tight tolerance for symmetric curves where expected value is stable.
let trim_tolerance_tight = 0.001

///|
test "trim_single_path/basic" {
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let i = [[0.0, 0.0], [0.0, 0.0]]
  let o = [[0.0, 0.0], [0.0, 0.0]]
  let path = @model.BezierPath::new(
    vertices=v,
    in_tangents=i,
    out_tangents=o,
    closed=false,
  )

  // Trim from 25% to 75%
  let trimmed = trim_single_path(path, 0.25, 0.75, 0.0)[0]

  // Trim semantics are length-based (lottie-web): for this straight segment,
  // 25%..75% maps to x=25..75 even when cubic parameterization is non-linear.
  inspect(trimmed.vertices.length(), content="2")
  if (trimmed.vertices[0][0] - 25.0).abs() > trim_tolerance_loose {
    fail("Unexpected trim start x: \{trimmed.vertices[0][0]}")
  }
  if (trimmed.vertices[1][0] - 75.0).abs() > trim_tolerance_loose {
    fail("Unexpected trim end x: \{trimmed.vertices[1][0]}")
  }
}

///|
test "trim_single_path/linear_proper" {
  // To get a truly linear segment from 0 to 100
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let o = [[33.333333333333336, 0.0], [0.0, 0.0]]
  let i = [[0.0, 0.0], [-33.333333333333336, 0.0]]
  let path = @model.BezierPath::new(
    vertices=v,
    in_tangents=i,
    out_tangents=o,
    closed=false,
  )

  let trimmed = trim_single_path(path, 0.25, 0.75, 0.0)[0]
  // Accuracy is good enough
  inspect(trimmed.vertices[0][0], content="24.999999999999993")
  inspect(trimmed.vertices[1][0], content="75")
}

///|
test "trim_single_path/cubic" {
  // Cubic Bezier from (0,0) to (100,0) with control points (0,100) and (100,100)
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let i = [[0.0, 0.0], [0.0, 100.0]]
  let o = [[0.0, 100.0], [0.0, 0.0]]
  let path = @model.BezierPath::new(
    vertices=v,
    in_tangents=i,
    out_tangents=o,
    closed=false,
  )

  // Trim from 0% to 50%
  let trimmed = trim_single_path(path, 0.0, 0.5, 0.0)[0]

  inspect(trimmed.vertices.length(), content="2")
  inspect(trimmed.vertices[0][0], content="0")
  // At t=0.5, x should be 50.0 (symmetry)
  if (trimmed.vertices[1][0] - 50.0).abs() > trim_tolerance_tight {
    fail("Unexpected cubic mid x: \{trimmed.vertices[1][0]}")
  }
  // At t=0.5, y should be 75.0
  inspect(trimmed.vertices[1][1], content="75")
}

///|
test "apply_trim_path_with_mode/simultaneously_vs_individually" {
  let path1 = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [100.0, 0.0]],
    in_tangents=[[0.0, 0.0], [-33.333333333333336, 0.0]],
    out_tangents=[[33.333333333333336, 0.0], [0.0, 0.0]],
    closed=false,
  )
  let path2 = @model.BezierPath::new(
    vertices=[[200.0, 0.0], [300.0, 0.0]],
    in_tangents=[[0.0, 0.0], [-33.333333333333336, 0.0]],
    out_tangents=[[33.333333333333336, 0.0], [0.0, 0.0]],
    closed=false,
  )
  let paths = [path1, path2]

  // mode=1: trim across the concatenated path length [0, 200]
  let sim = apply_trim_path_with_mode(paths, 25.0, 75.0, 0.0, 1)
  if sim.length() != 2 {
    fail("Simultaneous trim should keep 2 partial paths, got \{sim.length()}")
  }
  if (sim[0].vertices[0][0] - 50.0).abs() > 0.001 ||
    (sim[0].vertices[1][0] - 100.0).abs() > 0.001 {
    fail("Unexpected first simultaneous segment")
  }
  if (sim[1].vertices[0][0] - 200.0).abs() > 0.001 ||
    (sim[1].vertices[1][0] - 250.0).abs() > 0.001 {
    fail("Unexpected second simultaneous segment")
  }

  // mode=2: trim each path independently
  let ind = apply_trim_path_with_mode(paths, 25.0, 75.0, 0.0, 2)
  if ind.length() != 2 {
    fail("Individual trim should keep 2 partial paths, got \{ind.length()}")
  }
  if (ind[0].vertices[0][0] - 25.0).abs() > 0.001 ||
    (ind[0].vertices[1][0] - 75.0).abs() > 0.001 {
    fail("Unexpected first individual segment")
  }
  if (ind[1].vertices[0][0] - 225.0).abs() > 0.001 ||
    (ind[1].vertices[1][0] - 275.0).abs() > 0.001 {
    fail("Unexpected second individual segment")
  }
}
