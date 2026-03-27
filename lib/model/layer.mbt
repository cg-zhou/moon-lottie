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
pub(all) struct TextAnimatorSelector {
  based_on : Int
  shape : Int
  range_units : Int
  randomize : Int
  range_start : LottieProperty[Double]
  range_end : LottieProperty[Double]
  ease_high : LottieProperty[Double]
  ease_low : LottieProperty[Double]
  amount : LottieProperty[Double]
  offset : LottieProperty[Double]
}

///|
pub(all) struct TextAnimatorProperties {
  scale : LottieProperty[Array[Double]]?
  position : LottieProperty[Array[Double]]?
  rotation : LottieProperty[Double]?
  opacity : LottieProperty[Double]?
  tracking : LottieProperty[Double]?
  fill_color : LottieProperty[Array[Double]]?
  stroke_color : LottieProperty[Array[Double]]?
  stroke_width : LottieProperty[Double]?
}

///|
pub(all) struct TextAnimator {
  selector : TextAnimatorSelector
  properties : TextAnimatorProperties
}

///|
pub(all) struct TextData {
  text : LottieProperty[TextDocument]
  animators : Array[TextAnimator]
  anchor_grouping : Int
  grouping_alignment : LottieProperty[Array[Double]]
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
  stroke_color : Array[Double]
  stroke_width : Double
  stroke_over_fill : Bool
}

///|
pub(all) struct LayerFillEffect {
  color : LottieProperty[Array[Double]]
  opacity : LottieProperty[Double]
}

///|
pub fn LayerFillEffect::new(
  color~ : LottieProperty[Array[Double]],
  opacity~ : LottieProperty[Double],
) -> LayerFillEffect {
  { color, opacity }
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
  fill_effect : LayerFillEffect?
  time_remap : LottieProperty[Double]?
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
  fill_effect? : LayerFillEffect? = None,
  time_remap? : LottieProperty[Double]? = None,
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
    fill_effect,
    time_remap,
    data,
  }
}
