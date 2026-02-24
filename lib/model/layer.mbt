pub enum LayerData {
  Shape(Array[Shape])
  Solid(String, Int, Int) // Color, width, height
  PreComp(String, Int, Int) // RefId, width, height
  Null
  Image(String) // RefId
}

pub struct Layer {
  pub ddd : Int?
  pub ind : Int
  pub ty : Int
  pub nm : String?
  pub parent : Int?
  pub ks : Transform
  pub ao : Int?
  pub ip : Double
  pub op : Double
  pub st : Double
  pub bm : Int?
  pub data : LayerData
}
