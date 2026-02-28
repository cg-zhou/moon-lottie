///|
pub struct Player[R] {
  animation : @model.Animation
  renderer : R
  mut current_frame : Double
  mut current_paths : Array[@model.BezierPath]
  mut debug_enabled : Bool
  mut debug_logs : Array[String]
  mut debug_layer : String
  mut debug_shape : String
  mut debug_property : String
}

///|
pub fn[R] Player::new(animation : @model.Animation, renderer : R) -> Player[R] {
  {
    animation,
    renderer,
    current_frame: 0.0,
    current_paths: [],
    debug_enabled: false,
    debug_logs: [],
    debug_layer: "",
    debug_shape: "",
    debug_property: "",
  }
}

///|
pub fn[R] Player::set_frame(self : Player[R], frame : Double) -> Unit {
  self.current_frame = frame
}

///|
pub fn[R] Player::set_debug(self : Player[R], enabled : Bool) -> Unit {
  self.debug_enabled = enabled
}

///|
pub fn[R] Player::get_debug_logs(self : Player[R]) -> Array[String] {
  self.debug_logs
}

///|
fn[R] Player::debug_log(self : Player[R], stage : String) -> Unit {
  if self.debug_enabled {
    self.debug_logs.push(
      "frame=\{self.current_frame},layer=\{self.debug_layer},shape=\{self.debug_shape},property=\{self.debug_property},stage=\{stage}",
    )
  }
}

///|
pub fn[R : Renderer] Player::render(self : Player[R]) -> Unit {
  if self.debug_enabled || self.debug_logs.length() > 0 {
    self.debug_logs = []
    self.debug_layer = ""
    self.debug_shape = ""
    self.debug_property = ""
  }
  self.renderer.set_transform(@math.Matrix::identity())
  self.renderer.clear_rect(
    0.0,
    0.0,
    self.animation.w.to_double(),
    self.animation.h.to_double(),
  )

  // Lottie renders layers from bottom to top (reverse order in the array)
  let layers = self.animation.layers
  for i = layers.length() - 1; i >= 0; i = i - 1 {
    let layer = layers[i]
    // Skip if hidden
    if layer.hd == Some(true) {
      continue
    }
    // Skip if this is a matte source (it will be rendered by the matted layer)
    if layer.td == Some(1) {
      continue
    }
    self.render_layer(layer, layers)
  }
}

///|
fn[R : Renderer] Player::apply_parent_transform(
  self : Player[R],
  parent_ind : Int,
  scope : Array[@model.Layer],
  comp_frame : Double,
) -> Unit {
  for layer in scope {
    if layer.ind == parent_ind {
      match layer.parent {
        Some(p_ind) => self.apply_parent_transform(p_ind, scope, comp_frame)
        None => ()
      }
      let local_frame = comp_frame - layer.st
      let matrix = @runtime.evaluate_transform(layer.ks, local_frame)
      self.renderer.concat_transform(matrix)
      return
    }
  }
}

///|
fn[R : Renderer] Player::render_layer(
  self : Player[R],
  layer : @model.Layer,
  scope : Array[@model.Layer],
) -> Unit {
  let comp_frame = self.current_frame
  if comp_frame < layer.ip || comp_frame >= layer.op {
    return
  }

  let local_frame = comp_frame - layer.st
  let saved_frame = self.current_frame
  self.current_frame = local_frame
  self.debug_layer = match layer.nm {
    Some(name) => "\{name}#\{layer.ind}"
    None => "#\{layer.ind}"
  }
  self.debug_shape = ""
  self.debug_property = "layer"
  self.debug_log("render_layer")

  self.renderer.save()

  // 0. Apply Parent Transform
  match layer.parent {
    Some(p_ind) => self.apply_parent_transform(p_ind, scope, comp_frame)
    None => ()
  }

  // 1. Apply Layer Transform
  let matrix = @runtime.evaluate_transform(layer.ks, self.current_frame)
  self.renderer.concat_transform(matrix)

  // 1.2 Apply Layer Opacity
  let opacity = @runtime.evaluate_double_property(
    layer.ks.opacity,
    self.current_frame,
  )
  self.renderer.set_opacity(opacity / 100.0)

  // 1.5 Apply Layer Masks
  let mut mask_restore_count = 0
  match layer.masks {
    Some(masks) => {
      let mut i = 0
      while i < masks.length() {
        let mask = masks[i]

        // Group contiguous Add masks
        if mask.mode == @model.MaskMode::Add && not(mask.inv) {
          self.renderer.begin_path()
          self.renderer.set_fill_rule("nonzero")
          while i < masks.length() {
            let m = masks[i]
            if m.mode == @model.MaskMode::Add && not(m.inv) {
              let path_val = @runtime.evaluate_path_property(
                m.pt,
                self.current_frame,
              )
              self.draw_lottie_path(path_val)
              i = i + 1
            } else {
              break
            }
          }
          self.renderer.clip()
          continue
        }

        // Handle Subtract or Inverted Add/Subtract
        match mask.mode {
          @model.MaskMode::Subtract | @model.MaskMode::Add => {
            let is_inv = (mask.mode == @model.MaskMode::Add && mask.inv) ||
              (mask.mode == @model.MaskMode::Subtract && not(mask.inv))

            if is_inv {
              // Difference: Save current state, then clip with a hole
              self.renderer.save()
              mask_restore_count = mask_restore_count + 1
              self.renderer.begin_path()
              self.renderer.move_to(-10000.0, -10000.0)
              self.renderer.line_to(10000.0, -10000.0)
              self.renderer.line_to(10000.0, 10000.0)
              self.renderer.line_to(-10000.0, 10000.0)
              self.renderer.close_path()

              let path_val = @runtime.evaluate_path_property(
                mask.pt,
                self.current_frame,
              )
              self.draw_lottie_path(path_val)
              self.renderer.set_fill_rule("evenodd")
              self.renderer.clip()
            } else {
              // Non-inverted Add was handled in the grouped block
              // Inverted Subtract is same as Add
              self.renderer.begin_path()
              let path_val = @runtime.evaluate_path_property(
                mask.pt,
                self.current_frame,
              )
              self.draw_lottie_path(path_val)
              self.renderer.set_fill_rule("nonzero")
              self.renderer.clip()
            }
          }
          @model.MaskMode::Intersect => {
            self.renderer.begin_path()
            let path_val = @runtime.evaluate_path_property(
              mask.pt,
              self.current_frame,
            )
            self.draw_lottie_path(path_val)
            if mask.inv {
              // Inverted Intersect involves complex logic, simplified:
              self.renderer.move_to(-10000.0, -10000.0)
              self.renderer.line_to(10000.0, -10000.0)
              self.renderer.line_to(10000.0, 10000.0)
              self.renderer.line_to(-10000.0, 10000.0)
              self.renderer.close_path()
              self.renderer.set_fill_rule("evenodd")
            } else {
              self.renderer.set_fill_rule("nonzero")
            }
            self.renderer.clip()
          }
          _ => ()
        }
        i = i + 1
      }
    }
    None => ()
  }

  // 2. Render Layer Content
  self.render_layer_content(layer)

  // 3. Restore mask states
  for _ in 0..<mask_restore_count {
    self.renderer.restore()
  }

  // 4. Apply Track Matte
  match layer.tt {
    Some(1) | Some(2) | Some(3) | Some(4) => {
      let mut matte_source : @model.Layer? = None
      for i = 0; i < scope.length(); i = i + 1 {
        if scope[i].ind == layer.ind && i > 0 {
          matte_source = Some(scope[i - 1])
          break
        }
      }
      match matte_source {
        Some(m_layer) => {
          let mode = match layer.tt {
            Some(1) => "destination-in"
            Some(2) => "destination-out"
            Some(3) => "destination-in" // Luma requires more, fallback to Alpha
            Some(4) => "destination-out"
            _ => "source-over"
          }
          self.renderer.set_blend_mode(mode)
          self.render_layer(m_layer, scope)
          self.renderer.set_blend_mode("source-over")
        }
        None => ()
      }
    }
    _ => ()
  }
  self.renderer.restore()
  self.current_frame = saved_frame
}

///|
fn parse_hex_color(hex : String) -> (Int, Int, Int) {
  if hex.length() < 7 || hex[0] != '#' {
    return (0, 0, 0)
  }
  fn hex_to_int(c : Char) -> Int {
    if c >= '0' && c <= '9' {
      c.to_int() - '0'.to_int()
    } else if c >= 'a' && c <= 'f' {
      c.to_int() - 'a'.to_int() + 10
    } else if c >= 'A' && c <= 'F' {
      c.to_int() - 'A'.to_int() + 10
    } else {
      0
    }
  }

  let r = hex_to_int(hex[1].to_int().unsafe_to_char()) * 16 +
    hex_to_int(hex[2].to_int().unsafe_to_char())
  let g = hex_to_int(hex[3].to_int().unsafe_to_char()) * 16 +
    hex_to_int(hex[4].to_int().unsafe_to_char())
  let b = hex_to_int(hex[5].to_int().unsafe_to_char()) * 16 +
    hex_to_int(hex[6].to_int().unsafe_to_char())
  (r, g, b)
}

///|
fn get_vec_at(v : Array[Double], i : Int, default : Double) -> Double {
  if i >= 0 && i < v.length() {
    v[i]
  } else {
    default
  }
}

///|
fn get_pt_at(v : Array[Array[Double]], i : Int, j : Int) -> Double {
  if i >= 0 && i < v.length() {
    let pt = v[i]
    if j >= 0 && j < pt.length() {
      pt[j]
    } else {
      0.0
    }
  } else {
    0.0
  }
}

///|
fn[R : Renderer] Player::render_layer_content(
  self : Player[R],
  layer : @model.Layer,
) -> Unit {
  let svg_layer_marker = "Shape Layer - SVG"
  match layer.data {
    Shape(shapes) => {
      // Clear current paths for each layer's top level
      self.current_paths = []
      let render_in_reverse = match layer.nm {
        Some(name) => name.contains(svg_layer_marker)
        None => false
      }
      if render_in_reverse {
        for i = shapes.length() - 1; i >= 0; i = i - 1 {
          self.render_shape(shapes[i])
        }
      } else {
        for shape in shapes {
          self.render_shape(shape)
        }
      }
    }
    Solid(color, w, h) => {
      self.renderer.begin_path()
      self.renderer.move_to(0.0, 0.0)
      self.renderer.line_to(w.to_double(), 0.0)
      self.renderer.line_to(w.to_double(), h.to_double())
      self.renderer.line_to(0.0, h.to_double())
      self.renderer.close_path()
      let (r, g, b) = parse_hex_color(color)
      self.renderer.fill(r, g, b, 1.0)
    }
    PreComp(ref_id, _w, _h) =>
      match self.animation.assets {
        Some(assets) =>
          for asset in assets {
            if asset.id == ref_id {
              match asset.layers {
                Some(layers) =>
                  for i = layers.length() - 1; i >= 0; i = i - 1 {
                    let child_layer = layers[i]
                    if child_layer.hd == Some(true) {
                      continue
                    }
                    if child_layer.td == Some(1) {
                      continue
                    }
                    self.render_layer(child_layer, layers)
                  }
                None => ()
              }
              break
            }
          }
        _ => ()
      }
    Image(ref_id) =>
      match self.animation.assets {
        Some(assets) =>
          for asset in assets {
            if asset.id == ref_id {
              let w = match asset.w {
                Some(v) => v
                None => 0
              }
              let h = match asset.h {
                Some(v) => v
                None => 0
              }
              self.renderer.draw_image(asset.id, w.to_double(), h.to_double())
              break
            }
          }
        _ => ()
      }
    Text(data) => {
      let doc = @runtime.evaluate_text_document_property(
        data.text,
        self.current_frame,
      )
      if doc.t != "" {
        let (r, g, b) = if doc.fc.length() >= 3 {
          (
            (get_vec_at(doc.fc, 0, 0.0) * 255.0).to_int(),
            (get_vec_at(doc.fc, 1, 0.0) * 255.0).to_int(),
            (get_vec_at(doc.fc, 2, 0.0) * 255.0).to_int(),
          )
        } else {
          (0, 0, 0)
        }
        self.renderer.draw_text(doc.t, doc.f, doc.s, r, g, b, 1.0, doc.j)
      }
    }
    Null => ()
  }
}

///|
pub fn[R : Renderer] Player::render_shape(
  self : Player[R],
  shape : @model.Shape,
) -> Unit {
  self.debug_shape = match shape.nm {
    Some(name) => "\{name}:\{shape.ty}"
    None => shape.ty
  }
  self.debug_property = shape.ty
  self.debug_log("render_shape")
  match shape.hd {
    Some(true) => return
    _ => ()
  }
  match shape.data {
    Group(items) => {
      self.renderer.save()
      let old_paths = self.current_paths
      self.current_paths = []
      let group_has_paint_ops = shape_group_has_paint(items)

      // AE typically puts the group transform at the end of the shape list,
      // but it applies to all siblings. We find it and apply it first.
      for item in items {
        match item.data {
          Transform(tr) => {
            let matrix = @runtime.evaluate_transform(tr, self.current_frame)
            self.renderer.concat_transform(matrix)
            let opacity = @runtime.evaluate_double_property(
              tr.opacity,
              self.current_frame,
            )
            self.renderer.set_opacity(opacity / 100.0)
          }
          _ => ()
        }
      }
      for item in items {
        match item.data {
          Transform(_) => () // Skip, already applied
          _ => self.render_shape(item)
        }
      }

      // Merge inner paths with outer paths
      let inner_paths = self.current_paths
      self.current_paths = old_paths
      if not(group_has_paint_ops) {
        for p in inner_paths {
          self.current_paths.push(p)
        }
      }
      self.renderer.restore()
    }
    Rect(r) => {
      let p = @runtime.evaluate_vec_property(r.p, self.current_frame)
      let s = @runtime.evaluate_vec_property(r.s, self.current_frame)
      let corner_r = @runtime.evaluate_double_property(r.r, self.current_frame)
      let x = get_vec_at(p, 0, 0.0)
      let y = get_vec_at(p, 1, 0.0)
      let w = get_vec_at(s, 0, 0.0)
      let h = get_vec_at(s, 1, 0.0)
      self.current_paths.push(create_rect_path(x, y, w, h, corner_r))
    }
    Ellipse(e) => {
      let p = @runtime.evaluate_vec_property(e.p, self.current_frame)
      let s = @runtime.evaluate_vec_property(e.s, self.current_frame)
      let cx = get_vec_at(p, 0, 0.0)
      let cy = get_vec_at(p, 1, 0.0)
      let rx = get_vec_at(s, 0, 0.0) / 2.0
      let ry = get_vec_at(s, 1, 0.0) / 2.0
      self.current_paths.push(create_ellipse_path(cx, cy, rx, ry))
    }
    Path(p) => {
      let path = @runtime.evaluate_path_property(p.ks, self.current_frame)
      self.current_paths.push(path)
    }
    Fill(f) => {
      let color_vec = @runtime.evaluate_vec_property(f.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.o, self.current_frame)
      let r = (get_vec_at(color_vec, 0, 0.0) * 255.0).to_int()
      let g = (get_vec_at(color_vec, 1, 0.0) * 255.0).to_int()
      let b = (get_vec_at(color_vec, 2, 0.0) * 255.0).to_int()
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.fill(r, g, b, opacity / 100.0)
    }
    Stroke(s) => {
      let color_vec = @runtime.evaluate_vec_property(s.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.o, self.current_frame)
      let width = @runtime.evaluate_double_property(s.w, self.current_frame)
      let r = (get_vec_at(color_vec, 0, 0.0) * 255.0).to_int()
      let g = (get_vec_at(color_vec, 1, 0.0) * 255.0).to_int()
      let b = (get_vec_at(color_vec, 2, 0.0) * 255.0).to_int()
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.set_stroke_style(s.lc, s.lj, s.ml)
      self.renderer.stroke(r, g, b, opacity / 100.0, width)
    }
    GradientFill(f) => {
      let start_p = @runtime.evaluate_vec_property(f.s, self.current_frame)
      let end_p = @runtime.evaluate_vec_property(f.e, self.current_frame)
      let stops = @runtime.evaluate_vec_property(f.g.k, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.o, self.current_frame)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      match f.t {
        Linear =>
          self.renderer.fill_linear_gradient(
            get_vec_at(start_p, 0, 0.0),
            get_vec_at(start_p, 1, 0.0),
            get_vec_at(end_p, 0, 0.0),
            get_vec_at(end_p, 1, 0.0),
            f.g.p,
            stops,
            opacity / 100.0,
          )
        Radial => {
          let x0 = get_vec_at(start_p, 0, 0.0)
          let y0 = get_vec_at(start_p, 1, 0.0)
          let x1 = get_vec_at(end_p, 0, 0.0)
          let y1 = get_vec_at(end_p, 1, 0.0)
          let dx = x1 - x0
          let dy = y1 - y0
          let radius = @math.sqrt(dx * dx + dy * dy)
          self.renderer.fill_radial_gradient(
            x0,
            y0,
            radius,
            x0,
            y0,
            0.0,
            f.g.p,
            stops,
            opacity / 100.0,
          )
        }
      }
    }
    GradientStroke(s) => {
      let start_p = @runtime.evaluate_vec_property(s.s, self.current_frame)
      let end_p = @runtime.evaluate_vec_property(s.e, self.current_frame)
      let stops = @runtime.evaluate_vec_property(s.g.k, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.o, self.current_frame)
      let width = @runtime.evaluate_double_property(s.w, self.current_frame)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.set_stroke_style(s.lc, s.lj, s.ml)
      match s.t {
        Linear =>
          self.renderer.stroke_linear_gradient(
            get_vec_at(start_p, 0, 0.0),
            get_vec_at(start_p, 1, 0.0),
            get_vec_at(end_p, 0, 0.0),
            get_vec_at(end_p, 1, 0.0),
            s.g.p,
            stops,
            opacity / 100.0,
            width,
          )
        Radial => {
          let x0 = get_vec_at(start_p, 0, 0.0)
          let y0 = get_vec_at(start_p, 1, 0.0)
          let x1 = get_vec_at(end_p, 0, 0.0)
          let y1 = get_vec_at(end_p, 1, 0.0)
          let dx = x1 - x0
          let dy = y1 - y0
          let radius = @math.sqrt(dx * dx + dy * dy)
          self.renderer.stroke_radial_gradient(
            x0,
            y0,
            radius,
            x0,
            y0,
            0.0,
            s.g.p,
            stops,
            opacity / 100.0,
            width,
          )
        }
      }
    }
    Transform(tr) => {
      let matrix = @runtime.evaluate_transform(tr, self.current_frame)
      self.renderer.concat_transform(matrix)
    }
    TrimPath(t) => {
      let start = @runtime.evaluate_double_property(t.s, self.current_frame)
      let end = @runtime.evaluate_double_property(t.e, self.current_frame)
      let offset = @runtime.evaluate_double_property(t.o, self.current_frame)
      self.current_paths = apply_trim_path(
        self.current_paths,
        start,
        end,
        offset,
      )
    }
    Polystar(sr) => self.current_paths.push(self.create_polystar_path(sr))
    Repeater(rep) => {
      let copies = @runtime.evaluate_double_property(rep.c, self.current_frame).to_int()
      let offset = @runtime.evaluate_double_property(rep.o, self.current_frame)
      let tr_matrix = @runtime.evaluate_transform(rep.tr, self.current_frame)

      let original_paths = self.current_paths
      let new_paths = []

      // Lottie Repeater: n-th copy transform is (tr_matrix ^ (n + offset))
      // Composite: 1 = Above (new copies on top), 2 = Below

      let start_idx = if rep.m == 1 { 0 } else { copies - 1 }
      let end_idx = if rep.m == 1 { copies } else { -1 }
      let step = if rep.m == 1 { 1 } else { -1 }

      let mut i = start_idx
      while (if step == 1 { i < end_idx } else { i > end_idx }) {
        let mut m = @math.Matrix::identity()
        let total_steps = i.to_double() + offset

        // Simple power implementation for matrix
        for _j = 0; _j < total_steps.to_int(); _j = _j + 1 {
          m = m.multiply(tr_matrix)
        }

        for path in original_paths {
          new_paths.push(transform_path(path, m))
        }
        i = i + step
      }
      self.current_paths = new_paths
    }
    MergePaths(merge) =>
      // Lottie MergePaths: 1=Merge, 2=Add, 3=Subtract, 4=Intersect, 5=Exclude
      // For SVG, we use fill-rule="evenodd" to approximate boolean operations
      // since we don't have a path boolean engine in MoonBit yet.
      match merge.mm {
        @model.MergeMode::Merge | @model.MergeMode::Add =>
          self.renderer.set_fill_rule("nonzero")
        @model.MergeMode::Subtract
        | @model.MergeMode::Intersect
        | @model.MergeMode::Exclude => self.renderer.set_fill_rule("evenodd")
      }
    Rounding(rounding) => {
      let radius = @runtime.evaluate_double_property(
        rounding.r,
        self.current_frame,
      )
      if radius > 0.0 {
        let new_paths = []
        for path in self.current_paths {
          new_paths.push(apply_rounding_to_path(path, radius))
        }
        self.current_paths = new_paths
      }
    }
  }
}

///|
fn shape_group_has_paint(items : Array[@model.Shape]) -> Bool {
  for item in items {
    match item.data {
      Fill(_) | Stroke(_) | GradientFill(_) | GradientStroke(_) => return true
      Group(nested) =>
        if shape_group_has_paint(nested) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
fn apply_rounding_to_path(
  path : @model.BezierPath,
  _radius : Double,
) -> @model.BezierPath {
  // Simplified rounding: if a corner is sharp (tangents [0,0]), 
  // we could attempt to round it. For now, we return as is
  // until a robust Bezier rounding algorithm is implemented.
  // Standard Lottie Rounding (rd) is complex as it affects any path.
  path
}

///|
fn transform_path(
  path : @model.BezierPath,
  m : @math.Matrix,
) -> @model.BezierPath {
  let v = []
  for i, _ in path.v {
    let (nx, ny) = m.transform_point(get_pt_at(path.v, i, 0), get_pt_at(path.v, i, 1))
    v.push([nx, ny])
  }
  // Tangents are relative, but they still get scaled/rotated (not translated)
  let i_tangents = []
  for idx, _ in path.i {
    // To transform a vector (relative point), we ignore translation (e, f)
    let px = get_pt_at(path.i, idx, 0)
    let py = get_pt_at(path.i, idx, 1)
    let nx = px * m.a + py * m.c
    let ny = px * m.b + py * m.d
    i_tangents.push([nx, ny])
  }
  let o_tangents = []
  for idx, _ in path.o {
    let px = get_pt_at(path.o, idx, 0)
    let py = get_pt_at(path.o, idx, 1)
    let nx = px * m.a + py * m.c
    let ny = px * m.b + py * m.d
    o_tangents.push([nx, ny])
  }
  @model.BezierPath::new(v~, i=i_tangents, o=o_tangents, c=path.c)
}

///|
fn[R : Renderer] Player::draw_lottie_path(
  self : Player[R],
  path : @model.BezierPath,
) -> Unit {
  let v = path.v
  if v.length() > 0 {
    let i = path.i
    let o = path.o
    self.renderer.move_to(get_pt_at(v, 0, 0), get_pt_at(v, 0, 1))
    for n = 1; n < v.length(); n = n + 1 {
      let cp1x = get_pt_at(v, n - 1, 0) + get_pt_at(o, n - 1, 0)
      let cp1y = get_pt_at(v, n - 1, 1) + get_pt_at(o, n - 1, 1)
      let cp2x = get_pt_at(v, n, 0) + get_pt_at(i, n, 0)
      let cp2y = get_pt_at(v, n, 1) + get_pt_at(i, n, 1)
      self.renderer.cubic_to(
        cp1x,
        cp1y,
        cp2x,
        cp2y,
        get_pt_at(v, n, 0),
        get_pt_at(v, n, 1),
      )
    }
    if path.c {
      let n = v.length()
      let cp1x = get_pt_at(v, n - 1, 0) + get_pt_at(o, n - 1, 0)
      let cp1y = get_pt_at(v, n - 1, 1) + get_pt_at(o, n - 1, 1)
      let cp2x = get_pt_at(v, 0, 0) + get_pt_at(i, 0, 0)
      let cp2y = get_pt_at(v, 0, 1) + get_pt_at(i, 0, 1)
      self.renderer.cubic_to(
        cp1x,
        cp1y,
        cp2x,
        cp2y,
        get_pt_at(v, 0, 0),
        get_pt_at(v, 0, 1),
      )
      self.renderer.close_path()
    }
  }
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
pub fn create_canvas_player(
  animation : @model.Animation,
) -> Player[CanvasRenderer] {
  Player::new(animation, CanvasRenderer::new())
}

///|
fn create_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  r : Double,
) -> @model.BezierPath {
  let _ = r
  @model.BezierPath::new_rect(x, y, w, h)
}

///|
fn create_ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> @model.BezierPath {
  let kappa = 0.55228475
  let ox = rx * kappa
  let oy = ry * kappa
  @model.BezierPath::new(
    v=[[cx, cy - ry], [cx + rx, cy], [cx, cy + ry], [cx - rx, cy]],
    i=[[-ox, 0.0], [0.0, -oy], [ox, 0.0], [0.0, oy]],
    o=[[ox, 0.0], [0.0, oy], [-ox, 0.0], [0.0, -oy]],
    c=true,
  )
}

///|
pub fn apply_trim_path(
  paths : Array[@model.BezierPath],
  start : Double,
  end : Double,
  offset : Double,
) -> Array[@model.BezierPath] {
  let s_val = start / 100.0
  let e_val = end / 100.0
  let o_val = offset / 360.0 // Offset is in degrees in AE? Or 0-100? In Lottie it's degrees.

  if s_val <= 0.0 && e_val >= 1.0 {
    return paths
  }

  let result = []
  for path in paths {
    for p in trim_single_path(path, s_val, e_val, o_val) {
      result.push(p)
    }
  }
  result
}

///|
pub fn trim_single_path(
  path : @model.BezierPath,
  s : Double,
  e : Double,
  o : Double,
) -> Array[@model.BezierPath] {
  let v = path.v
  if v.length() < 2 {
    return [path]
  }

  // 1. Calculate length of each segment
  let seg_lengths = []
  let mut total_length = 0.0
  let num_pts = v.length()
  let num_segs = if path.c { num_pts } else { num_pts - 1 }

  for j = 0; j < num_segs; j = j + 1 {
    let next_j = (j + 1) % num_pts
    let p0 = @math.Vector2::new(get_pt_at(v, j, 0), get_pt_at(v, j, 1))
    let p1 = @math.Vector2::new(
      get_pt_at(v, j, 0) + get_pt_at(path.o, j, 0),
      get_pt_at(v, j, 1) + get_pt_at(path.o, j, 1),
    )
    let p2 = @math.Vector2::new(
      get_pt_at(v, next_j, 0) + get_pt_at(path.i, next_j, 0),
      get_pt_at(v, next_j, 1) + get_pt_at(path.i, next_j, 1),
    )
    let p3 = @math.Vector2::new(get_pt_at(v, next_j, 0), get_pt_at(v, next_j, 1))
    let len = @math.get_cubic_bezier_length(p0, p1, p2, p3, 10)
    seg_lengths.push(len)
    total_length += len
  }

  if total_length == 0.0 {
    return [path]
  }

  // 2. Adjust s and e with offset and normalize to [0, 1]
  // Lottie offset is in degrees, s and e are 0-1 (normalized)
  let start_norm = {
    let mut val = s + o
    val = val - val.floor()
    val
  }
  let end_norm = {
    let mut val = e + o
    val = val - val.floor()
    val
  }

  // If e - s >= 1.0, it's the full path
  if e - s >= 1.0 {
    return [path]
  }

  if start_norm < end_norm {
    return [
      extract_bezier_segment(
        path, seg_lengths, total_length, start_norm, end_norm,
      ),
    ]
  } else {
    let p1 = extract_bezier_segment(
      path, seg_lengths, total_length, start_norm, 1.0,
    )
    let p2 = extract_bezier_segment(
      path, seg_lengths, total_length, 0.0, end_norm,
    )
    return [p1, p2]
  }
}

///|
fn extract_bezier_segment(
  path : @model.BezierPath,
  seg_lengths : Array[Double],
  total_length : Double,
  s_norm : Double,
  e_norm : Double,
) -> @model.BezierPath {
  let s_len = s_norm * total_length
  let e_len = e_norm * total_length

  let new_v = []
  let new_i = []
  let new_o = []

  let mut current_acc = 0.0
  let num_pts = path.v.length()
  let num_segs = if path.c { num_pts } else { num_pts - 1 }

  for j = 0; j < num_segs; j = j + 1 {
    let seg_len = seg_lengths[j]
    let seg_start = current_acc
    let seg_end = current_acc + seg_len

    // Check if segment is within [s_len, e_len]
    if seg_end > s_len && seg_start < e_len {
      let next_j = (j + 1) % num_pts
      let p0 = @math.Vector2::new(
        get_pt_at(path.v, j, 0),
        get_pt_at(path.v, j, 1),
      )
      let p1 = @math.Vector2::new(
        get_pt_at(path.v, j, 0) + get_pt_at(path.o, j, 0),
        get_pt_at(path.v, j, 1) + get_pt_at(path.o, j, 1),
      )
      let p2 = @math.Vector2::new(
        get_pt_at(path.v, next_j, 0) + get_pt_at(path.i, next_j, 0),
        get_pt_at(path.v, next_j, 1) + get_pt_at(path.i, next_j, 1),
      )
      let p3 = @math.Vector2::new(
        get_pt_at(path.v, next_j, 0),
        get_pt_at(path.v, next_j, 1),
      )

      // Calculate local t for start and end
      let t_start = if s_len > seg_start {
        (s_len - seg_start) / seg_len
      } else {
        0.0
      }
      let t_end = if e_len < seg_end {
        (e_len - seg_start) / seg_len
      } else {
        1.0
      }

      let t_start_relative = if t_end > 0.0 { t_start / t_end } else { 0.0 }

      // sp0...sp3 were unused, removed
      let (p0_r, p1_r, p2_r, p3_r, _, _, _) = @math.split_cubic_bezier(
        p0, p1, p2, p3, t_end,
      )
      // Now trim the beginning of this new curve (p0_r to p3_r) at t_start_relative
      // To trim from t_start_relative to 1:
      let (_, _, _, final_p0, final_p1, final_p2, final_p3) = @math.split_cubic_bezier(
        p0_r, p1_r, p2_r, p3_r, t_start_relative,
      )

      // final_p0, final_p1, final_p2, final_p3 is our segment
      if new_v.length() == 0 {
        new_v.push([final_p0.x, final_p0.y])
        new_i.push([0.0, 0.0])
      }

      // Update last out tangent
      new_o.push([final_p1.x - final_p0.x, final_p1.y - final_p0.y])

      // Push new vertex
      new_v.push([final_p3.x, final_p3.y])
      new_i.push([final_p2.x - final_p3.x, final_p2.y - final_p3.y])
    }

    current_acc += seg_len
  }

  if new_v.length() == 0 {
    return @model.BezierPath::new(v=[], i=[], o=[], c=false)
  }

  // Last vertex has no out tangent (or it's the end of open path)
  new_o.push([0.0, 0.0])

  @model.BezierPath::new(v=new_v, i=new_i, o=new_o, c=false)
}

///|
fn[R] Player::create_polystar_path(
  self : Player[R],
  sr : @model.PolystarShape,
) -> @model.BezierPath {
  let pt = @runtime.evaluate_double_property(sr.pt, self.current_frame)
  let p = @runtime.evaluate_vec_property(sr.p, self.current_frame)
  let r = @runtime.evaluate_double_property(sr.r, self.current_frame)
  let or = @runtime.evaluate_double_property(sr.or, self.current_frame)
  let or_round = @runtime.evaluate_double_property(
    sr.or_round,
    self.current_frame,
  )

  let cx = get_vec_at(p, 0, 0.0)
  let cy = get_vec_at(p, 1, 0.0)
  let num_points = pt.to_int()
  let vertices = []
  let ins = []
  let outs = []

  if sr.sy == 2 { // Polygon
    let angle_step = 2.0 * @std_math.PI / pt
    let start_angle = (r - 90.0) * @std_math.PI / 180.0

    for i = 0; i < num_points; i = i + 1 {
      let angle = start_angle + angle_step * i.to_double()
      let x = cx + or * @std_math.cos(angle)
      let y = cy + or * @std_math.sin(angle)
      vertices.push([x, y])

      if or_round > 0.0 {
        // Lottie Polygon rounding: tangents are perpendicular to the radius
        let dist = or_round * 0.471960249438992 / 100.0 * or
        let tx = -dist * @std_math.sin(angle)
        let ty = dist * @std_math.cos(angle)
        ins.push([-tx, -ty])
        outs.push([tx, ty])
      } else {
        ins.push([0.0, 0.0])
        outs.push([0.0, 0.0])
      }
    }
  } else { // Star
    let ir = @runtime.evaluate_double_property(sr.ir, self.current_frame)
    let ir_round = @runtime.evaluate_double_property(
      sr.ir_round,
      self.current_frame,
    )
    let angle_step = @std_math.PI / pt
    let start_angle = (r - 90.0) * @std_math.PI / 180.0

    for i = 0; i < num_points * 2; i = i + 1 {
      let angle = start_angle + angle_step * i.to_double()
      let radius = if i % 2 == 0 { or } else { ir }
      let roundness = if i % 2 == 0 { or_round } else { ir_round }

      let x = cx + radius * @std_math.cos(angle)
      let y = cy + radius * @std_math.sin(angle)
      vertices.push([x, y])

      if roundness > 0.0 {
        let cp_dist = radius * roundness * 0.471960249438992 / 100.0
        let tx = cp_dist * @std_math.sin(angle)
        let ty = -cp_dist * @std_math.cos(angle)
        // Tangents alternate direction for star effect
        if i % 2 == 0 {
          ins.push([tx, ty])
          outs.push([-tx, -ty])
        } else {
          ins.push([-tx, -ty])
          outs.push([tx, ty])
        }
      } else {
        ins.push([0.0, 0.0])
        outs.push([0.0, 0.0])
      }
    }
  }

  @model.BezierPath::new(v=vertices, i=ins, o=outs, c=true)
}
