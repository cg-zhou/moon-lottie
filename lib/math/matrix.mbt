///|
pub struct Matrix {
  a : Double
  b : Double
  c : Double
  d : Double
  e : Double
  f : Double
} derive(Debug, Eq)

///|
pub fn Matrix::new(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> Matrix {
  { a, b, c, d, e, f }
}

///|
pub fn Matrix::identity() -> Matrix {
  { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 }
}

///|
pub fn Matrix::multiply(self : Matrix, other : Matrix) -> Matrix {
  {
    a: self.a * other.a + self.c * other.b,
    b: self.b * other.a + self.d * other.b,
    c: self.a * other.c + self.c * other.d,
    d: self.b * other.c + self.d * other.d,
    e: self.a * other.e + self.c * other.f + self.e,
    f: self.b * other.e + self.d * other.f + self.f,
  }
}

///|
pub fn Matrix::translate(self : Matrix, x : Double, y : Double) -> Matrix {
  self.multiply({ a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: x, f: y })
}

///|
pub fn Matrix::scale(self : Matrix, x : Double, y : Double) -> Matrix {
  self.multiply({ a: x, b: 0.0, c: 0.0, d: y, e: 0.0, f: 0.0 })
}

///|
pub fn Matrix::rotate(self : Matrix, angle : Double) -> Matrix {
  let cos = @std_math.cos(angle)
  let sin = @std_math.sin(angle)
  self.multiply({ a: cos, b: sin, c: -sin, d: cos, e: 0.0, f: 0.0 })
}

///|
pub fn Matrix::transform_point(
  self : Matrix,
  x : Double,
  y : Double,
) -> (Double, Double) {
  let nx = self.a * x + self.c * y + self.e
  let ny = self.b * x + self.d * y + self.f
  (nx, ny)
}

///|
pub fn sqrt(x : Double) -> Double {
  x.sqrt()
}
