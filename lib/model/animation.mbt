///|
pub(all) struct GlyphInfo {
  ch : String
  style : String
  family : String
  size : Double
  advance_width : Double
  shapes : Array[Shape]
}

///|
pub(all) struct FontInfo {
  name : String
  family : String
  style : String
  ascent : Double
}

///|
pub struct Animation {
  version : String // JSON: v
  frame_rate : Double // JSON: fr
  in_point : Double // JSON: ip
  out_point : Double // JSON: op
  width : Int // JSON: w
  height : Int // JSON: h
  name : String? // JSON: nm
  three_d : Int? // JSON: ddd
  assets : Array[Asset]?
  layers : Array[Layer]
  markers : Array[Marker]?
  fonts : Array[FontInfo]?
  glyphs : Array[GlyphInfo]?
}

///|
pub fn Animation::new(
  version~ : String,
  frame_rate~ : Double,
  in_point~ : Double,
  out_point~ : Double,
  width~ : Int,
  height~ : Int,
  name? : String? = None,
  three_d? : Int? = None,
  assets? : Array[Asset]? = None,
  layers~ : Array[Layer],
  markers? : Array[Marker]? = None,
  fonts? : Array[FontInfo]? = None,
  glyphs? : Array[GlyphInfo]? = None,
) -> Animation {
  {
    version,
    frame_rate,
    in_point,
    out_point,
    width,
    height,
    name,
    three_d,
    assets,
    layers,
    markers,
    fonts,
    glyphs,
  }
}

///|
pub(all) struct Asset {
  id : String
  layers : Array[Layer]?
  path : String?
  folder : String?
  width : Int?
  height : Int?
}

///|
pub struct Marker {
  time : Double
  duration : Double
  marker_type : Double?
}
