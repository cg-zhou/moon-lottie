pub enum LayerData {
  Shape(Array[Shape])
  Solid(String, Int, Int) // Color, width, height
  PreComp(String, Int, Int) // RefId, width, height
  Null
  Image(String) // RefId
}

pub fn LayerData::new_shape(shapes : Array[Shape]) -> LayerData {
  LayerData::Shape(shapes)
}

pub fn LayerData::new_solid(color : String, w : Int, h : Int) -> LayerData {
  LayerData::Solid(color, w, h)
}

pub fn LayerData::new_null() -> LayerData {
  LayerData::Null
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
  hd : Bool? // Hidden
  masks : Array[Mask]?
  tt : Int? // Matte Type
  td : Int? // Matte Inherit (1 or 0)
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
  hd~ : Bool? = None,
  masks~ : Array[Mask]? = None,
  tt~ : Int? = None,
  td~ : Int? = None,
  data~ : LayerData = LayerData::Null
) -> Layer {
  { ddd, ind, ty, nm, parent, ks, ao, ip, op, st, bm, hd, masks, tt, td, data }
}
