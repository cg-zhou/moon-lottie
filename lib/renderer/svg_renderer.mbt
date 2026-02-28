///| SvgRenderer

///|
/// A renderer that generates SVG string output for Lottie animations.
pub struct SvgRenderer {
  width : Double
  height : Double
  buffer : StringBuilder
  defs_buffer : StringBuilder
  state_stack : Array[(@math.Matrix, String, Int)]
  mut current_matrix : @math.Matrix
  mut path_buffer : StringBuilder
  mut gradient_count : Int
  mut group_depth : Int
  mut current_fill_rule : String
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
  self.state_stack.push((self.current_matrix, self.current_fill_rule, 1))
  self.buffer.write_string("<g>")
  self.group_depth = self.group_depth + 1
}

///|
pub impl Renderer for SvgRenderer with restore(self : SvgRenderer) -> Unit {
  match self.state_stack.pop() {
    Some((m, fr, gc)) => {
      self.current_matrix = m
      self.current_fill_rule = fr
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
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"\{color}\" stroke-opacity=\"\{fmt(opacity)}\" stroke-width=\"\{fmt(width)}\" />",
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
  let _ = self
  let _ = line_cap
  let _ = line_join
  let _ = miter_limit
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
    let (m, fr, gc) = self.state_stack[last_idx]
    self.state_stack[last_idx] = (m, fr, gc + 1)
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
) -> Unit {
  self.buffer.write_string(
    "<image href=\"\{id}\" width=\"\{width}\" height=\"\{height}\" />",
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
    "<text font-family=\"\{font}\" font-size=\"\{size}\" fill=\"\{color}\" fill-opacity=\"\{opacity}\" text-anchor=\"\{anchor}\">\{text}</text>",
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
  let id = "lottie-id" // Normalized ID
  self.gradient_count = self.gradient_count + 1

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
  let id = "grad_\{self.gradient_count}"
  self.gradient_count = self.gradient_count + 1

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
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{opacity}\" stroke-width=\"\{width}\" />",
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
  let id = "grad_\{self.gradient_count}"
  self.gradient_count = self.gradient_count + 1
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
    self.buffer.write_string(
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
  let id = "grad_\{self.gradient_count}"
  self.gradient_count = self.gradient_count + 1
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
    self.buffer.write_string(
      "<path d=\"\{path_data}\" fill=\"none\" stroke=\"url(#\{id})\" stroke-opacity=\"\{opacity}\" stroke-width=\"\{width}\" />",
    )
  }
}

///|
pub impl Renderer for SvgRenderer with clip(self : SvgRenderer) -> Unit {
  let id = "clip_\{self.gradient_count}"
  self.gradient_count = self.gradient_count + 1
  let path_data = self.path_buffer.to_string()
  self.defs_buffer.write_string(
    "<clipPath id=\"\{id}\"><path d=\"\{path_data}\" fill-rule=\"\{self.current_fill_rule}\" /></clipPath>",
  )
  if self.state_stack.length() > 0 {
    let last_idx = self.state_stack.length() - 1
    let (m, fr, gc) = self.state_stack[last_idx]
    self.state_stack[last_idx] = (m, fr, gc + 1)
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
  let duration = ani.op - ani.ip
  let step = if num_frames > 1 {
    duration / (num_frames - 1).to_double()
  } else {
    0.0
  }

  for i = 0; i < num_frames; i = i + 1 {
    let frame = ani.ip + i.to_double() * step
    let renderer = SvgRenderer::new(ani.w.to_double(), ani.h.to_double())
    let player = Player::new(ani, renderer)
    player.set_frame(frame)
    player.render()
    svgs.push(renderer.get_output())
  }
  svgs
}
