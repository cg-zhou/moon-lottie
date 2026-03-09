///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_save() = "canvas" "save"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_restore() = "canvas" "restore"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_set_transform(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) = "canvas" "setTransform"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_concat_transform(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) = "canvas" "transform"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_begin_path() = "canvas" "beginPath"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_close_path() = "canvas" "closePath"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_move_to(x : Double, y : Double) = "canvas" "moveTo"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_line_to(x : Double, y : Double) = "canvas" "lineTo"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_cubic_to(
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) = "canvas" "bezierCurveTo"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_fill(r : Int, g : Int, b : Int, a : Double) = "canvas" "fill"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_stroke(r : Int, g : Int, b : Int, a : Double, width : Double) = "canvas" "stroke"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_set_stroke_style(cap : Int, join : Int, miter : Double) = "canvas" "setStrokeStyle"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_create_linear_gradient(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) = "canvas" "createLinearGradient"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_create_radial_gradient(
  cx : Double,
  cy : Double,
  r : Double,
  fx : Double,
  fy : Double,
  fr : Double,
) = "canvas" "createRadialGradient"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_add_gradient_stop(
  stop : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) = "canvas" "addGradientStop"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_fill_gradient(opacity : Double) = "canvas" "fillGradient"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_stroke_gradient(opacity : Double, width : Double) = "canvas" "strokeGradient"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_clip() = "canvas" "clip"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_clear_rect(x : Double, y : Double, w : Double, h : Double) = "canvas" "clearRect"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_draw_image(asset_index : Int, w : Double, h : Double) = "canvas" "drawImage"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_draw_text(
  text : String,
  font : String,
  size : Double,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  justify : Int,
) = "canvas" "drawText"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_set_global_composite_operation(mode : String) = "canvas" "setGlobalCompositeOperation"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_begin_layer() = "canvas" "beginLayer"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_end_layer(mode : String) = "canvas" "endLayer"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_set_fill_rule(rule : String) = "canvas" "setFillRule"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_set_opacity(opacity : Double) = "canvas" "setOpacity"

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub struct CanvasRenderer {}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub fn CanvasRenderer::new() -> CanvasRenderer {
  CanvasRenderer::{  }
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with save(self : CanvasRenderer) {
  let _ = self
  canvas_save()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with restore(self : CanvasRenderer) {
  let _ = self
  canvas_restore()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_transform(
  self : CanvasRenderer,
  m : @math.Matrix,
) {
  let _ = self
  canvas_set_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with concat_transform(
  self : CanvasRenderer,
  m : @math.Matrix,
) {
  let _ = self
  canvas_concat_transform(m.a, m.b, m.c, m.d, m.e, m.f)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with begin_path(self : CanvasRenderer) {
  let _ = self
  canvas_begin_path()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with close_path(self : CanvasRenderer) {
  let _ = self
  canvas_close_path()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with move_to(
  self : CanvasRenderer,
  x : Double,
  y : Double,
) {
  let _ = self
  canvas_move_to(x, y)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with line_to(
  self : CanvasRenderer,
  x : Double,
  y : Double,
) {
  let _ = self
  canvas_line_to(x, y)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with cubic_to(
  self : CanvasRenderer,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) {
  let _ = self
  canvas_cubic_to(cp1x, cp1y, cp2x, cp2y, x, y)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with fill(
  self : CanvasRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
) {
  let _ = self
  canvas_fill(r, g, b, opacity)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with stroke(
  self : CanvasRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  width : Double,
) {
  let _ = self
  canvas_stroke(r, g, b, opacity, width)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_stroke_style(
  self : CanvasRenderer,
  line_cap : Int,
  line_join : Int,
  miter_limit : Double,
) {
  let _ = self
  canvas_set_stroke_style(line_cap, line_join, miter_limit)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_begin_dash() = "canvas" "beginDash"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_add_dash(value : Double) = "canvas" "addDash"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_apply_dash(offset : Double) = "canvas" "applyDash"

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_line_dash(
  self : CanvasRenderer,
  dash_array : Array[Double],
  dash_offset : Double,
) {
  let _ = self
  canvas_begin_dash()
  for d in dash_array {
    canvas_add_dash(d)
  }
  canvas_apply_dash(dash_offset)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with fill_linear_gradient(
  self : CanvasRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
) {
  let _ = self
  canvas_create_linear_gradient(x1, y1, x2, y2)
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let r = (stops[i * 4 + 1] * 255.0).to_int().to_double()
    let g = (stops[i * 4 + 2] * 255.0).to_int().to_double()
    let b = (stops[i * 4 + 3] * 255.0).to_int().to_double()
    // Try to find matching alpha stop
    let mut a = 1.0
    if stops.length() >= p * 4 + p * 2 {
      // Simplification: assume alpha stops are in the same order as color stops
      a = stops[p * 4 + i * 2 + 1]
    }
    canvas_add_gradient_stop(offset, r, g, b, a)
  }
  canvas_fill_gradient(opacity)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with stroke_linear_gradient(
  self : CanvasRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
  width : Double,
) {
  let _ = self
  canvas_create_linear_gradient(x1, y1, x2, y2)
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let r = (stops[i * 4 + 1] * 255.0).to_int().to_double()
    let g = (stops[i * 4 + 2] * 255.0).to_int().to_double()
    let b = (stops[i * 4 + 3] * 255.0).to_int().to_double()
    let mut a = 1.0
    if stops.length() >= p * 4 + p * 2 {
      a = stops[p * 4 + i * 2 + 1]
    }
    canvas_add_gradient_stop(offset, r, g, b, a)
  }
  canvas_stroke_gradient(opacity, width)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with fill_radial_gradient(
  self : CanvasRenderer,
  cx : Double,
  cy : Double,
  r : Double,
  fx : Double,
  fy : Double,
  fr : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
) {
  let _ = self
  canvas_create_radial_gradient(cx, cy, r, fx, fy, fr)
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let r = (stops[i * 4 + 1] * 255.0).to_int().to_double()
    let g = (stops[i * 4 + 2] * 255.0).to_int().to_double()
    let b = (stops[i * 4 + 3] * 255.0).to_int().to_double()
    let mut a = 1.0
    if stops.length() >= p * 4 + p * 2 {
      a = stops[p * 4 + i * 2 + 1]
    }
    canvas_add_gradient_stop(offset, r, g, b, a)
  }
  canvas_fill_gradient(opacity)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with stroke_radial_gradient(
  self : CanvasRenderer,
  cx : Double,
  cy : Double,
  r : Double,
  fx : Double,
  fy : Double,
  fr : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
  width : Double,
) {
  let _ = self
  canvas_create_radial_gradient(cx, cy, r, fx, fy, fr)
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let r = (stops[i * 4 + 1] * 255.0).to_int().to_double()
    let g = (stops[i * 4 + 2] * 255.0).to_int().to_double()
    let b = (stops[i * 4 + 3] * 255.0).to_int().to_double()
    let mut a = 1.0
    if stops.length() >= p * 4 + p * 2 {
      a = stops[p * 4 + i * 2 + 1]
    }
    canvas_add_gradient_stop(offset, r, g, b, a)
  }
  canvas_stroke_gradient(opacity, width)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with clip(self : CanvasRenderer) {
  let _ = self
  canvas_clip()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with clear_rect(
  self : CanvasRenderer,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) {
  let _ = self
  canvas_clear_rect(x, y, w, h)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with draw_image(
  self : CanvasRenderer,
  id : String,
  w : Double,
  h : Double,
  asset_index : Int,
) {
  let _ = self
  // Wasm canvas bridge uses numeric asset indices to avoid relying on
  // unstable WasmGC string marshalling for image ids.
  let _ = id
  canvas_draw_image(asset_index, w, h)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with draw_text(
  self : CanvasRenderer,
  text : String,
  font : String,
  size : Double,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  justify : Int,
) {
  let _ = self
  canvas_draw_text(text, font, size, r, g, b, opacity, justify)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_blend_mode(
  self : CanvasRenderer,
  mode : String,
) {
  let _ = self
  canvas_set_global_composite_operation(mode)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_fill_rule(
  self : CanvasRenderer,
  rule : String,
) {
  let _ = self
  canvas_set_fill_rule(rule)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with set_opacity(
  self : CanvasRenderer,
  opacity : Double,
) {
  let _ = self
  canvas_set_opacity(opacity)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with begin_layer(
  self : CanvasRenderer,
) {
  let _ = self
  canvas_begin_layer()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with end_layer(
  self : CanvasRenderer,
  mode : String,
) {
  let _ = self
  canvas_end_layer(mode)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_prepare_matte_layer() = "canvas" "prepareMatteLayer"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_begin_matte_exit() = "canvas" "beginMatteExit"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn canvas_end_matte_exit(matte_type : Int) = "canvas" "endMatteExit"

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with prepare_matte_layer(
  self : CanvasRenderer,
) {
  let _ = self
  canvas_prepare_matte_layer()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with begin_matte_exit(
  self : CanvasRenderer,
) {
  let _ = self
  canvas_begin_matte_exit()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub impl Renderer for CanvasRenderer with end_matte_exit(
  self : CanvasRenderer,
  matte_type : Int,
) {
  let _ = self
  canvas_end_matte_exit(matte_type)
}
