test "bench: create easing common" (b : @bench.T) {
  b.bench(fn() {
    b.keep(bezier(0.25, 0.1, 0.25, 1.0))
  })
}

test "bench: evaluate 1000 samples" (b : @bench.T) {
  let easing = bezier(0.25, 0.1, 0.25, 1.0)
  b.bench(fn() {
    let mut acc = 0.0
    for i in 0..<1000 {
      let x = i.to_double() / 999.0
      acc = acc + easing(x)
    }
    b.keep(acc)
  })
}

test "bench: create many easings" (b : @bench.T) {
  b.bench(fn() {
    let mut acc = 0.0
    for i in 0..<200 {
      let t = i.to_double() / 199.0
      let e = bezier(t, 0.0, 1.0 - t, 1.0)
      acc = acc + e(0.5)
    }
    b.keep(acc)
  })
}
