///| Helper to get string from Json
fn get_string(json : Json, key : String) -> String? {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(String(s, ..)) => Some(s)
        _ => None
      }
    _ => None
  }
}

///| Helper to get double from Json
fn get_double(json : Json, key : String) -> Double? {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(Number(n, ..)) => Some(n)
        _ => None
      }
    _ => None
  }
}

///| Helper to get int from Json
fn get_int(json : Json, key : String) -> Int? {
  match get_double(json, key) {
    Some(d) => Some(d.to_int())
    None => None
  }
}

///| Parse a simple Property (non-animated for now)
fn parse_property_double(json : Json?) -> @model.LottieProperty[Double]? {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let k = match obj.get("k") {
            Some(k) => k
            None => return None
          }
          match k {
            Number(n, ..) => Some(@model.LottieProperty::new_static(n))
            _ => None
          }
        }
        Number(n, ..) => Some(@model.LottieProperty::new_static(n))
        _ => None
      }
    None => None
  }
}

fn parse_property_vec(json : Json?) -> @model.LottieProperty[Array[Double]]? {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let k = match obj.get("k") {
            Some(k) => k
            None => return None
          }
          match k {
            Array(arr) => {
              let vals = []
              for v in arr {
                match v {
                  Number(n, ..) => vals.push(n)
                  _ => ()
                }
              }
              Some(@model.LottieProperty::new_static(vals))
            }
            Number(n, ..) => Some(@model.LottieProperty::new_static([n]))
            _ => None
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
          Some(@model.LottieProperty::new_static(vals))
        }
        _ => None
      }
    None => None
  }
}

///| Parse Transform
fn parse_transform(json : Json?) -> @model.Transform? {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          let anchor = match parse_property_vec(obj.get("a")) {
            Some(v) => v
            None => return None
          }
          let position = match parse_property_vec(obj.get("p")) {
            Some(v) => v
            None => return None
          }
          let scale = match parse_property_vec(obj.get("s")) {
            Some(v) => v
            None => return None
          }
          let rotation = match parse_property_double(obj.get("r")) {
            Some(v) => v
            None => return None
          }
          let opacity = match parse_property_double(obj.get("o")) {
            Some(v) => v
            None => return None
          }
          Some(
            @model.Transform::new(
              anchor~,
              position~,
              scale~,
              rotation~,
              opacity~,
            ),
          )
        }
        _ => None
      }
    None => None
  }
}

///| Parse BezierPath data (the 'v', 'i', 'o', 'c' structure)
fn parse_bezier_path(json : Json) -> @model.BezierPath? {
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
      Some(@model.BezierPath::new(v~, i~, o~, c~))
    }
    _ => None
  }
}

///| Parse LottieProperty with BezierPath value
fn parse_property_bezier(json : Json?) -> @model.LottieProperty[@model.BezierPath]? {
  match json {
    Some(j) =>
      match j {
        Object(obj) => {
          // Case 1: Standard Lottie property { "a": 0, "k": { "v": ... } }
          match obj.get("k") {
            Some(k) =>
              match parse_bezier_path(k) {
                Some(bp) => Some(@model.LottieProperty::new_static(bp))
                None => None
              }
            None =>
              // Case 2: Simple path { "v": ... } without being wrapped in property
              match parse_bezier_path(j) {
                Some(bp) => Some(@model.LottieProperty::new_static(bp))
                None => None
              }
          }
        }
        _ => None
      }
    None => None
  }
}

///| Parse a single Shape object
fn parse_shape(json : Json) -> @model.Shape? {
  match json {
    Object(obj) => {
      let ty = match obj.get("ty") {
        Some(String(s)) => s
        _ => return None
      }
      let nm = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let data : @model.ShapeData = match ty {
        "gr" => {
          let items = []
          match obj.get("it") {
            Some(Array(arr)) =>
              for i in arr {
                match parse_shape(i) {
                  Some(s) => items.push(s)
                  None => ()
                }
              }
            _ => ()
          }
          @model.ShapeData::new_group(items)
        }
        "rc" => {
          let p = match parse_property_vec(obj.get("p")) {
            Some(v) => v
            None => return None
          }
          let s = match parse_property_vec(obj.get("s")) {
            Some(v) => v
            None => return None
          }
          let r = match parse_property_double(obj.get("r")) {
            Some(v) => v
            None => @model.LottieProperty::new_static(0.0)
          }
          @model.ShapeData::new_rect(@model.RectShape::new(p~, s~, r~))
        }
        "el" => {
          let p = match parse_property_vec(obj.get("p")) {
            Some(v) => v
            None => return None
          }
          let s = match parse_property_vec(obj.get("s")) {
            Some(v) => v
            None => return None
          }
          @model.ShapeData::new_ellipse(@model.EllipseShape::new(p~, s~))
        }
        "sh" => {
          let ks = match parse_property_bezier(obj.get("ks")) {
            Some(v) => v
            None => return None
          }
          @model.ShapeData::new_path(@model.PathShape::new(ks~))
        }
        "fl" => {
          let c = match parse_property_vec(obj.get("c")) {
            Some(v) => v
            None => return None
          }
          let o = match parse_property_double(obj.get("o")) {
            Some(v) => v
            None => @model.LottieProperty::new_static(100.0)
          }
          @model.ShapeData::new_fill(@model.FillShape::new(c~, o~))
        }
        "st" => {
          let c = match parse_property_vec(obj.get("c")) {
            Some(v) => v
            None => return None
          }
          let o = match parse_property_double(obj.get("o")) {
            Some(v) => v
            None => @model.LottieProperty::new_static(100.0)
          }
          let w = match parse_property_double(obj.get("w")) {
            Some(v) => v
            None => @model.LottieProperty::new_static(1.0)
          }
          @model.ShapeData::new_stroke(@model.StrokeShape::new(c~, o~, w~))
        }
        "tr" => {
          match parse_transform(Some(json)) {
            Some(tr) => @model.ShapeData::new_transform(tr)
            None => return None
          }
        }
        _ => return None
      }
      Some(@model.Shape::new(ty~, data~, nm~))
    }
    _ => None
  }
}

///| Parse Layer
fn parse_layer(json : Json) -> @model.Layer? {
  match json {
    Object(obj) => {
      let ind = match obj.get("ind") {
        Some(Number(n, ..)) => n.to_int()
        _ => 0
      }
      let ty = match obj.get("ty") {
        Some(Number(n, ..)) => n.to_int()
        _ => return None
      }
      let ks = match parse_transform(obj.get("ks")) {
        Some(t) => t
        None => return None
      }
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
      let data : @model.LayerData = match ty {
        4 => {
          // Shape Layer
          let shapes = []
          match obj.get("shapes") {
            Some(Array(arr)) =>
              for s_json in arr {
                match parse_shape(s_json) {
                  Some(s) => shapes.push(s)
                  None => ()
                }
              }
            _ => ()
          }
          @model.LayerData::new_shape(shapes)
        }
        1 => {
          // Solid Layer
          let sc = match obj.get("sc") {
            Some(String(s, ..)) => s
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
          @model.LayerData::new_solid(sc, sw, sh)
        }
        _ => @model.LayerData::new_null()
      }
      Some(@model.Layer::new(ind~, ty~, ks~, ip~, op~, st~, nm~, data~))
    }
    _ => None
  }
}

///| Parse the top-level Animation object
pub fn parse_animation(json : Json) -> @model.Animation? {
  let v = match get_string(json, "v") {
    Some(v) => v
    None => return None
  }
  let fr = match get_double(json, "fr") {
    Some(fr) => fr
    None => return None
  }
  let ip = match get_double(json, "ip") {
    Some(ip) => ip
    None => return None
  }
  let op = match get_double(json, "op") {
    Some(op) => op
    None => return None
  }
  let w = match get_int(json, "w") {
    Some(w) => w
    None => return None
  }
  let h = match get_int(json, "h") {
    Some(h) => h
    None => return None
  }

  let layers = []
  match json {
    Object(obj) =>
      match obj.get("layers") {
        Some(Array(arr)) =>
          for l_json in arr {
            match parse_layer(l_json) {
              Some(l) => layers.push(l)
              None => ()
            }
          }
        _ => ()
      }
    _ => ()
  }

  Some(
    @model.Animation::new(
      v~,
      fr~,
      ip~,
      op~,
      w~,
      h~,
      nm=get_string(json, "nm"),
      ddd=get_int(json, "ddd"),
      layers~,
    ),
  )
}
