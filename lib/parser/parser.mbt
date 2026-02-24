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
    Some(j) => {
      // Check if it's an object with "k"
      match j.as_object() {
        Some(obj) => {
          match obj.get("k") {
            Some(k) => {
              match k.as_number() {
                Some(n) => Some({ a: 0, k: n, ix: None, x: None })
                None => None
              }
            }
            None => None
          }
        }
        None => {
          // Maybe it's just a number
          match j.as_number() {
            Some(n) => Some({ a: 0, k: n, ix: None, x: None })
            None => None
          }
        }
      }
    }
    None => None
  }
}

///| Parse Transform
fn parse_transform(json : Json?) -> @model.Transform? {
  let obj = json?.as_object()?
  Some({
    anchor: parse_property_vec(obj.get("a"))?,
    position: parse_property_vec(obj.get("p"))?,
    scale: parse_property_vec(obj.get("s"))?,
    rotation: parse_property_double(obj.get("r"))?,
    opacity: parse_property_double(obj.get("o"))?,
    skew: None,
    skew_axis: None,
  })
}

fn parse_property_vec(json : Json?) -> @model.LottieProperty[Array[Double]]? {
  // Simple vec parser placeholder
  None
}

///| Parse the top-level Animation object
pub fn parse_animation(json : Json) -> @model.Animation? {
  let v = get_string(json, "v")?
  let fr = get_double(json, "fr")?
  let ip = get_double(json, "ip")?
  let op = get_double(json, "op")?
  let w = get_int(json, "w")?
  let h = get_int(json, "h")?
  
  // Basic layers parsing placeholder
  let layers = [] 
  
  Some({
    v,
    fr,
    ip,
    op,
    w,
    h,
    nm: get_string(json, "nm"),
    ddd: get_int(json, "ddd"),
    assets: None, // TODO
    layers,
    markers: None,
  })
}
