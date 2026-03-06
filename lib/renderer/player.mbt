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
    self.animation.width.to_double(),
    self.animation.height.to_double(),
  )

  // Lottie renders layers from bottom to top (reverse order in the array)
  let layers = self.animation.layers
  for i = layers.length() - 1; i >= 0; i = i - 1 {
    let layer = layers[i]
    // Skip if hidden
    if layer.hidden == Some(true) {
      continue
    }
    // Skip if this is a matte source (it will be rendered by the matted layer)
    if layer.matte_inherit == Some(1) {
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
    if layer.index == parent_ind {
      match layer.parent {
        Some(p_ind) => self.apply_parent_transform(p_ind, scope, comp_frame)
        None => ()
      }
      let matrix = @runtime.evaluate_transform(layer.transform, comp_frame)
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
  if comp_frame < layer.in_point || comp_frame >= layer.out_point {
    return
  }

  let layer_frame = comp_frame - layer.start_time
  let saved_frame = self.current_frame
  self.current_frame = layer_frame
  self.debug_layer = match layer.name {
    Some(name) => "\{name}#\{layer.index}"
    None => "#\{layer.index}"
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
  // lottie-web evaluates layer transform keyframes in composition time.
  let matrix = @runtime.evaluate_transform(layer.transform, comp_frame)
  self.renderer.concat_transform(matrix)

  // 1.2 Apply Layer Opacity
  let opacity = @runtime.evaluate_double_property(
    layer.transform.opacity,
    comp_frame,
  )
  self.renderer.set_opacity(opacity / 100.0)

  // 1.5 Find matte source (before rendering so we know if begin_layer is needed)
  let mut matte_source : @model.Layer? = None
  match layer.matte_type {
    Some(1) | Some(2) | Some(3) | Some(4) => {
      for i = 0; i < scope.length(); i = i + 1 {
        if scope[i].index == layer.index && i > 0 {
          matte_source = Some(scope[i - 1])
          break
        }
      }
    }
    _ => ()
  }

  // 1.6 Begin isolated compositing layer for effects / track matte.
  // This ensures compositing stays local to this layer.
  let needs_layer_isolation = match matte_source {
    Some(_) => true
    None => match layer.fill_effect {
      Some(_) => true
      None => false
    }
  }
  if needs_layer_isolation {
    self.renderer.begin_layer()
  }

  // 2. Apply Layer Masks
  let mut mask_restore_count = 0
  match layer.masks {
    Some(masks) => {
      let mut i = 0
      while i < masks.length() {
        let mask = masks[i]

        // Group contiguous Add masks
        if mask.mode == @model.MaskMode::Add && not(mask.inverted) {
          self.renderer.begin_path()
          self.renderer.set_fill_rule("nonzero")
          while i < masks.length() {
            let m = masks[i]
            if m.mode == @model.MaskMode::Add && not(m.inverted) {
              let path_val = @runtime.evaluate_path_property(
                m.path,
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
            let is_inv = (mask.mode == @model.MaskMode::Add && mask.inverted) ||
              (mask.mode == @model.MaskMode::Subtract && not(mask.inverted))

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
                mask.path,
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
                mask.path,
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
              mask.path,
              self.current_frame,
            )
            self.draw_lottie_path(path_val)
            if mask.inverted {
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

  // 3. Render Layer Content
  self.render_layer_content(layer, layer_frame)

  // 4. Restore mask states
  for _ in 0..<mask_restore_count {
    self.renderer.restore()
  }

  // 5. Apply Layer Effects
  match layer.fill_effect {
    Some(fill_effect) => self.apply_layer_fill_effect(fill_effect, layer_frame)
    None => ()
  }

  // 6. Apply Track Matte inside the isolated layer
  match matte_source {
    Some(m_layer) => {
      let mode = match layer.matte_type {
        Some(1) | Some(3) => "destination-in"
        Some(2) | Some(4) => "destination-out"
        _ => "destination-in"
      }
      self.renderer.set_blend_mode(mode)
      let matte_saved_frame = self.current_frame
      self.current_frame = comp_frame
      // Track matte source is a sibling layer in composition space.
      // Reset transform before rendering matte source to avoid inheriting
      // the matted layer's local transform.
      self.renderer.save()
      self.renderer.set_transform(@math.Matrix::identity())
      self.render_layer(m_layer, scope)
      self.renderer.restore()
      self.current_frame = matte_saved_frame
      self.renderer.set_blend_mode("source-over")
    }
    None => ()
  }
  if needs_layer_isolation {
    self.renderer.end_layer("source-over")
  }
  self.renderer.restore()
  self.current_frame = saved_frame
}

///|
fn[R : Renderer] Player::apply_layer_fill_effect(
  self : Player[R],
  effect : @model.LayerFillEffect,
  frame : Double,
) -> Unit {
  let color = @runtime.evaluate_vec_property(effect.color, frame)
  let opacity = @runtime.evaluate_double_property(effect.opacity, frame)
  let (r, g, b) = color_rgb_from_vec(color)
  self.renderer.set_blend_mode("source-atop")
  self.renderer.begin_path()
  self.renderer.move_to(-10000.0, -10000.0)
  self.renderer.line_to(10000.0, -10000.0)
  self.renderer.line_to(10000.0, 10000.0)
  self.renderer.line_to(-10000.0, 10000.0)
  self.renderer.close_path()
  self.renderer.fill(r, g, b, opacity / 100.0)
  self.renderer.set_blend_mode("source-over")
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
fn color_channel_to_u8(v : Double) -> Int {
  // Align with lottie-rs `Rgba::from(Value)`:
  // - [0, 1] normalized values
  // - [0, 255] byte-range values
  // - 1.0 is treated as normalized upper-bound (=> 255), matching lottie-rs
  let c = if v > 1.0 && v <= 255.0 { v } else { v * 255.0 }
  let i = c.to_int()
  if i < 0 {
    0
  } else if i > 255 {
    255
  } else {
    i
  }
}

///|
fn color_rgb_from_vec(v : Array[Double]) -> (Int, Int, Int) {
  (
    color_channel_to_u8(get_vec_at(v, 0, 0.0)),
    color_channel_to_u8(get_vec_at(v, 1, 0.0)),
    color_channel_to_u8(get_vec_at(v, 2, 0.0)),
  )
}

///|
fn resolve_image_asset_src(asset : @model.Asset) -> String {
  let p = match asset.path {
    Some(v) => v
    None => ""
  }
  let u = match asset.folder {
    Some(v) => v
    None => ""
  }
  if p == "" { asset.id } else { u + p }
}

///|
fn[R : Renderer] Player::render_layer_content(
  self : Player[R],
  layer : @model.Layer,
  precomp_frame : Double,
) -> Unit {
  match layer.data {
    Shape(shapes) => {
      // Clear current paths for each layer's top level
      self.current_paths = []
      // Use the same rendering logic as Group internals:
      // collect paths forward, then draw paints in reverse for correct z-order.
      self.render_shape_items(shapes)
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
    PreComp(ref_id, w, h) =>
      match self.animation.assets {
        Some(assets) =>
          for asset in assets {
            if asset.id == ref_id {
              let saved_frame = self.current_frame
              self.current_frame = precomp_frame
              self.renderer.save()
              self.renderer.begin_path()
              self.renderer.move_to(0.0, 0.0)
              self.renderer.line_to(w.to_double(), 0.0)
              self.renderer.line_to(w.to_double(), h.to_double())
              self.renderer.line_to(0.0, h.to_double())
              self.renderer.close_path()
              self.renderer.set_fill_rule("nonzero")
              self.renderer.clip()
              match asset.layers {
                Some(layers) =>
                  for i = layers.length() - 1; i >= 0; i = i - 1 {
                    let child_layer = layers[i]
                    if child_layer.hidden == Some(true) {
                      continue
                    }
                    if child_layer.matte_inherit == Some(1) {
                      continue
                    }
                    self.render_layer(child_layer, layers)
                  }
                None => ()
              }
              self.renderer.restore()
              self.current_frame = saved_frame
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
              let w = match asset.width {
                Some(v) => v
                None => 0
              }
              let h = match asset.height {
                Some(v) => v
                None => 0
              }
              let src = resolve_image_asset_src(asset)
              self.renderer.draw_image(src, w.to_double(), h.to_double())
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
      if doc.text != "" {
        let (r, g, b) = color_rgb_from_vec(doc.fill_color)
        self.renderer.draw_text(doc.text, doc.font, doc.size, r, g, b, 1.0, doc.justify)
      }
    }
    Null => ()
  }
}

///|
/// Render a list of shape items matching lottie-web's z-ordering.
///
/// lottie-web builds a style list in reverse order, then draws styles forward.
/// This means fills/strokes at lower array indices (visually "on top" in AE)
/// are drawn LAST (painter's algorithm – on top).
///
/// We achieve the same result by:
///   1. Forward-scanning to accumulate paths and snapshot them at each paint op.
///   2. Putting painted groups into the same draw list as sibling paint ops.
///   3. Drawing the collected draw list in REVERSE order (last = underneath).
fn[R : Renderer] Player::render_shape_items(
  self : Player[R],
  items : Array[@model.Shape],
) -> Unit {
  // Phase 1: Forward pass – accumulate paths; collect drawable ops with snapshots.
  // Groups WITHOUT paint ops contribute paths (like plain path shapes),
  // so they must be processed here so their paths are available when
  // subsequent fills/strokes take a snapshot.
  let draw_items : Array[@model.Shape] = []
  let draw_path_snapshots : Array[Array[@model.BezierPath]] = []
  let draw_item_path_modifiers : Array[Array[@model.Shape]] = []
  for item in items {
    match item.data {
      Transform(_) => ()
      Group(nested) =>
        if not(shape_group_has_paint(nested)) {
          // Path-only group: render now so its paths accumulate into
          // current_paths before the next paint op snapshots them.
          self.render_shape(item)
        } else {
          // Painted group participates in z-order with sibling paint ops.
          draw_items.push(item)
          draw_path_snapshots.push([])
          draw_item_path_modifiers.push([])
        }
      Fill(_) | Stroke(_) | GradientFill(_) | GradientStroke(_) => {
        draw_items.push(item)
        // Snapshot current accumulated paths for this paint op.
        let snapshot = []
        for p in self.current_paths {
          snapshot.push(p)
        }
        draw_path_snapshots.push(snapshot)
        draw_item_path_modifiers.push([])
      }
      TrimPath(t) => {
        // Keep existing behavior for currently accumulated (non-deferred) paths.
        self.render_shape(item)
        // Trim Paths in lottie-web affect preceding drawable content in the same
        // shape list. Our paint ops and painted groups are deferred for z-order,
        // so we need to also apply this modifier to already collected draw items.
        let start = @runtime.evaluate_double_property(t.start, self.current_frame)
        let end = @runtime.evaluate_double_property(t.end, self.current_frame)
        let offset = @runtime.evaluate_double_property(t.offset, self.current_frame)
        for i = 0; i < draw_items.length(); i = i + 1 {
          match draw_items[i].data {
            Fill(_) | Stroke(_) | GradientFill(_) | GradientStroke(_) =>
              draw_path_snapshots[i] = apply_trim_path_with_mode(
                draw_path_snapshots[i],
                start,
                end,
                offset,
                t.multiple,
              )
            Group(_) => draw_item_path_modifiers[i].push(item)
            _ => ()
          }
        }
      }
      _ => self.render_shape(item) // path shapes, modifiers, etc.
    }
  }
  // Save accumulated paths (needed for outer merge after Group rendering).
  let all_inner_paths = []
  for p in self.current_paths {
    all_inner_paths.push(p)
  }

  // Phase 2: Draw collected drawable ops in REVERSE order (last first = underneath).
  // This keeps sibling painted groups and sibling paint styles in one shared z-order,
  // matching lottie-web behavior.
  for i = draw_items.length() - 1; i >= 0; i = i - 1 {
    match draw_items[i].data {
      Fill(_) | Stroke(_) | GradientFill(_) | GradientStroke(_) => {
        self.current_paths = draw_path_snapshots[i]
        self.render_shape(draw_items[i])
      }
      Group(nested) => {
        let modifiers = draw_item_path_modifiers[i]
        if modifiers.length() == 0 {
          self.render_shape(draw_items[i])
        } else {
          let items_with_modifiers = []
          for nested_item in nested {
            items_with_modifiers.push(nested_item)
          }
          for modifier in modifiers {
            items_with_modifiers.push(modifier)
          }
          let decorated_group = @model.Shape::new(
            shape_type = draw_items[i].shape_type,
            data = @model.ShapeData::new_group(items_with_modifiers),
          )
          self.render_shape(decorated_group)
        }
      }
      _ => ()
    }
  }

  // Restore accumulated paths for potential outer merge.
  self.current_paths = all_inner_paths
}

///|
pub fn[R : Renderer] Player::render_shape(
  self : Player[R],
  shape : @model.Shape,
) -> Unit {
  self.debug_shape = match shape.name {
    Some(name) => "\{name}:\{shape.shape_type}"
    None => shape.shape_type
  }
  self.debug_property = shape.shape_type
  self.debug_log("render_shape")
  match shape.hidden {
    Some(true) => return
    _ => ()
  }
  match shape.data {
    Group(items) => {
      self.renderer.save()
      let old_paths = self.current_paths
      self.current_paths = []
      let group_has_paint_ops = shape_group_has_paint(items)

      // Evaluate group transform and apply it to the renderer.
      let mut group_matrix = @math.Matrix::identity()
      for item in items {
        match item.data {
          Transform(tr) => {
            group_matrix = @runtime.evaluate_transform(tr, self.current_frame)
            self.render_shape(item)
          }
          _ => ()
        }
      }

      // Render non-transform items using the shared helper that
      // collects paths forward and draws paints in lottie-web z-order.
      self.render_shape_items(items)

      // Merge inner paths with outer paths.
      // When the group has no paint, its paths bubble up to the parent.
      // Transform them by the group's local matrix so they are in the
      // parent's coordinate space.
      let inner_paths = self.current_paths
      self.current_paths = old_paths
      if not(group_has_paint_ops) {
        for p in inner_paths {
          self.current_paths.push(transform_path(p, group_matrix))
        }
      }
      self.renderer.restore()
    }
    Rect(r) => {
      let p = @runtime.evaluate_vec_property(r.position, self.current_frame)
      let s = @runtime.evaluate_vec_property(r.size, self.current_frame)
      let corner_r = @runtime.evaluate_double_property(r.roundness, self.current_frame)
      let x = get_vec_at(p, 0, 0.0)
      let y = get_vec_at(p, 1, 0.0)
      let w = get_vec_at(s, 0, 0.0)
      let h = get_vec_at(s, 1, 0.0)
      self.current_paths.push(create_rect_path(x, y, w, h, corner_r))
    }
    Ellipse(e) => {
      let p = @runtime.evaluate_vec_property(e.position, self.current_frame)
      let s = @runtime.evaluate_vec_property(e.size, self.current_frame)
      let cx = get_vec_at(p, 0, 0.0)
      let cy = get_vec_at(p, 1, 0.0)
      let rx = get_vec_at(s, 0, 0.0) / 2.0
      let ry = get_vec_at(s, 1, 0.0) / 2.0
      self.current_paths.push(create_ellipse_path(cx, cy, rx, ry))
    }
    Path(p) => {
      let path = @runtime.evaluate_path_property(p.path, self.current_frame)
      self.current_paths.push(path)
    }
    Fill(f) => {
      let color_vec = @runtime.evaluate_vec_property(f.color, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.opacity, self.current_frame)
      let (r, g, b) = color_rgb_from_vec(color_vec)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.fill(r, g, b, opacity / 100.0)
    }
    Stroke(s) => {
      let color_vec = @runtime.evaluate_vec_property(s.color, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.opacity, self.current_frame)
      let width = @runtime.evaluate_double_property(s.width, self.current_frame)
      let (r, g, b) = color_rgb_from_vec(color_vec)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.set_stroke_style(s.line_cap, s.line_join, s.miter_limit)
      if s.dashes.length() > 0 {
        let dash_array : Array[Double] = []
        let mut dash_offset = 0.0
        for d in s.dashes {
          let v = @runtime.evaluate_double_property(d.value, self.current_frame)
          if d.name == "o" {
            dash_offset = v
          } else {
            dash_array.push(v)
          }
        }
        self.renderer.set_line_dash(dash_array, dash_offset)
      }
      self.renderer.stroke(r, g, b, opacity / 100.0, width)
    }
    GradientFill(f) => {
      let start_p = @runtime.evaluate_vec_property(f.start_point, self.current_frame)
      let end_p = @runtime.evaluate_vec_property(f.end_point, self.current_frame)
      let stops = @runtime.evaluate_vec_property(f.gradient_colors.color_stops, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.opacity, self.current_frame)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      match f.gradient_type {
        Linear =>
          self.renderer.fill_linear_gradient(
            get_vec_at(start_p, 0, 0.0),
            get_vec_at(start_p, 1, 0.0),
            get_vec_at(end_p, 0, 0.0),
            get_vec_at(end_p, 1, 0.0),
            f.gradient_colors.color_count,
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
            f.gradient_colors.color_count,
            stops,
            opacity / 100.0,
          )
        }
      }
    }
    GradientStroke(s) => {
      let start_p = @runtime.evaluate_vec_property(s.start_point, self.current_frame)
      let end_p = @runtime.evaluate_vec_property(s.end_point, self.current_frame)
      let stops = @runtime.evaluate_vec_property(s.gradient_colors.color_stops, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.opacity, self.current_frame)
      let width = @runtime.evaluate_double_property(s.width, self.current_frame)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.set_stroke_style(s.line_cap, s.line_join, s.miter_limit)
      match s.gradient_type {
        Linear =>
          self.renderer.stroke_linear_gradient(
            get_vec_at(start_p, 0, 0.0),
            get_vec_at(start_p, 1, 0.0),
            get_vec_at(end_p, 0, 0.0),
            get_vec_at(end_p, 1, 0.0),
            s.gradient_colors.color_count,
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
            s.gradient_colors.color_count,
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
      let opacity = @runtime.evaluate_double_property(
        tr.opacity,
        self.current_frame,
      )
      self.renderer.set_opacity(opacity / 100.0)
    }
    TrimPath(t) => {
      let start = @runtime.evaluate_double_property(t.start, self.current_frame)
      let end = @runtime.evaluate_double_property(t.end, self.current_frame)
      let offset = @runtime.evaluate_double_property(t.offset, self.current_frame)
      self.current_paths = apply_trim_path_with_mode(
        self.current_paths,
        start,
        end,
        offset,
        t.multiple,
      )
    }
    Polystar(sr) => self.current_paths.push(self.create_polystar_path(sr))
    Repeater(rep) => {
      let copies = @runtime.evaluate_double_property(rep.copies, self.current_frame).to_int()
      let offset = @runtime.evaluate_double_property(rep.offset, self.current_frame)
      let tr_matrix = @runtime.evaluate_transform(rep.transform, self.current_frame)
      let so = @runtime.evaluate_double_property(rep.start_opacity, self.current_frame)
      let eo = @runtime.evaluate_double_property(rep.end_opacity, self.current_frame)

      let original_paths = self.current_paths
      let new_paths = []

      // Lottie Repeater: n-th copy transform is (tr_matrix ^ (n + offset))
      // Composite: 1 = Above (new copies on top), 2 = Below

      let start_idx = if rep.composite == 1 { 0 } else { copies - 1 }
      let end_idx = if rep.composite == 1 { copies } else { -1 }
      let step = if rep.composite == 1 { 1 } else { -1 }

      // Check if per-copy opacity varies
      let needs_opacity = (so - eo).abs() > shape_epsilon ||
        (so - 100.0).abs() > shape_epsilon

      let mut i = start_idx
      while (if step == 1 { i < end_idx } else { i > end_idx }) {
        let mut m = @math.Matrix::identity()
        let total_steps = i.to_double() + offset

        // Simple power implementation for matrix
        for _j = 0; _j < total_steps.to_int(); _j = _j + 1 {
          m = m.multiply(tr_matrix)
        }

        // Compute per-copy opacity: lerp(so, eo, i / (copies - 1))
        if needs_opacity {
          let t = if copies > 1 {
            i.to_double() / (copies - 1).to_double()
          } else {
            0.0
          }
          let copy_opacity = so + (eo - so) * t
          self.renderer.save()
          self.renderer.set_opacity(copy_opacity / 100.0)
        }

        for path in original_paths {
          new_paths.push(transform_path(path, m))
        }

        if needs_opacity {
          self.renderer.restore()
        }

        i = i + step
      }
      self.current_paths = new_paths
    }
    MergePaths(merge) =>
      // Lottie MergePaths: 1=Merge, 2=Add, 3=Subtract, 4=Intersect, 5=Exclude
      // For SVG, we use fill-rule="evenodd" to approximate boolean operations
      // since we don't have a path boolean engine in MoonBit yet.
      match merge.merge_mode {
        @model.MergeMode::Merge | @model.MergeMode::Add =>
          self.renderer.set_fill_rule("nonzero")
        @model.MergeMode::Subtract
        | @model.MergeMode::Intersect
        | @model.MergeMode::Exclude => self.renderer.set_fill_rule("evenodd")
      }
    Rounding(rounding) => {
      let radius = @runtime.evaluate_double_property(
        rounding.radius,
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
pub fn apply_rounding_to_path(
  path : @model.BezierPath,
  radius : Double,
) -> @model.BezierPath {
  let v = path.vertices
  let i_t = path.in_tangents
  let o_t = path.out_tangents
  let n = v.length()
  if n < 2 {
    return path
  }

  let new_v : Array[Array[Double]] = []
  let new_i : Array[Array[Double]] = []
  let new_o : Array[Array[Double]] = []

  let count = n
  for idx = 0; idx < count; idx = idx + 1 {
    let is_first = idx == 0 && not(path.closed)
    let is_last = idx == n - 1 && not(path.closed)

    // Check if this is a sharp corner (zero tangents)
    let it0 = get_pt_at(i_t, idx, 0)
    let it1 = get_pt_at(i_t, idx, 1)
    let ot0 = get_pt_at(o_t, idx, 0)
    let ot1 = get_pt_at(o_t, idx, 1)
    let is_sharp = it0.abs() < shape_epsilon &&
      it1.abs() < shape_epsilon &&
      ot0.abs() < shape_epsilon &&
      ot1.abs() < shape_epsilon

    if not(is_sharp) || is_first || is_last {
      // Non-sharp corner or endpoint: keep as-is
      new_v.push([get_pt_at(v, idx, 0), get_pt_at(v, idx, 1)])
      new_i.push([it0, it1])
      new_o.push([ot0, ot1])
    } else {
      // Sharp corner: round it
      let prev_idx = if idx > 0 { idx - 1 } else { n - 1 }
      let next_idx = if idx < n - 1 { idx + 1 } else { 0 }

      let cx = get_pt_at(v, idx, 0)
      let cy = get_pt_at(v, idx, 1)
      let px = get_pt_at(v, prev_idx, 0)
      let py = get_pt_at(v, prev_idx, 1)
      let nx = get_pt_at(v, next_idx, 0)
      let ny = get_pt_at(v, next_idx, 1)

      // Distances to prev and next
      let dp = ((cx - px) * (cx - px) + (cy - py) * (cy - py)).sqrt()
      let dn = ((cx - nx) * (cx - nx) + (cy - ny) * (cy - ny)).sqrt()

      // Clamp radius to half of shortest edge
      let max_r = if dp < dn { dp } else { dn }
      let max_r = max_r / 2.0
      let r = if radius < max_r { radius } else { max_r }

      if r < shape_epsilon {
        new_v.push([cx, cy])
        new_i.push([0.0, 0.0])
        new_o.push([0.0, 0.0])
      } else {
        // Direction vectors
        let dir_px = (px - cx) / dp
        let dir_py = (py - cy) / dp
        let dir_nx = (nx - cx) / dn
        let dir_ny = (ny - cy) / dn

        // New vertices: offset along each edge by radius
        let v1x = cx + dir_px * r
        let v1y = cy + dir_py * r
        let v2x = cx + dir_nx * r
        let v2y = cy + dir_ny * r

        // Control point factor for quarter-circle approximation
        let kappa = 0.5519150244935105 // 4*(sqrt(2)-1)/3 for circular arc

        new_v.push([v1x, v1y])
        new_i.push([0.0, 0.0])
        new_o.push([-dir_px * r * kappa, -dir_py * r * kappa])

        new_v.push([v2x, v2y])
        new_i.push([-dir_nx * r * kappa, -dir_ny * r * kappa])
        new_o.push([0.0, 0.0])
      }
    }
  }

  @model.BezierPath::new(
    vertices=new_v,
    in_tangents=new_i,
    out_tangents=new_o,
    closed=path.closed,
  )
}

///|
fn transform_path(
  path : @model.BezierPath,
  m : @math.Matrix,
) -> @model.BezierPath {
  let v = []
  for i, _ in path.vertices {
    let (nx, ny) = m.transform_point(get_pt_at(path.vertices, i, 0), get_pt_at(path.vertices, i, 1))
    v.push([nx, ny])
  }
  // Tangents are relative, but they still get scaled/rotated (not translated)
  let i_tangents = []
  for idx, _ in path.in_tangents {
    // To transform a vector (relative point), we ignore translation (e, f)
    let px = get_pt_at(path.in_tangents, idx, 0)
    let py = get_pt_at(path.in_tangents, idx, 1)
    let nx = px * m.a + py * m.c
    let ny = px * m.b + py * m.d
    i_tangents.push([nx, ny])
  }
  let o_tangents = []
  for idx, _ in path.out_tangents {
    let px = get_pt_at(path.out_tangents, idx, 0)
    let py = get_pt_at(path.out_tangents, idx, 1)
    let nx = px * m.a + py * m.c
    let ny = px * m.b + py * m.d
    o_tangents.push([nx, ny])
  }
  @model.BezierPath::new(
    vertices=v,
    in_tangents=i_tangents,
    out_tangents=o_tangents,
    closed=path.closed,
  )
}

///|
fn[R : Renderer] Player::draw_lottie_path(
  self : Player[R],
  path : @model.BezierPath,
) -> Unit {
  let v = path.vertices
  if v.length() > 0 {
    let i = path.in_tangents
    let o = path.out_tangents
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
    if path.closed {
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
    vertices=[[cx, cy - ry], [cx + rx, cy], [cx, cy + ry], [cx - rx, cy]],
    in_tangents=[[-ox, 0.0], [0.0, -oy], [ox, 0.0], [0.0, oy]],
    out_tangents=[[ox, 0.0], [0.0, oy], [-ox, 0.0], [0.0, -oy]],
    closed=true,
  )
}

///|
/// Sampling count for cubic arc-length approximation in Trim Path extraction.
/// 50 keeps frame drift low on complex curves while staying fast enough for tests/demo.
let cubic_subdivision_intervals = 50

///|
let trim_t_epsilon = 0.000000001

///|
/// Small epsilon for floating-point comparisons in shape modifiers
let shape_epsilon = 0.001

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
pub fn apply_trim_path_with_mode(
  paths : Array[@model.BezierPath],
  start : Double,
  end : Double,
  offset : Double,
  mode : Int,
) -> Array[@model.BezierPath] {
  if mode == 1 {
    apply_trim_path_simultaneously(paths, start, end, offset)
  } else {
    apply_trim_path(paths, start, end, offset)
  }
}

///|
fn apply_trim_path_simultaneously(
  paths : Array[@model.BezierPath],
  start : Double,
  end : Double,
  offset : Double,
) -> Array[@model.BezierPath] {
  let s_val = start / 100.0
  let e_val = end / 100.0
  let o_val = offset / 360.0
  if s_val <= 0.0 && e_val >= 1.0 {
    return paths
  }
  if e_val - s_val >= 1.0 {
    return paths
  }
  let start_norm = {
    let mut val = s_val + o_val
    val = val - val.floor()
    val
  }
  let end_norm = {
    let mut val = e_val + o_val
    val = val - val.floor()
    val
  }
  if start_norm < end_norm {
    trim_paths_by_global_range(paths, start_norm, end_norm)
  } else {
    let part1 = trim_paths_by_global_range(paths, start_norm, 1.0)
    let part2 = trim_paths_by_global_range(paths, 0.0, end_norm)
    let result = []
    for p in part1 {
      result.push(p)
    }
    for p in part2 {
      result.push(p)
    }
    result
  }
}

///|
fn trim_paths_by_global_range(
  paths : Array[@model.BezierPath],
  s_norm : Double,
  e_norm : Double,
) -> Array[@model.BezierPath] {
  let lengths = []
  let mut total_length = 0.0
  for path in paths {
    let len = get_path_length(path)
    lengths.push(len)
    total_length += len
  }
  if total_length == 0.0 {
    return paths
  }
  let s_len = s_norm * total_length
  let e_len = e_norm * total_length
  let result = []
  let mut current_acc = 0.0
  for i = 0; i < paths.length(); i = i + 1 {
    let path = paths[i]
    let path_len = lengths[i]
    let path_start = current_acc
    let path_end = current_acc + path_len
    if path_len > 0.0 && path_end > s_len && path_start < e_len {
      let local_s = if s_len > path_start {
        (s_len - path_start) / path_len
      } else {
        0.0
      }
      let local_e = if e_len < path_end {
        (e_len - path_start) / path_len
      } else {
        1.0
      }
      if local_s <= 0.0 && local_e >= 1.0 {
        result.push(path)
      } else {
        // Avoid exact 1.0 because trim_single_path normalizes 1.0 to 0.0 internally.
        let trim_end_max = 0.999999999999
        let adjusted_local_e = if local_e >= 1.0 { trim_end_max } else { local_e }
        for p in trim_single_path(path, local_s, adjusted_local_e, 0.0) {
          result.push(p)
        }
      }
    }
    current_acc += path_len
  }
  result
}

///|
fn get_path_length(path : @model.BezierPath) -> Double {
  if path.vertices.length() < 2 {
    return 0.0
  }
  let num_pts = path.vertices.length()
  let num_segs = if path.closed { num_pts } else { num_pts - 1 }
  let mut total_length = 0.0
  for j = 0; j < num_segs; j = j + 1 {
    let next_j = (j + 1) % num_pts
    let p0 = @math.Vector2::new(get_pt_at(path.vertices, j, 0), get_pt_at(path.vertices, j, 1))
    let p1 = @math.Vector2::new(
      get_pt_at(path.vertices, j, 0) + get_pt_at(path.out_tangents, j, 0),
      get_pt_at(path.vertices, j, 1) + get_pt_at(path.out_tangents, j, 1),
    )
    let p2 = @math.Vector2::new(
      get_pt_at(path.vertices, next_j, 0) + get_pt_at(path.in_tangents, next_j, 0),
      get_pt_at(path.vertices, next_j, 1) + get_pt_at(path.in_tangents, next_j, 1),
    )
    let p3 = @math.Vector2::new(get_pt_at(path.vertices, next_j, 0), get_pt_at(path.vertices, next_j, 1))
    total_length += @math.get_cubic_bezier_length(
      p0,
      p1,
      p2,
      p3,
      cubic_subdivision_intervals,
    )
  }
  total_length
}

///|
/// Find parametric `t` on a cubic where arc length from 0..t reaches
/// `target_length`. Returns 0.0 for non-positive targets and 1.0 if the
/// target length exceeds total sampled curve length.
fn find_t_for_length_on_cubic(
  p0 : @math.Vector2,
  p1 : @math.Vector2,
  p2 : @math.Vector2,
  p3 : @math.Vector2,
  target_length : Double,
) -> Double {
  if target_length <= 0.0 {
    return 0.0
  }
  let intervals = cubic_subdivision_intervals
  let mut acc = 0.0
  let mut prev_t = 0.0
  let mut prev_pt = p0
  let mut prev_acc = 0.0
  for i = 1; i <= intervals; i = i + 1 {
    let t = i.to_double() / intervals.to_double()
    let pt = @math.point_on_cubic_bezier(p0, p1, p2, p3, t)
    let dx = pt.x - prev_pt.x
    let dy = pt.y - prev_pt.y
    acc += @math.sqrt(dx * dx + dy * dy)
    if acc >= target_length {
      let seg_len = acc - prev_acc
      let local_ratio = if seg_len > 0.0 {
        (target_length - prev_acc) / seg_len
      } else {
        0.0
      }
      return prev_t + (t - prev_t) * local_ratio
    }
    prev_t = t
    prev_pt = pt
    prev_acc = acc
  }
  1.0
}

///|
pub fn trim_single_path(
  path : @model.BezierPath,
  s : Double,
  e : Double,
  o : Double,
) -> Array[@model.BezierPath] {
  let v = path.vertices
  if v.length() < 2 {
    return [path]
  }

  // 1. Calculate length of each segment
  let seg_lengths = []
  let mut total_length = 0.0
  let num_pts = v.length()
  let num_segs = if path.closed { num_pts } else { num_pts - 1 }

  for j = 0; j < num_segs; j = j + 1 {
    let next_j = (j + 1) % num_pts
    let p0 = @math.Vector2::new(get_pt_at(v, j, 0), get_pt_at(v, j, 1))
    let p1 = @math.Vector2::new(
      get_pt_at(v, j, 0) + get_pt_at(path.out_tangents, j, 0),
      get_pt_at(v, j, 1) + get_pt_at(path.out_tangents, j, 1),
    )
    let p2 = @math.Vector2::new(
      get_pt_at(v, next_j, 0) + get_pt_at(path.in_tangents, next_j, 0),
      get_pt_at(v, next_j, 1) + get_pt_at(path.in_tangents, next_j, 1),
    )
    let p3 = @math.Vector2::new(get_pt_at(v, next_j, 0), get_pt_at(v, next_j, 1))
    let len = @math.get_cubic_bezier_length(
      p0,
      p1,
      p2,
      p3,
      cubic_subdivision_intervals,
    )
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
  let num_pts = path.vertices.length()
  let num_segs = if path.closed { num_pts } else { num_pts - 1 }

  for j = 0; j < num_segs; j = j + 1 {
    let seg_len = seg_lengths[j]
    let seg_start = current_acc
    let seg_end = current_acc + seg_len

    // Check if segment is within [s_len, e_len]
    if seg_end > s_len && seg_start < e_len {
      let next_j = (j + 1) % num_pts
      let p0 = @math.Vector2::new(
        get_pt_at(path.vertices, j, 0),
        get_pt_at(path.vertices, j, 1),
      )
      let p1 = @math.Vector2::new(
        get_pt_at(path.vertices, j, 0) + get_pt_at(path.out_tangents, j, 0),
        get_pt_at(path.vertices, j, 1) + get_pt_at(path.out_tangents, j, 1),
      )
      let p2 = @math.Vector2::new(
        get_pt_at(path.vertices, next_j, 0) + get_pt_at(path.in_tangents, next_j, 0),
        get_pt_at(path.vertices, next_j, 1) + get_pt_at(path.in_tangents, next_j, 1),
      )
      let p3 = @math.Vector2::new(
        get_pt_at(path.vertices, next_j, 0),
        get_pt_at(path.vertices, next_j, 1),
      )

      // Calculate local t for start and end
      let t_start = if s_len > seg_start {
        find_t_for_length_on_cubic(p0, p1, p2, p3, s_len - seg_start)
      } else {
        0.0
      }
      let t_end = if e_len < seg_end {
        find_t_for_length_on_cubic(p0, p1, p2, p3, e_len - seg_start)
      } else {
        1.0
      }

      // Skip zero-length subsegments (matches lottie-web behavior for degenerate trims).
      if t_end - t_start <= trim_t_epsilon {
        continue
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
    return @model.BezierPath::new(vertices=[], in_tangents=[], out_tangents=[], closed=false)
  }

  // Last vertex has no out tangent (or it's the end of open path)
  new_o.push([0.0, 0.0])

  @model.BezierPath::new(vertices=new_v, in_tangents=new_i, out_tangents=new_o, closed=false)
}

///|
fn[R] Player::create_polystar_path(
  self : Player[R],
  sr : @model.PolystarShape,
) -> @model.BezierPath {
  let pt = @runtime.evaluate_double_property(sr.points, self.current_frame)
  let p = @runtime.evaluate_vec_property(sr.position, self.current_frame)
  let r = @runtime.evaluate_double_property(sr.rotation, self.current_frame)
  let or = @runtime.evaluate_double_property(sr.outer_radius, self.current_frame)
  let or_round = @runtime.evaluate_double_property(
    sr.outer_roundness,
    self.current_frame,
  )

  let cx = get_vec_at(p, 0, 0.0)
  let cy = get_vec_at(p, 1, 0.0)
  let num_points = pt.to_int()
  let vertices = []
  let ins = []
  let outs = []

  if sr.star_type == 2 { // Polygon
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
    let ir = @runtime.evaluate_double_property(sr.inner_radius, self.current_frame)
    let ir_round = @runtime.evaluate_double_property(
      sr.inner_roundness,
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

  @model.BezierPath::new(
    vertices=vertices,
    in_tangents=ins,
    out_tangents=outs,
    closed=true,
  )
}
