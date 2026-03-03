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
} derive(
  FromJson(
    fields(
      version(rename="v"),
      frame_rate(rename="fr"),
      in_point(rename="ip"),
      out_point(rename="op"),
      width(rename="w"),
      height(rename="h"),
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

///|
struct AssetImageJson {
  id : String
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
/// Helper to get string from Json
fn get_string(json : Json, key : String) -> String raise LottieError {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(String(s)) => s
        Some(_) => raise UnexpectedType(key, "String")
        None => raise MissingKey(key)
      }
    _ => raise InvalidJson("Expected Object when looking for key: " + key)
  }
}

///|
/// Helper to get double from Json
fn get_double(json : Json, key : String) -> Double raise LottieError {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(Number(n, ..)) => n
        Some(_) => raise UnexpectedType(key, "Number")
        None => raise MissingKey(key)
      }
    _ => raise InvalidJson("Expected Object when looking for key: " + key)
  }
}

///|
/// Helper to get int from Json
fn get_int(json : Json, key : String) -> Int raise LottieError {
  get_double(json, key).to_int()
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

///|
fn parse_number_array(json : Json?) -> Array[Double]? {
  match json {
    Some(Array(arr)) => {
      let values = []
      for v in arr {
        match v {
          Number(n, ..) => values.push(n)
          _ => ()
        }
      }
      Some(values)
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
    Some(j) =>
      match j {
        Object(obj) => {
          let a_flag = match obj.get("a") {
            Some(Number(n, ..)) => n == 1.0
            _ => false
          }
          let x = match obj.get("x") {
            Some(String(s)) => Some(s)
            _ => None
          }
          let k = match obj.get("k") {
            Some(k) => k
            None => raise MissingKey("k in property")
          }
          let animated_from_k = match k {
            Array(arr) =>
              if arr.length() > 0 {
                match arr[0] {
                  Object(first) =>
                    match first.get("t") {
                      Some(_) => true
                      _ => false
                    }
                  _ => false
                }
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
                  match kf_json {
                    Object(kf_obj) => {
                      let t = match kf_obj.get("t") {
                        Some(Number(n, ..)) => n.to_int()
                        _ => 0
                      }
                      let s = match kf_obj.get("s") {
                        Some(Array([Number(n, ..)])) => n
                        Some(Number(n, ..)) => n
                        _ =>
                          match prev_value {
                            Some(v) => v
                            None => 0.0
                          }
                      }
                      let e = match kf_obj.get("e") {
                        Some(Array([Number(n, ..)])) => Some(n)
                        Some(Number(n, ..)) => Some(n)
                        _ => None
                      }
                      let in_tangent = parse_bezier_tangent(kf_obj.get("i"))
                      let out_tangent = parse_bezier_tangent(kf_obj.get("o"))
                      let hold = match kf_obj.get("h") {
                        Some(Number(n, ..)) => Some(n.to_int())
                        _ => None
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=t,
                          start_value=s,
                          end_value=e,
                          in_tangent=in_tangent,
                          out_tangent=out_tangent,
                          hold=hold,
                        ),
                      )
                      prev_value = match e {
                        Some(v) => Some(v)
                        None => Some(s)
                      }
                    }
                    _ => ()
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
        Object(obj) => {
          let a_flag = match obj.get("a") {
            Some(Number(n, ..)) => n == 1.0
            _ => false
          }
          let x = match obj.get("x") {
            Some(String(s)) => Some(s)
            _ => None
          }
          let k = match obj.get("k") {
            Some(k) => k
            None => raise MissingKey("k in property")
          }
          let animated_from_k = match k {
            Array(arr) =>
              if arr.length() > 0 {
                match arr[0] {
                  Object(first) =>
                    match first.get("t") {
                      Some(_) => true
                      _ => false
                    }
                  _ => false
                }
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
                  match kf_json {
                    Object(kf_obj) => {
                      let t = match kf_obj.get("t") {
                        Some(Number(n, ..)) => n.to_int()
                        _ => 0
                      }
                      let s = match kf_obj.get("s") {
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
                      let e = match kf_obj.get("e") {
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
                      let in_tangent = parse_bezier_tangent(kf_obj.get("i"))
                      let out_tangent = parse_bezier_tangent(kf_obj.get("o"))
                      let value_in_tangent = parse_number_array(kf_obj.get("ti"))
                      let value_out_tangent = parse_number_array(kf_obj.get("to"))
                      let hold = match kf_obj.get("h") {
                        Some(Number(n, ..)) => Some(n.to_int())
                        _ => None
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=t,
                          start_value=s,
                          end_value=e,
                          in_tangent=in_tangent,
                          out_tangent=out_tangent,
                          value_in_tangent=value_in_tangent,
                          value_out_tangent=value_out_tangent,
                          hold=hold,
                        ),
                      )
                      prev_value = match e {
                        Some(v) => Some(v)
                        None => Some(s)
                      }
                    }
                    _ => ()
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
    Some(Object(obj)) => {
      let d = parse_text_document_property(obj.get("d"))
      { text: d }
    }
    _ => raise UnexpectedType("text data", "Object")
  }
}

///|
/// Parse Transform
fn parse_transform(json : Json?) -> @model.Transform raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let split = match obj.get("p") {
            Some(Object(p_obj)) =>
              match p_obj.get("s") {
                Some(True) => true
                _ => false
              }
            _ => false
          }
          let anchor = parse_property_vec(obj.get("a"))
          let position = parse_property_vec(obj.get("p"))
          let px = if split {
            Some(parse_property_double(obj.get("x"))) catch {
              _ => None
            }
          } else {
            None
          }
          let py = if split {
            Some(parse_property_double(obj.get("y"))) catch {
              _ => None
            }
          } else {
            None
          }
          let scale = parse_property_vec(obj.get("s"))
          let rotation = parse_property_double(obj.get("r"))
          let opacity = parse_property_double(obj.get("o"))
          let skew = try {
            Some(parse_property_double(obj.get("sk")))
          } catch {
            _ => None
          }
          let skew_axis = try {
            Some(parse_property_double(obj.get("sa")))
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
        _ => raise UnexpectedType("transform", "Object")
      }
    None => raise InvalidJson("Transform json is missing")
  }
}

///|
/// Parse BezierPath data (the 'v', 'i', 'o', 'c' structure)
fn parse_bezier_path(json : Json) -> @model.BezierPath raise LottieError {
  match json {
    Object(obj) => {
      let vertices = match obj.get("v") {
        Some(Array(arr)) => {
          let res = []
          for p in arr {
            match p {
              Array([Number(x, ..), Number(y, ..)]) => res.push([x, y])
              _ => ()
            }
          }
          res
        }
        _ => []
      }
      let in_tangents = match obj.get("i") {
        Some(Array(arr)) => {
          let res = []
          for p in arr {
            match p {
              Array([Number(x, ..), Number(y, ..)]) => res.push([x, y])
              _ => ()
            }
          }
          res
        }
        _ => []
      }
      let out_tangents = match obj.get("o") {
        Some(Array(arr)) => {
          let res = []
          for p in arr {
            match p {
              Array([Number(x, ..), Number(y, ..)]) => res.push([x, y])
              _ => ()
            }
          }
          res
        }
        _ => []
      }
      let closed = match obj.get("c") {
        Some(True) => true
        Some(False) => false
        Some(Number(n, ..)) => n == 1.0
        _ => false
      }
      @model.BezierPath::new(vertices~, in_tangents~, out_tangents~, closed~)
    }
    _ => raise UnexpectedType("bezier_path", "Object")
  }
}

///|
/// Parse LottieProperty with BezierPath value
fn parse_property_bezier(
  json : Json?,
) -> @model.LottieProperty[@model.BezierPath] raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let a_flag = match obj.get("a") {
            Some(Number(n, ..)) => n == 1.0
            _ => false
          }
          match obj.get("k") {
            Some(k) =>
              if a_flag || (
                match k {
                  Array(arr) =>
                    if arr.length() > 0 {
                      match arr[0] {
                        Object(first) =>
                          match first.get("t") {
                            Some(_) => true
                            _ => false
                          }
                        _ => false
                      }
                    } else {
                      false
                    }
                  _ => false
                }
              ) {
                // Animated
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
                          let s = try {
                            match kf_obj.get("s") {
                              Some(Array([val])) => parse_bezier_path(val)
                              Some(val) => parse_bezier_path(val)
                              None => raise MissingKey("s in keyframe")
                            }
                          } catch {
                            _ => continue
                          }
                          let e = try {
                            match kf_obj.get("e") {
                              Some(Array([val])) => Some(parse_bezier_path(val))
                              Some(val) => Some(parse_bezier_path(val))
                              _ => None
                            }
                          } catch {
                            _ => None
                          }
                          let hold = match kf_obj.get("h") {
                            Some(Number(n, ..)) => Some(n.to_int())
                            _ => None
                          }
                          keyframes.push(
                            @model.LottieKeyframe::new(
                              frame=t,
                              start_value=s,
                              end_value=e,
                              hold=hold,
                            ),
                          )
                        }
                        _ => ()
                      }
                    }
                  _ => ()
                }
                @model.LottieProperty::new_animated(keyframes)
              } else {
                @model.LottieProperty::new_static(parse_bezier_path(k))
              }
            None =>
              // Case 2: Simple path { "v": ... } without being wrapped in property
              @model.LottieProperty::new_static(parse_bezier_path(j))
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
  match json {
    Object(obj) => {
      let shape_type = match obj.get("ty") {
        Some(String(s)) => s
        _ => raise MissingKey("ty in shape")
      }
      let name = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let hidden = match obj.get("hd") {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
      let data : @model.ShapeData = match shape_type {
        "gr" => {
          let items = []
          match obj.get("it") {
            Some(Array(arr)) =>
              for i in arr {
                items.push(parse_shape(i)) catch {
                  _ => ()
                }
              }
            _ => ()
          }
          @model.ShapeData::new_group(items)
        }
        "rc" => {
          let position = parse_property_vec(obj.get("p"))
          let size = parse_property_vec(obj.get("s"))
          let roundness = parse_property_double(obj.get("r")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          @model.ShapeData::new_rect(@model.RectShape::new(position~, size~, roundness~))
        }
        "el" => {
          let position = parse_property_vec(obj.get("p"))
          let size = parse_property_vec(obj.get("s"))
          @model.ShapeData::new_ellipse(@model.EllipseShape::new(position~, size~))
        }
        "sh" => {
          let path = parse_property_bezier(obj.get("ks"))
          @model.ShapeData::new_path(@model.PathShape::new(path~))
        }
        "fl" => {
          let color = parse_property_vec(obj.get("c"))
          let opacity = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          @model.ShapeData::new_fill(@model.FillShape::new(color~, opacity~))
        }
        "st" => {
          let color = parse_property_vec(obj.get("c"))
          let opacity = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let width = parse_property_double(obj.get("w")) catch {
            _ => @model.LottieProperty::new_static(1.0)
          }
          let line_cap = match obj.get("lc") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let line_join = match obj.get("lj") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let miter_limit = match obj.get("ml") {
            Some(Number(n, ..)) => n
            _ => 4.0
          }
          @model.ShapeData::new_stroke(
            @model.StrokeShape::new(color~, opacity~, width~, line_cap~, line_join~, miter_limit~),
          )
        }
        "gf" => {
          let gradient_type = match obj.get("t") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let start_point = parse_property_vec(obj.get("s"))
          let end_point = parse_property_vec(obj.get("e"))
          let opacity = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let g_json = match obj.get("g") {
            Some(j) => j
            _ => raise MissingKey("g in gf")
          }
          let (g_p, g_k) = match g_json {
            Object(g_obj) => {
              let color_count = match g_obj.get("p") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }
              let color_stops = match g_obj.get("k") {
                Some(k_json) => parse_property_vec(Some(k_json))
                _ => parse_property_vec(Some(g_json))
              }
              (color_count, color_stops)
            }
            _ => (0, parse_property_vec(Some(g_json)))
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
          let gradient_type = match obj.get("t") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let start_point = parse_property_vec(obj.get("s"))
          let end_point = parse_property_vec(obj.get("e"))
          let opacity = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let width = parse_property_double(obj.get("w")) catch {
            _ => @model.LottieProperty::new_static(1.0)
          }
          let line_cap = match obj.get("lc") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let line_join = match obj.get("lj") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let miter_limit = match obj.get("ml") {
            Some(Number(n, ..)) => n
            _ => 4.0
          }
          let g_json = match obj.get("g") {
            Some(j) => j
            _ => raise MissingKey("g in gs")
          }
          let (g_p, g_k) = match g_json {
            Object(g_obj) => {
              let color_count = match g_obj.get("p") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }
              let color_stops = match g_obj.get("k") {
                Some(k_json) => parse_property_vec(Some(k_json))
                _ => parse_property_vec(Some(g_json))
              }
              (color_count, color_stops)
            }
            _ => (0, parse_property_vec(Some(g_json)))
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
          let start = parse_property_double(obj.get("s")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let end = parse_property_double(obj.get("e")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let offset = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let multiple = get_int(json, "m") catch { _ => 1 }
          @model.ShapeData::new_trim_path(@model.TrimPath::new(start~, end~, offset~, multiple~))
        }
        "sr" => {
          let points = parse_property_double(obj.get("pt"))
          let position = parse_property_vec(obj.get("p"))
          let rotation = parse_property_double(obj.get("r"))
          let inner_radius = parse_property_double(obj.get("ir")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let inner_roundness = parse_property_double(obj.get("is")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let outer_radius = parse_property_double(obj.get("or"))
          let outer_roundness = parse_property_double(obj.get("os")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let star_type = match obj.get("sy") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
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
          let copies = parse_property_double(obj.get("c"))
          let offset = parse_property_double(obj.get("o"))
          let composite = get_int(json, "m") catch { _ => 1 }
          let transform = parse_transform(obj.get("tr"))
          @model.ShapeData::new_repeater(
            @model.Repeater::new(copies~, offset~, composite~, transform~),
          )
        }
        "mm" => {
          let mm = get_int(json, "mm") catch { _ => 1 }
          @model.ShapeData::new_merge_paths(@model.MergePaths::new(mm))
        }
        "rd" => {
          let radius = parse_property_double(obj.get("r")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          @model.ShapeData::new_rounding(@model.Rounding::new(radius~))
        }
        _ => raise InvalidJson("Unknown shape type: " + shape_type)
      }
      @model.Shape::new(shape_type~, data~, name~, hidden~)
    }
    _ => raise UnexpectedType("shape", "Object")
  }
}

///|
/// Parse a single Mask object
fn parse_mask(json : Json) -> @model.Mask raise LottieError {
  match json {
    Object(obj) => {
      let inverted = match obj.get("inv") {
        Some(True) => true
        _ => false
      }
      let path = parse_property_bezier(obj.get("pt"))
      let opacity = parse_property_double(obj.get("o")) catch {
        _ => @model.LottieProperty::new_static(100.0)
      }
      let mode = match obj.get("mode") {
        Some(String("a")) => @model.MaskMode::Add
        Some(String("s")) => @model.MaskMode::Subtract
        Some(String("i")) => @model.MaskMode::Intersect
        Some(String("l")) => @model.MaskMode::Lighten
        Some(String("d")) => @model.MaskMode::Darken
        Some(String("f")) => @model.MaskMode::Difference
        _ => @model.MaskMode::None
      }
      let name = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      @model.Mask::new(inverted~, path~, opacity~, mode~, name~)
    }
    _ => raise UnexpectedType("mask", "Object")
  }
}

///|
/// Parse Layer
fn parse_layer(json : Json) -> @model.Layer raise LottieError {
  match json {
    Object(obj) => {
      let index = match obj.get("ind") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
      let layer_type = match obj.get("ty") {
        Some(Number(n, ..)) => n.to_int()
        _ => raise MissingKey("ty in layer")
      }
      let transform = parse_transform(obj.get("ks"))
      let in_point = match obj.get("ip") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let out_point = match obj.get("op") {
        Some(Number(n, ..)) => n
        _ => 1000.0
      }
      let start_time = match obj.get("st") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let name = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let hidden = match obj.get("hd") {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
      let parent = Some(get_int(json, "parent")) catch { _ => None }
      let masks = match obj.get("masksProperties") {
        Some(Array(arr)) => {
          let res = []
          for m_json in arr {
            res.push(parse_mask(m_json)) catch {
              _ => ()
            }
          }
          Some(res)
        }
        _ => None
      }
      let matte_type = Some(get_int(json, "tt")) catch { _ => None }
      let matte_inherit = Some(get_int(json, "td")) catch { _ => None }
      let data : @model.LayerData = match layer_type {
        0 => {
          let ref_id = get_string(json, "refId") catch { _ => "" }
          let width = get_int(json, "w") catch { _ => 0 }
          let height = get_int(json, "h") catch { _ => 0 }
          @model.LayerData::PreComp(ref_id, width, height)
        }
        1 => {
          let sc = match obj.get("sc") {
            Some(String(s)) => s
            _ => "#000000"
          }
          let sw = match obj.get("sw") {
            Some(Number(n, ..)) => n.to_int()
            _ => 0
          }
          let sh = match obj.get("sh") {
            Some(Number(n, ..)) => n.to_int()
            _ => 0
          }
          @model.LayerData::Solid(sc, sw, sh)
        }
        2 => {
          let ref_id = get_string(json, "refId") catch { _ => "" }
          @model.LayerData::Image(ref_id)
        }
        3 => @model.LayerData::Null
        4 => {
          let shapes = []
          match obj.get("shapes") {
            Some(Array(arr)) =>
              for s_json in arr {
                shapes.push(parse_shape(s_json)) catch {
                  _ => ()
                }
              }
            _ => ()
          }
          @model.LayerData::Shape(shapes)
        }
        5 => @model.LayerData::Text(parse_text_data(obj.get("t")))
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
    _ => raise UnexpectedType("layer", "Object")
  }
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
  match json {
    Object(obj) => {
      // Parse Assets
      match obj.get("assets") {
        Some(Array(arr)) =>
          for a_json in arr {
            assets.push(parse_asset(a_json)) catch {
              _ => ()
            }
          }
        _ => ()
      }
      // Parse Layers
      match obj.get("layers") {
        Some(Array(arr)) =>
          for l_json in arr {
            layers.push(parse_layer(l_json)) catch {
              _ => ()
            }
          }
        _ => ()
      }
    }
    _ => ()
  }

  @model.Animation::new(
    version~,
    frame_rate~,
    in_point~,
    out_point~,
    width~,
    height~,
    name=Some(get_string(json, "nm")) catch { _ => None },
    three_d=Some(get_int(json, "ddd")) catch { _ => None },
    assets=if assets.length() > 0 { Some(assets) } else { None },
    layers~,
  )
}

///|
/// Parse a single asset object (Image or PreComp)
fn parse_asset(json : Json) -> @model.Asset raise LottieError {
  match json {
    Object(obj) => {
      let id = get_string(json, "id")
      if obj.get("layers") != None {
        // PreComp
        let layers = []
        match obj.get("layers") {
          Some(Array(arr)) =>
            for l_json in arr {
              layers.push(parse_layer(l_json)) catch {
                _ => ()
              }
            }
          _ => ()
        }
        { id, layers: Some(layers), path: None, folder: None, width: None, height: None }
      } else {
        // Image asset
        let image_asset : AssetImageJson = (@json.from_json(json)) catch {
          _ => raise InvalidJson("Invalid image asset")
        }
        {
          id: image_asset.id,
          layers: None,
          path: image_asset.path,
          folder: image_asset.folder,
          width: image_asset.width,
          height: image_asset.height,
        }
      }
    }
    _ => raise UnexpectedType("asset", "Object")
  }
}
