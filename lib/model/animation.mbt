pub struct Animation {
  v : String    // Version
  fr : Double   // Frame rate
  ip : Double   // In point
  op : Double   // Out point
  w : Int       // Width
  h : Int       // Height
  nm : String?  // Name
  ddd : Int?    // 3D
  assets : Array[Asset]?
  layers : Array[Layer]
  markers : Array[Marker]?
}

pub enum Asset {
  Image(String, String, Int, Int) // Id, path, width, height
  PreComp(String, Array[Layer])   // Id, layers
}

pub struct Marker {
  tm : Double   // Time
  dur : Double  // Duration
  dr : Double?  // Marker type?
}
