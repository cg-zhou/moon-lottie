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
  clip(self : Self) -> Unit
  
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
fn canvas_clip() = "canvas" "clip"
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

pub impl Renderer for CanvasRenderer with clip(self : CanvasRenderer) {
  let _ = self
  canvas_clip()
}

pub impl Renderer for CanvasRenderer with clear_rect(self : CanvasRenderer, x : Double, y : Double, w : Double, h : Double) {
  let _ = self
  canvas_clear_rect(x, y, w, h)
}

pub impl Renderer for CanvasRenderer with draw_image(self : CanvasRenderer, id : String, w : Double, h : Double) {
  let _ = self
  canvas_draw_image(id, w, h)
}

///| DrawCommand representing a single drawing operation.
///| Useful for testing, serialization, and cross-platform recording.
pub enum DrawCommand {
  Save
  Restore
  SetTransform(@math.Matrix)
  ConcatTransform(@math.Matrix)
  BeginPath
  ClosePath
  MoveTo(Double, Double)
  LineTo(Double, Double)
  CubicTo(Double, Double, Double, Double, Double, Double)
  Fill(Int, Int, Int, Double)
  Stroke(Int, Int, Int, Double, Double)
  Clip
  ClearRect(Double, Double, Double, Double)
  DrawImage(String, Double, Double)
} derive(Show, Eq)

///| Renderer that records all commands into a list.
pub struct CommandRecorder {
  commands : Array[DrawCommand]
}

pub fn CommandRecorder::new() -> CommandRecorder {
  { commands: [] }
}

pub fn CommandRecorder::get_commands(self : CommandRecorder) -> Array[DrawCommand] {
  self.commands
}

pub impl Renderer for CommandRecorder with save(self : CommandRecorder) {
  self.commands.push(Save)
}

pub impl Renderer for CommandRecorder with restore(self : CommandRecorder) {
  self.commands.push(Restore)
}

pub impl Renderer for CommandRecorder with set_transform(self : CommandRecorder, m : @math.Matrix) {
  self.commands.push(SetTransform(m))
}

pub impl Renderer for CommandRecorder with concat_transform(self : CommandRecorder, m : @math.Matrix) {
  self.commands.push(ConcatTransform(m))
}

pub impl Renderer for CommandRecorder with begin_path(self : CommandRecorder) {
  self.commands.push(BeginPath)
}

pub impl Renderer for CommandRecorder with close_path(self : CommandRecorder) {
  self.commands.push(ClosePath)
}

pub impl Renderer for CommandRecorder with move_to(self : CommandRecorder, x : Double, y : Double) {
  self.commands.push(MoveTo(x, y))
}

pub impl Renderer for CommandRecorder with line_to(self : CommandRecorder, x : Double, y : Double) {
  self.commands.push(LineTo(x, y))
}

pub impl Renderer for CommandRecorder with cubic_to(self : CommandRecorder, cp1x : Double, cp1y : Double, cp2x : Double, cp2y : Double, x : Double, y : Double) {
  self.commands.push(CubicTo(cp1x, cp1y, cp2x, cp2y, x, y))
}

pub impl Renderer for CommandRecorder with fill(self : CommandRecorder, r : Int, g : Int, b : Int, opacity : Double) {
  self.commands.push(Fill(r, g, b, opacity))
}

pub impl Renderer for CommandRecorder with stroke(self : CommandRecorder, r : Int, g : Int, b : Int, opacity : Double, width : Double) {
  self.commands.push(Stroke(r, g, b, opacity, width))
}

pub impl Renderer for CommandRecorder with clip(self : CommandRecorder) {
  self.commands.push(Clip)
}

pub impl Renderer for CommandRecorder with clear_rect(self : CommandRecorder, x : Double, y : Double, w : Double, h : Double) {
  self.commands.push(ClearRect(x, y, w, h))
}

pub impl Renderer for CommandRecorder with draw_image(self : CommandRecorder, id : String, w : Double, h : Double) {
  self.commands.push(DrawImage(id, w, h))
}
