///|
extern "wasm" fn js_get_json_len() -> Int = "demo" "get_json_len"

///|
extern "wasm" fn js_get_json_char(idx : Int) -> Int = "demo" "get_json_char"

///|
extern "wasm" fn js_log_frame(frame : Double) -> Unit = "demo" "log_frame"

///|
fn main {
  // main can be empty
}

///|
fn get_json_from_js() -> String {
  let len = js_get_json_len()
  let sb = @builtin.StringBuilder::new(size_hint=len)
  for i = 0; i < len; i = i + 1 {
    let c = js_get_json_char(i)
    sb.write_char(c.to_char().unwrap())
  }
  sb.to_string()
}

///|
pub fn create_player_from_js() -> @renderer.Player[@renderer.CanvasRenderer]? {
  try {
    let json_str = get_json_from_js()
    let json = @json.parse(json_str)
    let anim = @parser.parse_animation(json)
    Some(@renderer.create_canvas_player(anim))
  } catch {
    _ => None
  }
}

///|
pub fn update_player_with_speed(
  player : @renderer.Player[@renderer.CanvasRenderer],
  frame : Double,
  speed : Double,
) -> Double {
  let next_frame = frame + speed
  js_log_frame(next_frame)
  player.set_frame(next_frame)
  player.render()
  next_frame
}

///|
pub fn get_frame_count(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> Double {
  player.animation.out_point - player.animation.in_point
}

///|
pub fn get_width(player : @renderer.Player[@renderer.CanvasRenderer]) -> Int {
  player.animation.width
}

///|
pub fn get_height(player : @renderer.Player[@renderer.CanvasRenderer]) -> Int {
  player.animation.height
}

///|
pub fn get_fps(player : @renderer.Player[@renderer.CanvasRenderer]) -> Double {
  player.animation.frame_rate
}

///|
pub fn get_version_len(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> Int {
  player.animation.version.length()
}

///|
pub fn get_version_char(
  player : @renderer.Player[@renderer.CanvasRenderer],
  idx : Int,
) -> Int {
  let version = player.animation.version
  if idx < 0 || idx >= version.length() {
    // JS reconstructs exported strings by reading indices in [0, len).
    // Return -1 as an invalid-index sentinel instead of trapping on misuse.
    -1
  } else {
    version[idx].to_int()
  }
}

///|
pub fn update_player(
  player : @renderer.Player[@renderer.CanvasRenderer],
  frame : Double,
) -> Unit {
  js_log_frame(frame)
  player.set_frame(frame)
  player.render()
}

///|
pub fn get_in_point(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> Double {
  player.animation.in_point
}
