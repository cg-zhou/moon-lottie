///| Helper to get string from Json
fn get_string(json : Json, key : String) -> String? {
  match json.as_object() {
    Some(obj) => {
      match obj.get(key) {
        Some(val) => val.as_string()
        None => None
      }
    }
    None => None
  }
}

///| Helper to get double from Json
fn get_double(json : Json, key : String) -> Double? {
  match json.as_object() {
    Some(obj) => {
      match obj.get(key) {
        Some(val) => val.as_number()
        None => None
      }
    }
    None => None
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
      match j.as_object() {
        Some(obj) => {
          let k = match obj.get("k") {
            Some(k) => k
            None => return None
          }
          match k.as_number() {
            Some(n) => Some(@model.LottieProperty::new_static(n))
            None => None
          }
        }
        None =>
          match j.as_number() {
            Some(n) => Some(@model.LottieProperty::new_static(n))
            None => None
          }
      }
    None => None
  }
}

fn parse_property_vec(json : Json?) -> @model.LottieProperty[Array[Double]]? {
  match json {
    Some(j) =>
      match j.as_object() {
        Some(obj) => {
          let k = match obj.get("k") {
            Some(k) => k
            None => return None
          }
          match k.as_array() {
            Some(arr) => {
              let vals = []
              for v in arr {
                match v.as_number() {
                  Some(n) => vals.push(n)
                  None => ()
                }
              }
              Some(@model.LottieProperty::new_static(vals))
            }
            None =>
              match k.as_number() {
                Some(n) => Some(@model.LottieProperty::new_static([n]))
                None => None
              }
          }
        }
        None =>
          match j.as_array() {
            Some(arr) => {
              let vals = []
              for v in arr {
                match v.as_number() {
                  Some(n) => vals.push(n)
                  None => ()
                }
              }
              Some(@model.LottieProperty::new_static(vals))
            }
            None => None
          }
      }
    None => None
  }
}

///| Parse Transform
fn parse_transform(json : Json?) -> @model.Transform? {
  match json {
    Some(j) =>
      match j.as_object() {
        Some(obj) => {
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
        None => None
      }
    None => None
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
  
  let layers : Array[@model.Layer] = []
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
