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

///|
struct KeyframeJson {
  frame : Double?
  start_value : Json?
  end_value : Json?
  in_tangent : Json?
  out_tangent : Json?
  value_in_tangent : Array[Double]?
  value_out_tangent : Array[Double]?
  hold : Int?
} derive(
  FromJson(
    fields(
      frame(rename="t"),
      start_value(rename="s"),
      end_value(rename="e"),
      in_tangent(rename="i"),
      out_tangent(rename="o"),
      value_in_tangent(rename="ti"),
      value_out_tangent(rename="to"),
      hold(rename="h"),
    ),
  ),
)

///|
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
  items : Array[Json]?
  path : Json?
  position : Json?
  size_or_start : Json?
  end_or_bezier : Json?
  rotation_or_roundness : Json?
  color_or_copies : Json?
  opacity_or_offset : Json?
  width : Json?
  line_cap : Int?
  line_join : Int?
  miter_limit : Double?
  gradient_type : Int?
  gradient : Json?
  trim_or_composite : Int?
  points : Json?
  inner_radius : Json?
  inner_roundness : Json?
  outer_radius : Json?
  outer_roundness : Json?
  star_type : Int?
  transform : Json?
  merge_mode : Int?
} derive(
  FromJson(
    fields(
      shape_type(rename="ty"),
      name(rename="nm"),
      hidden(rename="hd"),
      items(rename="it"),
      path(rename="ks"),
      position(rename="p"),
      size_or_start(rename="s"),
      end_or_bezier(rename="e"),
      rotation_or_roundness(rename="r"),
      color_or_copies(rename="c"),
      opacity_or_offset(rename="o"),
      width(rename="w"),
      line_cap(rename="lc"),
      line_join(rename="lj"),
      miter_limit(rename="ml"),
      gradient_type(rename="t"),
      gradient(rename="g"),
      trim_or_composite(rename="m"),
      points(rename="pt"),
      inner_radius(rename="ir"),
      inner_roundness(rename="is"),
      outer_radius(rename="or"),
      outer_roundness(rename="os"),
      star_type(rename="sy"),
      transform(rename="tr"),
      merge_mode(rename="mm"),
    ),
  ),
)

///|
struct LayerJson {
  index : Int?
  layer_type : Int
  transform : Json?
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
  text_data : Json?
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
      masks(rename="masksProperties"),
      matte_type(rename="tt"),
      matte_inherit(rename="td"),
      ref_id(rename="refId"),
      width(rename="w"),
      height(rename="h"),
      solid_color(rename="sc"),
      solid_width(rename="sw"),
      solid_height(rename="sh"),
      text_data(rename="t"),
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
    Some(Number(n, ..)) => Some(@model.BezierValue::new_single(n))
    Some(Array(arr)) => {
      let values = []
      for v in arr {
        match v {
          Number(n, ..) => values.push(n)
          _ => ()
        }
      }
      Some(@model.BezierValue::new_multi(values))
    }
    _ => None
  }
}

///|
fn parse_bezier_tangent(json : Json?) -> @model.Bezier? {
  match json {
    Some(Object(obj)) =>
      match (parse_bezier_value(obj.get("x")), parse_bezier_value(obj.get("y"))) {
        (Some(x), Some(y)) => Some(@model.Bezier::new(x, y))
        _ => None
      }
    _ => None
  }
}

fn property_animated_flag(flag : Json?) -> Bool {
  match flag {
    Some(Number(n, ..)) => n == 1.0
    Some(True) => true
    _ => false
  }
}

///|
fn has_keyframe_time(json : Json) -> Bool {
  let kf : KeyframeJson = (@json.from_json(json)) catch { _ => return false }
  kf.frame != None
}

///|
/// Parse a simple Property (non-animated for now)
fn parse_property_double(
  json : Json?,
) -> @model.LottieProperty[Double] raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(_) => {
          let prop : PropertyJson = (@json.from_json(j)) catch {
            _ => raise UnexpectedType("property", "Object")
          }
          let a_flag = property_animated_flag(prop.animated_flag)
          let x = prop.expression
          let k = match prop.value {
            Some(v) => v
            None => raise MissingKey("k in property")
          }
          let animated_from_k = match k {
            Array(arr) =>
              if arr.length() > 0 {
                has_keyframe_time(arr[0])
              } else {
                false
              }
            _ => false
          }
          if a_flag || animated_from_k {
            // Animated
            let keyframes = []
            let mut prev_value : Double? = None
            match k {
              Array(arr) =>
                for kf_json in arr {
                  let kf : KeyframeJson = (@json.from_json(kf_json)) catch { _ => continue }
                  let t = kf.frame.unwrap_or(0.0).to_int()
                  let s = match kf.start_value {
                    Some(Array([Number(n, ..)])) => n
                    Some(Number(n, ..)) => n
                    _ =>
                      match prev_value {
                        Some(v) => v
                        None => 0.0
                      }
                  }
                  let e = match kf.end_value {
                    Some(Array([Number(n, ..)])) => Some(n)
                    Some(Number(n, ..)) => Some(n)
                    _ => None
                  }
                  let in_tangent = parse_bezier_tangent(kf.in_tangent)
                  let out_tangent = parse_bezier_tangent(kf.out_tangent)
                  keyframes.push(
                    @model.LottieKeyframe::new(
                      frame=t,
                      start_value=s,
                      end_value=e,
                      in_tangent=in_tangent,
                      out_tangent=out_tangent,
                      hold=kf.hold,
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
            match k {
              Number(n, ..) =>
                @model.LottieProperty::new_static(n, expression=x)
              _ => raise UnexpectedType("k", "Number")
            }
          }
        }
        Number(n, ..) => @model.LottieProperty::new_static(n)
        _ => raise UnexpectedType("property", "Object or Number")
      }
    None => raise InvalidJson("Property json is missing")
  }
}

///|
fn parse_property_vec(
  json : Json?,
) -> @model.LottieProperty[Array[Double]] raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(_) => {
          let prop : PropertyJson = (@json.from_json(j)) catch {
            _ => raise UnexpectedType("property", "Object")
          }
          let a_flag = property_animated_flag(prop.animated_flag)
          let x = prop.expression
          let k = match prop.value {
            Some(v) => v
            None => raise MissingKey("k in property")
          }
          let animated_from_k = match k {
            Array(arr) =>
              if arr.length() > 0 {
                has_keyframe_time(arr[0])
              } else {
                false
              }
            _ => false
          }
          if a_flag || animated_from_k {
            // Animated
            let keyframes = []
            let mut prev_value : Array[Double]? = None
            match k {
              Array(arr) =>
                for kf_json in arr {
                  let kf : KeyframeJson = (@json.from_json(kf_json)) catch { _ => continue }
                  let t = kf.frame.unwrap_or(0.0).to_int()
                  let s = match kf.start_value {
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
                  let e = match kf.end_value {
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
                  let in_tangent = parse_bezier_tangent(kf.in_tangent)
                  let out_tangent = parse_bezier_tangent(kf.out_tangent)
                  keyframes.push(
                    @model.LottieKeyframe::new(
                      frame=t,
                      start_value=s,
                      end_value=e,
                      in_tangent=in_tangent,
                      out_tangent=out_tangent,
                      value_in_tangent=kf.value_in_tangent,
                      value_out_tangent=kf.value_out_tangent,
                      hold=kf.hold,
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
            match k {
              Array(arr) => {
                let vals = []
                for v in arr {
                  match v {
                    Number(n, ..) => vals.push(n)
                    _ => ()
                  }
                }
                @model.LottieProperty::new_static(vals, expression=x)
              }
              Number(n, ..) =>
                @model.LottieProperty::new_static([n], expression=x)
              _ => raise UnexpectedType("k", "Array or Number")
            }
          }
        }
        Array(arr) => {
          let vals = []
          for v in arr {
            match v {
              Number(n, ..) => vals.push(n)
              _ => ()
            }
          }
          @model.LottieProperty::new_static(vals)
        }
        _ => raise UnexpectedType("property", "Object or Array")
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
    Some(j) =>
      match j {
        Object(obj) => {
          let a = match obj.get("a") {
            Some(Number(n, ..)) => n == 1.0
            _ => false
          }
          let k = match obj.get("k") {
            Some(k) => k
            None => raise MissingKey("k in text property")
          }
          if a {
            let keyframes = []
            match k {
              Array(arr) =>
                for kf_json in arr {
                  match kf_json {
                    Object(kf_obj) => {
                      let t = match kf_obj.get("t") {
                        Some(Number(n, ..)) => n.to_int()
                        _ => 0
                      }
                      let s = match kf_obj.get("s") {
                        Some(json) => parse_text_document(json)
                        _ => raise MissingKey("s in text keyframe")
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(frame=t, start_value=s),
                      )
                    }
                    _ => ()
                  }
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
              Object(_) =>
                @model.LottieProperty::new_static(parse_text_document(k))
              _ => raise UnexpectedType("k", "Array or Object")
            }
          }
        }
        _ => raise UnexpectedType("text property", "Object")
      }
    None => raise InvalidJson("Text property missing")
  }
}

///|
fn parse_text_data(json : Json?) -> @model.TextData raise LottieError {
  match json {
    Some(j) => {
      let decoded : TextDataJson = (@json.from_json(j)) catch {
        _ => raise UnexpectedType("text data", "Object")
      }
      let d = parse_text_document_property(decoded.document)
      { text: d }
    }
    None => raise UnexpectedType("text data", "Object")
  }
}

///|
/// Parse Transform
fn parse_transform(json : Json?) -> @model.Transform raise LottieError {
  match json {
    Some(j) => {
      let decoded : TransformJson = (@json.from_json(j)) catch {
        _ => raise UnexpectedType("transform", "Object")
      }
      let split = match decoded.position {
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
      let anchor = parse_property_vec(decoded.anchor)
      let position = parse_property_vec(decoded.position)
      let px = if split {
        Some(parse_property_double(decoded.position_x)) catch {
          _ => None
        }
      } else {
        None
      }
      let py = if split {
        Some(parse_property_double(decoded.position_y)) catch {
          _ => None
        }
      } else {
        None
      }
      let scale = parse_property_vec(decoded.scale)
      let rotation = parse_property_double(decoded.rotation)
      let opacity = parse_property_double(decoded.opacity)
      let skew = try {
        Some(parse_property_double(decoded.skew))
      } catch {
        _ => None
      }
      let skew_axis = try {
        Some(parse_property_double(decoded.skew_axis))
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
fn parse_bezier_path(json : Json) -> @model.BezierPath raise LottieError {
  let decoded : BezierPathJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("bezier_path", "Object")
  }
  let closed = match decoded.closed {
    Some(True) => true
    Some(False) => false
    Some(Number(n, ..)) => n == 1.0
    _ => false
  }
  let vertices = decoded.vertices.unwrap_or([])
  let in_tangents = decoded.in_tangents.unwrap_or([])
  let out_tangents = decoded.out_tangents.unwrap_or([])
  @model.BezierPath::new(vertices~, in_tangents~, out_tangents~, closed~)
}

///|
/// Parse LottieProperty with BezierPath value
fn parse_property_bezier(
  json : Json?,
) -> @model.LottieProperty[@model.BezierPath] raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(_) => {
          let prop : PropertyJson = (@json.from_json(j)) catch {
            _ => raise UnexpectedType("property_bezier", "Object")
          }
          let a_flag = property_animated_flag(prop.animated_flag)
          match prop.value {
            Some(k) =>
              if a_flag || (
                match k {
                  Array(arr) =>
                    if arr.length() > 0 {
                      has_keyframe_time(arr[0])
                    } else {
                      false
                    }
                  _ => false
                }
              ) {
                let keyframes = []
                match k {
                  Array(arr) =>
                    for kf_json in arr {
                      let kf : KeyframeJson = (@json.from_json(kf_json)) catch { _ => continue }
                      let t = kf.frame.unwrap_or(0.0).to_int()
                      let s = try {
                        match kf.start_value {
                          Some(Array([val])) => parse_bezier_path(val)
                          Some(val) => parse_bezier_path(val)
                          None => raise MissingKey("s in keyframe")
                        }
                      } catch {
                        _ => continue
                      }
                      let e = try {
                        match kf.end_value {
                          Some(Array([val])) => Some(parse_bezier_path(val))
                          Some(val) => Some(parse_bezier_path(val))
                          _ => None
                        }
                      } catch {
                        _ => None
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=t,
                          start_value=s,
                          end_value=e,
                          hold=kf.hold,
                        ),
                      )
                    }
                  _ => ()
                }
                @model.LottieProperty::new_animated(keyframes)
              } else {
                @model.LottieProperty::new_static(parse_bezier_path(k))
              }
            None => @model.LottieProperty::new_static(parse_bezier_path(j))
          }
        }
        _ => raise UnexpectedType("property_bezier", "Object")
      }
    None => raise InvalidJson("Property bezier json is missing")
  }
}

///| Parse a single Shape object

///|
/// Parse a shape from Json
pub fn parse_shape(json : Json) -> @model.Shape raise LottieError {
  let decoded : ShapeJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("shape", "Object")
  }
  let shape_type = decoded.shape_type
  let data : @model.ShapeData = match shape_type {
    "gr" => {
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
      let position = parse_property_vec(decoded.position)
      let size = parse_property_vec(decoded.size_or_start)
      let roundness = parse_property_double(decoded.rotation_or_roundness) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      @model.ShapeData::new_rect(@model.RectShape::new(position~, size~, roundness~))
    }
    "el" => {
      let position = parse_property_vec(decoded.position)
      let size = parse_property_vec(decoded.size_or_start)
      @model.ShapeData::new_ellipse(@model.EllipseShape::new(position~, size~))
    }
    "sh" => {
      let path = parse_property_bezier(decoded.path)
      @model.ShapeData::new_path(@model.PathShape::new(path~))
    }
    "fl" => {
      let color = parse_property_vec(decoded.color_or_copies)
      let opacity = parse_property_double(decoded.opacity_or_offset) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      @model.ShapeData::new_fill(@model.FillShape::new(color~, opacity~))
    }
    "st" => {
      let color = parse_property_vec(decoded.color_or_copies)
      let opacity = parse_property_double(decoded.opacity_or_offset) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let width = parse_property_double(decoded.width) catch {
        _ => @model.LottieProperty::new_static(1.0)
      }
      let line_cap = decoded.line_cap.unwrap_or(1)
      let line_join = decoded.line_join.unwrap_or(1)
      let miter_limit = decoded.miter_limit.unwrap_or(4.0)
      @model.ShapeData::new_stroke(
        @model.StrokeShape::new(color~, opacity~, width~, line_cap~, line_join~, miter_limit~),
      )
    }
    "gf" => {
      let gradient_type = decoded.gradient_type.unwrap_or(1)
      let start_point = parse_property_vec(decoded.size_or_start)
      let end_point = parse_property_vec(decoded.end_or_bezier)
      let opacity = parse_property_double(decoded.opacity_or_offset) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let g_json = match decoded.gradient {
        Some(j) => j
        None => raise MissingKey("g in gf")
      }
      let gradient : GradientJson = (@json.from_json(g_json)) catch {
        _ => { color_count: None, color_stops: None }
      }
      let g_p = gradient.color_count.unwrap_or(0)
      let g_k = match gradient.color_stops {
        Some(k_json) => parse_property_vec(Some(k_json))
        None => parse_property_vec(Some(g_json))
      }
      let g_colors = @model.GradientColors::new(color_count=g_p, color_stops=g_k)
      @model.ShapeData::new_gradient_fill(
        @model.GradientFillShape::new(
          gradient_type~,
          opacity~,
          start_point~,
          end_point~,
          gradient_colors=g_colors,
        ),
      )
    }
    "gs" => {
      let gradient_type = decoded.gradient_type.unwrap_or(1)
      let start_point = parse_property_vec(decoded.size_or_start)
      let end_point = parse_property_vec(decoded.end_or_bezier)
      let opacity = parse_property_double(decoded.opacity_or_offset) catch {
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
      let gradient : GradientJson = (@json.from_json(g_json)) catch {
        _ => { color_count: None, color_stops: None }
      }
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
    "tr" => @model.ShapeData::new_transform(parse_transform(Some(json)))
    "tm" => {
      let start = parse_property_double(decoded.size_or_start) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let end = parse_property_double(decoded.end_or_bezier) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let offset = parse_property_double(decoded.opacity_or_offset) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      let multiple = decoded.trim_or_composite.unwrap_or(1)
      @model.ShapeData::new_trim_path(@model.TrimPath::new(start~, end~, offset~, multiple~))
    }
    "sr" => {
      let points = parse_property_double(decoded.points)
      let position = parse_property_vec(decoded.position)
      let rotation = parse_property_double(decoded.rotation_or_roundness)
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
      let copies = parse_property_double(decoded.color_or_copies)
      let offset = parse_property_double(decoded.opacity_or_offset)
      let composite = decoded.trim_or_composite.unwrap_or(1)
      let transform = parse_transform(decoded.transform)
      @model.ShapeData::new_repeater(
        @model.Repeater::new(copies~, offset~, composite~, transform~),
      )
    }
    "mm" => {
      let mm = decoded.merge_mode.unwrap_or(1)
      @model.ShapeData::new_merge_paths(@model.MergePaths::new(mm))
    }
    "rd" => {
      let radius = parse_property_double(decoded.rotation_or_roundness) catch {
        _ => @model.LottieProperty::new_static(0.0)
      }
      @model.ShapeData::new_rounding(@model.Rounding::new(radius~))
    }
    _ => raise InvalidJson("Unknown shape type: " + shape_type)
  }
  let name = decoded.name
  let hidden = decoded.hidden
  @model.Shape::new(shape_type~, data~, name~, hidden~)
}

///|
/// Parse a single Mask object
fn parse_mask(json : Json) -> @model.Mask raise LottieError {
  let decoded : MaskJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("mask", "Object")
  }
  let inverted = decoded.inverted.unwrap_or(false)
  let path = parse_property_bezier(decoded.path)
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
/// Parse Layer
fn parse_layer(json : Json) -> @model.Layer raise LottieError {
  let decoded : LayerJson = (@json.from_json(json)) catch {
    _ => raise UnexpectedType("layer", "Object")
  }
  let index = decoded.index.unwrap_or(0)
  let layer_type = decoded.layer_type
  let transform = parse_transform(decoded.transform)
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
    5 => @model.LayerData::Text(parse_text_data(decoded.text_data))
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
