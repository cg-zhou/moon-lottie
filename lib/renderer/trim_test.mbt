///|
test "trim_single_path/basic" {
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let i = [[0.0, 0.0], [0.0, 0.0]]
  let o = [[0.0, 0.0], [0.0, 0.0]]
  let path = @model.BezierPath::new(v~, i~, o~, c=false)

  // Trim from 25% to 75%
  let trimmed = trim_single_path(path, 0.25, 0.75, 0.0)

  // Note: with p1=p0 and p2=p3, it's not linear. 
  // x(t) = 300t^2 - 200t^3
  // x(0.25) = 15.625, x(0.75) = 300*0.5625 - 200*0.421875 = 168.75 - 84.375 = 84.375
  inspect(trimmed.v.length(), content="2")
  inspect(trimmed.v[0][0], content="15.625")
  inspect(trimmed.v[1][0], content="84.375")
}

///|
test "trim_single_path/linear_proper" {
  // To get a truly linear segment from 0 to 100
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let o = [[33.333333333333336, 0.0], [0.0, 0.0]]
  let i = [[0.0, 0.0], [-33.333333333333336, 0.0]]
  let path = @model.BezierPath::new(v~, i~, o~, c=false)

  let trimmed = trim_single_path(path, 0.25, 0.75, 0.0)
  // Accuracy is good enough
  inspect(trimmed.v[0][0], content="24.999999999999993")
  inspect(trimmed.v[1][0], content="75")
}

///|
test "trim_single_path/cubic" {
  // Cubic Bezier from (0,0) to (100,0) with control points (0,100) and (100,100)
  let v = [[0.0, 0.0], [100.0, 0.0]]
  let i = [[0.0, 0.0], [0.0, 100.0]]
  let o = [[0.0, 100.0], [0.0, 0.0]]
  let path = @model.BezierPath::new(v~, i~, o~, c=false)

  // Trim from 0% to 50%
  let trimmed = trim_single_path(path, 0.0, 0.5, 0.0)

  inspect(trimmed.v.length(), content="2")
  inspect(trimmed.v[0][0], content="0")
  // At t=0.5, x should be 50.0 (symmetry)
  inspect(trimmed.v[1][0], content="50")
  // At t=0.5, y should be 75.0
  inspect(trimmed.v[1][1], content="75")
}
