test "parse_animation_basic" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = match @parser.parse_animation(json) {
    Some(ani) => ani
    None => fail("Failed to parse animation")
  }
  if ani.v != "5.5.0" {
    fail("v mismatch")
  }
}

test "parse_shape_layer" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"rc\",\"nm\":\"rect\",\"p\":{\"k\":[10,10]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":5}}]}]}"
  let json = @json.parse(json_str)
  let ani = match @parser.parse_animation(json) {
    Some(ani) => ani
    None => fail("Failed to parse animation with shapes")
  }
  if ani.layers.length() != 1 {
    fail("Layer count mismatch")
  }
}
