///|
pub(all) enum LayerData {
  Shape(Array[Shape])
  Solid(String, Int, Int) // Color, width, height
  PreComp(String, Int, Int) // RefId, width, height
  Null
  Image(String) // RefId
  Text(TextData)
}

///|
pub(all) struct TextData {
  text : LottieProperty[TextDocument]
}

///|
pub(all) struct TextDocument {
  size : Double
  font : String
  text : String
  justify : Int
  tracking : Double
  line_height : Double
  baseline_shift : Double
  fill_color : Array[Double]
}

///|
pub fn LayerData::new_shape(shapes : Array[Shape]) -> LayerData {
  LayerData::Shape(shapes)
}

///|
pub fn LayerData::new_solid(color : String, w : Int, h : Int) -> LayerData {
  LayerData::Solid(color, w, h)
}

///|
pub fn LayerData::new_null() -> LayerData {
  LayerData::Null
}

///|
pub struct Layer {
  three_d : Int?
  index : Int
  layer_type : Int
  name : String?
  parent : Int?
  transform : Transform
  auto_orient : Int?
  in_point : Double
  out_point : Double
  start_time : Double
  blend_mode : Int?
  hidden : Bool?
  masks : Array[Mask]?
  matte_type : Int?
  matte_inherit : Int?
  data : LayerData
}

///|
pub fn Layer::new(
  index~ : Int,
  layer_type~ : Int,
  transform~ : Transform,
  in_point~ : Double,
  out_point~ : Double,
  start_time~ : Double,
  three_d? : Int? = None,
  name? : String? = None,
  parent? : Int? = None,
  auto_orient? : Int? = None,
  blend_mode? : Int? = None,
  hidden? : Bool? = None,
  masks? : Array[Mask]? = None,
  matte_type? : Int? = None,
  matte_inherit? : Int? = None,
  data? : LayerData = LayerData::Null,
) -> Layer {
  {
    three_d,
    index,
    layer_type,
    name,
    parent,
    transform,
    auto_orient,
    in_point,
    out_point,
    start_time,
    blend_mode,
    hidden,
    masks,
    matte_type,
    matte_inherit,
    data,
  }
}
