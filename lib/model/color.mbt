/// Color types migrated from lottie-rs model/color.rs

///|
/// Represents an RGBA color with components in the [0.0, 1.0] range.
pub struct Color {
  r : Double
  g : Double
  b : Double
  a : Double
} derive(Show, Eq)

///|
pub fn Color::new(r : Double, g : Double, b : Double, a : Double) -> Color {
  { r, g, b, a }
}

///|
/// Construct from 8-bit channels (0~255), aligned with lottie-rs Rgba::new_u8.
pub fn Color::new_u8(r : Int, g : Int, b : Int, a : Int) -> Color {
  let clamp = fn(v : Int) {
    if v < 0 {
      0
    } else if v > 255 {
      255
    } else {
      v
    }
  }
  {
    r: clamp(r).to_double() / 255.0,
    g: clamp(g).to_double() / 255.0,
    b: clamp(b).to_double() / 255.0,
    a: clamp(a).to_double() / 255.0,
  }
}

///|
/// Construct from a Lottie float array [r, g, b] or [r, g, b, a] (0.0–1.0).
pub fn Color::from_array(arr : Array[Double]) -> Color {
  let r = if arr.length() > 0 { arr[0] } else { 0.0 }
  let g = if arr.length() > 1 { arr[1] } else { 0.0 }
  let b = if arr.length() > 2 { arr[2] } else { 0.0 }
  let a = if arr.length() > 3 { arr[3] } else { 1.0 }
  { r, g, b, a }
}

///|
/// Convert to an array [r, g, b, a] with components in [0.0, 1.0].
pub fn Color::to_array(self : Color) -> Array[Double] {
  [self.r, self.g, self.b, self.a]
}

///|
fn to_u8(v : Double) -> Int {
  let v = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
  (v * 255.0 + 0.5).to_int()
}

///|
/// Convert to a CSS hex color string, e.g. "#FF0000".
pub fn Color::to_hex_string(self : Color) -> String {
  let chars = "0123456789ABCDEF"
  fn hex(v : Int) -> String {
    let v = if v < 0 { 0 } else if v > 255 { 255 } else { v }
    let high = v / 16
    let low = v % 16
    let s = StringBuilder::new()
    s.write_char(chars[high].to_int().unsafe_to_char())
    s.write_char(chars[low].to_int().unsafe_to_char())
    s.to_string()
  }

  "#" + hex(to_u8(self.r)) + hex(to_u8(self.g)) + hex(to_u8(self.b))
}

///|
/// Linear interpolation between two colors.
pub fn Color::lerp(self : Color, other : Color, t : Double) -> Color {
  {
    r: self.r + (other.r - self.r) * t,
    g: self.g + (other.g - self.g) * t,
    b: self.b + (other.b - self.b) * t,
    a: self.a + (other.a - self.a) * t,
  }
}

///|
/// Transparent black.
pub fn Color::transparent() -> Color {
  { r: 0.0, g: 0.0, b: 0.0, a: 0.0 }
}

///|
/// Opaque black.
pub fn Color::black() -> Color {
  { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }
}

///|
/// Opaque white.
pub fn Color::white() -> Color {
  { r: 1.0, g: 1.0, b: 1.0, a: 1.0 }
}
