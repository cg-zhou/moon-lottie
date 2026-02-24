pub enum LayerData {
  Shape(Array[Shape])
  Solid(String, Int, Int) // Color, width, height
  PreComp(String, Int, Int) // RefId, width, height
  Null
  Image(String) // RefId
}

pub struct Layer {
  ddd : Int?
  ind : Int
  ty : Int
  nm : String?
  parent : Int?
  ks : Transform
  ao : Int?
  ip : Double
  op : Double
  st : Double
  bm : Int?
  data : LayerData
}
