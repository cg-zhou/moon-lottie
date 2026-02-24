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

pub fn Layer::new(
  ind~ : Int,
  ty~ : Int,
  ks~ : Transform,
  ip~ : Double,
  op~ : Double,
  st~ : Double,
  ddd~ : Int? = None,
  nm~ : String? = None,
  parent~ : Int? = None,
  ao~ : Int? = None,
  bm~ : Int? = None,
  data~ : LayerData = LayerData::Null
) -> Layer {
  { ddd, ind, ty, nm, parent, ks, ao, ip, op, st, bm, data }
}
