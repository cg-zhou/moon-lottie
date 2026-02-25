
fn canvas_save() = "canvas" "save"
fn canvas_restore() = "canvas" "restore"
fn canvas_set_transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = "canvas" "setTransform"
fn canvas_concat_transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = "canvas" "transform"
fn canvas_begin_path() = "canvas" "beginPath"
fn canvas_close_path() = "canvas" "closePath"
fn canvas_move_to(x: Double, y: Double) = "canvas" "moveTo"
fn canvas_line_to(x: Double, y: Double) = "canvas" "lineTo"
fn canvas_cubic_to(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) = "canvas" "bezierCurveTo"
fn canvas_fill(color: String) = "canvas" "fill"
fn canvas_stroke(color: String, width: Double) = "canvas" "stroke"
fn canvas_clear_rect(x: Double, y: Double, w: Double, h: Double) = "canvas" "clearRect"
fn canvas_draw_image(id: String, w: Double, h: Double) = "canvas" "drawImage"
fn canvas_set_global_alpha(alpha: Double) = "canvas" "setGlobalAlpha"
fn canvas_set_fill_style(color: String) = "canvas" "setFillStyle"
fn canvas_set_stroke_style(color: String) = "canvas" "setStrokeStyle"
fn canvas_set_line_width(width: Double) = "canvas" "setLineWidth"

pub struct CanvasRenderer {}

pub fn CanvasRenderer::new() -> CanvasRenderer {
  CanvasRenderer::{}
}

impl Renderer for CanvasRenderer with save(self) {
  let _ = self
  canvas_save()
}

impl Renderer for CanvasRenderer with restore(self) {
  let _ = self
  canvas_restore()
}

impl Renderer for CanvasRenderer with set_transform(self, m) {
  let _ = self
  canvas_set_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

impl Renderer for CanvasRenderer with concat_transform(self, m) {
  let _ = self
  canvas_concat_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

impl Renderer for CanvasRenderer with begin_path(self) {
  let _ = self
  canvas_begin_path()
}

impl Renderer for CanvasRenderer with close_path(self) {
  let _ = self
  canvas_close_path()
}

impl Renderer for CanvasRenderer with move_to(self, x, y) {
  let _ = self
  canvas_move_to(x, y)
}

impl Renderer for CanvasRenderer with line_to(self, x, y) {
  let _ = self
  canvas_line_to(x, y)
}

impl Renderer for CanvasRenderer with cubic_to(self, cp1x, cp1y, cp2x, cp2y, x, y) {
  let _ = self
  canvas_cubic_to(cp1x, cp1y, cp2x, cp2y, x, y)
}

impl Renderer for CanvasRenderer with fill(self, color, opacity) {
  let _ = self
  canvas_save()
  canvas_set_global_alpha(opacity)
  canvas_set_fill_style(color)
  canvas_fill(color)
  canvas_restore()
}

impl Renderer for CanvasRenderer with stroke(self, color, opacity, width) {
  let _ = self
  canvas_save()
  canvas_set_global_alpha(opacity)
  canvas_set_stroke_style(color)
  canvas_set_line_width(width)
  canvas_stroke(color, width)
  canvas_restore()
}

impl Renderer for CanvasRenderer with clear_rect(self, x, y, w, h) {
  let _ = self
  canvas_clear_rect(x, y, w, h)
}

impl Renderer for CanvasRenderer with draw_image(self, id, w, h) {
  let _ = self
  canvas_draw_image(id, w, h)
}
