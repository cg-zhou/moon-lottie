fn main {
  let cases = [
    (0.25, 0.1, 0.25, 1.0),
    (0.42, 0.0, 1.0, 1.0),
    (0.0, 0.0, 0.58, 1.0),
    (0.17, 0.67, 0.83, 0.67),
  ]

  for item in cases {
    let (x1, y1, x2, y2) = item
    let easing = @bezier.bezier(x1, y1, x2, y2)
    for i in 0..=20 {
      let x = i.to_double() / 20.0
      let y = easing(x)
      println(
        x1.to_string() +
        "," +
        y1.to_string() +
        "," +
        x2.to_string() +
        "," +
        y2.to_string() +
        "," +
        x.to_string() +
        "," +
        y.to_string(),
      )
    }
  }
}
