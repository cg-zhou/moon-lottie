///|
extern "wasm" fn js_get_json_string() -> String = "demo" "get_json_string"

///|
extern "wasm" fn js_log_frame(frame : Double) -> Unit = "demo" "log_frame"

///|
extern "wasm" fn js_evaluate_expression_double(
  expression : String,
  frame : Double,
  layer_index : Int,
  value : Double,
) -> Double = "expressions" "evaluate_double"

///|
extern "wasm" fn js_evaluate_expression_vec(
  expression : String,
  frame : Double,
  layer_index : Int,
  value : String,
) -> String = "expressions" "evaluate_vec"

///|
extern "wasm" fn js_evaluate_expression_path(
  expression : String,
  frame : Double,
  layer_index : Int,
  value : String,
) -> String = "expressions" "evaluate_path"

///|
fn main {
  // main can be empty
}

///|
fn get_json_from_js() -> String {
  js_get_json_string()
}

///|
pub fn create_player_from_js() -> @renderer.Player[@renderer.CanvasRenderer]? {
  try {
    @runtime.install_expression_handlers(
      (expression, frame, layer_index, value) =>
        js_evaluate_expression_double(expression, frame, layer_index, value),
      (expression, frame, layer_index, value) =>
        js_evaluate_expression_vec(expression, frame, layer_index, value),
      (expression, frame, layer_index, value) =>
        js_evaluate_expression_path(expression, frame, layer_index, value),
    )
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
pub fn get_version(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> String {
  player.animation.version
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
