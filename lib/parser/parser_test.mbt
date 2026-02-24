test "parse_animation_basic" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = match @parser.parse_animation(json) {
    Some(ani) => ani
    None => fail("Failed to parse animation")
  }
  
  // Guardrails: Full field assertion for root animation
  if ani.v != "5.5.0" { fail("v mismatch: expected 5.5.0") }
  if ani.fr != 60.0 { fail("fr mismatch: expected 60.0") }
  if ani.ip != 0.0 { fail("ip mismatch: expected 0.0") }
  if ani.op != 100.0 { fail("op mismatch: expected 100.0") }
  if ani.w != 500 { fail("w mismatch: expected 500") }
  if ani.h != 500 { fail("h mismatch: expected 500") }
  if ani.layers.length() != 0 { fail("layers length mismatch: expected 0") }
}

test "parse_shape_layer" {
  // ... (existing test code)
}

test "parse_simple_path_shape" {
  // A shape layer with a path that doesn't use "k" wrapper
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[1,1]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"sh\",\"nm\":\"path1\",\"ks\":{\"v\":[[0,0],[10,10]],\"i\":[[0,0],[0,0]],\"o\":[[0,0],[0,0]],\"c\":true}}]}]}"
  let json = @json.parse(json_str)
  let ani = match @parser.parse_animation(json) {
    Some(ani) => ani
    None => fail("Failed to parse animation with simple path")
  }
  
  match ani.layers[0].data {
    @model.LayerData::Shape(shapes) => {
      match shapes[0].data {
        @model.ShapeData::Path(p) => {
          match p.ks.value {
            @model.PropertyValue::Static(bp) => {
              if bp.v.length() != 2 { fail("Path vertices length mismatch") }
              if bp.c != true { fail("Path closed mismatch") }
            }
            _ => fail("Path should be static")
          }
        }
        _ => fail("Should be a Path shape")
      }
    }
    _ => fail("Should be a Shape layer")
  }
}
