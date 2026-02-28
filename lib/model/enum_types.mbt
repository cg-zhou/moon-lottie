/// Enum types migrated from lottie-rs model.rs (no external dependencies)

///|
/// Lottie blend mode values as defined in the Lottie spec.
/// Mirrors lottie-rs BlendMode enum (repr u8 starting at 0).
pub enum BlendMode {
  Normal
  Multiply
  Screen
  Overlay
  Darken
  Lighten
  ColorDodge
  ColorBurn
  HardLight
  SoftLight
  Difference
  Exclusion
  Hue
  Saturation
  Color
  Luminosity
  Add
  HardMix
}

///|
/// Parse a BlendMode from its integer value (Lottie JSON "bm" field).
pub fn BlendMode::from_int(v : Int) -> BlendMode {
  match v {
    0 => BlendMode::Normal
    1 => BlendMode::Multiply
    2 => BlendMode::Screen
    3 => BlendMode::Overlay
    4 => BlendMode::Darken
    5 => BlendMode::Lighten
    6 => BlendMode::ColorDodge
    7 => BlendMode::ColorBurn
    8 => BlendMode::HardLight
    9 => BlendMode::SoftLight
    10 => BlendMode::Difference
    11 => BlendMode::Exclusion
    12 => BlendMode::Hue
    13 => BlendMode::Saturation
    14 => BlendMode::Color
    15 => BlendMode::Luminosity
    16 => BlendMode::Add
    17 => BlendMode::HardMix
    _ => BlendMode::Normal
  }
}

///|
/// Convert BlendMode to its integer representation.
pub fn BlendMode::to_int(self : BlendMode) -> Int {
  match self {
    Normal => 0
    Multiply => 1
    Screen => 2
    Overlay => 3
    Darken => 4
    Lighten => 5
    ColorDodge => 6
    ColorBurn => 7
    HardLight => 8
    SoftLight => 9
    Difference => 10
    Exclusion => 11
    Hue => 12
    Saturation => 13
    Color => 14
    Luminosity => 15
    Add => 16
    HardMix => 17
  }
}

///|
/// Lottie matte mode values ("tt" field in Layer).
/// Mirrors lottie-rs MatteMode enum.
pub enum MatteMode {
  Normal
  Alpha
  InvertedAlpha
  Luma
  InvertedLuma
}

///|
/// Parse a MatteMode from its integer value.
pub fn MatteMode::from_int(v : Int) -> MatteMode {
  match v {
    0 => MatteMode::Normal
    1 => MatteMode::Alpha
    2 => MatteMode::InvertedAlpha
    3 => MatteMode::Luma
    4 => MatteMode::InvertedLuma
    _ => MatteMode::Normal
  }
}

///|
/// Convert MatteMode to its integer representation.
pub fn MatteMode::to_int(self : MatteMode) -> Int {
  match self {
    Normal => 0
    Alpha => 1
    InvertedAlpha => 2
    Luma => 3
    InvertedLuma => 4
  }
}

///|
/// Fill rule — controls how self-intersecting paths are filled.
/// Mirrors lottie-rs FillRule enum.
pub enum FillRule {
  NonZeroFill // 1
  EvenOddFill // 2
}

///|
pub fn FillRule::from_int(v : Int) -> FillRule {
  match v {
    2 => FillRule::EvenOddFill
    _ => FillRule::NonZeroFill
  }
}

///|
pub fn FillRule::to_int(self : FillRule) -> Int {
  match self {
    NonZeroFill => 1
    EvenOddFill => 2
  }
}

///|
/// Returns the CSS fill-rule string used in SVG.
pub fn FillRule::to_svg_string(self : FillRule) -> String {
  match self {
    NonZeroFill => "nonzero"
    EvenOddFill => "evenodd"
  }
}

///|
/// Stroke line cap style. Mirrors lottie-rs LineCap enum.
pub enum LineCap {
  Butt // 1
  Round // 2
  Square // 3
}

///|
pub fn LineCap::from_int(v : Int) -> LineCap {
  match v {
    2 => LineCap::Round
    3 => LineCap::Square
    _ => LineCap::Butt
  }
}

///|
pub fn LineCap::to_int(self : LineCap) -> Int {
  match self {
    Butt => 1
    Round => 2
    Square => 3
  }
}

///|
/// Stroke line join style. Mirrors lottie-rs LineJoin enum.
pub enum LineJoin {
  Miter // 1
  Round // 2
  Bevel // 3
}

///|
pub fn LineJoin::from_int(v : Int) -> LineJoin {
  match v {
    2 => LineJoin::Round
    3 => LineJoin::Bevel
    _ => LineJoin::Miter
  }
}

///|
pub fn LineJoin::to_int(self : LineJoin) -> Int {
  match self {
    Miter => 1
    Round => 2
    Bevel => 3
  }
}
