test "parse_animation_basic" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"
  let json = @json.parse!(json_str)
  let ani = match @parser.parse_animation(json) {
    Some(ani) => ani
    None => fail("Failed to parse animation")
  }
  if ani.v != "5.5.0" {
    fail("v mismatch")
  }
  if ani.fr != 60.0 {
    fail("fr mismatch")
  }
  if ani.w != 500 {
    fail("w mismatch")
  }
  if ani.h != 500 {
    fail("h mismatch")
  }
}
