///|
#cfg(target="js")
extern "js" fn js_get_json_string() -> String = "demo.get_json_string"

///|
#cfg(any(target="wasm", target="wasm-gc"))
extern "wasm" fn js_get_json_string() -> String = "demo" "get_json_string"

///|
#cfg(target="js")
extern "js" fn js_log_frame(frame : Double) -> Unit = "demo.log_frame"

///|
#cfg(any(target="wasm", target="wasm-gc"))
extern "wasm" fn js_log_frame(frame : Double) -> Unit = "demo" "log_frame"

///|
#cfg(target="js")
extern "js" fn js_evaluate_expression_double(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : Double,
) -> Double = "expressions.evaluate_double"

///|
#cfg(any(target="wasm", target="wasm-gc"))
extern "wasm" fn js_evaluate_expression_double(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : Double,
) -> Double = "expressions" "evaluate_double"

///|
#cfg(target="js")
extern "js" fn js_evaluate_expression_vec(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : String,
) -> String = "expressions.evaluate_vec"

///|
#cfg(any(target="wasm", target="wasm-gc"))
extern "wasm" fn js_evaluate_expression_vec(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : String,
) -> String = "expressions" "evaluate_vec"

///|
#cfg(target="js")
extern "js" fn js_evaluate_expression_path(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : String,
) -> String = "expressions.evaluate_path"

///|
#cfg(any(target="wasm", target="wasm-gc"))
extern "wasm" fn js_evaluate_expression_path(
  expression : String,
  frame : Double,
  layer_index : Int,
  comp_id : String,
  value : String,
) -> String = "expressions" "evaluate_path"

///|
fn main {
  // main can be empty
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
struct SvgAnimationHandle {
  player : @renderer.Player[@renderer.SvgRenderer]
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
fn parse_animation_from_js() -> @model.Animation raise {
  @runtime.install_expression_handlers(
    (expression, frame, layer_index, comp_id, value) =>
      js_evaluate_expression_double(expression, frame, layer_index, comp_id, value),
    (expression, frame, layer_index, comp_id, value) =>
      js_evaluate_expression_vec(expression, frame, layer_index, comp_id, value),
    (expression, frame, layer_index, comp_id, value) =>
      js_evaluate_expression_path(expression, frame, layer_index, comp_id, value),
  )
  let json_str = get_json_from_js()
  let json = @json.parse(json_str)
  @parser.parse_animation(json)
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
fn get_json_from_js() -> String {
  js_get_json_string()
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn create_player_from_js() -> @renderer.Player[@renderer.CanvasRenderer]? {
  try {
    let anim = parse_animation_from_js()
    Some(@renderer.create_canvas_player(anim))
  } catch {
    _ => None
  }
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn create_svg_animation_from_js() -> SvgAnimationHandle? {
  try {
    let animation = parse_animation_from_js()
    let renderer = @renderer.SvgRenderer::new(
      animation.width.to_double(),
      animation.height.to_double(),
    )
    let player = @renderer.Player::new(animation, renderer)
    Some({ player, })
  } catch {
    _ => None
  }
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
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
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_frame_count(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> Double {
  player.animation.out_point - player.animation.in_point
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_width(player : @renderer.Player[@renderer.CanvasRenderer]) -> Int {
  player.animation.width
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_height(player : @renderer.Player[@renderer.CanvasRenderer]) -> Int {
  player.animation.height
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_fps(player : @renderer.Player[@renderer.CanvasRenderer]) -> Double {
  player.animation.frame_rate
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_version(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> String {
  player.animation.version
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn update_player(
  player : @renderer.Player[@renderer.CanvasRenderer],
  frame : Double,
) -> Unit {
  js_log_frame(frame)
  player.set_frame(frame)
  player.render()
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn get_in_point(
  player : @renderer.Player[@renderer.CanvasRenderer],
) -> Double {
  player.animation.in_point
}

///|
#cfg(any(target="wasm", target="wasm-gc", target="js"))
pub fn render_svg_frame(
  handle : SvgAnimationHandle,
  frame : Double,
) -> String {
  let player = handle.player
  player.set_frame(frame)
  player.render()
  player.renderer.get_output()
}
