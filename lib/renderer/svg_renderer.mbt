///| SvgRenderer

///|
/// A renderer that generates SVG string output for Lottie animations.
pub struct SvgRenderer {
  width : Double
  height : Double
  buffer : StringBuilder
  defs_buffer : StringBuilder
  state_stack : Array[
    (
      @math.Matrix,
      String,
      Int,
      String,
      String,
      Double,
      Array[Double],
      Double
    )
  ]
  mut current_matrix : @math.Matrix
  mut path_buffer : StringBuilder
  mut def_count : Int
  mut group_depth : Int
  mut current_fill_rule : String
  mut current_line_cap : String
  mut current_line_join : String
  mut current_miter_limit : Double
  mut current_dash_array : Array[Double]
  mut current_dash_offset : Double
}

///|
pub fn SvgRenderer::new(width : Double, height : Double) -> SvgRenderer {
  {
    width,
    height,
    buffer: StringBuilder::new(),
    defs_buffer: StringBuilder::new(),
    state_stack: [],
    current_matrix: @math.Matrix::identity(),
    path_buffer: StringBuilder::new(),
    def_count: 0,
    group_depth: 0,
    current_fill_rule: "nonzero",
    current_line_cap: "butt",
    current_line_join: "miter",
    current_miter_limit: 4.0,
    current_dash_array: [],
    current_dash_offset: 0.0,
  }
}

///|
fn fmt(v : Double) -> String {
  let factor = 100.0
  let rounded = (v * factor).to_int().to_double() / factor
  rounded.to_string()
}

///|
pub fn SvgRenderer::get_output(self : SvgRenderer) -> String {
  let output = StringBuilder::new()
  output.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{fmt(self.width)}\" height=\"\{fmt(self.height)}\" viewBox=\"0 0 \{fmt(self.width)} \{fmt(self.height)}\">",
  )
  if self.defs_buffer.to_string().length() > 0 {
    output.write_string("<defs>")
    output.write_string(self.defs_buffer.to_string())
    output.write_string("</defs>")
  }
  output.write_string(self.buffer.to_string())
  output.write_string("</svg>")
  output.to_string()
}

///|
fn is_near_zero(v : Double) -> Bool {
  v.abs() < 0.000001
}

///|
fn escape_xml(value : String) -> String {
  let out = StringBuilder::new()
  for ch in value {
    match ch {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&apos;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn matrix_to_attr(matrix : @math.Matrix) -> String {
  // SVG uses matrix(a b c d e f) for 2D affine transforms. We recover those six
  // coefficients by sampling the transformed origin and unit basis vectors from
  // the current MoonBit matrix and converting them back into SVG's matrix form.
  let origin = matrix.transform_point(0.0, 0.0)
  let x_axis = matrix.transform_point(1.0, 0.0)
  let y_axis = matrix.transform_point(0.0, 1.0)
  let a = x_axis.0 - origin.0
  let b = x_axis.1 - origin.1
  let c = y_axis.0 - origin.0
  let d = y_axis.1 - origin.1
  let e = origin.0
  let f = origin.1
  if is_near_zero(a - 1.0) && is_near_zero(b) && is_near_zero(c) &&
    is_near_zero(d - 1.0) && is_near_zero(e) && is_near_zero(f) {
    ""
  } else {
    " transform=\"matrix(\{fmt(a)} \{fmt(b)} \{fmt(c)} \{fmt(d)} \{fmt(e)} \{fmt(f)})\""
  }
}

///|
fn stroke_attrs(renderer : SvgRenderer) -> String {
  let attrs = StringBuilder::new()
  attrs.write_string(" stroke-linecap=\"\{renderer.current_line_cap}\"")
  attrs.write_string(" stroke-linejoin=\"\{renderer.current_line_join}\"")
  attrs.write_string(
    " stroke-miterlimit=\"\{fmt(renderer.current_miter_limit)}\"",
  )
  if renderer.current_dash_array.length() > 0 {
    let dash_values = StringBuilder::new()
    for i = 0; i < renderer.current_dash_array.length(); i = i + 1 {
      if i > 0 {
        dash_values.write_string(" ")
      }
      dash_values.write_string(fmt(renderer.current_dash_array[i]))
    }
    attrs.write_string(
      " stroke-dasharray=\"\{dash_values.to_string()}\" stroke-dashoffset=\"\{fmt(renderer.current_dash_offset)}\"",
    )
  }
  attrs.to_string()
}

///|
fn next_def_id(renderer : SvgRenderer, prefix : String) -> String {
  let id = "\{prefix}_\{renderer.def_count}"
  renderer.def_count = renderer.def_count + 1
  id
}

///|
fn point_distance(p1 : (Double, Double), p2 : (Double, Double)) -> Double {
  @math.sqrt(
    (p2.0 - p1.0) * (p2.0 - p1.0) + (p2.1 - p1.1) * (p2.1 - p1.1),
  )
}

///|
pub impl Renderer for SvgRenderer with save(self : SvgRenderer) -> Unit {
  self.state_stack.push((
    self.current_matrix,
    self.current_fill_rule,
    1,
    self.current_line_cap,
    self.current_line_join,
    self.current_miter_limit,
    self.current_dash_array,
    self.current_dash_offset,
  ))
  self.buffer.write_string("<g>")
  self.group_depth = self.group_depth + 1
}

///|
pub impl Renderer for SvgRenderer with restore(self : SvgRenderer) -> Unit {
  match self.state_stack.pop() {
    Some((m, fr, gc, lc, lj, ml, da, doff)) => {
      self.current_matrix = m
      self.current_fill_rule = fr
      self.current_line_cap = lc
      self.current_line_join = lj
      self.current_miter_limit = ml
      self.current_dash_array = da
      self.current_dash_offset = doff
      for i = 0; i < gc; i = i + 1 {
        self.buffer.write_string("</g>")
        self.group_depth = self.group_depth - 1
      }
    }
    None => ()
  }
}

///|
pub impl Renderer for SvgRenderer with set_transform(
  self : SvgRenderer,
  matrix : @math.Matrix,
) -> Unit {
  self.current_matrix = matrix
}

///|
pub impl Renderer for SvgRenderer with concat_transform(
  self : SvgRenderer,
  matrix : @math.Matrix,
) -> Unit {
  self.current_matrix = self.current_matrix.multiply(matrix)
}

///|
pub impl Renderer for SvgRenderer with begin_path(self : SvgRenderer) -> Unit {
  self.path_buffer = StringBuilder::new()
}

///|
pub impl Renderer for SvgRenderer with close_path(self : SvgRenderer) -> Unit {
  self.path_buffer.write_string("Z")
}

///|
pub impl Renderer for SvgRenderer with move_to(
  self : SvgRenderer,
  x : Double,
  y : Double,
) -> Unit {
  self.path_buffer.write_string("M\{fmt(x)},\{fmt(y)} ")
}

///|
pub impl Renderer for SvgRenderer with line_to(
  self : SvgRenderer,
  x : Double,
  y : Double,
) -> Unit {
  self.path_buffer.write_string("L\{fmt(x)},\{fmt(y)} ")
}

///|
pub impl Renderer for SvgRenderer with cubic_to(
  self : SvgRenderer,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.path_buffer.write_string(
    "C\{fmt(cp1x)},\{fmt(cp1y)} \{fmt(cp2x)},\{fmt(cp2y)} \{fmt(x)},\{fmt(y)} ",
  )
}

///|
fn color_to_hex(r : Int, g : Int, b : Int) -> String {
  fn hex(v : Int) -> String {
    let chars = "0123456789ABCDEF"
    let v = if v < 0 { 0 } else if v > 255 { 255 } else { v }
    let high = v / 16
    let low = v % 16
    let s = StringBuilder::new()
    s.write_char(chars[high].to_int().unsafe_to_char())
    s.write_char(chars[low].to_int().unsafe_to_char())
    s.to_string()
  }

  "#" + hex(r) + hex(g) + hex(b)
}

///|
pub impl Renderer for SvgRenderer with fill(
  self : SvgRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
) -> Unit {
  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    let color = color_to_hex(r, g, b)
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"\{color}\" fill-opacity=\"\{fmt(opacity)}\" fill-rule=\"\{self.current_fill_rule}\"\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with stroke(
  self : SvgRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  width : Double,
) -> Unit {
  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    let color = color_to_hex(r, g, b)
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"\{color}\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{stroke_attrs(self)}\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with set_stroke_style(
  self : SvgRenderer,
  line_cap : Int,
  line_join : Int,
  miter_limit : Double,
) -> Unit {
  self.current_line_cap = match line_cap {
    2 => "round"
    3 => "square"
    _ => "butt"
  }
  self.current_line_join = match line_join {
    2 => "round"
    3 => "bevel"
    _ => "miter"
  }
  self.current_miter_limit = miter_limit
}

///|
pub impl Renderer for SvgRenderer with set_line_dash(
  self : SvgRenderer,
  dash_array : Array[Double],
  dash_offset : Double,
) -> Unit {
  self.current_dash_array = dash_array
  self.current_dash_offset = dash_offset
}

///|
pub impl Renderer for SvgRenderer with set_fill_rule(
  self : SvgRenderer,
  rule : String,
) -> Unit {
  self.current_fill_rule = rule
}

///|
pub impl Renderer for SvgRenderer with set_opacity(
  self : SvgRenderer,
  opacity : Double,
) -> Unit {
  if self.state_stack.length() > 0 {
    let last_idx = self.state_stack.length() - 1
    let (m, fr, gc, lc, lj, ml, da, doff) = self.state_stack[last_idx]
    self.state_stack[last_idx] = (m, fr, gc + 1, lc, lj, ml, da, doff)
  }
  self.buffer.write_string("<g opacity=\"\{fmt(opacity)}\">")
  self.group_depth = self.group_depth + 1
}

///|
pub impl Renderer for SvgRenderer with set_blend_mode(
  self : SvgRenderer,
  mode : String,
) -> Unit {
  let _ = self
  let _ = mode
}

///|
pub impl Renderer for SvgRenderer with begin_layer(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with end_layer(
  self : SvgRenderer,
  mode : String,
) -> Unit {
  let _ = self
  let _ = mode
}

///|
pub impl Renderer for SvgRenderer with prepare_matte_layer(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with begin_matte_exit(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with end_matte_exit(
  self : SvgRenderer,
  matte_type : Int,
) -> Unit {
  let _ = self
  let _ = matte_type
}

///|
pub impl Renderer for SvgRenderer with supports_mask_composite(
  self : SvgRenderer,
) -> Bool {
  let _ = self
  false
}

///|
pub impl Renderer for SvgRenderer with begin_mask_composite(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with begin_mask_path(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with apply_mask_path(
  self : SvgRenderer,
  mode : Int,
  opacity : Double,
  inverted : Bool,
  expansion : Double,
) -> Unit {
  let _ = self
  let _ = mode
  let _ = opacity
  let _ = inverted
  let _ = expansion
}

///|
pub impl Renderer for SvgRenderer with end_mask_composite(
  self : SvgRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for SvgRenderer with clear_rect(
  self : SvgRenderer,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit {
  let _ = self
  let _ = x
  let _ = y
  let _ = w
  let _ = h
}

///|
pub impl Renderer for SvgRenderer with draw_image(
  self : SvgRenderer,
  id : String,
  width : Double,
  height : Double,
  asset_index : Int,
) -> Unit {
  // SVG renderer writes the resolved href directly, so it does not need the
  // wasm-only numeric asset index used by the canvas bridge.
  let _ = asset_index
  self.buffer.write_string(
    "<image href=\"\{escape_xml(id)}\" width=\"\{fmt(width)}\" height=\"\{fmt(height)}\"\{matrix_to_attr(self.current_matrix)} />",
  )
}

///|
pub impl Renderer for SvgRenderer with draw_text(
  self : SvgRenderer,
  text : String,
  font : String,
  size : Double,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  justify : Int,
) -> Unit {
  let color = color_to_hex(r, g, b)
  let anchor = match justify {
    1 => "end"
    2 => "middle"
    _ => "start"
  }
  self.buffer.write_string(
    "<text font-family=\"\{escape_xml(font)}\" font-size=\"\{fmt(size)}\" fill=\"\{color}\" fill-opacity=\"\{fmt(opacity)}\" text-anchor=\"\{anchor}\"\{matrix_to_attr(self.current_matrix)}>\{escape_xml(text)}</text>",
  )
}

///|
pub impl Renderer for SvgRenderer with fill_linear_gradient(
  self : SvgRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
) -> Unit {
  let id = next_def_id(self, "grad")

  let p1 = self.current_matrix.transform_point(x1, y1)
  let p2 = self.current_matrix.transform_point(x2, y2)

  self.defs_buffer.write_string(
    "<linearGradient id=\"\{id}\" x1=\"\{fmt(p1.0)}\" y1=\"\{fmt(p1.1)}\" x2=\"\{fmt(p2.0)}\" y2=\"\{fmt(p2.1)}\" gradientUnits=\"userSpaceOnUse\">",
  )
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let color = color_to_hex(
      (stops[i * 4 + 1] * 255.0).to_int(),
      (stops[i * 4 + 2] * 255.0).to_int(),
      (stops[i * 4 + 3] * 255.0).to_int(),
    )
    let mut opacity_stop = 1.0
    if stops.length() >= p * 4 + p * 2 {
      opacity_stop = stops[p * 4 + i * 2 + 1]
    }
    self.defs_buffer.write_string(
      "<stop offset=\"\{fmt(offset)}\" stop-color=\"\{color}\" stop-opacity=\"\{fmt(opacity_stop)}\" />",
    )
  }
  self.defs_buffer.write_string("</linearGradient>")

  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"url(#\{id})\" fill-opacity=\"\{fmt(opacity)}\" fill-rule=\"\{self.current_fill_rule}\"\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with stroke_linear_gradient(
  self : SvgRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
  width : Double,
) -> Unit {
  let id = next_def_id(self, "grad")

  let p1 = self.current_matrix.transform_point(x1, y1)
  let p2 = self.current_matrix.transform_point(x2, y2)

  self.defs_buffer.write_string(
    "<linearGradient id=\"\{id}\" x1=\"\{p1.0}\" y1=\"\{p1.1}\" x2=\"\{p2.0}\" y2=\"\{p2.1}\" gradientUnits=\"userSpaceOnUse\">",
  )
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let color = color_to_hex(
      (stops[i * 4 + 1] * 255.0).to_int(),
      (stops[i * 4 + 2] * 255.0).to_int(),
      (stops[i * 4 + 3] * 255.0).to_int(),
    )
    let mut opacity_stop = 1.0
    if stops.length() >= p * 4 + p * 2 {
      opacity_stop = stops[p * 4 + i * 2 + 1]
    }
    self.defs_buffer.write_string(
      "<stop offset=\"\{offset}\" stop-color=\"\{color}\" stop-opacity=\"\{opacity_stop}\" />",
    )
  }
  self.defs_buffer.write_string("</linearGradient>")

  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{stroke_attrs(self)}\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with fill_radial_gradient(
  self : SvgRenderer,
  cx : Double,
  cy : Double,
  r : Double,
  fx : Double,
  fy : Double,
  fr : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
) -> Unit {
  let id = next_def_id(self, "grad")
  let p_c = self.current_matrix.transform_point(cx, cy)
  let p_f = self.current_matrix.transform_point(fx, fy)
  let fr_point = self.current_matrix.transform_point(fx + fr, fy)
  let radius_point = self.current_matrix.transform_point(cx + r, cy)
  let gradient_radius = point_distance(p_c, radius_point)
  let focus_radius = point_distance(p_f, fr_point)

  self.defs_buffer.write_string(
    "<radialGradient id=\"\{id}\" cx=\"\{fmt(p_c.0)}\" cy=\"\{fmt(p_c.1)}\" r=\"\{fmt(gradient_radius)}\" fx=\"\{fmt(p_f.0)}\" fy=\"\{fmt(p_f.1)}\" fr=\"\{fmt(focus_radius)}\" gradientUnits=\"userSpaceOnUse\">",
  )
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let color = color_to_hex(
      (stops[i * 4 + 1] * 255.0).to_int(),
      (stops[i * 4 + 2] * 255.0).to_int(),
      (stops[i * 4 + 3] * 255.0).to_int(),
    )
    let mut opacity_stop = 1.0
    if stops.length() >= p * 4 + p * 2 {
      opacity_stop = stops[p * 4 + i * 2 + 1]
    }
    self.defs_buffer.write_string(
      "<stop offset=\"\{offset}\" stop-color=\"\{color}\" stop-opacity=\"\{opacity_stop}\" />",
    )
  }
  self.defs_buffer.write_string("</radialGradient>")

  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"url(#\{id})\" fill-opacity=\"\{fmt(opacity)}\" fill-rule=\"\{self.current_fill_rule}\"\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with stroke_radial_gradient(
  self : SvgRenderer,
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
) -> Unit {
  let id = next_def_id(self, "grad")
  let p_c = self.current_matrix.transform_point(cx, cy)
  let p_f = self.current_matrix.transform_point(fx, fy)
  let fr_point = self.current_matrix.transform_point(fx + fr, fy)
  let radius_point = self.current_matrix.transform_point(cx + r, cy)
  let gradient_radius = point_distance(p_c, radius_point)
  let focus_radius = point_distance(p_f, fr_point)

  self.defs_buffer.write_string(
    "<radialGradient id=\"\{id}\" cx=\"\{fmt(p_c.0)}\" cy=\"\{fmt(p_c.1)}\" r=\"\{fmt(gradient_radius)}\" fx=\"\{fmt(p_f.0)}\" fy=\"\{fmt(p_f.1)}\" fr=\"\{fmt(focus_radius)}\" gradientUnits=\"userSpaceOnUse\">",
  )
  for i = 0; i < p; i = i + 1 {
    let offset = stops[i * 4]
    let color = color_to_hex(
      (stops[i * 4 + 1] * 255.0).to_int(),
      (stops[i * 4 + 2] * 255.0).to_int(),
      (stops[i * 4 + 3] * 255.0).to_int(),
    )
    let mut opacity_stop = 1.0
    if stops.length() >= p * 4 + p * 2 {
      opacity_stop = stops[p * 4 + i * 2 + 1]
    }
    self.defs_buffer.write_string(
      "<stop offset=\"\{offset}\" stop-color=\"\{color}\" stop-opacity=\"\{opacity_stop}\" />",
    )
  }
  self.defs_buffer.write_string("</radialGradient>")

  let path_data = self.path_buffer.to_string()
  if path_data.length() > 0 {
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{stroke_attrs(self)}\{matrix_to_attr(self.current_matrix)} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with clip(self : SvgRenderer) -> Unit {
  let id = next_def_id(self, "clip")
  let path_data = self.path_buffer.to_string()
  self.defs_buffer.write_string(
    "<clipPath id=\"\{id}\"><path d=\"\{path_data}\" fill-rule=\"\{self.current_fill_rule}\"\{matrix_to_attr(self.current_matrix)} /></clipPath>",
  )
  if self.state_stack.length() > 0 {
    let last_idx = self.state_stack.length() - 1
    let (m, fr, gc, lc, lj, ml, da, doff) = self.state_stack[last_idx]
    self.state_stack[last_idx] = (m, fr, gc + 1, lc, lj, ml, da, doff)
  }
  self.buffer.write_string("<g clip-path=\"url(#\{id})\">")
  self.group_depth = self.group_depth + 1
}

///|
/// Helper to render an animation to a set of SVG snapshots.
pub fn render_animation_to_svgs(
  ani : @model.Animation,
  num_frames : Int,
) -> Array[String] {
  let svgs = []
  let duration = ani.out_point - ani.in_point
  let step = if num_frames > 1 {
    duration / (num_frames - 1).to_double()
  } else {
    0.0
  }

  for i = 0; i < num_frames; i = i + 1 {
    let frame = ani.in_point + i.to_double() * step
    let renderer = SvgRenderer::new(ani.width.to_double(), ani.height.to_double())
    let player = Player::new(ani, renderer)
    player.set_frame(frame)
    player.render()
    svgs.push(renderer.get_output())
  }
  svgs
}
