let newton_iterations : Int = 4
let newton_min_slope : Double = 0.001
let subdivision_precision : Double = 0.0000001
let subdivision_max_iterations : Int = 10

let spline_table_size : Int = 11
let sample_step_size : Double = 1.0 / (spline_table_size.to_double() - 1.0)

fn a(a1 : Double, a2 : Double) -> Double {
  1.0 - 3.0 * a2 + 3.0 * a1
}

fn b(a1 : Double, a2 : Double) -> Double {
  3.0 * a2 - 6.0 * a1
}

fn c(a1 : Double) -> Double {
  3.0 * a1
}

fn calc_bezier(t : Double, a1 : Double, a2 : Double) -> Double {
  ((a(a1, a2) * t + b(a1, a2)) * t + c(a1)) * t
}

fn get_slope(t : Double, a1 : Double, a2 : Double) -> Double {
  3.0 * a(a1, a2) * t * t + 2.0 * b(a1, a2) * t + c(a1)
}

fn binary_subdivide(x : Double, ax : Double, bx : Double, x1 : Double, x2 : Double) -> Double {
  let mut current_x = 0.0
  let mut current_t = 0.0
  let mut a = ax
  let mut b = bx
  let mut i = 0
  while i < subdivision_max_iterations {
    current_t = a + (b - a) / 2.0
    current_x = calc_bezier(current_t, x1, x2) - x
    if current_x > 0.0 {
      b = current_t
    } else {
      a = current_t
    }
    if current_x.abs() <= subdivision_precision {
      break
    }
    i = i + 1
  }
  current_t
}

fn newton_raphson_iterate(x : Double, guess_t : Double, x1 : Double, x2 : Double) -> Double {
  let mut t = guess_t
  for _i in 0..<newton_iterations {
    let current_slope = get_slope(t, x1, x2)
    if current_slope == 0.0 {
      return t
    }
    let current_x = calc_bezier(t, x1, x2) - x
    t = t - current_x / current_slope
  }
  t
}

fn build_samples(x1 : Double, x2 : Double) -> Array[Double] {
  let sample_values : Array[Double] = []
  for i in 0..<spline_table_size {
    sample_values.push(calc_bezier(i.to_double() * sample_step_size, x1, x2))
  }
  sample_values
}

fn get_t_for_x(x : Double, x1 : Double, x2 : Double, sample_values : Array[Double]) -> Double {
  let mut interval_start = 0.0
  let mut current_sample = 1
  let last_sample = spline_table_size - 1

  while current_sample != last_sample && sample_values[current_sample] <= x {
    interval_start = interval_start + sample_step_size
    current_sample = current_sample + 1
  }

  current_sample = current_sample - 1

  let dist = (x - sample_values[current_sample]) /
    (sample_values[current_sample + 1] - sample_values[current_sample])
  let guess_for_t = interval_start + dist * sample_step_size

  let initial_slope = get_slope(guess_for_t, x1, x2)
  if initial_slope >= newton_min_slope {
    newton_raphson_iterate(x, guess_for_t, x1, x2)
  } else if initial_slope == 0.0 {
    guess_for_t
  } else {
    binary_subdivide(x, interval_start, interval_start + sample_step_size, x1, x2)
  }
}

pub fn bezier(m_x1 : Double, m_y1 : Double, m_x2 : Double, m_y2 : Double) -> (Double) -> Double {
  if not(0.0 <= m_x1 && m_x1 <= 1.0 && 0.0 <= m_x2 && m_x2 <= 1.0) {
    panic()
  }

  if m_x1 == m_y1 && m_x2 == m_y2 {
    return fn(x) { x }
  }

  let sample_values = build_samples(m_x1, m_x2)

  fn easing(x : Double) -> Double {
    if x == 0.0 || x == 1.0 {
      return x
    }
    calc_bezier(get_t_for_x(x, m_x1, m_x2, sample_values), m_y1, m_y2)
  }

  easing
}
