///| Helper to get string from Json
fn get_string(json : Json, key : String) -> String? {
  match json {
    Object(obj) =>
      match obj.get(key) {
        Some(String(s)) => Some(s)
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
        Some(Number(n)) => Some(n)
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
            Number(n) => Some(@model.LottieProperty::new_static(n))
            _ => None
          }
        }
        Number(n) => Some(@model.LottieProperty::new_static(n))
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
                  Number(n) => vals.push(n)
                  _ => ()
                }
              }
              Some(@model.LottieProperty::new_static(vals))
            }
            Number(n) => Some(@model.LottieProperty::new_static([n]))
            _ => None
          }
        }
        Array(arr) => {
          let vals = []
          for v in arr {
            match v {
              Number(n) => vals.push(n)
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

///| Parse Layer
fn parse_layer(json : Json) -> @model.Layer? {
  match json {
    Object(obj) => {
      let ind = match obj.get("ind") {
        Some(Number(n)) => n.to_int()
        _ => 0
      }
      let ty = match obj.get("ty") {
        Some(Number(n)) => n.to_int()
        _ => return None
      }
      let ks = match parse_transform(obj.get("ks")) {
        Some(t) => t
        None => return None
      }
      let ip = match obj.get("ip") {
        Some(Number(n)) => n
        _ => 0.0
      }
      let op = match obj.get("op") {
        Some(Number(n)) => n
        _ => 1000.0
      }
      let st = match obj.get("st") {
        Some(Number(n)) => n
        _ => 0.0
      }
      let nm = match obj.get("nm") {
        Some(String(s)) => Some(s)
        _ => None
      }
      Some(@model.Layer::new(ind~, ty~, ks~, ip~, op~, st~, nm~))
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
