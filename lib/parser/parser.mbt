///|
/// Lottie parsing errors
pub suberror LottieError {
  InvalidJson(String)
  MissingKey(String)
  UnexpectedType(String, String) // key, expected type
} derive(Show)

///|
/// Global tracker for unknown keys (for L1 Reporting)
let known_keys : Array[String] = [
  "v", "fr", "ip", "op", "w", "h", "nm", "ddd", "assets", "layers", "fonts", "chars",
  "ty", "ks", "p", "a", "k", "s", "e", "o", "r", "sk", "sa", "x", "y", "z",
  "d", "st", "bm", "ind", "cl", "ln", "tg", "sr", "parent", "sh", "sw", "sc", "lc", "lj", "ml",
  "shapes", "it", "c", "g", "t", "hd", "v", "fc", "fill-rule", "gr", "tr", "p", "s", "r", "o",
  "expressions", "markers", "metadata", "masks", "inv", "pt", "mode", "px", "py", "pz",
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
/// Parse a simple Property (non-animated for now)
fn parse_property_double(
  json : Json?,
) -> @model.LottieProperty[Double] raise LottieError {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let a = match obj.get("a") {
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
          if a {
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
                      let s = match kf_obj.get("s") {
                        Some(Array([Number(n, ..)])) => n
                        Some(Number(n, ..)) => n
                        _ => 0.0
                      }
                      let e = match kf_obj.get("e") {
                        Some(Array([Number(n, ..)])) => Some(n)
                        Some(Number(n, ..)) => Some(n)
                        _ => None
                      }
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=t,
                          start_value=s,
                          end_value=e,
                        ),
                      )
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
          let a = match obj.get("a") {
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
          if a {
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
                        _ => []
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
                      keyframes.push(
                        @model.LottieKeyframe::new(
                          frame=t,
                          start_value=s,
                          end_value=e,
                        ),
                      )
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
  match json {
    Object(obj) => {
      let s = match obj.get("s") {
        Some(Number(n, ..)) => n
        _ => 12.0
      }
      let f = match obj.get("f") {
        Some(String(s)) => s
        _ => ""
      }
      let t = match obj.get("t") {
        Some(String(s)) => s
        _ => ""
      }
      let j = match obj.get("j") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
      let tr = match obj.get("tr") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let lh = match obj.get("lh") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let ls = match obj.get("ls") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let fc = match obj.get("fc") {
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
        _ => [0.0, 0.0, 0.0]
      }
      { s, f, t, j, tr, lh, ls, fc }
    }
    _ => raise UnexpectedType("text document", "Object")
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
          let s = match obj.get("p") {
            Some(Object(p_obj)) =>
              match p_obj.get("s") {
                Some(True) => true
                _ => false
              }
            _ => false
          }
          let anchor = parse_property_vec(obj.get("a"))
          let position = parse_property_vec(obj.get("p"))
          let px = if s {
            Some(parse_property_double(obj.get("x"))) catch {
              _ => None
            }
          } else {
            None
          }
          let py = if s {
            Some(parse_property_double(obj.get("y"))) catch {
              _ => None
            }
          } else {
            None
          }
          let scale = parse_property_vec(obj.get("s"))
          let rotation = parse_property_double(obj.get("r"))
          let opacity = parse_property_double(obj.get("o"))
          @model.Transform::new(
            anchor~,
            position~,
            scale~,
            rotation~,
            opacity~,
            px~,
            py~,
            s=if s { Some(true) } else { None },
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
      let v = match obj.get("v") {
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
      let i = match obj.get("i") {
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
      let o = match obj.get("o") {
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
      let c = match obj.get("c") {
        Some(True) => true
        Some(False) => false
        Some(Number(n, ..)) => n == 1.0
        _ => false
      }
      @model.BezierPath::new(v~, i~, o~, c~)
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
          let a = match obj.get("a") {
            Some(Number(n, ..)) => n == 1.0
            _ => false
          }
          match obj.get("k") {
            Some(k) =>
              if a {
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
                          keyframes.push(
                            @model.LottieKeyframe::new(
                              frame=t,
                              start_value=s,
                              end_value=e,
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
      let ty = match obj.get("ty") {
        Some(String(s)) => s
        _ => raise MissingKey("ty in shape")
      }
      let nm = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let hd = match obj.get("hd") {
        Some(True) => Some(true)
        Some(False) => Some(false)
        _ => None
      }
      let data : @model.ShapeData = match ty {
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
          let p = parse_property_vec(obj.get("p"))
          let s = parse_property_vec(obj.get("s"))
          let r = parse_property_double(obj.get("r")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          @model.ShapeData::new_rect(@model.RectShape::new(p~, s~, r~))
        }
        "el" => {
          let p = parse_property_vec(obj.get("p"))
          let s = parse_property_vec(obj.get("s"))
          @model.ShapeData::new_ellipse(@model.EllipseShape::new(p~, s~))
        }
        "sh" => {
          let ks = parse_property_bezier(obj.get("ks"))
          @model.ShapeData::new_path(@model.PathShape::new(ks~))
        }
        "fl" => {
          let c = parse_property_vec(obj.get("c"))
          let o = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          @model.ShapeData::new_fill(@model.FillShape::new(c~, o~))
        }
        "st" => {
          let c = parse_property_vec(obj.get("c"))
          let o = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let w = parse_property_double(obj.get("w")) catch {
            _ => @model.LottieProperty::new_static(1.0)
          }
          let lc = match obj.get("lc") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let lj = match obj.get("lj") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let ml = match obj.get("ml") {
            Some(Number(n, ..)) => n
            _ => 4.0
          }
          @model.ShapeData::new_stroke(
            @model.StrokeShape::new(c~, o~, w~, lc~, lj~, ml~),
          )
        }
        "gf" => {
          let t = match obj.get("t") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let s = parse_property_vec(obj.get("s"))
          let e = parse_property_vec(obj.get("e"))
          let o = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let g_json = match obj.get("g") {
            Some(j) => j
            _ => raise MissingKey("g in gf")
          }
          let (g_p, g_k) = match g_json {
            Object(g_obj) => {
              let p = match g_obj.get("p") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }
              let k = match g_obj.get("k") {
                Some(k_json) => parse_property_vec(Some(k_json))
                _ => parse_property_vec(Some(g_json))
              }
              (p, k)
            }
            _ => (0, parse_property_vec(Some(g_json)))
          }
          let g_colors = @model.GradientColors::new(p=g_p, k=g_k)
          @model.ShapeData::new_gradient_fill(
            @model.GradientFillShape::new(t~, o~, s~, e~, g=g_colors),
          )
        }
        "gs" => {
          let t = match obj.get("t") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let s = parse_property_vec(obj.get("s"))
          let e = parse_property_vec(obj.get("e"))
          let o = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let w = parse_property_double(obj.get("w")) catch {
            _ => @model.LottieProperty::new_static(1.0)
          }
          let lc = match obj.get("lc") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let lj = match obj.get("lj") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          let ml = match obj.get("ml") {
            Some(Number(n, ..)) => n
            _ => 4.0
          }
          let g_json = match obj.get("g") {
            Some(j) => j
            _ => raise MissingKey("g in gs")
          }
          let (g_p, g_k) = match g_json {
            Object(g_obj) => {
              let p = match g_obj.get("p") {
                Some(Number(n, ..)) => n.to_int()
                _ => 0
              }
              let k = match g_obj.get("k") {
                Some(k_json) => parse_property_vec(Some(k_json))
                _ => parse_property_vec(Some(g_json))
              }
              (p, k)
            }
            _ => (0, parse_property_vec(Some(g_json)))
          }
          let g_colors = @model.GradientColors::new(p=g_p, k=g_k)
          @model.ShapeData::new_gradient_stroke(
            @model.GradientStrokeShape::new(
              t~,
              o~,
              s~,
              e~,
              g=g_colors,
              w~,
              lc~,
              lj~,
              ml~,
            ),
          )
        }
        "tr" => @model.ShapeData::new_transform(parse_transform(Some(json)))
        "tm" => {
          let s = parse_property_double(obj.get("s")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let e = parse_property_double(obj.get("e")) catch {
            _ => @model.LottieProperty::new_static(100.0)
          }
          let o = parse_property_double(obj.get("o")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let m = get_int(json, "m") catch { _ => 1 }
          @model.ShapeData::new_trim_path(@model.TrimPath::new(s~, e~, o~, m~))
        }
        "sr" => {
          let pt = parse_property_double(obj.get("pt"))
          let p = parse_property_vec(obj.get("p"))
          let r = parse_property_double(obj.get("r"))
          let ir = parse_property_double(obj.get("ir")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let ir_round = parse_property_double(obj.get("is")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let or = parse_property_double(obj.get("or"))
          let or_round = parse_property_double(obj.get("os")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          let sy = match obj.get("sy") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
          @model.ShapeData::new_polystar(
            @model.PolystarShape::new(
              pt~,
              p~,
              r~,
              ir~,
              ir_round~,
              or~,
              or_round~,
              sy~,
            ),
          )
        }
        "rp" => {
          let c = parse_property_double(obj.get("c"))
          let o = parse_property_double(obj.get("o"))
          let m = get_int(json, "m") catch { _ => 1 }
          let tr = parse_transform(obj.get("tr"))
          @model.ShapeData::new_repeater(@model.Repeater::new(c~, o~, m~, tr~))
        }
        "mm" => {
          let mm = get_int(json, "mm") catch { _ => 1 }
          @model.ShapeData::new_merge_paths(@model.MergePaths::new(mm))
        }
        "rd" => {
          let r = parse_property_double(obj.get("r")) catch {
            _ => @model.LottieProperty::new_static(0.0)
          }
          @model.ShapeData::new_rounding(@model.Rounding::new(r~))
        }
        _ => raise InvalidJson("Unknown shape type: " + ty)
      }
      @model.Shape::new(ty~, data~, nm~, hd~)
    }
    _ => raise UnexpectedType("shape", "Object")
  }
}

///|
/// Parse a single Mask object
fn parse_mask(json : Json) -> @model.Mask raise LottieError {
  match json {
    Object(obj) => {
      let inv = match obj.get("inv") {
        Some(True) => true
        _ => false
      }
      let pt = parse_property_bezier(obj.get("pt"))
      let o = parse_property_double(obj.get("o")) catch {
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
      let nm = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      @model.Mask::new(inv~, pt~, o~, mode~, nm~)
    }
    _ => raise UnexpectedType("mask", "Object")
  }
}

///|
/// Parse Layer
fn parse_layer(json : Json) -> @model.Layer raise LottieError {
  match json {
    Object(obj) => {
      let ind = match obj.get("ind") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
      let ty = match obj.get("ty") {
        Some(Number(n, ..)) => n.to_int()
        _ => raise MissingKey("ty in layer")
      }
      let ks = parse_transform(obj.get("ks"))
      let ip = match obj.get("ip") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let op = match obj.get("op") {
        Some(Number(n, ..)) => n
        _ => 1000.0
      }
      let st = match obj.get("st") {
        Some(Number(n, ..)) => n
        _ => 0.0
      }
      let nm = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let hd = match obj.get("hd") {
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
      let tt = Some(get_int(json, "tt")) catch { _ => None }
      let td = Some(get_int(json, "td")) catch { _ => None }
      let data : @model.LayerData = match ty {
        0 => {
          let ref_id = get_string(json, "refId") catch { _ => "" }
          let w = get_int(json, "w") catch { _ => 0 }
          let h = get_int(json, "h") catch { _ => 0 }
          @model.LayerData::PreComp(ref_id, w, h)
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
        ind~,
        ty~,
        ks~,
        ip~,
        op~,
        st~,
        nm~,
        data~,
        hd~,
        parent~,
        masks~,
        tt~,
        td~,
      )
    }
    _ => raise UnexpectedType("layer", "Object")
  }
}

///|
/// Parse the top-level Animation object
pub fn parse_animation(json : Json) -> @model.Animation raise LottieError {
  let v = get_string(json, "v")
  let fr = get_double(json, "fr")
  let ip = get_double(json, "ip")
  let op = get_double(json, "op")
  let w = get_int(json, "w")
  let h = get_int(json, "h")

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
    v~,
    fr~,
    ip~,
    op~,
    w~,
    h~,
    nm=Some(get_string(json, "nm")) catch { _ => None },
    ddd=Some(get_int(json, "ddd")) catch { _ => None },
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
        { id, layers: Some(layers), p: None, u: None, w: None, h: None }
      } else {
        // Image asset
        let p = get_string(json, "p") catch { _ => "" }
        let u = get_string(json, "u") catch { _ => "" }
        let w = get_int(json, "w") catch { _ => 0 }
        let h = get_int(json, "h") catch { _ => 0 }
        { id, layers: None, p: Some(p), u: Some(u), w: Some(w), h: Some(h) }
      }
    }
    _ => raise UnexpectedType("asset", "Object")
  }
}
