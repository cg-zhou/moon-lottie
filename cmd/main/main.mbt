///|
fn main {
  println("MoonLottie initialized.")
}

///| Create a new player instance from a JSON string
pub fn create_player(json_str : String) -> @renderer.Player[@renderer.CanvasRenderer]? {
  try {
    let json = @json.parse(json_str)
    match @parser.parse_animation(json) {
      Some(anim) => Some(@renderer.create_canvas_player(anim))
      None => None
    }
  } catch {
    _ => None
  }
}

///| Render a specific frame
pub fn update_player(player : @renderer.Player[@renderer.CanvasRenderer], frame : Double) -> Unit {
  player.set_frame(frame)
  player.render()
}
