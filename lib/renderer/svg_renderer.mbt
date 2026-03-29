///| SvgRenderer

///|
/// A renderer that generates SVG string output for Lottie animations.
pub struct SvgRenderer {
  width : Double
  height : Double
  mut buffer : StringBuilder
  defs_buffer : StringBuilder
  state_stack : Array[SvgRendererState]
  mut current_matrix : @math.Matrix
  mut path_buffer : StringBuilder
  mut gradient_count : Int
  mut group_depth : Int
  mut current_fill_rule : String
  mut current_blend_mode : String
  mut current_line_cap : Int
  mut current_line_join : Int
  mut current_miter_limit : Double
  mut current_dash_array : Array[Double]
  mut current_dash_offset : Double
  layer_stack : Array[SvgLayerCapture]
  matte_stack : Array[SvgMatteCapture]
}

///|
struct SvgRendererState {
  current_matrix : @math.Matrix
  current_fill_rule : String
  group_count : Int
  current_blend_mode : String
  current_line_cap : Int
  current_line_join : Int
  current_miter_limit : Double
  current_dash_array : Array[Double]
  current_dash_offset : Double
}

///|
struct SvgLayerCapture {
  buffer : StringBuilder
}

///|
struct SvgMatteCapture {
  parent_buffer : StringBuilder
  content_markup : String
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
    gradient_count: 0,
    group_depth: 0,
    current_fill_rule: "nonzero",
    current_blend_mode: "source-over",
    current_line_cap: 1,
    current_line_join: 1,
    current_miter_limit: 4.0,
    current_dash_array: [],
    current_dash_offset: 0.0,
    layer_stack: [],
    matte_stack: [],
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
pub impl Renderer for SvgRenderer with save(self : SvgRenderer) -> Unit {
  self.state_stack.push({
    current_matrix: self.current_matrix,
    current_fill_rule: self.current_fill_rule,
    group_count: 1,
    current_blend_mode: self.current_blend_mode,
    current_line_cap: self.current_line_cap,
    current_line_join: self.current_line_join,
    current_miter_limit: self.current_miter_limit,
    current_dash_array: self.current_dash_array,
    current_dash_offset: self.current_dash_offset,
  })
  self.buffer.write_string("<g>")
  self.group_depth = self.group_depth + 1
}

///|
pub impl Renderer for SvgRenderer with restore(self : SvgRenderer) -> Unit {
  match self.state_stack.pop() {
    Some(state) => {
      self.current_matrix = state.current_matrix
      self.current_fill_rule = state.current_fill_rule
      self.current_blend_mode = state.current_blend_mode
      self.current_line_cap = state.current_line_cap
      self.current_line_join = state.current_line_join
      self.current_miter_limit = state.current_miter_limit
      self.current_dash_array = state.current_dash_array
      self.current_dash_offset = state.current_dash_offset
      for i = 0; i < state.group_count; i = i + 1 {
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
  let p = self.current_matrix.transform_point(x, y)
  self.path_buffer.write_string("M\{fmt(p.0)},\{fmt(p.1)} ")
}

///|
pub impl Renderer for SvgRenderer with line_to(
  self : SvgRenderer,
  x : Double,
  y : Double,
) -> Unit {
  let p = self.current_matrix.transform_point(x, y)
  self.path_buffer.write_string("L\{fmt(p.0)},\{fmt(p.1)} ")
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
  let p1 = self.current_matrix.transform_point(cp1x, cp1y)
  let p2 = self.current_matrix.transform_point(cp2x, cp2y)
  let p = self.current_matrix.transform_point(x, y)
  self.path_buffer.write_string(
    "C\{fmt(p1.0)},\{fmt(p1.1)} \{fmt(p2.0)},\{fmt(p2.1)} \{fmt(p.0)},\{fmt(p.1)} ",
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
fn escape_xml_text(value : String) -> String {
  let buffer = StringBuilder::new()
  for i = 0; i < value.length(); i = i + 1 {
    let current_char = value[i].to_int().unsafe_to_char()
    match current_char {
      '&' => buffer.write_string("&amp;")
      '<' => buffer.write_string("&lt;")
      '>' => buffer.write_string("&gt;")
      '"' => buffer.write_string("&quot;")
      '\'' => buffer.write_string("&#39;")
      _ => buffer.write_char(current_char)
    }
  }
  buffer.to_string()
}

///|
fn matrix_to_svg_transform(matrix : @math.Matrix) -> String {
  "matrix(\{fmt(matrix.a)} \{fmt(matrix.b)} \{fmt(matrix.c)} \{fmt(matrix.d)} \{fmt(matrix.e)} \{fmt(matrix.f)})"
}

///|
fn line_cap_to_svg(line_cap : Int) -> String {
  match line_cap {
    2 => "round"
    3 => "square"
    _ => "butt"
  }
}

///|
fn line_join_to_svg(line_join : Int) -> String {
  match line_join {
    2 => "round"
    3 => "bevel"
    _ => "miter"
  }
}

///|
fn dash_array_to_svg(dash_array : Array[Double]) -> String {
  let buffer = StringBuilder::new()
  for i = 0; i < dash_array.length(); i = i + 1 {
    if i > 0 {
      buffer.write_string(",")
    }
    buffer.write_string(fmt(dash_array[i]))
  }
  buffer.to_string()
}

///|
fn SvgRenderer::next_id(self : SvgRenderer, prefix : String) -> String {
  let id = "\{prefix}_\{self.gradient_count}"
  self.gradient_count = self.gradient_count + 1
  id
}

///|
fn SvgRenderer::stroke_attrs(self : SvgRenderer) -> String {
  let attrs = StringBuilder::new()
  attrs.write_string(
    " stroke-linecap=\"\{line_cap_to_svg(self.current_line_cap)}\" stroke-linejoin=\"\{line_join_to_svg(self.current_line_join)}\" stroke-miterlimit=\"\{fmt(self.current_miter_limit)}\"",
  )
  if self.current_dash_array.length() > 0 {
    attrs.write_string(
      " stroke-dasharray=\"\{dash_array_to_svg(self.current_dash_array)}\" stroke-dashoffset=\"\{fmt(self.current_dash_offset)}\"",
    )
  }
  attrs.to_string()
}

///|
fn SvgRenderer::append_markup(self : SvgRenderer, markup : String) -> Unit {
  if self.current_blend_mode == "source-atop" {
    let existing = self.buffer.to_string()
    if existing.length() == 0 {
      return
    }
    let mask_id = self.next_id("blend_mask")
    self.defs_buffer.write_string(
      "<mask id=\"\{mask_id}\" maskUnits=\"userSpaceOnUse\">",
    )
    self.defs_buffer.write_string(existing)
    self.defs_buffer.write_string("</mask>")
    self.buffer = StringBuilder::new()
    self.buffer.write_string("<g mask=\"url(#\{mask_id})\">")
    self.buffer.write_string(markup)
    self.buffer.write_string("</g>")
    return
  }
  if self.current_blend_mode != "source-over" {
    self.buffer.write_string(
      "<g style=\"mix-blend-mode:\{escape_xml_text(self.current_blend_mode)}\">",
    )
    self.buffer.write_string(markup)
    self.buffer.write_string("</g>")
    return
  }
  self.buffer.write_string(markup)
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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"\{color}\" fill-opacity=\"\{fmt(opacity)}\" fill-rule=\"\{self.current_fill_rule}\" />",
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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"\{color}\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{self.stroke_attrs()} />",
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
  self.current_line_cap = line_cap
  self.current_line_join = line_join
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
    let state = self.state_stack[last_idx]
    self.state_stack[last_idx] = {
      current_matrix: state.current_matrix,
      current_fill_rule: state.current_fill_rule,
      group_count: state.group_count + 1,
      current_blend_mode: state.current_blend_mode,
      current_line_cap: state.current_line_cap,
      current_line_join: state.current_line_join,
      current_miter_limit: state.current_miter_limit,
      current_dash_array: state.current_dash_array,
      current_dash_offset: state.current_dash_offset,
    }
  }
  self.buffer.write_string("<g opacity=\"\{fmt(opacity)}\">")
  self.group_depth = self.group_depth + 1
}

///|
pub impl Renderer for SvgRenderer with set_blend_mode(
  self : SvgRenderer,
  mode : String,
) -> Unit {
  self.current_blend_mode = mode
}

///|
pub impl Renderer for SvgRenderer with begin_layer(
  self : SvgRenderer,
) -> Unit {
  self.layer_stack.push({ buffer: self.buffer })
  self.buffer = StringBuilder::new()
}

///|
pub impl Renderer for SvgRenderer with end_layer(
  self : SvgRenderer,
  mode : String,
) -> Unit {
  let layer_markup = self.buffer.to_string()
  match self.layer_stack.pop() {
    Some(layer) => {
      self.buffer = layer.buffer
      if mode != "source-over" && mode != "" {
        self.buffer.write_string(
          "<g style=\"mix-blend-mode:\{escape_xml_text(mode)}\">",
        )
        self.buffer.write_string(layer_markup)
        self.buffer.write_string("</g>")
      } else {
        self.buffer.write_string(layer_markup)
      }
    }
    None => ()
  }
}

///|
pub impl Renderer for SvgRenderer with prepare_matte_layer(
  self : SvgRenderer,
) -> Unit {
  self.matte_stack.push({
    parent_buffer: self.buffer,
    content_markup: "",
  })
  self.buffer = StringBuilder::new()
}

///|
pub impl Renderer for SvgRenderer with begin_matte_exit(
  self : SvgRenderer,
) -> Unit {
  match self.matte_stack.pop() {
    Some(matte) => {
      self.matte_stack.push({
        parent_buffer: matte.parent_buffer,
        content_markup: self.buffer.to_string(),
      })
      self.buffer = StringBuilder::new()
    }
    None => ()
  }
}

///|
pub impl Renderer for SvgRenderer with end_matte_exit(
  self : SvgRenderer,
  matte_type : Int,
) -> Unit {
  let matte_markup = self.buffer.to_string()
  match self.matte_stack.pop() {
    Some(matte) => {
      self.buffer = matte.parent_buffer
      if matte.content_markup.length() == 0 || matte_markup.length() == 0 {
        return
      }
      let mask_id = self.next_id("matte")
      self.defs_buffer.write_string(
        "<mask id=\"\{mask_id}\" maskUnits=\"userSpaceOnUse\">",
      )
      if matte_type == 2 {
        self.defs_buffer.write_string(
          "<rect x=\"0\" y=\"0\" width=\"\{fmt(self.width)}\" height=\"\{fmt(self.height)}\" fill=\"#FFFFFF\" />",
        )
      }
      self.defs_buffer.write_string(matte_markup)
      self.defs_buffer.write_string("</mask>")
      self.buffer.write_string("<g mask=\"url(#\{mask_id})\">")
      self.buffer.write_string(matte.content_markup)
      self.buffer.write_string("</g>")
    }
    None => ()
  }
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
  self.append_markup(
    "<image href=\"\{escape_xml_text(id)}\" width=\"\{fmt(width)}\" height=\"\{fmt(height)}\" preserveAspectRatio=\"none\" transform=\"\{matrix_to_svg_transform(self.current_matrix)}\" />",
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
  self.append_markup(
    "<text font-family=\"\{escape_xml_text(font)}\" font-size=\"\{fmt(size)}\" fill=\"\{color}\" fill-opacity=\"\{fmt(opacity)}\" text-anchor=\"\{anchor}\" transform=\"\{matrix_to_svg_transform(self.current_matrix)}\">\{escape_xml_text(text)}</text>",
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
  let id = self.next_id("grad")

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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"url(#\{id})\" fill-opacity=\"\{fmt(opacity)}\" fill-rule=\"\{self.current_fill_rule}\" />",
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
  let id = self.next_id("grad")

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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{self.stroke_attrs()} />",
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
  let id = self.next_id("grad")
  let p_c = self.current_matrix.transform_point(cx, cy)
  let p_f = self.current_matrix.transform_point(fx, fy)
  let _ = fr

  self.defs_buffer.write_string(
    "<radialGradient id=\"\{id}\" cx=\"\{p_c.0}\" cy=\"\{p_c.1}\" r=\"\{r}\" fx=\"\{p_f.0}\" fy=\"\{p_f.1}\" gradientUnits=\"userSpaceOnUse\">",
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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"url(#\{id})\" fill-opacity=\"\{opacity}\" fill-rule=\"\{self.current_fill_rule}\" />",
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
  let id = self.next_id("grad")
  let p_c = self.current_matrix.transform_point(cx, cy)
  let p_f = self.current_matrix.transform_point(fx, fy)
  let _ = fr

  self.defs_buffer.write_string(
    "<radialGradient id=\"\{id}\" cx=\"\{p_c.0}\" cy=\"\{p_c.1}\" r=\"\{r}\" fx=\"\{p_f.0}\" fy=\"\{p_f.1}\" gradientUnits=\"userSpaceOnUse\">",
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
    self.append_markup(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\"\{self.stroke_attrs()} />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with clip(self : SvgRenderer) -> Unit {
  let id = self.next_id("clip")
  let path_data = self.path_buffer.to_string()
  self.defs_buffer.write_string(
    "<clipPath id=\"\{id}\"><path d=\"\{path_data}\" fill-rule=\"\{self.current_fill_rule}\" /></clipPath>",
  )
  if self.state_stack.length() > 0 {
    let last_idx = self.state_stack.length() - 1
    let state = self.state_stack[last_idx]
    self.state_stack[last_idx] = {
      current_matrix: state.current_matrix,
      current_fill_rule: state.current_fill_rule,
      group_count: state.group_count + 1,
      current_blend_mode: state.current_blend_mode,
      current_line_cap: state.current_line_cap,
      current_line_join: state.current_line_join,
      current_miter_limit: state.current_miter_limit,
      current_dash_array: state.current_dash_array,
      current_dash_offset: state.current_dash_offset,
    }
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
