///|
/// DrawilleRenderer

///|
priv struct DrawillePointF {
  x : Double
  y : Double
}

///|
priv struct StrokePolyline {
  points : Array[DrawillePointF]
  closed : Bool
}

///|
struct DrawillePoint {
  x : Int
  y : Int
} derive(Eq, Show)

///|
fn pointf_from_point(point : DrawillePoint) -> DrawillePointF {
  { x: point.x.to_double(), y: point.y.to_double() }
}

///|
fn pointf_add(a : DrawillePointF, b : DrawillePointF) -> DrawillePointF {
  { x: a.x + b.x, y: a.y + b.y }
}

///|
fn pointf_sub(a : DrawillePointF, b : DrawillePointF) -> DrawillePointF {
  { x: a.x - b.x, y: a.y - b.y }
}

///|
fn pointf_scale(point : DrawillePointF, scale : Double) -> DrawillePointF {
  { x: point.x * scale, y: point.y * scale }
}

///|
fn pointf_lerp(
  start : DrawillePointF,
  end_ : DrawillePointF,
  t : Double,
) -> DrawillePointF {
  {
    x: start.x + (end_.x - start.x) * t,
    y: start.y + (end_.y - start.y) * t,
  }
}

///|
fn pointf_dot(a : DrawillePointF, b : DrawillePointF) -> Double {
  a.x * b.x + a.y * b.y
}

///|
fn pointf_cross(a : DrawillePointF, b : DrawillePointF) -> Double {
  a.x * b.y - a.y * b.x
}

///|
fn pointf_length(point : DrawillePointF) -> Double {
  (point.x * point.x + point.y * point.y).sqrt()
}

///|
fn pointf_normalize(point : DrawillePointF) -> DrawillePointF {
  let length = pointf_length(point)
  if length <= 0.000001 {
    { x: 0.0, y: 0.0 }
  } else {
    { x: point.x / length, y: point.y / length }
  }
}

///|
fn pointf_eq(a : DrawillePointF, b : DrawillePointF) -> Bool {
  (a.x - b.x).abs() <= 0.000001 && (a.y - b.y).abs() <= 0.000001
}

///|
fn left_normal(point : DrawillePointF) -> DrawillePointF {
  { x: -point.y, y: point.x }
}

///|
fn right_normal(point : DrawillePointF) -> DrawillePointF {
  { x: point.y, y: -point.x }
}

///|
fn sample_point(x : Int, y : Int) -> DrawillePointF {
  { x: x.to_double(), y: y.to_double() }
}

///|
fn clamp_int(value : Int, lower : Int, upper : Int) -> Int {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn subpath_is_closed(points : Array[DrawillePoint]) -> Bool {
  points.length() > 1 && points[0] == points[points.length() - 1]
}

///|
fn subpath_vertices(points : Array[DrawillePoint]) -> Array[DrawillePointF] {
  let limit = if subpath_is_closed(points) { points.length() - 1 } else { points.length() }
  let vertices : Array[DrawillePointF] = []
  for i = 0; i < limit; i = i + 1 {
    vertices.push(pointf_from_point(points[i]))
  }
  vertices
}

///|
fn push_polyline_point(points : Array[DrawillePointF], point : DrawillePointF) -> Unit {
  if points.length() == 0 || !pointf_eq(points[points.length() - 1], point) {
    points.push(point)
  }
}

///|
fn append_stroke_polyline(
  polylines : Array[StrokePolyline],
  points : Array[DrawillePointF],
  closed : Bool,
) -> Array[DrawillePointF] {
  let compact : Array[DrawillePointF] = []
  for point in points {
    push_polyline_point(compact, point)
  }

  let mut normalized_closed = closed
  if compact.length() > 1 && pointf_eq(compact[0], compact[compact.length() - 1]) {
    let _ = compact.pop()
    normalized_closed = true
  }

  if compact.length() > 1 {
    polylines.push({ points: compact, closed: normalized_closed })
  }
  []
}

///|
fn normalize_dash_array(dash_array : Array[Double]) -> Array[Double] {
  let normalized : Array[Double] = []
  for dash in dash_array {
    if dash > 0.000001 {
      normalized.push(dash)
    }
  }

  if normalized.length() % 2 == 1 {
    let repeated : Array[Double] = []
    for dash in normalized {
      repeated.push(dash)
    }
    for dash in repeated {
      normalized.push(dash)
    }
  }
  normalized
}

///|
fn dash_pattern_length(dash_array : Array[Double]) -> Double {
  let mut length = 0.0
  for dash in dash_array {
    length = length + dash
  }
  length
}

///|
fn dashed_stroke_polylines(
  points : Array[DrawillePointF],
  closed : Bool,
  dash_array : Array[Double],
  dash_offset : Double,
) -> Array[StrokePolyline] {
  if points.length() < 2 {
    return []
  }
  if dash_array.length() == 0 {
    return [{ points, closed }]
  }

  let pattern_length = dash_pattern_length(dash_array)
  if pattern_length <= 0.000001 {
    return [{ points, closed }]
  }

  let segment_count = if closed { points.length() } else { points.length() - 1 }
  if segment_count <= 0 {
    return []
  }

  let mut pattern_index = 0
  let mut draw_on = true
  let mut offset = dash_offset % pattern_length
  if offset < 0.0 {
    offset = offset + pattern_length
  }
  while offset > dash_array[pattern_index] ||
    ((offset - dash_array[pattern_index]).abs() <= 0.000001 && offset > 0.0) {
    offset = offset - dash_array[pattern_index]
    pattern_index = (pattern_index + 1) % dash_array.length()
    draw_on = !draw_on
  }

  let mut remaining = dash_array[pattern_index] - offset
  if remaining <= 0.000001 {
    remaining = dash_array[pattern_index]
  }

  let polylines : Array[StrokePolyline] = []
  let mut current_points : Array[DrawillePointF] = []

  for segment_index = 0; segment_index < segment_count; segment_index = segment_index + 1 {
    let start = points[segment_index]
    let end_ = if segment_index + 1 == points.length() {
      points[0]
    } else {
      points[segment_index + 1]
    }
    let delta = pointf_sub(end_, start)
    let segment_length = pointf_length(delta)
    if segment_length <= 0.000001 {
      continue
    }

    let mut cursor = 0.0
    while cursor < segment_length - 0.000001 {
      if remaining <= 0.000001 {
        pattern_index = (pattern_index + 1) % dash_array.length()
        draw_on = !draw_on
        remaining = dash_array[pattern_index]
        continue
      }

      let available = segment_length - cursor
      let chunk = if remaining < available { remaining } else { available }
      let next_cursor = cursor + chunk

      if draw_on && chunk > 0.000001 {
        push_polyline_point(current_points, pointf_lerp(start, end_, cursor / segment_length))
        push_polyline_point(current_points, pointf_lerp(start, end_, next_cursor / segment_length))
      } else if current_points.length() > 1 {
        current_points = append_stroke_polyline(polylines, current_points, false)
      } else if current_points.length() > 0 {
        current_points = []
      }

      cursor = next_cursor
      remaining = remaining - chunk
      if remaining <= 0.000001 {
        pattern_index = (pattern_index + 1) % dash_array.length()
        draw_on = !draw_on
        remaining = dash_array[pattern_index]
        if !draw_on && current_points.length() > 1 {
          current_points = append_stroke_polyline(polylines, current_points, false)
        } else if !draw_on && current_points.length() > 0 {
          current_points = []
        }
      }
    }
  }

  if current_points.length() > 1 {
    let closed_fragment = closed && pointf_eq(current_points[0], current_points[current_points.length() - 1])
    current_points = append_stroke_polyline(polylines, current_points, closed_fragment)
  }
  polylines
}

///|
struct DrawilleRendererState {
  current_matrix : @math.Matrix
  current_fill_rule : String
  current_opacity : Double
  current_line_cap : Int
  current_line_join : Int
  current_miter_limit : Double
  current_dash_array : Array[Double]
  current_dash_offset : Double
}

///|
pub struct DrawilleRenderer {
  width : Double
  height : Double
  target_width : Int
  target_height : Int
  canvas : @drawille.Canvas
  state_stack : Array[DrawilleRendererState]
  mut current_matrix : @math.Matrix
  mut current_fill_rule : String
  mut current_opacity : Double
  mut current_line_cap : Int
  mut current_line_join : Int
  mut current_miter_limit : Double
  mut current_dash_array : Array[Double]
  mut current_dash_offset : Double
  mut current_path : Array[Array[DrawillePoint]]
  mut current_x : Double
  mut current_y : Double
  enable_ansi : Bool
}

///|
fn resolve_target_width(
  width : Double,
  height : Double,
  target_width : Int,
  target_height : Int,
) -> Int {
  let safe_width = width.max(1.0)
  let safe_height = height.max(1.0)
  if target_width > 0 {
    target_width
  } else if target_height > 0 {
    ((target_height.to_double() * safe_width) / safe_height).round().to_int().max(1)
  } else {
    safe_width.round().to_int().max(1)
  }
}

///|
fn resolve_target_height(
  width : Double,
  height : Double,
  target_width : Int,
  target_height : Int,
) -> Int {
  let safe_width = width.max(1.0)
  let safe_height = height.max(1.0)
  if target_height > 0 {
    target_height
  } else if target_width > 0 {
    ((target_width.to_double() * safe_height) / safe_width).round().to_int().max(1)
  } else {
    safe_height.round().to_int().max(1)
  }
}

///|
pub fn DrawilleRenderer::new(
  width : Double,
  height : Double,
  target_width? : Int = 0,
  target_height? : Int = 0,
  enable_ansi? : Bool = true,
) -> DrawilleRenderer {
  let resolved_target_width = resolve_target_width(width, height, target_width, target_height)
  let resolved_target_height = resolve_target_height(width, height, target_width, target_height)
  {
    width,
    height,
    target_width: resolved_target_width,
    target_height: resolved_target_height,
    canvas: @drawille.Canvas::new(),
    state_stack: [],
    current_matrix: @math.Matrix::identity(),
    current_fill_rule: "nonzero",
    current_opacity: 1.0,
    current_line_cap: 1,
    current_line_join: 1,
    current_miter_limit: 4.0,
    current_dash_array: [],
    current_dash_offset: 0.0,
    current_path: [],
    current_x: 0.0,
    current_y: 0.0,
    enable_ansi,
  }
}

///|
pub fn DrawilleRenderer::get_output(self : DrawilleRenderer) -> String {
  self.pin_viewport()
  let options = if self.enable_ansi {
    @drawille.default_render_options()
  } else {
    @drawille.without_ansi(@drawille.default_render_options())
  }
  self.canvas.render(options=options)
}

///|
fn DrawilleRenderer::content_scale(self : DrawilleRenderer) -> Double {
  let scale_x = self.target_width.to_double() / self.width.max(1.0)
  let scale_y = self.target_height.to_double() / self.height.max(1.0)
  if scale_x < scale_y { scale_x } else { scale_y }
}

///|
fn DrawilleRenderer::offset_x(self : DrawilleRenderer) -> Double {
  let scale = self.content_scale()
  ((self.target_width.to_double() - self.width.max(1.0) * scale) / 2.0).max(0.0)
}

///|
fn DrawilleRenderer::offset_y(self : DrawilleRenderer) -> Double {
  let scale = self.content_scale()
  ((self.target_height.to_double() - self.height.max(1.0) * scale) / 2.0).max(0.0)
}

///|
fn clamp_opacity(opacity : Double) -> Double {
  if opacity < 0.0 {
    0.0
  } else if opacity > 1.0 {
    1.0
  } else {
    opacity
  }
}

///|
fn to_channel(value : Int, opacity : Double) -> Int {
  let channel = (value.to_double() * opacity).round().to_int()
  @drawille.clamp_rgb(channel)
}

///|
fn DrawilleRenderer::effective_alpha(
  self : DrawilleRenderer,
  opacity : Double,
) -> Double {
  clamp_opacity(opacity * self.current_opacity)
}

///|
fn DrawilleRenderer::effective_style(
  self : DrawilleRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
) -> @drawille.Style {
  let alpha = self.effective_alpha(opacity)
  let color = @drawille.rgb(
    to_channel(r, alpha),
    to_channel(g, alpha),
    to_channel(b, alpha),
  )
  @drawille.with_fg(@drawille.default_style(), color)
}

///|
fn DrawilleRenderer::project_float(
  self : DrawilleRenderer,
  x : Double,
  y : Double,
) -> DrawillePointF {
  let (tx, ty) = self.current_matrix.transform_point(x, y)
  {
    x: tx * self.content_scale() + self.offset_x(),
    y: ty * self.content_scale() + self.offset_y(),
  }
}

///|
fn project_to_int(point : DrawillePointF) -> DrawillePoint {
  {
    x: point.x.round().to_int(),
    y: point.y.round().to_int(),
  }
}

///|
fn DrawilleRenderer::project(self : DrawilleRenderer, x : Double, y : Double) -> DrawillePoint {
  project_to_int(self.project_float(x, y))
}

///|
fn DrawilleRenderer::in_viewport(self : DrawilleRenderer, point : DrawillePoint) -> Bool {
  point.x >= 0 &&
  point.y >= 0 &&
  point.x < self.target_width &&
  point.y < self.target_height
}

///|
fn DrawilleRenderer::pin_viewport(self : DrawilleRenderer) -> Unit {
  let style = @drawille.default_style()
  self.canvas.set_style(0, 0, style)
  self.canvas.set_style(self.target_width - 1, self.target_height - 1, style)
}

///|
fn DrawilleRenderer::plot(
  self : DrawilleRenderer,
  point : DrawillePoint,
  style : @drawille.Style,
) -> Unit {
  if !self.in_viewport(point) {
    return
  }
  self.canvas.set(point.x, point.y)
  self.canvas.set_style(point.x, point.y, style)
}

///|
fn DrawilleRenderer::ensure_subpath(self : DrawilleRenderer, point : DrawillePoint) -> Unit {
  if self.current_path.length() == 0 {
    self.current_path.push([point])
  }
}

///|
fn DrawilleRenderer::push_point(self : DrawilleRenderer, point : DrawillePoint) -> Unit {
  self.ensure_subpath(point)
  let subpath = self.current_path[self.current_path.length() - 1]
  if subpath.length() == 0 || subpath[subpath.length() - 1] != point {
    subpath.push(point)
  }
}

///|
fn DrawilleRenderer::close_current_subpath(self : DrawilleRenderer) -> Unit {
  if self.current_path.length() == 0 {
    return
  }
  let subpath = self.current_path[self.current_path.length() - 1]
  if subpath.length() == 0 {
    return
  }
  let first = subpath[0]
  let last = subpath[subpath.length() - 1]
  if first != last {
    subpath.push(first)
  }
}

///|
fn subpath_vertex_count(points : Array[DrawillePoint]) -> Int {
  if points.length() == 0 {
    0
  } else if points.length() > 1 && points[0] == points[points.length() - 1] {
    points.length() - 1
  } else {
    points.length()
  }
}

///|
fn max_abs(a : Int, b : Int) -> Int {
  let abs_a = a.abs()
  let abs_b = b.abs()
  if abs_a > abs_b { abs_a } else { abs_b }
}

///|
fn DrawilleRenderer::stroke_half_width(self : DrawilleRenderer, width : Double) -> Double {
  ((width * self.content_scale()) / 2.0).max(0.5)
}

///|
fn DrawilleRenderer::stroke_scale(self : DrawilleRenderer) -> Double {
  matrix_stroke_scale(self.current_matrix) * self.content_scale()
}

///|
fn DrawilleRenderer::scaled_dash_array(self : DrawilleRenderer) -> Array[Double] {
  let scaled : Array[Double] = []
  let scale = self.stroke_scale()
  for dash in self.current_dash_array {
    scaled.push(dash * scale)
  }
  normalize_dash_array(scaled)
}

///|
fn DrawilleRenderer::scaled_dash_offset(self : DrawilleRenderer) -> Double {
  self.current_dash_offset * self.stroke_scale()
}

///|
fn DrawilleRenderer::stamp_brush(
  self : DrawilleRenderer,
  center : DrawillePoint,
  style : @drawille.Style,
  radius : Int,
) -> Unit {
  if radius <= 0 {
    self.plot(center, style)
    return
  }

  let limit = radius * radius
  for dx = -radius; dx <= radius; dx = dx + 1 {
    for dy = -radius; dy <= radius; dy = dy + 1 {
      if dx * dx + dy * dy <= limit {
        self.plot({ x: center.x + dx, y: center.y + dy }, style)
      }
    }
  }
}

///|
fn DrawilleRenderer::draw_segment(
  self : DrawilleRenderer,
  p0 : DrawillePoint,
  p1 : DrawillePoint,
  style : @drawille.Style,
  radius : Int,
) -> Unit {
  let dx = p1.x - p0.x
  let dy = p1.y - p0.y
  let steps = max_abs(dx, dy).max(1)
  for i = 0; i <= steps; i = i + 1 {
    let t = i.to_double() / steps.to_double()
    let point : DrawillePoint = {
      x: (p0.x.to_double() + dx.to_double() * t).round().to_int(),
      y: (p0.y.to_double() + dy.to_double() * t).round().to_int(),
    }
    self.stamp_brush(point, style, radius)
  }
}

///|
fn DrawilleRenderer::stroke_bounds(
  self : DrawilleRenderer,
  min_x : Double,
  max_x : Double,
  min_y : Double,
  max_y : Double,
) -> (Int, Int, Int, Int)? {
  if self.target_width <= 0 || self.target_height <= 0 {
    return None
  }

  let start_x = clamp_int(min_x.floor().to_int(), 0, self.target_width - 1)
  let end_x = clamp_int(max_x.ceil().to_int(), 0, self.target_width - 1)
  let start_y = clamp_int(min_y.floor().to_int(), 0, self.target_height - 1)
  let end_y = clamp_int(max_y.ceil().to_int(), 0, self.target_height - 1)
  if end_x < start_x || end_y < start_y {
    None
  } else {
    Some((start_x, end_x, start_y, end_y))
  }
}

///|
fn point_in_triangle(
  point : DrawillePointF,
  a : DrawillePointF,
  b : DrawillePointF,
  c : DrawillePointF,
) -> Bool {
  let ab = pointf_cross(pointf_sub(point, a), pointf_sub(b, a))
  let bc = pointf_cross(pointf_sub(point, b), pointf_sub(c, b))
  let ca = pointf_cross(pointf_sub(point, c), pointf_sub(a, c))
  let has_negative = ab < -0.000001 || bc < -0.000001 || ca < -0.000001
  let has_positive = ab > 0.000001 || bc > 0.000001 || ca > 0.000001
  !(has_negative && has_positive)
}

///|
fn line_intersection(
  point_a : DrawillePointF,
  direction_a : DrawillePointF,
  point_b : DrawillePointF,
  direction_b : DrawillePointF,
) -> DrawillePointF? {
  let denominator = pointf_cross(direction_a, direction_b)
  if denominator.abs() <= 0.000001 {
    return None
  }

  let delta = pointf_sub(point_b, point_a)
  let t = pointf_cross(delta, direction_b) / denominator
  Some(pointf_add(point_a, pointf_scale(direction_a, t)))
}

///|
fn DrawilleRenderer::plot_disc(
  self : DrawilleRenderer,
  center : DrawillePointF,
  style : @drawille.Style,
  radius : Double,
) -> Unit {
  match self.stroke_bounds(
    center.x - radius,
    center.x + radius,
    center.y - radius,
    center.y + radius,
  ) {
    Some((start_x, end_x, start_y, end_y)) => {
      let limit = radius * radius + 0.000001
      for x = start_x; x <= end_x; x = x + 1 {
        for y = start_y; y <= end_y; y = y + 1 {
          let point = sample_point(x, y)
          let dx = point.x - center.x
          let dy = point.y - center.y
          if dx * dx + dy * dy <= limit {
            self.plot({ x, y }, style)
          }
        }
      }
    }
    None => ()
  }
}

///|
fn DrawilleRenderer::fill_triangle(
  self : DrawilleRenderer,
  a : DrawillePointF,
  b : DrawillePointF,
  c : DrawillePointF,
  style : @drawille.Style,
) -> Unit {
  let area = pointf_cross(pointf_sub(b, a), pointf_sub(c, a)).abs()
  if area <= 0.000001 {
    return
  }

  let min_x = if a.x < b.x { if a.x < c.x { a.x } else { c.x } } else { if b.x < c.x { b.x } else { c.x } }
  let max_x = if a.x > b.x { if a.x > c.x { a.x } else { c.x } } else { if b.x > c.x { b.x } else { c.x } }
  let min_y = if a.y < b.y { if a.y < c.y { a.y } else { c.y } } else { if b.y < c.y { b.y } else { c.y } }
  let max_y = if a.y > b.y { if a.y > c.y { a.y } else { c.y } } else { if b.y > c.y { b.y } else { c.y } }

  match self.stroke_bounds(min_x, max_x, min_y, max_y) {
    Some((start_x, end_x, start_y, end_y)) => {
      for x = start_x; x <= end_x; x = x + 1 {
        for y = start_y; y <= end_y; y = y + 1 {
          if point_in_triangle(sample_point(x, y), a, b, c) {
            self.plot({ x, y }, style)
          }
        }
      }
    }
    None => ()
  }
}

///|
fn DrawilleRenderer::draw_square_cap(
  self : DrawilleRenderer,
  endpoint : DrawillePointF,
  outward : DrawillePointF,
  style : @drawille.Style,
  half_width : Double,
) -> Unit {
  let normal = left_normal(outward)
  let end_point = pointf_add(endpoint, pointf_scale(outward, half_width))
  let min_x = if endpoint.x < end_point.x { endpoint.x } else { end_point.x }
  let max_x = if endpoint.x > end_point.x { endpoint.x } else { end_point.x }
  let min_y = if endpoint.y < end_point.y { endpoint.y } else { end_point.y }
  let max_y = if endpoint.y > end_point.y { endpoint.y } else { end_point.y }

  match self.stroke_bounds(
    min_x - half_width,
    max_x + half_width,
    min_y - half_width,
    max_y + half_width,
  ) {
    Some((start_x, end_x, start_y, end_y)) => {
      for x = start_x; x <= end_x; x = x + 1 {
        for y = start_y; y <= end_y; y = y + 1 {
          let point = sample_point(x, y)
          let relative = pointf_sub(point, endpoint)
          let along = pointf_dot(relative, outward)
          let side = pointf_dot(relative, normal).abs()
          if along >= -0.000001 && along <= half_width + 0.000001 && side <= half_width + 0.000001 {
            self.plot({ x, y }, style)
          }
        }
      }
    }
    None => ()
  }
}

///|
fn DrawilleRenderer::draw_stroke_body(
  self : DrawilleRenderer,
  start : DrawillePointF,
  end_ : DrawillePointF,
  style : @drawille.Style,
  half_width : Double,
) -> Unit {
  let delta = pointf_sub(end_, start)
  let segment_length = pointf_length(delta)
  if segment_length <= 0.000001 {
    self.plot_disc(start, style, half_width)
    return
  }

  let direction = pointf_scale(delta, 1.0 / segment_length)
  let min_x = if start.x < end_.x { start.x } else { end_.x }
  let max_x = if start.x > end_.x { start.x } else { end_.x }
  let min_y = if start.y < end_.y { start.y } else { end_.y }
  let max_y = if start.y > end_.y { start.y } else { end_.y }

  match self.stroke_bounds(
    min_x - half_width,
    max_x + half_width,
    min_y - half_width,
    max_y + half_width,
  ) {
    Some((start_x, end_x, start_y, end_y)) => {
      for x = start_x; x <= end_x; x = x + 1 {
        for y = start_y; y <= end_y; y = y + 1 {
          let point = sample_point(x, y)
          let relative = pointf_sub(point, start)
          let along = pointf_dot(relative, direction)
          if along < -0.000001 || along > segment_length + 0.000001 {
            continue
          }
          let distance = pointf_cross(relative, direction).abs()
          if distance <= half_width + 0.000001 {
            self.plot({ x, y }, style)
          }
        }
      }
    }
    None => ()
  }
}

///|
fn DrawilleRenderer::draw_line_cap(
  self : DrawilleRenderer,
  endpoint : DrawillePointF,
  neighbor : DrawillePointF,
  style : @drawille.Style,
  half_width : Double,
) -> Unit {
  let outward = pointf_normalize(pointf_sub(endpoint, neighbor))
  if pointf_length(outward) <= 0.000001 {
    return
  }

  match self.current_line_cap {
    2 => self.plot_disc(endpoint, style, half_width)
    3 => self.draw_square_cap(endpoint, outward, style, half_width)
    _ => ()
  }
}

///|
fn DrawilleRenderer::draw_line_join(
  self : DrawilleRenderer,
  previous : DrawillePointF,
  vertex : DrawillePointF,
  next : DrawillePointF,
  style : @drawille.Style,
  half_width : Double,
) -> Unit {
  let incoming = pointf_normalize(pointf_sub(vertex, previous))
  let outgoing = pointf_normalize(pointf_sub(next, vertex))
  if pointf_length(incoming) <= 0.000001 || pointf_length(outgoing) <= 0.000001 {
    return
  }

  let alignment = pointf_dot(incoming, outgoing)
  if alignment > 0.999 {
    return
  }

  let turn = pointf_cross(incoming, outgoing)
  if turn.abs() <= 0.000001 {
    return
  }

  let outer_incoming = if turn > 0.0 { right_normal(incoming) } else { left_normal(incoming) }
  let outer_outgoing = if turn > 0.0 { right_normal(outgoing) } else { left_normal(outgoing) }
  let incoming_corner = pointf_add(vertex, pointf_scale(outer_incoming, half_width))
  let outgoing_corner = pointf_add(vertex, pointf_scale(outer_outgoing, half_width))

  match self.current_line_join {
    2 => self.plot_disc(vertex, style, half_width)
    3 => self.fill_triangle(vertex, incoming_corner, outgoing_corner, style)
    _ => {
      self.fill_triangle(vertex, incoming_corner, outgoing_corner, style)
      match line_intersection(incoming_corner, incoming, outgoing_corner, outgoing) {
        Some(miter_corner) => {
          let miter_length = pointf_length(pointf_sub(miter_corner, vertex))
          let miter_limit = self.current_miter_limit.max(1.0)
          if miter_length <= miter_limit * half_width + 0.000001 {
            self.fill_triangle(incoming_corner, miter_corner, outgoing_corner, style)
          }
        }
        None => ()
      }
    }
  }
}

///|
fn DrawilleRenderer::draw_stroke_polyline(
  self : DrawilleRenderer,
  polyline : StrokePolyline,
  style : @drawille.Style,
  half_width : Double,
) -> Unit {
  let points = polyline.points
  if points.length() < 2 {
    return
  }

  let segment_count = if polyline.closed { points.length() } else { points.length() - 1 }
  for i = 0; i < segment_count; i = i + 1 {
    let start = points[i]
    let end_ = if i + 1 == points.length() { points[0] } else { points[i + 1] }
    self.draw_stroke_body(start, end_, style, half_width)
  }

  if polyline.closed {
    for i = 0; i < points.length(); i = i + 1 {
      let previous = if i == 0 { points[points.length() - 1] } else { points[i - 1] }
      let next = if i + 1 == points.length() { points[0] } else { points[i + 1] }
      self.draw_line_join(previous, points[i], next, style, half_width)
    }
    return
  }

  for i = 1; i + 1 < points.length(); i = i + 1 {
    self.draw_line_join(points[i - 1], points[i], points[i + 1], style, half_width)
  }
  self.draw_line_cap(points[0], points[1], style, half_width)
  self.draw_line_cap(points[points.length() - 1], points[points.length() - 2], style, half_width)
}

///|
fn DrawilleRenderer::stroke_polylines(self : DrawilleRenderer, subpath : Array[DrawillePoint]) -> Array[StrokePolyline] {
  let vertices = subpath_vertices(subpath)
  if vertices.length() < 2 {
    return []
  }

  let closed = subpath_is_closed(subpath)
  let dash_array = self.scaled_dash_array()
  if dash_array.length() == 0 {
    [{ points: vertices, closed }]
  } else {
    dashed_stroke_polylines(vertices, closed, dash_array, self.scaled_dash_offset())
  }
}

///|
fn crossing_x_at_y(
  sample_y : Double,
  p0 : DrawillePoint,
  p1 : DrawillePoint,
) -> Double? {
  let y0 = p0.y.to_double()
  let y1 = p1.y.to_double()
  if y0 == y1 {
    return None
  }

  if (y0 <= sample_y && y1 > sample_y) || (y0 > sample_y && y1 <= sample_y) {
    let x0 = p0.x.to_double()
    let x1 = p1.x.to_double()
    Some(x0 + (sample_y - y0) * (x1 - x0) / (y1 - y0))
  } else {
    None
  }
}

///|
fn DrawilleRenderer::contains_point(
  self : DrawilleRenderer,
  sample_x : Double,
  sample_y : Double,
) -> Bool {
  let mut crossings = 0
  let mut winding = 0

  for subpath in self.current_path {
    let vertex_count = subpath_vertex_count(subpath)
    if vertex_count < 3 {
      continue
    }

    for i = 0; i < vertex_count; i = i + 1 {
      let next = if i + 1 == vertex_count { 0 } else { i + 1 }
      let p0 = subpath[i]
      let p1 = subpath[next]
      match crossing_x_at_y(sample_y, p0, p1) {
        Some(crossing_x) if crossing_x > sample_x => {
          crossings = crossings + 1
          let y0 = p0.y.to_double()
          let y1 = p1.y.to_double()
          if y0 <= sample_y && y1 > sample_y {
            winding = winding + 1
          } else if y0 > sample_y && y1 <= sample_y {
            winding = winding - 1
          }
        }
        _ => ()
      }
    }
  }

  if self.current_fill_rule == "evenodd" {
    crossings % 2 == 1
  } else {
    winding != 0
  }
}

///|
fn DrawilleRenderer::should_fill_pixel(
  self : DrawilleRenderer,
  x : Int,
  y : Int,
) -> Bool {
  let center_x = x.to_double() + 0.5
  let center_y = y.to_double() + 0.5
  if self.contains_point(center_x, center_y) {
    return true
  }

  let mut coverage = 0
  if self.contains_point(x.to_double() + 0.25, y.to_double() + 0.25) {
    coverage = coverage + 1
  }
  if self.contains_point(x.to_double() + 0.75, y.to_double() + 0.25) {
    coverage = coverage + 1
  }
  if self.contains_point(x.to_double() + 0.25, y.to_double() + 0.75) {
    coverage = coverage + 1
  }
  if self.contains_point(x.to_double() + 0.75, y.to_double() + 0.75) {
    coverage = coverage + 1
  }
  coverage >= 2
}

///|
fn DrawilleRenderer::draw_fill_edges(
  self : DrawilleRenderer,
  style : @drawille.Style,
) -> Unit {
  for subpath in self.current_path {
    let vertex_count = subpath_vertex_count(subpath)
    if vertex_count < 2 {
      continue
    }
    for i = 0; i < vertex_count; i = i + 1 {
      let next = if i + 1 == vertex_count { 0 } else { i + 1 }
      self.draw_segment(subpath[i], subpath[next], style, 0)
    }
  }
}

///|
fn DrawilleRenderer::fill_current_path(
  self : DrawilleRenderer,
  style : @drawille.Style,
) -> Unit {
  let mut has_polygon = false
  let mut min_x = 0
  let mut max_x = 0
  let mut min_y = 0
  let mut max_y = 0

  for subpath in self.current_path {
    let vertex_count = subpath_vertex_count(subpath)
    if vertex_count < 3 {
      continue
    }
    for i = 0; i < vertex_count; i = i + 1 {
      let point = subpath[i]
      if !has_polygon {
        min_x = point.x
        max_x = point.x
        min_y = point.y
        max_y = point.y
        has_polygon = true
      } else {
        if point.x < min_x {
          min_x = point.x
        }
        if point.x > max_x {
          max_x = point.x
        }
        if point.y < min_y {
          min_y = point.y
        }
        if point.y > max_y {
          max_y = point.y
        }
      }
    }
  }

  if !has_polygon {
    return
  }

  let start_x = if min_x < 0 { 0 } else { min_x }
  let end_x = if max_x >= self.target_width { self.target_width - 1 } else { max_x }
  let start_y = if min_y < 0 { 0 } else { min_y }
  let end_y = if max_y >= self.target_height { self.target_height - 1 } else { max_y }

  for y = start_y; y <= end_y; y = y + 1 {
    for x = start_x; x <= end_x; x = x + 1 {
      if self.should_fill_pixel(x, y) {
        self.plot({ x, y }, style)
      }
    }
  }

  self.draw_fill_edges(style)
}

///|
fn gradient_rgb(stops : Array[Double]) -> (Int, Int, Int) {
  if stops.length() >= 4 {
    (
      (stops[1] * 255.0).round().to_int(),
      (stops[2] * 255.0).round().to_int(),
      (stops[3] * 255.0).round().to_int(),
    )
  } else {
    (255, 255, 255)
  }
}

///|
pub impl Renderer for DrawilleRenderer with save(self : DrawilleRenderer) -> Unit {
  self.state_stack.push({
    current_matrix: self.current_matrix,
    current_fill_rule: self.current_fill_rule,
    current_opacity: self.current_opacity,
    current_line_cap: self.current_line_cap,
    current_line_join: self.current_line_join,
    current_miter_limit: self.current_miter_limit,
    current_dash_array: self.current_dash_array,
    current_dash_offset: self.current_dash_offset,
  })
}

///|
pub impl Renderer for DrawilleRenderer with restore(self : DrawilleRenderer) -> Unit {
  match self.state_stack.pop() {
    Some(state) => {
      self.current_matrix = state.current_matrix
      self.current_fill_rule = state.current_fill_rule
      self.current_opacity = state.current_opacity
      self.current_line_cap = state.current_line_cap
      self.current_line_join = state.current_line_join
      self.current_miter_limit = state.current_miter_limit
      self.current_dash_array = state.current_dash_array
      self.current_dash_offset = state.current_dash_offset
    }
    None => ()
  }
}

///|
pub impl Renderer for DrawilleRenderer with set_transform(
  self : DrawilleRenderer,
  matrix : @math.Matrix,
) -> Unit {
  self.current_matrix = matrix
}

///|
pub impl Renderer for DrawilleRenderer with concat_transform(
  self : DrawilleRenderer,
  matrix : @math.Matrix,
) -> Unit {
  self.current_matrix = self.current_matrix.multiply(matrix)
}

///|
pub impl Renderer for DrawilleRenderer with begin_path(self : DrawilleRenderer) -> Unit {
  self.current_path = []
}

///|
pub impl Renderer for DrawilleRenderer with begin_path_segment(
  self : DrawilleRenderer,
) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with close_path(self : DrawilleRenderer) -> Unit {
  self.close_current_subpath()
}

///|
pub impl Renderer for DrawilleRenderer with move_to(
  self : DrawilleRenderer,
  x : Double,
  y : Double,
) -> Unit {
  self.current_x = x
  self.current_y = y
  self.current_path.push([self.project(x, y)])
}

///|
pub impl Renderer for DrawilleRenderer with line_to(
  self : DrawilleRenderer,
  x : Double,
  y : Double,
) -> Unit {
  self.current_x = x
  self.current_y = y
  self.push_point(self.project(x, y))
}

///|
pub impl Renderer for DrawilleRenderer with cubic_to(
  self : DrawilleRenderer,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) -> Unit {
  let p0f = self.project_float(self.current_x, self.current_y)
  let p1f = self.project_float(cp1x, cp1y)
  let p2f = self.project_float(cp2x, cp2y)
  let p3f = self.project_float(x, y)
  let p0 = @math.Vector2::new(p0f.x, p0f.y)
  let p1 = @math.Vector2::new(p1f.x, p1f.y)
  let p2 = @math.Vector2::new(p2f.x, p2f.y)
  let p3 = @math.Vector2::new(p3f.x, p3f.y)
  let length = @math.get_cubic_bezier_length(p0, p1, p2, p3, 16)
  let steps = length.ceil().to_int().max(8)
  for i = 1; i <= steps; i = i + 1 {
    let t = i.to_double() / steps.to_double()
    let point = @math.point_on_cubic_bezier(p0, p1, p2, p3, t)
    self.push_point(project_to_int({ x: point.x, y: point.y }))
  }
  self.current_x = x
  self.current_y = y
}

///|
pub impl Renderer for DrawilleRenderer with fill(
  self : DrawilleRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
) -> Unit {
  if self.effective_alpha(opacity) <= 0.0 {
    return
  }
  let style = self.effective_style(r, g, b, opacity)
  self.fill_current_path(style)
}

///|
pub impl Renderer for DrawilleRenderer with stroke(
  self : DrawilleRenderer,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  width : Double,
) -> Unit {
  if self.effective_alpha(opacity) <= 0.0 || width <= 0.0 {
    return
  }
  let style = self.effective_style(r, g, b, opacity)
  let half_width = self.stroke_half_width(width)
  for subpath in self.current_path {
    for polyline in self.stroke_polylines(subpath) {
      self.draw_stroke_polyline(polyline, style, half_width)
    }
  }
}

///|
pub impl Renderer for DrawilleRenderer with set_stroke_style(
  self : DrawilleRenderer,
  line_cap : Int,
  line_join : Int,
  miter_limit : Double,
) -> Unit {
  self.current_line_cap = line_cap
  self.current_line_join = line_join
  self.current_miter_limit = miter_limit
}

///|
pub impl Renderer for DrawilleRenderer with set_line_dash(
  self : DrawilleRenderer,
  dash_array : Array[Double],
  dash_offset : Double,
) -> Unit {
  self.current_dash_array = dash_array
  self.current_dash_offset = dash_offset
}

///|
pub impl Renderer for DrawilleRenderer with fill_linear_gradient(
  self : DrawilleRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
) -> Unit {
  let _ = (x1, y1, x2, y2, p)
  let (r, g, b) = gradient_rgb(stops)
  self.fill(r, g, b, opacity)
}

///|
pub impl Renderer for DrawilleRenderer with stroke_linear_gradient(
  self : DrawilleRenderer,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  p : Int,
  stops : Array[Double],
  opacity : Double,
  width : Double,
) -> Unit {
  let _ = (x1, y1, x2, y2, p)
  let (r, g, b) = gradient_rgb(stops)
  self.stroke(r, g, b, opacity, width)
}

///|
pub impl Renderer for DrawilleRenderer with fill_radial_gradient(
  self : DrawilleRenderer,
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
  let _ = (cx, cy, r, fx, fy, fr, p)
  let (red, green, blue) = gradient_rgb(stops)
  self.fill(red, green, blue, opacity)
}

///|
pub impl Renderer for DrawilleRenderer with stroke_radial_gradient(
  self : DrawilleRenderer,
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
  let _ = (cx, cy, r, fx, fy, fr, p)
  let (red, green, blue) = gradient_rgb(stops)
  self.stroke(red, green, blue, opacity, width)
}

///|
pub impl Renderer for DrawilleRenderer with clip(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with draw_image(
  self : DrawilleRenderer,
  id : String,
  width : Double,
  height : Double,
  asset_index : Int,
) -> Unit {
  let _ = (self, id, width, height, asset_index)
}

///|
pub impl Renderer for DrawilleRenderer with draw_text(
  self : DrawilleRenderer,
  text : String,
  font : String,
  size : Double,
  r : Int,
  g : Int,
  b : Int,
  opacity : Double,
  justify : Int,
) -> Unit {
  if self.effective_alpha(opacity) <= 0.0 {
    return
  }
  let _ = (font, size, justify)
  let style = self.effective_style(r, g, b, opacity)
  let point = self.project(self.current_x, self.current_y)
  if !self.in_viewport(point) {
    return
  }
  self.canvas.set_text(point.x, point.y, text, style=style)
}

///|
pub impl Renderer for DrawilleRenderer with clear_rect(
  self : DrawilleRenderer,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit {
  let _ = (x, y, w, h)
  self.canvas.clear()
}

///|
pub impl Renderer for DrawilleRenderer with set_blend_mode(
  self : DrawilleRenderer,
  mode : String,
) -> Unit {
  let _ = (self, mode)
}

///|
pub impl Renderer for DrawilleRenderer with set_fill_rule(
  self : DrawilleRenderer,
  rule : String,
) -> Unit {
  self.current_fill_rule = rule
}

///|
pub impl Renderer for DrawilleRenderer with set_opacity(
  self : DrawilleRenderer,
  opacity : Double,
) -> Unit {
  self.current_opacity = clamp_opacity(opacity)
}

///|
pub impl Renderer for DrawilleRenderer with begin_layer(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with end_layer(
  self : DrawilleRenderer,
  mode : String,
) -> Unit {
  let _ = (self, mode)
}

///|
pub impl Renderer for DrawilleRenderer with prepare_matte_layer(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with begin_matte_exit(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with end_matte_exit(
  self : DrawilleRenderer,
  matte_type : Int,
) -> Unit {
  let _ = (self, matte_type)
}

///|
pub impl Renderer for DrawilleRenderer with supports_mask_composite(
  self : DrawilleRenderer,
) -> Bool {
  let _ = self
  false
}

///|
pub impl Renderer for DrawilleRenderer with begin_mask_composite(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with begin_mask_path(self : DrawilleRenderer) -> Unit {
  let _ = self
}

///|
pub impl Renderer for DrawilleRenderer with apply_mask_path(
  self : DrawilleRenderer,
  mode : Int,
  opacity : Double,
  inverted : Bool,
  expansion : Double,
) -> Unit {
  let _ = (self, mode, opacity, inverted, expansion)
}

///|
pub impl Renderer for DrawilleRenderer with end_mask_composite(self : DrawilleRenderer) -> Unit {
  let _ = self
}