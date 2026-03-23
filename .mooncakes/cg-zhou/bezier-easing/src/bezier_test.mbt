fn close_enough(a : Double, b : Double, precision : Double) -> Bool {
  (a - b).abs() < precision
}

test "bezier returns function" {
  let easing = bezier(0.0, 0.0, 1.0, 1.0)
  inspect(close_enough(easing(0.25), 0.25, 0.0000001), content="true")
}

test "linear curves are linear" {
  let easing1 = bezier(0.0, 0.0, 1.0, 1.0)
  let easing2 = bezier(1.0, 1.0, 0.0, 0.0)
  for i in 0..=100 {
    let x = i.to_double() / 100.0
    inspect(close_enough(easing1(x), x, 0.000001), content="true")
    inspect(close_enough(easing1(x), easing2(x), 0.000001), content="true")
  }
}

test "extremes are exact" {
  let params = [
    (0.25, 0.1, 0.25, 1.0),
    (0.42, 0.0, 1.0, 1.0),
    (0.0, 0.5, 1.0, 0.5),
    (0.67, -0.2, 0.33, 1.2),
  ]
  for item in params {
    let (a, b, c, d) = item
    let easing = bezier(a, b, c, d)
    inspect(easing(0.0), content="0")
    inspect(easing(1.0), content="1")
  }
}

test "projected curve composition approximates identity" {
  let params = [
    (0.1, 0.2, 0.9, 0.8),
    (0.25, 0.7, 0.8, 0.1),
    (0.33, 0.33, 0.66, 0.66),
    (0.15, 0.95, 0.85, 0.05),
  ]
  for item in params {
    let (a, b, c, d) = item
    let easing = bezier(a, b, c, d)
    let projected = bezier(b, a, d, c)
    for i in 0..=100 {
      let x = i.to_double() / 100.0
      let composed = projected(easing(x))
      inspect(close_enough(composed, x, 0.05), content="true")
    }
  }
}

test "symmetric curves stay symmetric" {
  let params = [
    (0.2, -0.2),
    (0.3, 0.0),
    (0.4, 0.4),
    (0.1, 0.8),
  ]
  for item in params {
    let (a, b) = item
    let c = 1.0 - a
    let d = 1.0 - b
    let easing = bezier(a, b, c, d)
    inspect(close_enough(easing(0.5), 0.5, 0.00001), content="true")
    for i in 0..=100 {
      let x = i.to_double() / 100.0
      let sym = 1.0 - easing(1.0 - x)
      inspect(close_enough(easing(x), sym, 0.000001), content="true")
    }
  }
}
