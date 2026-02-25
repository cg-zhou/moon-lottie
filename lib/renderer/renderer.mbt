///| Renderer Trait
///| Defines the interface for drawing Lottie primitives.
pub trait Renderer {
  save(self : Self) -> Unit
  restore(self : Self) -> Unit
  
  // Transform
  set_transform(self : Self, matrix : @math.Matrix) -> Unit
  concat_transform(self : Self, matrix : @math.Matrix) -> Unit
  
  // Path creation
  begin_path(self : Self) -> Unit
  close_path(self : Self) -> Unit
  move_to(self : Self, x : Double, y : Double) -> Unit
  line_to(self : Self, x : Double, y : Double) -> Unit
  cubic_to(self : Self, cp1x : Double, cp1y : Double, cp2x : Double, cp2y : Double, x : Double, y : Double) -> Unit
  
  // Painting
  fill(self : Self, r : Int, g : Int, b : Int, opacity : Double) -> Unit
  stroke(self : Self, r : Int, g : Int, b : Int, opacity : Double, width : Double) -> Unit
  
  // Images
  draw_image(self : Self, id : String, width : Double, height : Double) -> Unit
  
  // Canvas size
  clear_rect(self : Self, x : Double, y : Double, w : Double, h : Double) -> Unit
}

fn canvas_save() = "canvas" "save"
fn canvas_restore() = "canvas" "restore"
fn canvas_set_transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = "canvas" "setTransform"
fn canvas_concat_transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = "canvas" "transform"
fn canvas_begin_path() = "canvas" "beginPath"
fn canvas_close_path() = "canvas" "closePath"
fn canvas_move_to(x: Double, y: Double) = "canvas" "moveTo"
fn canvas_line_to(x: Double, y: Double) = "canvas" "lineTo"
fn canvas_cubic_to(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) = "canvas" "bezierCurveTo"
fn canvas_fill(r : Int, g : Int, b : Int, a : Double) = "canvas" "fill"
fn canvas_stroke(r : Int, g : Int, b : Int, a : Double, width: Double) = "canvas" "stroke"
fn canvas_clear_rect(x: Double, y: Double, w: Double, h: Double) = "canvas" "clearRect"
fn canvas_draw_image(id: String, w: Double, h: Double) = "canvas" "drawImage"

pub struct CanvasRenderer {}

pub fn CanvasRenderer::new() -> CanvasRenderer {
  CanvasRenderer::{}
}

pub impl Renderer for CanvasRenderer with save(self : CanvasRenderer) {
  let _ = self
  canvas_save()
}

pub impl Renderer for CanvasRenderer with restore(self : CanvasRenderer) {
  let _ = self
  canvas_restore()
}

pub impl Renderer for CanvasRenderer with set_transform(self : CanvasRenderer, m : @math.Matrix) {
  let _ = self
  canvas_set_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

pub impl Renderer for CanvasRenderer with concat_transform(self : CanvasRenderer, m : @math.Matrix) {
  let _ = self
  canvas_concat_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

pub impl Renderer for CanvasRenderer with begin_path(self : CanvasRenderer) {
  let _ = self
  canvas_begin_path()
}

pub impl Renderer for CanvasRenderer with close_path(self : CanvasRenderer) {
  let _ = self
  canvas_close_path()
}

pub impl Renderer for CanvasRenderer with move_to(self : CanvasRenderer, x : Double, y : Double) {
  let _ = self
  canvas_move_to(x, y)
}

pub impl Renderer for CanvasRenderer with line_to(self : CanvasRenderer, x : Double, y : Double) {
  let _ = self
  canvas_line_to(x, y)
}

pub impl Renderer for CanvasRenderer with cubic_to(self : CanvasRenderer, cp1x : Double, cp1y : Double, cp2x : Double, cp2y : Double, x : Double, y : Double) {
  let _ = self
  canvas_cubic_to(cp1x, cp1y, cp2x, cp2y, x, y)
}

pub impl Renderer for CanvasRenderer with fill(self : CanvasRenderer, r : Int, g : Int, b : Int, opacity : Double) {
  let _ = self
  canvas_fill(r, g, b, opacity)
}

pub impl Renderer for CanvasRenderer with stroke(self : CanvasRenderer, r : Int, g : Int, b : Int, opacity : Double, width : Double) {
  let _ = self
  canvas_stroke(r, g, b, opacity, width)
}

pub impl Renderer for CanvasRenderer with clear_rect(self : CanvasRenderer, x : Double, y : Double, w : Double, h : Double) {
  let _ = self
  canvas_clear_rect(x, y, w, h)
}

pub impl Renderer for CanvasRenderer with draw_image(self : CanvasRenderer, id : String, w : Double, h : Double) {
  let _ = self
  canvas_draw_image(id, w, h)
}
