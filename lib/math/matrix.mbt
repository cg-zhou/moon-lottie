pub struct Matrix {
  mut a : Double
  mut b : Double
  mut c : Double
  mut d : Double
  mut e : Double
  mut f : Double
}

pub fn Matrix::new(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double
) -> Matrix {
  { a, b, c, d, e, f }
}

pub fn Matrix::identity() -> Matrix {
  { a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0 }
}

pub fn multiply(self : Matrix, other : Matrix) -> Matrix {
  {
    a: self.a * other.a + self.c * other.b,
    b: self.b * other.a + self.d * other.b,
    c: self.a * other.c + self.c * other.d,
    d: self.b * other.c + self.d * other.d,
    e: self.a * other.e + self.c * other.f + self.e,
    f: self.b * other.e + self.d * other.f + self.f,
  }
}

pub fn translate(self : Matrix, x : Double, y : Double) -> Matrix {
  self.multiply({ a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: x, f: y })
}

pub fn scale(self : Matrix, x : Double, y : Double) -> Matrix {
  self.multiply({ a: x, b: 0.0, c: 0.0, d: y, e: 0.0, f: 0.0 })
}

pub fn rotate(self : Matrix, angle : Double) -> Matrix {
  let cos = angle.cos()
  let sin = angle.sin()
  self.multiply({ a: cos, b: sin, c: -sin, d: cos, e: 0.0, f: 0.0 })
}
