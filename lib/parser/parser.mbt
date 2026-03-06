///|
/// Lottie parsing errors
pub suberror LottieError {
  InvalidJson(String)
  MissingKey(String)
  UnexpectedType(String, String) // key, expected type
} derive(Show)

///|
/// Pilot derive-based decoding for animation root required fields.
struct AnimationRootJson {
  version : String
  frame_rate : Double
  in_point : Double
  out_point : Double
  width : Int
  height : Int
  name : String?
  three_d : Int?
  assets : Array[Json]?
  layers : Array[Json]
} derive(
  FromJson(
    fields(
      version(rename="v"),
      frame_rate(rename="fr"),
      in_point(rename="ip"),
      out_point(rename="op"),
      width(rename="w"),
      height(rename="h"),
      name(rename="nm"),
      three_d(rename="ddd"),
    ),
  ),
)

///|
struct TextDocumentJson {
  size : Double?
  font : String?
  text : String?
  justify : Int?
  tracking : Double?
  line_height : Double?
  baseline_shift : Double?
  fill_color : Array[Double]?
} derive(
  FromJson(
    fields(
      size(rename="s"),
      font(rename="f"),
      text(rename="t"),
      justify(rename="j"),
      tracking(rename="tr"),
      line_height(rename="lh"),
      baseline_shift(rename="ls"),
      fill_color(rename="fc"),
    ),
  ),
)

struct MaskJson {
  inverted : Bool?
  path : Json?
  opacity : Json?
  mode : String?
  name : String?
} derive(
  FromJson(
    fields(
      inverted(rename="inv"),
      path(rename="pt"),
      opacity(rename="o"),
      name(rename="nm"),
    ),
  ),
)

///|
struct PropertyJson {
  animated_flag : Json?
  expression : String?
  value : Json?
} derive(
  FromJson(
    fields(
      animated_flag(rename="a"),
      expression(rename="x"),
      value(rename="k"),
    ),
  ),
)

struct TransformJson {
  anchor : Json?
  position : Json?
  scale : Json?
  rotation : Json?
  opacity : Json?
  position_x : Json?
  position_y : Json?
  skew : Json?
  skew_axis : Json?
} derive(
  FromJson(
    fields(
      anchor(rename="a"),
      position(rename="p"),
      scale(rename="s"),
      rotation(rename="r"),
      opacity(rename="o"),
      position_x(rename="x"),
      position_y(rename="y"),
      skew(rename="sk"),
      skew_axis(rename="sa"),
    ),
  ),
)

///|
struct SplitPositionJson {
  split : Json?
} derive(FromJson(fields(split(rename="s"))))

///|
struct ShapeJson {
  shape_type : String
  name : String?
  hidden : Bool?
} derive(
  FromJson(
    fields(
      shape_type(rename="ty"),
      name(rename="nm"),
      hidden(rename="hd"),
    ),
  ),
)

///|
struct ShapeGroupJson {
  items : Array[Json]?
} derive(FromJson(fields(items(rename="it"))))

///|
struct ShapeRectJson {
  position : Json?
  size : Json?
  roundness : Json?
} derive(FromJson(fields(position(rename="p"), size(rename="s"), roundness(rename="r"))))

///|
struct ShapeEllipseJson {
  position : Json?
  size : Json?
} derive(FromJson(fields(position(rename="p"), size(rename="s"))))

///|
struct ShapePathJson {
  path : Json?
  closed : Json?
} derive(FromJson(fields(path(rename="ks"), closed(rename="closed"))))

///|
struct ShapeFillJson {
  color : Json?
  opacity : Json?
  fill_rule : Int?
} derive(FromJson(fields(color(rename="c"), opacity(rename="o"), fill_rule(rename="r"))))

///|
struct ShapeStrokeJson {
  color : Json?
  opacity : Json?
  width : Json?
  line_cap : Int?
  line_join : Int?
  miter_limit : Double?
  dashes : Array[Json]?
} derive(
  FromJson(
    fields(
      color(rename="c"),
      opacity(rename="o"),
      width(rename="w"),
      line_cap(rename="lc"),
      line_join(rename="lj"),
      miter_limit(rename="ml"),
      dashes(rename="d"),
    ),
  ),
)

///|
struct DashItemJson {
  name : String?
  value : Json?
} derive(
  FromJson(
    fields(
      name(rename="n"),
      value(rename="v"),
    ),
  ),
)

///|
struct ShapeGradientFillJson {
  gradient_type : Int?
  start_point : Json?
  end_point : Json?
  opacity : Json?
  gradient : Json?
  fill_rule : Int?
} derive(
  FromJson(
    fields(
      gradient_type(rename="t"),
      start_point(rename="s"),
      end_point(rename="e"),
      opacity(rename="o"),
      gradient(rename="g"),
      fill_rule(rename="r"),
    ),
  ),
)

///|
struct ShapeGradientStrokeJson {
  gradient_type : Int?
  start_point : Json?
  end_point : Json?
  opacity : Json?
  width : Json?
  line_cap : Int?
  line_join : Int?
  miter_limit : Double?
  gradient : Json?
} derive(
  FromJson(
    fields(
      gradient_type(rename="t"),
      start_point(rename="s"),
      end_point(rename="e"),
      opacity(rename="o"),
      width(rename="w"),
      line_cap(rename="lc"),
      line_join(rename="lj"),
      miter_limit(rename="ml"),
      gradient(rename="g"),
    ),
  ),
)

///|
struct ShapeTrimPathJson {
  start : Json?
  end : Json?
  offset : Json?
  multiple : Int?
} derive(
  FromJson(fields(start(rename="s"), end(rename="e"), offset(rename="o"), multiple(rename="m"))),
)

///|
struct ShapePolystarJson {
  points : Json?
  position : Json?
  rotation : Json?
  inner_radius : Json?
  inner_roundness : Json?
  outer_radius : Json?
  outer_roundness : Json?
  star_type : Int?
} derive(
  FromJson(
    fields(
      points(rename="pt"),
      position(rename="p"),
      rotation(rename="r"),
      inner_radius(rename="ir"),
      inner_roundness(rename="is"),
      outer_radius(rename="or"),
      outer_roundness(rename="os"),
      star_type(rename="sy"),
    ),
  ),
)

///|
struct ShapeRepeaterJson {
  copies : Json?
  offset : Json?
  composite : Int?
  transform : TransformJson?
} derive(
  FromJson(
    fields(copies(rename="c"), offset(rename="o"), composite(rename="m"), transform(rename="tr")),
  ),
)

///|
struct RepeaterTransformExtraJson {
  start_opacity : Json?
  end_opacity : Json?
} derive(
  FromJson(
    fields(start_opacity(rename="so"), end_opacity(rename="eo")),
  ),
)

///|
struct ShapeMergePathsJson {
  merge_mode : Int?
} derive(FromJson(fields(merge_mode(rename="mm"))))

///|
struct ShapeRoundingJson {
  radius : Json?
} derive(FromJson(fields(radius(rename="r"))))

///|
struct LayerJson {
  index : Int?
  layer_type : Int
  transform : TransformJson?
  in_point : Double?
  out_point : Double?
  start_time : Double?
  name : String?
  hidden : Bool?
  parent : Int?
  masks : Array[Json]?
  matte_type : Int?
  matte_inherit : Int?
  ref_id : String?
  width : Int?
  height : Int?
  solid_color : String?
  solid_width : Int?
  solid_height : Int?
  shapes : Array[Json]?
  text_data : TextDataJson?
  effects : Array[Json]?
} derive(
  FromJson(
    fields(
      index(rename="ind"),
      layer_type(rename="ty"),
      transform(rename="ks"),
      in_point(rename="ip"),
      out_point(rename="op"),
      start_time(rename="st"),
      name(rename="nm"),
      hidden(rename="hd"),
      parent(rename="parent"),
      masks(rename="masksProperties"),
      matte_type(rename="tt"),
      matte_inherit(rename="td"),
      ref_id(rename="refId"),
      width(rename="w"),
      height(rename="h"),
      solid_color(rename="sc"),
      solid_width(rename="sw"),
      solid_height(rename="sh"),
      shapes(rename="shapes"),
      text_data(rename="t"),
      effects(rename="ef"),
    ),
  ),
)

///|
struct LayerEffectParamJson {
  match_name : String?
  value : Json?
} derive(FromJson(fields(match_name(rename="mn"), value(rename="v"))))

///|
struct LayerEffectJson {
  effect_type : Int?
  enabled : Int?
  match_name : String?
  params : Array[Json]?
} derive(
  FromJson(
    fields(
      effect_type(rename="ty"),
      enabled(rename="en"),
      match_name(rename="mn"),
      params(rename="ef"),
    ),
  ),
)

///|
struct AssetJson {
  id : String
  layers : Array[Json]?
  path : String?
  folder : String?
  width : Int?
  height : Int?
} derive(
  FromJson(
    fields(
      path(rename="p"),
      folder(rename="u"),
      width(rename="w"),
      height(rename="h"),
    ),
  ),
)

///|
struct TextDataJson {
  document : Json?
} derive(FromJson(fields(document(rename="d"))))

///|
struct GradientJson {
  color_count : Int?
  color_stops : Json?
} derive(
  FromJson(
    fields(
      color_count(rename="p"),
      color_stops(rename="k"),
    ),
  ),
)

///|
struct BezierPathJson {
  vertices : Array[Array[Double]]?
  in_tangents : Array[Array[Double]]?
  out_tangents : Array[Array[Double]]?
  closed : Json?
} derive(
  FromJson(
    fields(
      vertices(rename="v"),
      in_tangents(rename="i"),
      out_tangents(rename="o"),
      closed(rename="c"),
    ),
  ),
)

struct BezierTangentJson {
  x : Json?
  y : Json?
} derive(FromJson)

struct PropertyKeyframeJson {
  time : Double?
  start_value : Json?
  end_value : Json?
  in_tangent : Json?
  out_tangent : Json?
  hold : Json?
  value_in_tangent : Array[Double]?
  value_out_tangent : Array[Double]?
} derive(
  FromJson(
    fields(
      time(rename="t"),
      start_value(rename="s"),
      end_value(rename="e"),
      in_tangent(rename="i"),
      out_tangent(rename="o"),
      hold(rename="h"),
      value_in_tangent(rename="ti"),
      value_out_tangent(rename="to"),
    ),
  ),
)

struct TextPropertyJson {
  animated_flag : Json?
  value : Json?
} derive(
  FromJson(
    fields(
      animated_flag(rename="a"),
      value(rename="k"),
    ),
  ),
)

///|
/// Global tracker for unknown keys (for L1 Reporting)
let known_keys : Array[String] = [
  "v", "fr", "ip", "op", "w", "h", "nm", "ddd", "assets", "layers", "fonts", "chars",
  "ty", "ks", "p", "a", "k", "s", "e", "o", "r", "sk", "sa", "x", "y", "z",
  "d", "st", "bm", "ind", "cl", "ln", "tg", "sr", "parent", "sh", "sw", "sc", "lc", "lj", "ml",
  "shapes", "it", "c", "g", "t", "hd", "v", "fc", "fill-rule", "gr", "tr", "p", "s", "r", "o",
  "expressions", "markers", "metadata", "masks", "inv", "pt", "mode", "px", "py", "pz", "i", "h", "to",
  "ti", "n",
]

///|
fn contains_key(arr : Array[String], key : String) -> Bool {
  for k in arr {
    if k == key {
      return true
    }
  }
  false
}

///|
/// Traverse Json to find any keys not in known_keys
pub fn report_unknown_keys(json : Json) -> Array[String] {
  let unknown = []
  fn traverse(j : Json, path : String) {
    match j {
      Object(obj) =>
        for k, v in obj {
          if not(contains_key(known_keys, k)) {
            unknown.push(if path == "" { k } else { path + "." + k })
          }
          traverse(v, if path == "" { k } else { path + "." + k })
        }
      Array(arr) =>
        for i, v in arr {
          let p = if path == "" { "" } else { path }
          traverse(v, "\{p}[\{i}]")
        }
      _ => ()
    }
  }

  traverse(json, "")
  unknown
}

///|
/// Unknown-key reporting summary with coverage counters.
pub struct UnknownKeyReport {
  total_keys : Int
  known_keys : Int
  unknown_paths : Array[String]
} derive(Show, Eq)

///|
/// Traverse Json to collect unknown keys and known/unknown coverage counters.
pub fn report_unknown_keys_with_coverage(json : Json) -> UnknownKeyReport {
  let mut total_keys = 0
  let mut known_keys_count = 0
  let unknown_paths = []
  fn traverse(j : Json, path : String) {
    match j {
      Object(obj) =>
        for k, v in obj {
          total_keys = total_keys + 1
          if contains_key(known_keys, k) {
            known_keys_count = known_keys_count + 1
          } else {
            unknown_paths.push(if path == "" { k } else { path + "." + k })
          }
          traverse(v, if path == "" { k } else { path + "." + k })
        }
      Array(arr) =>
        for i, v in arr {
          traverse(v, "\{path}[\{i}]")
        }
      _ => ()
    }
  }

  traverse(json, "")
  { total_keys, known_keys: known_keys_count, unknown_paths }
}

///|
fn parse_bezier_value(json : Json?) -> @model.BezierValue? {
  match json {
    Some(j) => {
      let single : Double? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match single {
        Some(v) => Some(@model.BezierValue::new_single(v))
        None => {
          let multi : Array[Double]? = try {
            Some(@json.from_json(j))
          } catch {
            _ => None
          }
          match multi {
            Some(values) => Some(@model.BezierValue::new_multi(values))
            None => None
          }
        }
      }
    }
    _ => None
  }
}

///|
fn parse_bezier_tangent(json : Json?) -> @model.Bezier? {
  match json {
    Some(j) => {
      let tangent : BezierTangentJson = (@json.from_json(j)) catch {
        _ => return None
      }
      match (parse_bezier_value(tangent.x), parse_bezier_value(tangent.y)) {
        (Some(x), Some(y)) => Some(@model.Bezier::new(x, y))
        _ => None
      }
    }
    _ => None
  }
}

fn property_animated_flag(flag : Json?) -> Bool {
  match flag {
    Some(j) => {
      let number_flag : Double? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match number_flag {
        Some(n) => n == 1.0
        None => {
          let bool_flag : Bool? = try {
            Some(@json.from_json(j))
          } catch {
            _ => None
          }
          match bool_flag {
            Some(v) => v
            None => false
          }
        }
      }
    }
    _ => false
  }
}

fn parse_gradient_or_default(json : Json) -> GradientJson {
  // Keep parser tolerant: malformed gradient metadata falls back to raw `g.k` parsing path below.
  (@json.from_json(json)) catch { _ => { color_count: None, color_stops: None } }
}

fn is_animated_keyframe_array(k : Json) -> Bool {
  match k {
    Array(arr) =>
      if arr.length() > 0 {
        let first = arr[0]
        let keyframe : PropertyKeyframeJson? = try {
          Some(@json.from_json(first))
        } catch {
          _ => None
        }
        match keyframe {
          Some(kf) =>
            match kf.time {
              Some(_) => true
              None => false
            }
          None => false
        }
      } else {
        false
      }
    _ => false
  }
}

fn keyframe_time_or_zero(time : Double?) -> Double {
  match time {
    Some(t) => t
    None => 0.0
  }
}

fn keyframe_hold_or_none(hold : Json?) -> Int? {
  match hold {
    Some(j) => {
      let int_hold : Int? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match int_hold {
        Some(v) => Some(v)
        None => {
          let num_hold : Double? = try {
            Some(@json.from_json(j))
          } catch {
            _ => None
          }
          match num_hold {
            Some(n) => Some(n.to_int())
            None => None
          }
        }
      }
    }
    _ => None
  }
}

///|
/// Parse a simple Property (non-animated for now)
fn parse_property_double(
  json : Json?,
) -> @model.LottieProperty[Double] raise LottieError {
  match json {
    Some(j) => {
      let prop : PropertyJson? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match prop {
        Some(prop) => {
          let a_flag = property_animated_flag(prop.animated_flag)
          let x = prop.expression
          let k = match prop.value {
            Some(v) => v
            None => raise MissingKey("k in property")
          }
          let animated_from_k = is_animated_keyframe_array(k)
          if a_flag || animated_from_k {
            // Animated
            let keyframes = []
            let mut prev_value : Double? = None
            match k {
              Array(arr) =>
                for kf_json in arr {
                  let keyframe : PropertyKeyframeJson? = try {
                    Some(@json.from_json(kf_json))
                  } catch {
                    _ => None
                  }
                  let keyframe = match keyframe {
                    Some(v) => v
                    None => continue
                  }
                  let t = keyframe_time_or_zero(keyframe.time)
                  let s = match keyframe.start_value {
                    Some(Array([Number(n, ..)])) => n
                    Some(Number(n, ..)) => n
                    _ =>
                      match prev_value {
                        Some(v) => v
                        None => 0.0
                      }
                  }
                  let e = match keyframe.end_value {
                    Some(Array([Number(n, ..)])) => Some(n)
                    Some(Number(n, ..)) => Some(n)
                    _ => None
                  }
                  let in_tangent = parse_bezier_tangent(keyframe.in_tangent)
                  let out_tangent = parse_bezier_tangent(keyframe.out_tangent)
                  keyframes.push(
                    @model.LottieKeyframe::new(
                      frame=t,
                      start_value=s,
                      end_value=e,
                      in_tangent=in_tangent,
                      out_tangent=out_tangent,
                      hold=keyframe_hold_or_none(keyframe.hold),
                    ),
                  )
                  prev_value = match e {
                    Some(v) => Some(v)
                    None => Some(s)
                  }
                }
              _ => ()
            }
            @model.LottieProperty::new_animated(keyframes, expression=x)
          } else {
            let value : Double = (@json.from_json(k)) catch {
              _ => raise UnexpectedType("k", "Number")
            }
            @model.LottieProperty::new_static(value, expression=x)
          }
        }
        None => {
          let value : Double = (@json.from_json(j)) catch {
            _ => raise UnexpectedType("property", "Object or Number")
          }
          @model.LottieProperty::new_static(value)
        }
      }
    }
    None => raise InvalidJson("Property json is missing")
  }
}

///|
fn parse_property_vec(
  json : Json?,
) -> @model.LottieProperty[Array[Double]] raise LottieError {
  match json {
    Some(j) => {
      let prop : PropertyJson? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match prop {
        Some(prop) => {
          let a_flag = property_animated_flag(prop.animated_flag)
          let x = prop.expression
          let k = match prop.value {
            Some(v) => v
            None => raise MissingKey("k in property")
          }
          let animated_from_k = is_animated_keyframe_array(k)
          if a_flag || animated_from_k {
            // Animated
            let keyframes = []
            let mut prev_value : Array[Double]? = None
            match k {
              Array(arr) =>
                for kf_json in arr {
                  let keyframe : PropertyKeyframeJson? = try {
                    Some(@json.from_json(kf_json))
                  } catch {
                    _ => None
                  }
                  let keyframe = match keyframe {
                    Some(v) => v
                    None => continue
                  }
                  let t = keyframe_time_or_zero(keyframe.time)
                  let s = match keyframe.start_value {
                    Some(Array(arr)) => {
                      let res = []
                      for v in arr {
                        match v {
                          Number(n, ..) => res.push(n)
                          _ => ()
                        }
                      }
                      res
                    }
                    _ =>
                      match prev_value {
                        Some(v) => v
                        None => []
                      }
                  }
                  let e = match keyframe.end_value {
                    Some(Array(arr)) => {
                      let res = []
                      for v in arr {
                        match v {
                          Number(n, ..) => res.push(n)
                          _ => ()
                        }
                      }
                      Some(res)
                    }
                    _ => None
                  }
                  let in_tangent = parse_bezier_tangent(keyframe.in_tangent)
                  let out_tangent = parse_bezier_tangent(keyframe.out_tangent)
                  keyframes.push(
                    @model.LottieKeyframe::new(
                      frame=t,
                      start_value=s,
                      end_value=e,
                      in_tangent=in_tangent,
                      out_tangent=out_tangent,
                      value_in_tangent=keyframe.value_in_tangent,
                      value_out_tangent=keyframe.value_out_tangent,
                      hold=keyframe_hold_or_none(keyframe.hold),
                    ),
                  )
                  prev_value = match e {
                    Some(v) => Some(v)
                    None => Some(s)
                  }
                }
              _ => ()
            }
            @model.LottieProperty::new_animated(keyframes, expression=x)
          } else {
            let vals : Array[Double]? = try {
              Some(@json.from_json(k))
            } catch {
              _ => None
            }
            match vals {
              Some(vs) => @model.LottieProperty::new_static(vs, expression=x)
              None => {
                let n : Double = (@json.from_json(k)) catch {
                  _ => raise UnexpectedType("k", "Array or Number")
                }
                @model.LottieProperty::new_static([n], expression=x)
              }
            }
          }
        }
        None => {
          let vals : Array[Double] = (@json.from_json(j)) catch {
            _ => raise UnexpectedType("property", "Object or Array")
          }
          @model.LottieProperty::new_static(vals)
        }
      }
    }
    None => raise InvalidJson("Property json is missing")
  }
}

///|
fn parse_text_document(json : Json) -> @model.TextDocument raise LottieError {
  let decoded : TextDocumentJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("text document", "Object")
  }
  {
    size: decoded.size.unwrap_or(12.0),
    font: decoded.font.unwrap_or(""),
    text: decoded.text.unwrap_or(""),
    justify: decoded.justify.unwrap_or(0),
    tracking: decoded.tracking.unwrap_or(0.0),
    line_height: decoded.line_height.unwrap_or(0.0),
    baseline_shift: decoded.baseline_shift.unwrap_or(0.0),
    fill_color: decoded.fill_color.unwrap_or([0.0, 0.0, 0.0]),
  }
}

///|
fn parse_text_document_property(
  json : Json?,
) -> @model.LottieProperty[@model.TextDocument] raise LottieError {
  match json {
    Some(j) => {
      let prop : TextPropertyJson = (@json.from_json(j)) catch {
        _ => raise UnexpectedType("text property", "Object")
      }
      let a = property_animated_flag(prop.animated_flag)
      let k = match prop.value {
        Some(v) => v
        None => raise MissingKey("k in text property")
      }
      if a {
        let keyframes = []
        match k {
          Array(arr) =>
            for kf_json in arr {
              let keyframe : PropertyKeyframeJson? = try {
                Some(@json.from_json(kf_json))
              } catch {
                _ => None
              }
              let keyframe = match keyframe {
                Some(v) => v
                None => continue
              }
              let s = match keyframe.start_value {
                Some(v) => parse_text_document(v)
                None => raise MissingKey("s in text keyframe")
              }
              keyframes.push(
                @model.LottieKeyframe::new(
                  frame=keyframe_time_or_zero(keyframe.time),
                  start_value=s,
                ),
              )
            }
          _ => ()
        }
        @model.LottieProperty::new_animated(keyframes)
      } else {
        match k {
          Array(arr) =>
            if arr.length() > 0 {
              @model.LottieProperty::new_static(parse_text_document(arr[0]))
            } else {
              raise MissingKey("k array is empty")
            }
          _ => @model.LottieProperty::new_static(parse_text_document(k))
        }
      }
    }
    None => raise InvalidJson("Text property missing")
  }
}

///|
fn parse_text_data_from_decoded(
  decoded : TextDataJson?,
) -> @model.TextData raise LottieError {
  match decoded {
    Some(d_json) => {
      let d = parse_text_document_property(d_json.document)
      { text: d }
    }
    None => raise InvalidJson("Text data is missing")
  }
}

///|
/// Parse Transform
fn parse_transform_from_decoded(
  decoded : TransformJson?,
) -> @model.Transform raise LottieError {
  match decoded {
    Some(transform_json) => {
      let split = match transform_json.position {
        Some(position_json) => {
          let split_json : SplitPositionJson = (@json.from_json(position_json)) catch {
            _ => { split: None }
          }
          match split_json.split {
            Some(True) => true
            _ => false
          }
        }
        None => false
      }
      let anchor = parse_property_vec(transform_json.anchor)
      let position = parse_property_vec(transform_json.position)
      let px = if split {
        Some(parse_property_double(transform_json.position_x)) catch {
          _ => None
        }
      } else {
        None
      }
      let py = if split {
        Some(parse_property_double(transform_json.position_y)) catch {
          _ => None
        }
      } else {
        None
      }
      let scale = parse_property_vec(transform_json.scale)
      let rotation = parse_property_double(transform_json.rotation)
      let opacity = parse_property_double(transform_json.opacity)
      let skew = try {
        Some(parse_property_double(transform_json.skew))
      } catch {
        _ => None
      }
      let skew_axis = try {
        Some(parse_property_double(transform_json.skew_axis))
      } catch {
        _ => None
      }
      @model.Transform::new(
        anchor~,
        position~,
        scale~,
        rotation~,
        opacity~,
         px~,
         py~,
         skew~,
         skew_axis~,
        split=if split { Some(true) } else { None },
      )
    }
    None => raise InvalidJson("Transform json is missing")
  }
}

///|
/// Parse BezierPath data (the 'v', 'i', 'o', 'c' structure)
fn parse_closed_flag(json : Json?, default_closed : Bool) -> Bool {
  match json {
    Some(True) => true
    Some(False) => false
    Some(Number(n, ..)) => n == 1.0
    _ => default_closed
  }
}

///|
fn parse_bezier_path(
  json : Json,
  fallback_closed : Bool,
) -> @model.BezierPath raise LottieError {
  let decoded : BezierPathJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("bezier_path", "Object")
  }
  let closed = parse_closed_flag(decoded.closed, fallback_closed)
  let vertices = decoded.vertices.unwrap_or([])
  let in_tangents = decoded.in_tangents.unwrap_or([])
  let out_tangents = decoded.out_tangents.unwrap_or([])
  @model.BezierPath::new(vertices~, in_tangents~, out_tangents~, closed~)
}

///|
/// Parse LottieProperty with BezierPath value
fn parse_property_bezier(
  json : Json?,
  fallback_closed : Bool,
) -> @model.LottieProperty[@model.BezierPath] raise LottieError {
  match json {
    Some(j) => {
      let prop : PropertyJson? = try {
        Some(@json.from_json(j))
      } catch {
        _ => None
      }
      match prop {
        Some(prop) => {
          let a_flag = property_animated_flag(prop.animated_flag)
          match prop.value {
            Some(k) =>
              if a_flag || is_animated_keyframe_array(k) {
                let keyframes = []
                match k {
                  Array(arr) =>
                    for kf_json in arr {
                      let keyframe : PropertyKeyframeJson? = try {
                        Some(@json.from_json(kf_json))
                      } catch {
                        _ => None
                      }
                      let keyframe = match keyframe {
                        Some(v) => v
                        None => continue
                      }
                      let s = try {
                        match keyframe.start_value {
                          Some(Array([val])) => parse_bezier_path(val, fallback_closed)
                          Some(val) => parse_bezier_path(val, fallback_closed)
                          None => raise MissingKey("s in keyframe")
                        }
                      } catch {
                        _ => continue
                      }
                      let e = try {
                        match keyframe.end_value {
                          Some(Array([val])) => Some(parse_bezier_path(val, fallback_closed))
                          Some(val) => Some(parse_bezier_path(val, fallback_closed))
                          _ => None
                        }
                      } catch {
                        _ => None
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=keyframe_time_or_zero(keyframe.time),
                          start_value=s,
                          end_value=e,
                          hold=keyframe_hold_or_none(keyframe.hold),
                        ),
                      )
                    }
                  _ => ()
                }
                @model.LottieProperty::new_animated(keyframes)
              } else {
                @model.LottieProperty::new_static(parse_bezier_path(k, fallback_closed))
              }
            None => @model.LottieProperty::new_static(parse_bezier_path(j, fallback_closed))
          }
        }
        None => @model.LottieProperty::new_static(parse_bezier_path(j, fallback_closed))
      }
    }
    None => raise InvalidJson("Property bezier json is missing")
  }
}

///| Parse a single Shape object

///|
/// Parse dash items from stroke "d" array
fn parse_dash_items(
  dashes : Array[Json]?,
) -> Array[@model.DashItem] {
  let result : Array[@model.DashItem] = []
  match dashes {
    Some(arr) =>
      for d in arr {
        let item : DashItemJson = (@json.from_json(d)) catch {
          _ => continue
        }
        let name = item.name.unwrap_or("")
        let value = parse_property_double(item.value) catch {
          _ => @model.LottieProperty::new_static(0.0)
        }
        result.push(@model.DashItem::new(name~, value~))
      }
    None => ()
  }
  result
}

///|
/// Parse a shape from Json
pub fn parse_shape(json : Json) -> @model.Shape raise LottieError {
  let common : ShapeJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("shape", "Object")
  }
  let shape_type = common.shape_type
  let data : @model.ShapeData = match shape_type {
    "gr" => {
      let decoded : ShapeGroupJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape gr", "Object")
      }
      let items = []
      match decoded.items {
        Some(arr) =>
          for i in arr {
            items.push(parse_shape(i)) catch {
              _ => ()
            }
          }
        None => ()
      }
      @model.ShapeData::new_group(items)
    }
    "rc" => {
      let decoded : ShapeRectJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape rc", "Object")
      }
      let position = parse_property_vec(decoded.position)
      let size = parse_property_vec(decoded.size)
      let roundness = parse_property_double(decoded.roundness) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      @model.ShapeData::new_rect(@model.RectShape::new(position~, size~, roundness~))
    }
    "el" => {
      let decoded : ShapeEllipseJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape el", "Object")
      }
      let position = parse_property_vec(decoded.position)
      let size = parse_property_vec(decoded.size)
      @model.ShapeData::new_ellipse(@model.EllipseShape::new(position~, size~))
    }
    "sh" => {
      let decoded : ShapePathJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape sh", "Object")
      }
      let shape_closed = parse_closed_flag(decoded.closed, false)
      let path = parse_property_bezier(decoded.path, shape_closed)
      @model.ShapeData::new_path(@model.PathShape::new(path~))
    }
    "fl" => {
      let decoded : ShapeFillJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape fl", "Object")
      }
      let color = parse_property_vec(decoded.color)
      let opacity = parse_property_double(decoded.opacity) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let fill_rule = decoded.fill_rule.unwrap_or(1)
      @model.ShapeData::new_fill(@model.FillShape::new(color~, opacity~, fill_rule~))
    }
    "st" => {
      let decoded : ShapeStrokeJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape st", "Object")
      }
      let color = parse_property_vec(decoded.color)
      let opacity = parse_property_double(decoded.opacity) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let width = parse_property_double(decoded.width) catch {
        _ => @model.LottieProperty::new_static(1.0)
      }
      let line_cap = decoded.line_cap.unwrap_or(1)
      let line_join = decoded.line_join.unwrap_or(1)
      let miter_limit = decoded.miter_limit.unwrap_or(4.0)
      let dashes = parse_dash_items(decoded.dashes)
      @model.ShapeData::new_stroke(
        @model.StrokeShape::new(color~, opacity~, width~, line_cap~, line_join~, miter_limit~, dashes~),
      )
    }
    "gf" => {
      let decoded : ShapeGradientFillJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape gf", "Object")
      }
      let gradient_type = decoded.gradient_type.unwrap_or(1)
      let start_point = parse_property_vec(decoded.start_point)
      let end_point = parse_property_vec(decoded.end_point)
      let opacity = parse_property_double(decoded.opacity) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let g_json = match decoded.gradient {
        Some(j) => j
        None => raise MissingKey("g in gf")
      }
      let gradient = parse_gradient_or_default(g_json)
      let g_p = gradient.color_count.unwrap_or(0)
      let g_k = match gradient.color_stops {
        Some(k_json) => parse_property_vec(Some(k_json))
        None => parse_property_vec(Some(g_json))
      }
      let g_colors = @model.GradientColors::new(color_count=g_p, color_stops=g_k)
      let fill_rule = decoded.fill_rule.unwrap_or(1)
      @model.ShapeData::new_gradient_fill(
        @model.GradientFillShape::new(
          gradient_type~,
          opacity~,
          start_point~,
          end_point~,
          gradient_colors=g_colors,
          fill_rule~,
        ),
      )
    }
    "gs" => {
      let decoded : ShapeGradientStrokeJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape gs", "Object")
      }
      let gradient_type = decoded.gradient_type.unwrap_or(1)
      let start_point = parse_property_vec(decoded.start_point)
      let end_point = parse_property_vec(decoded.end_point)
      let opacity = parse_property_double(decoded.opacity) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let width = parse_property_double(decoded.width) catch {
        _ => @model.LottieProperty::new_static(1.0)
      }
      let line_cap = decoded.line_cap.unwrap_or(1)
      let line_join = decoded.line_join.unwrap_or(1)
      let miter_limit = decoded.miter_limit.unwrap_or(4.0)
      let g_json = match decoded.gradient {
        Some(j) => j
        None => raise MissingKey("g in gs")
      }
      let gradient = parse_gradient_or_default(g_json)
      let g_p = gradient.color_count.unwrap_or(0)
      let g_k = match gradient.color_stops {
        Some(k_json) => parse_property_vec(Some(k_json))
        None => parse_property_vec(Some(g_json))
      }
      let g_colors = @model.GradientColors::new(color_count=g_p, color_stops=g_k)
      @model.ShapeData::new_gradient_stroke(
        @model.GradientStrokeShape::new(
          gradient_type~,
          opacity~,
          start_point~,
          end_point~,
          gradient_colors=g_colors,
          width~,
          line_cap~,
          line_join~,
          miter_limit~,
        ),
      )
    }
    "tr" => {
      let decoded : TransformJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape tr", "Object")
      }
      @model.ShapeData::new_transform(parse_transform_from_decoded(Some(decoded)))
    }
    "tm" => {
      let decoded : ShapeTrimPathJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape tm", "Object")
      }
      let start = parse_property_double(decoded.start) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let end = parse_property_double(decoded.end) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let offset = parse_property_double(decoded.offset) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let multiple = decoded.multiple.unwrap_or(1)
      @model.ShapeData::new_trim_path(@model.TrimPath::new(start~, end~, offset~, multiple~))
    }
    "sr" => {
      let decoded : ShapePolystarJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape sr", "Object")
      }
      let points = parse_property_double(decoded.points)
      let position = parse_property_vec(decoded.position)
      let rotation = parse_property_double(decoded.rotation)
      let inner_radius = parse_property_double(decoded.inner_radius) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let inner_roundness = parse_property_double(decoded.inner_roundness) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let outer_radius = parse_property_double(decoded.outer_radius)
      let outer_roundness = parse_property_double(decoded.outer_roundness) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let star_type = decoded.star_type.unwrap_or(1)
      @model.ShapeData::new_polystar(
        @model.PolystarShape::new(
          points~,
          position~,
          rotation~,
          inner_radius~,
          inner_roundness~,
          outer_radius~,
          outer_roundness~,
          star_type~,
        ),
      )
    }
    "rp" => {
      let decoded : ShapeRepeaterJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape rp", "Object")
      }
      let copies = parse_property_double(decoded.copies)
      let offset = parse_property_double(decoded.offset)
      let composite = decoded.composite.unwrap_or(1)
      let transform = match decoded.transform {
        Some(t) => parse_transform_from_decoded(Some(t))
        None => raise MissingKey("tr in rp")
      }
      // Parse start_opacity (so) and end_opacity (eo) from the raw tr JSON
      let tr_json = match json {
        Object(m) =>
          match m.get("tr") {
            Some(tr) => Some(tr)
            None => None
          }
        _ => None
      }
      let (start_opacity, end_opacity) = match tr_json {
        Some(tj) => {
          let extra : RepeaterTransformExtraJson = (@json.from_json(tj)) catch {
            _ => { start_opacity: None, end_opacity: None }
          }
          let so = parse_property_double(extra.start_opacity) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let eo = parse_property_double(extra.end_opacity) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          (so, eo)
        }
        None => (
          @model.LottieProperty::new_static(100.0),
          @model.LottieProperty::new_static(100.0),
        )
      }
      @model.ShapeData::new_repeater(
        @model.Repeater::new(copies~, offset~, composite~, transform~, start_opacity~, end_opacity~),
      )
    }
    "mm" => {
      let decoded : ShapeMergePathsJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape mm", "Object")
      }
      let mm = decoded.merge_mode.unwrap_or(1)
      @model.ShapeData::new_merge_paths(@model.MergePaths::new(mm))
    }
    "rd" => {
      let decoded : ShapeRoundingJson = (@json.from_json(json)) catch {
        _ => raise UnexpectedType("shape rd", "Object")
      }
      let radius = parse_property_double(decoded.radius) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      @model.ShapeData::new_rounding(@model.Rounding::new(radius~))
    }
    _ => raise InvalidJson("Unknown shape type: " + shape_type)
  }
  let name = common.name
  let hidden = common.hidden
  @model.Shape::new(shape_type~, data~, name~, hidden~)
}

///|
/// Parse a single Mask object
fn parse_mask(json : Json) -> @model.Mask raise LottieError {
  let decoded : MaskJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("mask", "Object")
  }
  let inverted = decoded.inverted.unwrap_or(false)
  let path = parse_property_bezier(decoded.path, false)
  let opacity = parse_property_double(decoded.opacity) catch {
    _ => @model.LottieProperty::new_static(100.0)
  }
  let mode = match decoded.mode {
    Some("a") => @model.MaskMode::Add
    Some("s") => @model.MaskMode::Subtract
    Some("i") => @model.MaskMode::Intersect
    Some("l") => @model.MaskMode::Lighten
    Some("d") => @model.MaskMode::Darken
    Some("f") => @model.MaskMode::Difference
    _ => @model.MaskMode::None
  }
  @model.Mask::new(inverted~, path~, opacity~, mode~, name=decoded.name)
}

///|
fn parse_layer_fill_effect(
  effects : Array[Json]?,
) -> @model.LayerFillEffect? {
  match effects {
    Some(arr) => {
      for effect_json in arr {
        let effect : LayerEffectJson = (@json.from_json(effect_json)) catch {
          _ => continue
        }
        if effect.enabled == Some(0) {
          continue
        }
        let is_fill = effect.match_name == Some("ADBE Fill") ||
          effect.effect_type == Some(21)
        if not(is_fill) {
          continue
        }
        let mut color = @model.LottieProperty::new_static([0.0, 0.0, 0.0, 1.0])
        let mut opacity = @model.LottieProperty::new_static(100.0)
        match effect.params {
          Some(params) => {
            for p_json in params {
              let param : LayerEffectParamJson = (@json.from_json(p_json)) catch {
                _ => continue
              }
              match param.match_name {
                Some("ADBE Fill-0002") => {
                  color = parse_property_vec(param.value) catch {
                    _ => color
                  }
                }
                Some("ADBE Fill-0005") => {
                  opacity = parse_property_double(param.value) catch {
                    _ => opacity
                  }
                }
                _ => ()
              }
            }
          }
          None => ()
        }
        return Some(@model.LayerFillEffect::new(color~, opacity~))
      }
      None
    }
    None => None
  }
}

///|
/// Parse Layer
fn parse_layer(json : Json) -> @model.Layer raise LottieError {
  let decoded : LayerJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("layer", "Object")
  }
  let index = decoded.index.unwrap_or(0)
  let layer_type = decoded.layer_type
  let transform = parse_transform_from_decoded(decoded.transform)
  let in_point = decoded.in_point.unwrap_or(0.0)
  let out_point = decoded.out_point.unwrap_or(1000.0)
  let start_time = decoded.start_time.unwrap_or(0.0)
  let name = decoded.name
  let hidden = decoded.hidden
  let parent = decoded.parent
  let masks = match decoded.masks {
    Some(arr) => {
      let res = []
      for m_json in arr {
        res.push(parse_mask(m_json)) catch {
          _ => ()
        }
      }
      Some(res)
    }
    None => None
  }
  let matte_type = decoded.matte_type
  let matte_inherit = decoded.matte_inherit
  let fill_effect = parse_layer_fill_effect(decoded.effects)
  let data : @model.LayerData = match layer_type {
    0 => @model.LayerData::PreComp(decoded.ref_id.unwrap_or(""), decoded.width.unwrap_or(0), decoded.height.unwrap_or(0))
    1 => @model.LayerData::Solid(
      decoded.solid_color.unwrap_or("#000000"),
      decoded.solid_width.unwrap_or(0),
      decoded.solid_height.unwrap_or(0),
    )
    2 => @model.LayerData::Image(decoded.ref_id.unwrap_or(""))
    3 => @model.LayerData::Null
    4 => {
      let shapes = []
      match decoded.shapes {
        Some(arr) =>
          for s_json in arr {
            shapes.push(parse_shape(s_json)) catch {
              _ => ()
            }
          }
        None => ()
      }
      @model.LayerData::Shape(shapes)
    }
    5 => @model.LayerData::Text(parse_text_data_from_decoded(decoded.text_data))
    _ => @model.LayerData::Null
  }
  @model.Layer::new(
    index~,
    layer_type~,
    transform~,
    in_point~,
    out_point~,
    start_time~,
    name~,
    data~,
    hidden~,
    parent~,
    masks~,
    matte_type~,
    matte_inherit~,
    fill_effect~,
  )
}

///|
/// Parse the top-level Animation object
pub fn parse_animation(json : Json) -> @model.Animation raise LottieError {
  let root : AnimationRootJson = (@json.from_json(json)) catch {
    e =>
      raise InvalidJson(
        "Animation root decode failed (required: v, fr, ip, op, w, h): \{e}",
      )
  }
  let version = root.version
  let frame_rate = root.frame_rate
  let in_point = root.in_point
  let out_point = root.out_point
  let width = root.width
  let height = root.height

  let layers = []
  let assets = []
  match root.assets {
    Some(arr) =>
      for a_json in arr {
        assets.push(parse_asset(a_json)) catch {
          _ => ()
        }
      }
    None => ()
  }
  for l_json in root.layers {
    layers.push(parse_layer(l_json)) catch {
      _ => ()
    }
  }

  @model.Animation::new(
    version~,
    frame_rate~,
    in_point~,
    out_point~,
    width~,
    height~,
    name=root.name,
    three_d=root.three_d,
    assets=if assets.length() > 0 { Some(assets) } else { None },
    layers~,
  )
}

///|
/// Parse a single asset object (Image or PreComp)
fn parse_asset(json : Json) -> @model.Asset raise LottieError {
  let decoded : AssetJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("asset", "Object")
  }
  match decoded.layers {
    Some(arr) => {
      let layers = []
      for l_json in arr {
        layers.push(parse_layer(l_json)) catch {
          _ => ()
        }
      }
      {
        id: decoded.id,
        layers: Some(layers),
        path: None,
        folder: None,
        width: None,
        height: None,
      }
    }
    None => {
      {
        id: decoded.id,
        layers: None,
        path: decoded.path,
        folder: decoded.folder,
        width: decoded.width,
        height: decoded.height,
      }
    }
  }
}
