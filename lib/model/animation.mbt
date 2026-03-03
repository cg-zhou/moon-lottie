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
  }
}

///|
pub(all) struct Asset {
  id : String
  layers : Array[Layer]?
  p : String? // path/image data
  u : String? // image folder
  w : Int? // width
  h : Int? // height
}

///|
pub struct Marker {
  tm : Double // Time
  dur : Double // Duration
  dr : Double? // Marker type?
}
