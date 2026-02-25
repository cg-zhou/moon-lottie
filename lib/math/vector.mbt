///|
pub struct Vector2 {
  x : Double
  y : Double
}

///|
pub fn Vector2::new(x : Double, y : Double) -> Vector2 {
  { x, y }
}

///|
pub fn Vector2::zero() -> Vector2 {
  { x: 0.0, y: 0.0 }
}

///|
pub fn Vector2::add(self : Vector2, other : Vector2) -> Vector2 {
  { x: self.x + other.x, y: self.y + other.y }
}

///|
pub fn Vector2::sub(self : Vector2, other : Vector2) -> Vector2 {
  { x: self.x - other.x, y: self.y - other.y }
}

///|
pub fn Vector2::scale(self : Vector2, factor : Double) -> Vector2 {
  { x: self.x * factor, y: self.y * factor }
}

///|
pub fn Vector2::length(self : Vector2) -> Double {
  (self.x * self.x + self.y * self.y).sqrt()
}

///|
pub fn Vector2::dot(self : Vector2, other : Vector2) -> Double {
  self.x * other.x + self.y * other.y
}

///|
pub fn Vector2::lerp(self : Vector2, other : Vector2, t : Double) -> Vector2 {
  { x: self.x + (other.x - self.x) * t, y: self.y + (other.y - self.y) * t }
}
