pub struct Animation {
  pub v : String    // Version
  pub fr : Double   // Frame rate
  pub ip : Double   // In point
  pub op : Double   // Out point
  pub w : Int       // Width
  pub h : Int       // Height
  pub nm : String?  // Name
  pub ddd : Int?    // 3D
  pub assets : Array[Asset]?
  pub layers : Array[Layer]
  pub markers : Array[Marker]?
}

pub enum Asset {
  Image(String, String, Int, Int) // Id, path, width, height
  PreComp(String, Array[Layer])   // Id, layers
}

pub struct Marker {
  pub tm : Double   // Time
  pub dur : Double  // Duration
  pub dr : Double?  // Marker type?
}
