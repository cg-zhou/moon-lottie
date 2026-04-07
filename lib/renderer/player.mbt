///|
pub struct Player[R] {
  animation : @model.Animation
  renderer : R
  mut current_frame : Double
  // The composition frame for the layer currently being rendered.
  // Shape properties (paths, fills, strokes, trim paths, etc.) must be
  // evaluated at this frame — matching lottie-web which computes
  //   frameNum = comp.renderedFrame - offsetTime
  // and compares against   kf.t - offsetTime,
  // which is equivalent to evaluating at comp.renderedFrame vs raw kf.t.
  mut current_comp_frame : Double
  mut current_layer_index : Int
  mut current_comp_id : String
  mut current_paths : Array[@model.BezierPath]
  mut renderer_matrix : @math.Matrix
  mut renderer_matrix_stack : Array[@math.Matrix]
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
    current_comp_frame: 0.0,
    current_layer_index: -1,
    current_comp_id: "",
    current_paths: [],
    renderer_matrix: @math.Matrix::identity(),
    renderer_matrix_stack: [],
    debug_enabled: false,
    debug_logs: [],
    debug_layer: "",
    debug_shape: "",
    debug_property: "",
  }
}

///|
fn[R] Player::evaluate_double(
  self : Player[R],
  prop : @model.LottieProperty[Double],
  frame : Double,
) -> Double {
  @runtime.evaluate_double_property_with_context(
    prop,
    frame,
    self.current_layer_index,
    self.current_comp_id,
  )
}

///|
fn[R] Player::evaluate_vec(
  self : Player[R],
  prop : @model.LottieProperty[Array[Double]],
  frame : Double,
) -> Array[Double] {
  @runtime.evaluate_vec_property_with_context(
    prop,
    frame,
    self.current_layer_index,
    self.current_comp_id,
  )
}

///|
fn[R] Player::evaluate_path(
  self : Player[R],
  prop : @model.LottieProperty[@model.BezierPath],
  frame : Double,
) -> @model.BezierPath {
  @runtime.evaluate_path_property_with_context(
    prop,
    frame,
    self.current_layer_index,
    self.current_comp_id,
  )
}

///|
fn[R] Player::evaluate_transform(
  self : Player[R],
  transform : @model.Transform,
  frame : Double,
) -> @math.Matrix {
  @runtime.evaluate_transform_with_context(
    transform,
    frame,
    self.current_layer_index,
    self.current_comp_id,
  )
}

///|
fn transform_vec_component(values : Array[Double], index : Int, fallback : Double) -> Double {
  if index < values.length() {
    values[index]
  } else {
    fallback
  }
}

///|
fn build_transform_matrix(
  anchor : Array[Double],
  position : Array[Double],
  scale : Array[Double],
  rotation : Double,
) -> @math.Matrix {
  let ax = transform_vec_component(anchor, 0, 0.0)
  let ay = transform_vec_component(anchor, 1, 0.0)
  let px = transform_vec_component(position, 0, 0.0)
  let py = transform_vec_component(position, 1, 0.0)
  let sx = transform_vec_component(scale, 0, 100.0)
  let sy = transform_vec_component(scale, 1, 100.0)
  let m1 = @math.Matrix::identity().translate(px, py)
  let m2 = m1.rotate(rotation * 3.141592653589793 / 180.0)
  let m3 = m2.scale(sx / 100.0, sy / 100.0)
  m3.translate(-ax, -ay)
}

///|
fn[R] Player::evaluate_transform_position_with_context(
  self : Player[R],
  transform : @model.Transform,
  frame : Double,
  layer_index : Int,
) -> Array[Double] {
  if transform.split == Some(true) {
    let x = match transform.px {
      Some(prop) =>
        @runtime.evaluate_double_property_with_context(
          prop,
          frame,
          layer_index,
          self.current_comp_id,
        )
      None => 0.0
    }
    let y = match transform.py {
      Some(prop) =>
        @runtime.evaluate_double_property_with_context(
          prop,
          frame,
          layer_index,
          self.current_comp_id,
        )
      None => 0.0
    }
    [x, y]
  } else {
    @runtime.evaluate_vec_property_with_context(
      transform.position,
      frame,
      layer_index,
      self.current_comp_id,
    )
  }
}

///|
fn[R] Player::evaluate_auto_orient_rotation(
  self : Player[R],
  layer : @model.Layer,
  frame : Double,
  layer_index : Int,
) -> Double {
  let auto_orient_enabled = match layer.auto_orient {
    Some(0) | None => false
    Some(_) => true
  }
  if !auto_orient_enabled {
    return 0.0
  }
  let current_position = self.evaluate_transform_position_with_context(
    layer.transform,
    frame,
    layer_index,
  )
  let sample_offsets = [0.01, 0.1, 0.5, 1.0]
  let epsilon = 0.000001
  for offset in sample_offsets {
    let previous_position = self.evaluate_transform_position_with_context(
      layer.transform,
      frame - offset,
      layer_index,
    )
    let next_position = self.evaluate_transform_position_with_context(
      layer.transform,
      frame + offset,
      layer_index,
    )
    let dx = transform_vec_component(next_position, 0, 0.0) -
      transform_vec_component(previous_position, 0, 0.0)
    let dy = transform_vec_component(next_position, 1, 0.0) -
      transform_vec_component(previous_position, 1, 0.0)
    if dx.abs() > epsilon || dy.abs() > epsilon {
      return @std_math.atan2(dy, dx) * 180.0 / 3.141592653589793
    }
    let forward_dx = transform_vec_component(next_position, 0, 0.0) -
      transform_vec_component(current_position, 0, 0.0)
    let forward_dy = transform_vec_component(next_position, 1, 0.0) -
      transform_vec_component(current_position, 1, 0.0)
    if forward_dx.abs() > epsilon || forward_dy.abs() > epsilon {
      return @std_math.atan2(forward_dy, forward_dx) * 180.0 / 3.141592653589793
    }
    let backward_dx = transform_vec_component(current_position, 0, 0.0) -
      transform_vec_component(previous_position, 0, 0.0)
    let backward_dy = transform_vec_component(current_position, 1, 0.0) -
      transform_vec_component(previous_position, 1, 0.0)
    if backward_dx.abs() > epsilon || backward_dy.abs() > epsilon {
      return @std_math.atan2(backward_dy, backward_dx) * 180.0 / 3.141592653589793
    }
  }
  0.0
}

///|
fn[R] Player::evaluate_layer_transform_with_context(
  self : Player[R],
  layer : @model.Layer,
  frame : Double,
  layer_index : Int,
) -> @math.Matrix {
  let transform = layer.transform
  let anchor = @runtime.evaluate_vec_property_with_context(
    transform.anchor,
    frame,
    layer_index,
    self.current_comp_id,
  )
  let position = self.evaluate_transform_position_with_context(
    transform,
    frame,
    layer_index,
  )
  let scale = @runtime.evaluate_vec_property_with_context(
    transform.scale,
    frame,
    layer_index,
    self.current_comp_id,
  )
  let rotation = @runtime.evaluate_double_property_with_context(
    transform.rotation,
    frame,
    layer_index,
    self.current_comp_id,
  ) +
    self.evaluate_auto_orient_rotation(layer, frame, layer_index)
  build_transform_matrix(anchor, position, scale, rotation)
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
fn[R : Renderer] Player::renderer_save(self : Player[R]) -> Unit {
  self.renderer.save()
  self.renderer_matrix_stack.push(self.renderer_matrix)
}

///|
fn[R : Renderer] Player::renderer_restore(self : Player[R]) -> Unit {
  self.renderer.restore()
  match self.renderer_matrix_stack.pop() {
    Some(matrix) => self.renderer_matrix = matrix
    None => ()
  }
}

///|
fn[R : Renderer] Player::renderer_set_transform(
  self : Player[R],
  matrix : @math.Matrix,
) -> Unit {
  self.renderer.set_transform(matrix)
  self.renderer_matrix = matrix
}

///|
fn[R : Renderer] Player::renderer_concat_transform(
  self : Player[R],
  matrix : @math.Matrix,
) -> Unit {
  self.renderer.concat_transform(matrix)
  self.renderer_matrix = self.renderer_matrix.multiply(matrix)
}

///|
fn[R] Player::debug_log(self : Player[R], stage : String) -> Unit {
  if self.debug_enabled {
    self.debug_logs.push(
      "frame=\{self.current_frame},layer=\{self.debug_layer},shape=\{self.debug_shape},property=\{self.debug_property},stage=\{stage}",
    )
  }
}

///| Replays the layer's mask list into the renderer's SVG-style mask
///| compositor, which accumulates add/subtract/intersect mask alpha on a
///| dedicated mask buffer before applying it back to the isolated layer.
fn[R : Renderer] Player::apply_layer_mask_composite(
  self : Player[R],
  layer : @model.Layer,
  scope : Array[@model.Layer],
  comp_frame : Double,
  masks : Array[@model.Mask],
) -> Unit {
  let base_matrix = self.renderer_matrix
  match layer.parent {
    Some(parent_ind) => self.apply_parent_transform(parent_ind, scope, comp_frame)
    None => ()
  }
  let layer_matrix = self.evaluate_layer_transform_with_context(
    layer,
    comp_frame,
    self.current_layer_index,
  )
  self.renderer_concat_transform(layer_matrix)

  let mut has_effective_mask = false
  for mask in masks {
    if mask.mode == @model.MaskMode::None {
      continue
    }
    if !has_effective_mask {
      self.renderer.begin_mask_composite()
      has_effective_mask = true
    }
    self.renderer.begin_mask_path()
    self.renderer.set_fill_rule("nonzero")
    self.renderer.begin_path()
    let path_val = self.evaluate_path(mask.path, self.current_comp_frame)
    self.draw_lottie_path(path_val)
    let opacity = (
      self.evaluate_double(mask.opacity, self.current_comp_frame) / 100.0
    ).max(0.0).min(1.0)
    let expansion = self.evaluate_double(mask.expansion, self.current_comp_frame)
    self.renderer.apply_mask_path(
      mask_mode_to_composite_code(mask.mode),
      opacity,
      mask.inverted,
      expansion,
    )
  }
  if has_effective_mask {
    self.renderer.end_mask_composite()
  }
  self.renderer_set_transform(base_matrix)
}

///|
pub fn[R : Renderer] Player::render(self : Player[R]) -> Unit {
  if self.debug_enabled || self.debug_logs.length() > 0 {
    self.debug_logs = []
    self.debug_layer = ""
    self.debug_shape = ""
    self.debug_property = ""
  }
  self.renderer_matrix_stack = []
  self.renderer_set_transform(@math.Matrix::identity())
  self.renderer.clear_rect(
    0.0,
    0.0,
    self.animation.width.to_double(),
    self.animation.height.to_double(),
  )
  self.current_comp_id = ""

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
      let matrix = self.evaluate_layer_transform_with_context(
        layer,
        comp_frame,
        layer.index,
      )
      self.renderer_concat_transform(matrix)
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
  let precomp_frame = match layer.time_remap {
    Some(time_remap) => {
      let remapped_seconds = @runtime.evaluate_double_property_with_context(
        time_remap,
        layer_frame,
        layer.index,
        self.current_comp_id,
      )
      let remapped = remapped_seconds * self.animation.frame_rate
      if remapped == layer.out_point { remapped - 1.0 } else { remapped }
    }
    None => layer_frame
  }
  let saved_frame = self.current_frame
  let saved_comp_frame = self.current_comp_frame
  let saved_layer_index = self.current_layer_index
  let saved_comp_id = self.current_comp_id
  // Shape properties inside this layer must be evaluated at comp_frame.
  // lottie-web computes: frameNum = comp.renderedFrame - offsetTime
  // and compares against kf.t - offsetTime, which is equivalent to
  // evaluating at comp.renderedFrame (= comp_frame here) vs raw kf.t.
  self.current_comp_frame = comp_frame
  self.current_frame = layer_frame
  self.current_layer_index = layer.index
  self.debug_layer = match layer.name {
    Some(name) => "\{name}#\{layer.index}"
    None => "#\{layer.index}"
  }
  self.debug_shape = ""
  self.debug_property = "layer"
  self.debug_log("render_layer")

  // 0. Find matte source (needed before prepareLayer, matching lottie-web's order).
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

  let mut use_mask_composite = false
  match layer.masks {
    Some(masks) =>
      if self.renderer.supports_mask_composite() &&
        layer_masks_support_composite(masks) &&
        layer_masks_require_composite(masks) {
        use_mask_composite = true
      }
    None => ()
  }

  // 0.1 prepareLayer (lottie-web pattern): called BEFORE save() and transforms.
  // Saves background to buffer[0], captures base transform, clears canvas.
  let has_fill_effect = match layer.fill_effect {
    Some(_) => true
    None => false
  }
  let has_matte_source = match matte_source {
    Some(_) => true
    None => false
  }
  let needs_layer_isolation = (
    use_mask_composite || has_fill_effect
  ) || has_matte_source
  if needs_layer_isolation {
    self.renderer.begin_layer()
  }
  match matte_source {
    Some(_) => self.renderer.prepare_matte_layer()
    None => ()
  }

  self.renderer_save()

  // 1. Apply Parent Transform
  match layer.parent {
    Some(p_ind) => self.apply_parent_transform(p_ind, scope, comp_frame)
    None => ()
  }

  // 2. Apply Layer Transform
  // lottie-web evaluates all layer properties (transforms and shapes) using
  // comp_frame directly, since (comp_frame - st) vs (t - st) simplifies to
  // comp_frame vs t.
  let matrix = self.evaluate_layer_transform_with_context(
    layer,
    comp_frame,
    self.current_layer_index,
  )
  self.renderer_concat_transform(matrix)

  // 2.2 Apply Layer Opacity
  let opacity = self.evaluate_double(
    layer.transform.opacity,
    comp_frame,
  )
  self.renderer.set_opacity(opacity / 100.0)

  // 3. Apply Layer Masks
  let mut mask_restore_count = 0
  match (layer.masks, use_mask_composite) {
    (Some(_), true) => ()
    (Some(masks), false) => {
      let mut i = 0
      while i < masks.length() {
        let mask = masks[i]

        // Consecutive Add masks share one clip step. On SVG this becomes one
        // clipPath with multiple sibling path nodes, which matches lottie-web.
        if mask.mode == @model.MaskMode::Add && !mask.inverted {
          self.renderer.begin_path()
          self.renderer.set_fill_rule("nonzero")
          let mut first_add_mask = true
          while i < masks.length() &&
            masks[i].mode == @model.MaskMode::Add &&
            !masks[i].inverted {
            if !first_add_mask {
              self.renderer.begin_path_segment()
            }
            let path_val = self.evaluate_path(
              masks[i].path,
              self.current_comp_frame,
            )
            self.draw_lottie_path(path_val)
            first_add_mask = false
            i = i + 1
          }
          self.renderer.clip()
          continue
        }

        // Handle Subtract or Inverted Add/Subtract
        match mask.mode {
          @model.MaskMode::Subtract | @model.MaskMode::Add => {
            let is_inv = (mask.mode == @model.MaskMode::Add && mask.inverted) ||
              (mask.mode == @model.MaskMode::Subtract && !mask.inverted)

            if is_inv {
              // Difference: Save current state, then clip with a hole
              self.renderer_save()
              mask_restore_count = mask_restore_count + 1
              self.renderer.begin_path()
              self.renderer.move_to(-10000.0, -10000.0)
              self.renderer.line_to(10000.0, -10000.0)
              self.renderer.line_to(10000.0, 10000.0)
              self.renderer.line_to(-10000.0, 10000.0)
              self.renderer.close_path()

              let path_val = self.evaluate_path(
                mask.path,
                self.current_comp_frame,
              )
              self.draw_lottie_path(path_val)
              self.renderer.set_fill_rule("evenodd")
              self.renderer.clip()
            } else {
              // Non-inverted Add was handled in the grouped block
              // Inverted Subtract is same as Add
              self.renderer.begin_path()
              let path_val = self.evaluate_path(
                mask.path,
                self.current_comp_frame,
              )
              self.draw_lottie_path(path_val)
              self.renderer.set_fill_rule("nonzero")
              self.renderer.clip()
            }
          }
          @model.MaskMode::Intersect => {
            self.renderer.begin_path()
            let path_val = self.evaluate_path(
              mask.path,
              self.current_comp_frame,
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
    (None, _) => ()
  }

  // 4. Render Layer Content
  self.render_layer_content(layer, precomp_frame)

  // 5. Restore clip-based mask states
  for _ in 0..<mask_restore_count {
    self.renderer_restore()
  }

  self.renderer_restore()

  // 6. Apply Layer Effects after restore() so isolated renderers (like SVG)
  // can composite against a balanced layer subtree.
  match layer.fill_effect {
    Some(fill_effect) => self.apply_layer_fill_effect(fill_effect, comp_frame)
    None => ()
  }

  // 7. Apply SVG-style layer mask compositing on the isolated layer content.
  match (layer.masks, use_mask_composite) {
    (Some(masks), true) => self.apply_layer_mask_composite(layer, scope, comp_frame, masks)
    _ => ()
  }

  // 8. Apply Track Matte using lottie-web's exitLayer two-buffer pattern.
  // This runs AFTER restore() so the canvas is back at the base transform,
  // matching lottie-web's exitLayer() which is called after restore().
  match matte_source {
    Some(m_layer) => {
      // begin_matte_exit: saves layer content to buffer[1], clears canvas,
      // restores base transform for matte source rendering.
      self.renderer.begin_matte_exit()
      // Render matte source on main canvas starting from base transform.
      // The matte's render_layer will apply its own parent chain from identity,
      // matching lottie-web's mask.renderFrame(true) called from exitLayer.
      let matte_saved_frame = self.current_frame
      self.current_frame = comp_frame
      self.renderer_save()
      self.renderer_set_transform(@math.Matrix::identity())
      self.render_layer(m_layer, scope)
      self.renderer_restore()
      self.current_frame = matte_saved_frame
      // end_matte_exit: source-in composite buffer[1] (layer content) with
      // matte on canvas, then destination-over buffer[0] (background).
      let matte_type = match layer.matte_type {
        Some(1) | Some(3) => 1
        Some(2) | Some(4) => 2
        _ => 1
      }
      self.renderer.end_matte_exit(matte_type)
    }
    None => ()
  }
  if needs_layer_isolation {
    self.renderer.end_layer("source-over")
  }

  self.current_frame = saved_frame
  self.current_comp_frame = saved_comp_frame
  self.current_layer_index = saved_layer_index
  self.current_comp_id = saved_comp_id
}
///|
fn[R : Renderer] Player::apply_layer_fill_effect(
  self : Player[R],
  effect : @model.LayerFillEffect,
  frame : Double,
) -> Unit {
  let color = self.evaluate_vec(effect.color, frame)
  let opacity = self.evaluate_double(effect.opacity, frame)
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
fn find_font_info(
  animation : @model.Animation,
  font_name : String,
) -> @model.FontInfo? {
  match animation.fonts {
    Some(fonts) =>
      for font in fonts {
        if font.name == font_name {
          return Some(font)
        }
      }
    None => ()
  }
  None
}

///|
fn glyph_matches_font(
  glyph : @model.GlyphInfo,
  doc_font_name : String,
  font_info : @model.FontInfo?,
) -> Bool {
  if doc_font_name.contains(glyph.style) {
    match font_info {
      Some(font) => glyph.family == "" || glyph.family == font.family
      None => true
    }
  } else {
    false
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

fn[R : Renderer] render_text_glyph_paints(
  player : Player[R],
  fill_r : Int,
  fill_g : Int,
  fill_b : Int,
  fill_opacity : Double,
  stroke_r : Int,
  stroke_g : Int,
  stroke_b : Int,
  stroke_opacity : Double,
  stroke_width : Double,
  stroke_over_fill : Bool,
) -> Unit {
  if stroke_over_fill {
    player.renderer.fill(fill_r, fill_g, fill_b, fill_opacity)
    if stroke_width > 0.0 {
      player.renderer.stroke(
        stroke_r,
        stroke_g,
        stroke_b,
        stroke_opacity,
        stroke_width,
      )
    }
  } else {
    if stroke_width > 0.0 {
      player.renderer.stroke(
        stroke_r,
        stroke_g,
        stroke_b,
        stroke_opacity,
        stroke_width,
      )
    }
    player.renderer.fill(fill_r, fill_g, fill_b, fill_opacity)
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
              let saved_comp_id = self.current_comp_id
              self.current_frame = precomp_frame
              self.current_comp_id = ref_id
              self.renderer_save()
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
              self.renderer_restore()
              self.current_frame = saved_frame
              self.current_comp_id = saved_comp_id
              break
            }
          }
        _ => ()
      }
    Image(ref_id) =>
      match self.animation.assets {
        Some(assets) =>
          for i = 0; i < assets.length(); i = i + 1 {
            let asset = assets[i]
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
              self.renderer.draw_image(src, w.to_double(), h.to_double(), i)
              break
            }
          }
        _ => ()
      }
    Text(data) => {
      let doc = @runtime.evaluate_text_document_property(
        data.text,
        self.current_comp_frame,
      )
        if doc.text != "" {
          match self.animation.glyphs {
            Some(glyphs) =>
            self.render_text_with_glyphs(
              doc,
              data.animators,
              data.anchor_grouping,
              data.grouping_alignment,
              glyphs,
            )
            None => {
              let (r, g, b) = color_rgb_from_vec(doc.fill_color)
              self.renderer.draw_text(doc.text, doc.font, doc.size, r, g, b, 1.0, doc.justify)
          }
        }
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
  let mut draw_items : Array[@model.Shape] = []
  let mut draw_path_snapshots : Array[Array[@model.BezierPath]] = []
  let mut draw_item_path_modifiers : Array[Array[@model.Shape]] = []
  let mut draw_item_matrices : Array[@math.Matrix] = []
  let mut draw_item_opacities : Array[Double] = []
  for item_idx = 0; item_idx < items.length(); item_idx = item_idx + 1 {
    let item = items[item_idx]
    match item.data {
      Transform(_) => ()
      Group(nested) =>
        if !shape_group_has_paint(nested) {
          // Path-only group: render now so its paths accumulate into
          // current_paths before the next paint op snapshots them.
          self.render_shape(item)
        } else {
          // Painted group participates in z-order with sibling paint ops.
          draw_items.push(item)
          draw_path_snapshots.push([])
          draw_item_path_modifiers.push([])
          draw_item_matrices.push(@math.Matrix::identity())
          draw_item_opacities.push(1.0)
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
        draw_item_matrices.push(@math.Matrix::identity())
        draw_item_opacities.push(1.0)
      }
      TrimPath(t) => {
        // Keep existing behavior for currently accumulated (non-deferred) paths.
        self.render_shape(item)
        // Trim Paths in lottie-web affect preceding drawable content in the same
        // shape list. Our paint ops and painted groups are deferred for z-order,
        // so we need to also apply this modifier to already collected draw items.
        let start = self.evaluate_double(t.start, self.current_comp_frame)
        let end = self.evaluate_double(t.end, self.current_comp_frame)
        let offset = self.evaluate_double(t.offset, self.current_comp_frame)
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
      Repeater(rep) => {
        let repeater_source_items = []
        for source_idx = 0; source_idx < item_idx; source_idx = source_idx + 1 {
          repeater_source_items.push(items[source_idx])
        }
        if shape_group_has_paint(repeater_source_items) {
          self.current_paths = []
          draw_items = []
          draw_path_snapshots = []
          draw_item_path_modifiers = []
          draw_item_matrices = []
          draw_item_opacities = []

          let copies = self.evaluate_double(rep.copies, self.current_comp_frame).to_int()
          let offset = self.evaluate_double(rep.offset, self.current_comp_frame)
          let tr_matrix = self.evaluate_transform(rep.transform, self.current_comp_frame)
          let so = self.evaluate_double(rep.start_opacity, self.current_comp_frame)
          let eo = self.evaluate_double(rep.end_opacity, self.current_comp_frame)
          let needs_opacity = (so - eo).abs() > shape_epsilon ||
            (so - 100.0).abs() > shape_epsilon
          let repeated_group = @model.Shape::new(
            shape_type="gr",
            data=@model.ShapeData::new_group(repeater_source_items),
          )
          let start_idx = if rep.composite == 1 { 0 } else { copies - 1 }
          let end_idx = if rep.composite == 1 { copies } else { -1 }
          let step = if rep.composite == 1 { 1 } else { -1 }
          let mut copy_idx = start_idx
          while (if step == 1 { copy_idx < end_idx } else { copy_idx > end_idx }) {
            let mut m = @math.Matrix::identity()
            let total_steps = copy_idx.to_double() + offset
            for _step = 0; _step < total_steps.to_int(); _step = _step + 1 {
              m = m.multiply(tr_matrix)
            }
            let opacity = if needs_opacity {
              let t = if copies > 1 {
                copy_idx.to_double() / (copies - 1).to_double()
              } else {
                0.0
              }
              (so + (eo - so) * t) / 100.0
            } else {
              1.0
            }
            draw_items.push(repeated_group)
            draw_path_snapshots.push([])
            draw_item_path_modifiers.push([])
            draw_item_matrices.push(m)
            draw_item_opacities.push(opacity)
            copy_idx = copy_idx + step
          }
        } else {
          self.render_shape(item)
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
    let draw_matrix = draw_item_matrices[i]
    let draw_opacity = draw_item_opacities[i]
    let needs_wrapper = draw_opacity < repeater_opacity_threshold ||
      draw_matrix != @math.Matrix::identity()
    if needs_wrapper {
      self.renderer_save()
      self.renderer_concat_transform(draw_matrix)
      if draw_opacity < repeater_opacity_threshold {
        self.renderer.set_opacity(draw_opacity)
      }
    }
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
          let group_items_with_modifiers = []
          for nested_item in nested {
            group_items_with_modifiers.push(nested_item)
          }
          for modifier in modifiers {
            group_items_with_modifiers.push(modifier)
          }
          let decorated_group = @model.Shape::new(
            shape_type = draw_items[i].shape_type,
            data = @model.ShapeData::new_group(group_items_with_modifiers),
          )
          self.render_shape(decorated_group)
        }
      }
      _ => ()
    }
    if needs_wrapper {
      self.renderer_restore()
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
      self.renderer_save()
      let old_paths = self.current_paths
      self.current_paths = []
      let group_has_paint_ops = shape_group_has_paint(items)

      // Evaluate group transform and apply it to the renderer.
      let mut group_matrix = @math.Matrix::identity()
      for item in items {
        match item.data {
          Transform(tr) => {
            group_matrix = self.evaluate_transform(tr, self.current_comp_frame)
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
      if !group_has_paint_ops {
        for p in inner_paths {
          self.current_paths.push(transform_path(p, group_matrix))
        }
      }
      self.renderer_restore()
    }
    Rect(r) => {
      let p = self.evaluate_vec(r.position, self.current_comp_frame)
      let s = self.evaluate_vec(r.size, self.current_comp_frame)
      let corner_r = self.evaluate_double(r.roundness, self.current_comp_frame)
      let x = get_vec_at(p, 0, 0.0)
      let y = get_vec_at(p, 1, 0.0)
      let w = get_vec_at(s, 0, 0.0)
      let h = get_vec_at(s, 1, 0.0)
      self.current_paths.push(create_rect_path(x, y, w, h, corner_r, r.direction))
    }
    Ellipse(e) => {
      let p = self.evaluate_vec(e.position, self.current_comp_frame)
      let s = self.evaluate_vec(e.size, self.current_comp_frame)
      let cx = get_vec_at(p, 0, 0.0)
      let cy = get_vec_at(p, 1, 0.0)
      let rx = get_vec_at(s, 0, 0.0) / 2.0
      let ry = get_vec_at(s, 1, 0.0) / 2.0
      self.current_paths.push(create_ellipse_path(cx, cy, rx, ry, e.direction))
    }
    Path(p) => {
      let path = self.evaluate_path(p.path, self.current_comp_frame)
      self.current_paths.push(path)
    }
    Fill(f) => {
      let color_vec = self.evaluate_vec(f.color, self.current_comp_frame)
      let opacity = self.evaluate_double(f.opacity, self.current_comp_frame)
      let (r, g, b) = color_rgb_from_vec(color_vec)
      self.renderer.set_fill_rule(if f.fill_rule == 2 { "evenodd" } else { "nonzero" })
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.fill(r, g, b, opacity / 100.0)
    }
    Stroke(s) => {
      let color_vec = self.evaluate_vec(s.color, self.current_comp_frame)
      let opacity = self.evaluate_double(s.opacity, self.current_comp_frame)
      let width = self.evaluate_double(s.width, self.current_comp_frame)
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
          let v = self.evaluate_double(d.value, self.current_comp_frame)
          if d.name == "o" {
            dash_offset = v
          } else {
            dash_array.push(v)
          }
        }
        self.renderer.set_line_dash(dash_array, dash_offset)
      } else {
        // Reset any previously set dash pattern so it does not bleed into
        // subsequent strokes within the same save/restore scope.
        self.renderer.set_line_dash([], 0.0)
      }
      self.renderer.stroke(r, g, b, opacity / 100.0, width)
    }
    GradientFill(f) => {
      let start_p = self.evaluate_vec(f.start_point, self.current_comp_frame)
      let end_p = self.evaluate_vec(f.end_point, self.current_comp_frame)
      let stops = self.evaluate_vec(f.gradient_colors.color_stops, self.current_comp_frame)
      let opacity = self.evaluate_double(f.opacity, self.current_comp_frame)
      self.renderer.set_fill_rule(if f.fill_rule == 2 { "evenodd" } else { "nonzero" })
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
      let start_p = self.evaluate_vec(s.start_point, self.current_comp_frame)
      let end_p = self.evaluate_vec(s.end_point, self.current_comp_frame)
      let stops = self.evaluate_vec(s.gradient_colors.color_stops, self.current_comp_frame)
      let opacity = self.evaluate_double(s.opacity, self.current_comp_frame)
      let width = self.evaluate_double(s.width, self.current_comp_frame)
      self.renderer.begin_path()
      for p in self.current_paths {
        self.draw_lottie_path(p)
      }
      self.renderer.set_stroke_style(s.line_cap, s.line_join, s.miter_limit)
      if s.dashes.length() > 0 {
        let dash_array : Array[Double] = []
        let mut dash_offset = 0.0
        for d in s.dashes {
          let v = self.evaluate_double(d.value, self.current_comp_frame)
          if d.name == "o" {
            dash_offset = v
          } else {
            dash_array.push(v)
          }
        }
        self.renderer.set_line_dash(dash_array, dash_offset)
      } else {
        self.renderer.set_line_dash([], 0.0)
      }
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
      let matrix = self.evaluate_transform(tr, self.current_comp_frame)
      self.renderer_concat_transform(matrix)
      let opacity = self.evaluate_double(
        tr.opacity,
        self.current_comp_frame,
      )
      self.renderer.set_opacity(opacity / 100.0)
    }
    TrimPath(t) => {
      let start = self.evaluate_double(t.start, self.current_comp_frame)
      let end = self.evaluate_double(t.end, self.current_comp_frame)
      let offset = self.evaluate_double(t.offset, self.current_comp_frame)
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
      let copies = self.evaluate_double(rep.copies, self.current_comp_frame).to_int()
      let offset = self.evaluate_double(rep.offset, self.current_comp_frame)
      let tr_matrix = self.evaluate_transform(rep.transform, self.current_comp_frame)
      let so = self.evaluate_double(rep.start_opacity, self.current_comp_frame)
      let eo = self.evaluate_double(rep.end_opacity, self.current_comp_frame)

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
          self.renderer_save()
          self.renderer.set_opacity(copy_opacity / 100.0)
        }

        for path in original_paths {
          new_paths.push(transform_path(path, m))
        }

        if needs_opacity {
          self.renderer_restore()
        }

        i = i + step
      }
      self.current_paths = new_paths
    }
    MergePaths(_merge) =>
      // lottie-web's SVG and canvas renderers do not register MergePaths (ty="mm")
      // as a shape modifier and do not handle it in any special way — it is
      // effectively ignored. Fill-rule is controlled by the fill shape's own
      // `r` property (1=nonzero, 2=evenodd), not by MergePaths merge mode.
      // We match that behavior here and treat MergePaths as a no-op.
      ()
    Rounding(rounding) => {
      let radius = self.evaluate_double(
        rounding.radius,
        self.current_comp_frame,
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
    let is_first = idx == 0 && !path.closed
    let is_last = idx == n - 1 && !path.closed

    // Check if this is a sharp corner (zero tangents)
    let it0 = get_pt_at(i_t, idx, 0)
    let it1 = get_pt_at(i_t, idx, 1)
    let ot0 = get_pt_at(o_t, idx, 0)
    let ot1 = get_pt_at(o_t, idx, 1)
    let is_sharp = it0.abs() < shape_epsilon &&
      it1.abs() < shape_epsilon &&
      ot0.abs() < shape_epsilon &&
      ot1.abs() < shape_epsilon

    if !is_sharp || is_first || is_last {
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
#cfg(any(target="js", target="wasm", target="wasm-gc"))
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
  direction : Int,
) -> @model.BezierPath {
  let half_w = w.abs() / 2.0
  let half_h = h.abs() / 2.0
  let max_r = if half_w < half_h { half_w } else { half_h }
  let radius = if r < 0.0 {
    0.0
  } else if r > max_r {
    max_r
  } else {
    r
  }
  if radius <= 0.0 {
    // lottie-web: `if (this.d === 2 || this.d === 1)` produces CW; else (d=3) CCW.
    if direction == shape_direction_ccw {
      // Counter-clockwise: top-right → top-left → bottom-left → bottom-right
      return @model.BezierPath::new_rect_ccw(x, y, w, h)
    } else {
      return @model.BezierPath::new_rect(x, y, w, h)
    }
  }
  let left = x - w / 2.0
  let right = x + w / 2.0
  let top = y - h / 2.0
  let bottom = y + h / 2.0
  // 4 * (sqrt(2) - 1) / 3 ≈ 0.5522847498307936: standard cubic Bézier approximation factor for
  // quarter-circle arcs, matching lottie-web rounded-rectangle corners.
  let kappa = 0.5522847498307936
  let cp = radius * kappa
  // lottie-web: `if (this.d === 2 || this.d === 1)` produces CW; else (d=3) CCW.
  if direction == shape_direction_ccw {
    @model.BezierPath::new(
      vertices=[
        [right - radius, top],
        [left + radius, top],
        [left, top + radius],
        [left, bottom - radius],
        [left + radius, bottom],
        [right - radius, bottom],
        [right, bottom - radius],
        [right, top + radius],
      ],
      in_tangents=[
        [cp, 0.0],
        [0.0, 0.0],
        [0.0, -cp],
        [0.0, 0.0],
        [-cp, 0.0],
        [0.0, 0.0],
        [0.0, cp],
        [0.0, 0.0],
      ],
      out_tangents=[
        [0.0, 0.0],
        [-cp, 0.0],
        [0.0, 0.0],
        [0.0, cp],
        [0.0, 0.0],
        [cp, 0.0],
        [0.0, 0.0],
        [0.0, -cp],
      ],
      closed=true,
    )
  } else {
    @model.BezierPath::new(
      vertices=[
        [left + radius, top],
        [right - radius, top],
        [right, top + radius],
        [right, bottom - radius],
        [right - radius, bottom],
        [left + radius, bottom],
        [left, bottom - radius],
        [left, top + radius],
      ],
      in_tangents=[
        [-cp, 0.0],
        [0.0, 0.0],
        [0.0, -cp],
        [0.0, 0.0],
        [cp, 0.0],
        [0.0, 0.0],
        [0.0, cp],
        [0.0, 0.0],
      ],
      out_tangents=[
        [0.0, 0.0],
        [cp, 0.0],
        [0.0, 0.0],
        [0.0, cp],
        [0.0, 0.0],
        [-cp, 0.0],
        [0.0, 0.0],
        [0.0, -cp],
      ],
      closed=true,
    )
  }
}

///|
let shape_direction_ccw = 3

///|
fn create_ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  direction : Int,
) -> @model.BezierPath {
  let kappa = 0.55228475
  let ox = rx * kappa
  let oy = ry * kappa
  // lottie-web: `_cw = this.d !== 3` — d=3 produces counter-clockwise winding,
  // any other value (including 1, 2) produces clockwise winding.
  if direction != shape_direction_ccw {
    // Clockwise: top → right → bottom → left
    @model.BezierPath::new(
      vertices=[[cx, cy - ry], [cx + rx, cy], [cx, cy + ry], [cx - rx, cy]],
      in_tangents=[[-ox, 0.0], [0.0, -oy], [ox, 0.0], [0.0, oy]],
      out_tangents=[[ox, 0.0], [0.0, oy], [-ox, 0.0], [0.0, -oy]],
      closed=true,
    )
  } else {
    // Counter-clockwise: top → left → bottom → right
    @model.BezierPath::new(
      vertices=[[cx, cy - ry], [cx - rx, cy], [cx, cy + ry], [cx + rx, cy]],
      in_tangents=[[ox, 0.0], [0.0, -oy], [-ox, 0.0], [0.0, oy]],
      out_tangents=[[-ox, 0.0], [0.0, oy], [ox, 0.0], [0.0, -oy]],
      closed=true,
    )
  }
}

///|
/// Sampling count for cubic arc-length approximation in Trim Path extraction.
/// 50 keeps frame drift low on complex curves while staying fast enough for tests/demo.
let cubic_subdivision_intervals = 50

///|
let trim_t_epsilon = 0.000000001

///|
/// Fallback advance width ratio when no glyph is found for a character.
/// Approximates a typical character width as a fraction of the font size.
let glyph_fallback_advance_ratio = 0.6

///|
/// Small epsilon for floating-point comparisons in shape modifiers
let shape_epsilon = 0.001

///|
/// Threshold for deciding whether an opacity multiplier differs enough from 1.0
/// to require an extra repeater wrapper on the renderer stack. Values within
/// 1e-6 of full opacity are treated as 1.0 to avoid redundant save/restore
/// wrappers from floating-point interpolation noise.
let repeater_opacity_threshold = 0.999999

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

  if s_val == e_val {
    return []
  }

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
  if s_val == e_val {
    return []
  }
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
  if start_norm == end_norm {
    return []
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

  // Empty trim: when start equals end, nothing is visible
  if s == e {
    return []
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
  } else if start_norm == end_norm {
    // After offset normalization, start and end are at the same point:
    // this means the full path is selected (wraps all the way around).
    return [path]
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
  let pt = self.evaluate_double(sr.points, self.current_comp_frame)
  let p = self.evaluate_vec(sr.position, self.current_comp_frame)
  let r = self.evaluate_double(sr.rotation, self.current_comp_frame)
  let or = self.evaluate_double(sr.outer_radius, self.current_comp_frame)
  let or_round = self.evaluate_double(
    sr.outer_roundness,
    self.current_comp_frame,
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
    let ir = self.evaluate_double(sr.inner_radius, self.current_comp_frame)
    let ir_round = self.evaluate_double(
      sr.inner_roundness,
      self.current_comp_frame,
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

///|
fn compute_animator_mult(
  selector : @model.TextAnimatorSelector,
  char_index : Int,
  total_chars : Int,
  frame : Double,
) -> Double {
  if total_chars <= 0 {
    return 0.0
  }
  let offset_raw = @runtime.evaluate_double_property(selector.offset, frame)
  let divisor = if selector.range_units == 2 { 1.0 } else { 100.0 / total_chars.to_double() }
  let o = offset_raw / divisor
  let s_raw = @runtime.evaluate_double_property(selector.range_start, frame)
  let s_val = s_raw / divisor + o
  let e_raw = @runtime.evaluate_double_property(selector.range_end, frame)
  let e_val = e_raw / divisor + o
  let (s_final, e_final) = if s_val <= e_val {
    (s_val, e_val)
  } else {
    (e_val, s_val)
  }
  let ne = @runtime.evaluate_double_property(selector.ease_high, frame)
  let xe = @runtime.evaluate_double_property(selector.ease_low, frame)
  let (x1, y1) = if ne > 0.0 { (ne / 100.0, 0.0) } else { (0.0, -ne / 100.0) }
  let (x2, y2) = if xe > 0.0 {
    (1.0 - xe / 100.0, 1.0)
  } else {
    (1.0, 1.0 + xe / 100.0)
  }
  let ind = char_index.to_double()
  let sh = selector.shape
  let mult = match sh {
    2 => {
      if e_final == s_final {
        if ind >= e_final { 1.0 } else { 0.0 }
      } else {
        let v = 0.5 / (e_final - s_final) + (ind - s_final) / (e_final - s_final)
        if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
      }
    }
    3 => {
      if e_final == s_final {
        if ind >= e_final { 0.0 } else { 1.0 }
      } else {
        let v = 0.5 / (e_final - s_final) + (ind - s_final) / (e_final - s_final)
        let clamped = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
        1.0 - clamped
      }
    }
    4 => {
      if e_final == s_final {
        0.0
      } else {
        let v = 0.5 / (e_final - s_final) + (ind - s_final) / (e_final - s_final)
        let mut clamped = if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
        if clamped < 0.5 {
          clamped = clamped * 2.0
        } else {
          clamped = 1.0 - 2.0 * (clamped - 0.5)
        }
        clamped
      }
    }
    5 => {
      if e_final == s_final {
        0.0
      } else {
        let tot = e_final - s_final
        let clamped_ind = {
          let v = ind + 0.5 - s_final
          if v < 0.0 {
            0.0
          } else if v > tot {
            tot
          } else {
            v
          }
        }
        let x = -tot / 2.0 + clamped_ind
        let a = tot / 2.0
        @math.sqrt(1.0 - (x * x) / (a * a))
      }
    }
    6 => {
      if e_final == s_final {
        0.0
      } else {
        let tot = e_final - s_final
        let clamped_ind = {
          let v = ind + 0.5 - s_final
          if v < 0.0 {
            0.0
          } else if v > tot {
            tot
          } else {
            v
          }
        }
        let pi = 3.141592653589793
        (1.0 + @std_math.cos(pi + pi * 2.0 * clamped_ind / tot)) / 2.0
      }
    }
    _ => {
      if ind >= s_final.floor() {
        let m = if ind - s_final < 0.0 {
          let v = (if e_final < 1.0 { e_final } else { 1.0 }) - (s_final - ind)
          if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
        } else {
          let v = e_final - ind
          if v < 0.0 { 0.0 } else if v > 1.0 { 1.0 } else { v }
        }
        m
      } else {
        0.0
      }
    }
  }
  let eased = @math.solve_cubic_bezier_easing(x1, y1, x2, y2, mult)
  let amount = @runtime.evaluate_double_property(selector.amount, frame)
  eased * amount / 100.0
}

///|
fn is_text_newline_char(ch : Char) -> Bool {
  ch == '\r' || ch == '\n'
}

///|
fn should_advance_selector_index(
  chars : Array[Char],
  ci : Int,
  based_on : Int,
) -> Bool {
  let ch = chars[ci]
  if is_text_newline_char(ch) {
    return based_on != 2
  }
  match based_on {
    2 => ch != ' '
    3 => ch == ' ' || ci == chars.length() - 1
    4 => ci == chars.length() - 1
    _ => true
  }
}

///|
fn count_selector_total_chars(chars : Array[Char], based_on : Int) -> Int {
  let mut total = 0
  for ci = 0; ci < chars.length(); ci = ci + 1 {
    if should_advance_selector_index(chars, ci, based_on) {
      total = total + 1
    }
  }
  total
}

///|
fn build_selector_indices(chars : Array[Char], based_on : Int) -> Array[Int] {
  let indices : Array[Int] = []
  let mut current = 0
  for ci = 0; ci < chars.length(); ci = ci + 1 {
    indices.push(current)
    if should_advance_selector_index(chars, ci, based_on) {
      current = current + 1
    }
  }
  indices
}

fn build_text_animator_random_order(total : Int, seed : Int) -> Array[Int] {
  let order : Array[Int] = []
  if total <= 0 {
    return order
  }
  let step = if total > 1 { total - 1 } else { 1 }
  let offset = ((seed * 3 + 1) % total + total) % total
  for i = 0; i < total; i = i + 1 {
    order.push((i * step + offset) % total)
  }
  order
}

///|
fn build_text_letter_group_metrics(
  chars : Array[Char],
  advances : Array[Double],
  anchor_grouping : Int,
) -> (Array[Double], Array[Double]) {
  let grouped_widths : Array[Double] = []
  let grouped_offsets : Array[Double] = []
  let n = chars.length()
  let mut current_size = 0.0
  let mut current_pos = 0
  for i = 0; i < n; i = i + 1 {
    let ch = chars[i]
    let advance = advances[i]
    grouped_widths.push(advance)
    grouped_offsets.push(current_size)
    match anchor_grouping {
      2 => {
        current_size = current_size + advance
        if ch == ' ' || ch == '\r' || i == n - 1 {
          let final_size = if ch == ' ' || ch == '\r' {
            current_size - advance
          } else {
            current_size
          }
          for j = current_pos; j <= i; j = j + 1 {
            grouped_widths[j] = final_size
          }
          current_pos = i + 1
          current_size = 0.0
        }
      }
      3 => {
        current_size = current_size + advance
        if ch == '\r' || i == n - 1 {
          let final_size = if ch == '\r' { current_size - advance } else { current_size }
          for j = current_pos; j <= i; j = j + 1 {
            grouped_widths[j] = final_size
          }
          current_pos = i + 1
          current_size = 0.0
        }
      }
      _ => ()
    }
  }
  (grouped_widths, grouped_offsets)
}

///|
fn get_text_group_alignment(
  grouping_alignment : @model.LottieProperty[Array[Double]],
  frame : Double,
) -> (Double, Double) {
  let alignment = @runtime.evaluate_vec_property(grouping_alignment, frame)
  (get_vec_at(alignment, 0, 0.0), get_vec_at(alignment, 1, 0.0))
}

///|
fn get_text_group_pivot(
  group_width : Double,
  group_offset : Double,
  align_x : Double,
  align_y : Double,
  y_off : Double,
) -> (Double, Double, Double) {
  let offf = group_width / 2.0 - group_offset
  let pivot_x = (align_x * group_width) * 0.005
  let pivot_y = (align_y * y_off) * 0.01
  (offf, pivot_x, pivot_y)
}

///|
fn[R : Renderer] Player::emit_glyph_shape_paths(
  self : Player[R],
  shapes : Array[@model.Shape],
) -> Unit {
  for shape in shapes {
    match shape.hidden {
      Some(true) => continue
      _ => ()
    }
    match shape.data {
      @model.ShapeData::Path(p) => {
        let path = self.evaluate_path(p.path, self.current_comp_frame)
        self.draw_lottie_path(path)
      }
      @model.ShapeData::Group(items) =>
        self.emit_glyph_shape_paths(items)
      _ => ()
    }
  }
}

///|
fn[R : Renderer] Player::render_text_with_glyphs(
  self : Player[R],
  doc : @model.TextDocument,
  animators : Array[@model.TextAnimator],
  anchor_grouping : Int,
  grouping_alignment : @model.LottieProperty[Array[Double]],
  glyphs : Array[@model.GlyphInfo],
) -> Unit {
  // Base fill color from text document (normalized 0-1)
  let base_fill_r = get_vec_at(doc.fill_color, 0, 0.0)
  let base_fill_g = get_vec_at(doc.fill_color, 1, 0.0)
  let base_fill_b = get_vec_at(doc.fill_color, 2, 0.0)
  let base_stroke_r = get_vec_at(doc.stroke_color, 0, 0.0)
  let base_stroke_g = get_vec_at(doc.stroke_color, 1, 0.0)
  let base_stroke_b = get_vec_at(doc.stroke_color, 2, 0.0)
  let text = doc.text
  let chars = text.to_array()
  let n = chars.length()
  let base_tracking = doc.tracking * 0.001 * doc.size
  let font_info = find_font_info(self.animation, doc.font)

  // Compute advance widths and total width for justification
  let mut total_width = 0.0
  let char_advances : Array[Double] = []
  for ci = 0; ci < n; ci = ci + 1 {
    let ch = chars[ci]
    let ch_str = ch.to_string()
    let mut found = false
    for g in glyphs {
      if g.ch == ch_str && glyph_matches_font(g, doc.font, font_info) {
        let advance = g.advance_width * doc.size / 100.0
        char_advances.push(advance)
        total_width += advance
        if ci < n - 1 {
          total_width += base_tracking
        }
        found = true
        break
      }
    }
    if !found {
      let fallback = doc.size * glyph_fallback_advance_ratio
      char_advances.push(fallback)
      total_width += fallback
      if ci < n - 1 {
        total_width += base_tracking
      }
    }
  }
  let char_indices_by_mode = [
    build_selector_indices(chars, 1),
    build_selector_indices(chars, 2),
    build_selector_indices(chars, 3),
    build_selector_indices(chars, 4),
  ]
  let selector_totals_by_mode = [
    count_selector_total_chars(chars, 1),
    count_selector_total_chars(chars, 2),
    count_selector_total_chars(chars, 3),
    count_selector_total_chars(chars, 4),
  ]
  let (group_widths, group_offsets) = build_text_letter_group_metrics(
    chars,
    char_advances,
    anchor_grouping,
  )
  let (align_x, align_y) = get_text_group_alignment(
    grouping_alignment,
    self.current_comp_frame,
  )
  let y_off = doc.size * 1.2 * 0.714

  // Starting x based on justification
  let mut cursor_x = match doc.justify {
    1 => -total_width
    2 => -total_width / 2.0
    _ => 0.0
  }

  let random_orders : Array[Array[Int]] = []
  for ai = 0; ai < animators.length(); ai = ai + 1 {
    let selector = animators[ai].selector
    let mode_idx = if selector.based_on >= 1 && selector.based_on <= 4 {
      selector.based_on - 1
    } else {
      0
    }
    if selector.randomize == 1 {
      let total_chars = selector_totals_by_mode[mode_idx]
      random_orders.push(
        build_text_animator_random_order(total_chars, ai + text.length()),
      )
    } else {
      random_orders.push([])
    }
  }
  for ci = 0; ci < n; ci = ci + 1 {
    let ch = chars[ci]
    let ch_str = ch.to_string()
    let advance = char_advances[ci]

    // Compute animator effects for this character
    let mut anim_scale_x = 1.0
    let mut anim_scale_y = 1.0
    let mut anim_pos_x = 0.0
    let mut anim_pos_y = 0.0
    let mut anim_rotation = 0.0
    let mut anim_tracking = 0.0
    let mut char_opacity = 1.0
    // Keep fill color in normalized [0,1] space for blending
    let mut char_fill_r = base_fill_r
    let mut char_fill_g = base_fill_g
    let mut char_fill_b = base_fill_b
    let mut char_stroke_r = base_stroke_r
    let mut char_stroke_g = base_stroke_g
    let mut char_stroke_b = base_stroke_b
    let mut char_stroke_width = doc.stroke_width
    for ai = 0; ai < animators.length(); ai = ai + 1 {
      let anim = animators[ai]
      let sel = anim.selector
      let mode_idx = if sel.based_on >= 1 && sel.based_on <= 4 {
        sel.based_on - 1
      } else {
        0
      }
      let total_chars = selector_totals_by_mode[mode_idx]
      let base_char_anim_idx = char_indices_by_mode[mode_idx][ci]
      let char_anim_idx = if sel.randomize == 1 &&
          base_char_anim_idx >= 0 &&
          base_char_anim_idx < random_orders[ai].length() {
        random_orders[ai][base_char_anim_idx]
      } else {
        base_char_anim_idx
      }
      let mult = compute_animator_mult(
        sel, char_anim_idx, total_chars, self.current_comp_frame,
      )
      match anim.properties.scale {
        Some(scale_prop) => {
          let sv = self.evaluate_vec(
            scale_prop, self.current_comp_frame,
          )
          let sx = if sv.length() > 0 { sv[0] } else { 100.0 }
          let sy = if sv.length() > 1 { sv[1] } else { 100.0 }
          let sx_delta = sx / 100.0 - 1.0
          let sy_delta = sy / 100.0 - 1.0
          anim_scale_x = anim_scale_x * (1.0 + mult * sx_delta)
          anim_scale_y = anim_scale_y * (1.0 + mult * sy_delta)
        }
        None => ()
      }
      match anim.properties.position {
        Some(pos_prop) => {
          let pv = self.evaluate_vec(
            pos_prop, self.current_comp_frame,
          )
          let px = if pv.length() > 0 { pv[0] } else { 0.0 }
          let py = if pv.length() > 1 { pv[1] } else { 0.0 }
          anim_pos_x = anim_pos_x + mult * px
          anim_pos_y = anim_pos_y + mult * py
        }
        None => ()
      }
      match anim.properties.rotation {
        Some(rotation_prop) => {
          let rv = self.evaluate_double(
            rotation_prop, self.current_comp_frame,
          )
          anim_rotation = anim_rotation + mult * rv
        }
        None => ()
      }
      match anim.properties.fill_color {
        Some(fc_prop) => {
          let fv = self.evaluate_vec(
            fc_prop, self.current_comp_frame,
          )
          // fv values are in [0,1] normalized range; blend toward anim color
          let ar = get_vec_at(fv, 0, 0.0)
          let ag = get_vec_at(fv, 1, 0.0)
          let ab = get_vec_at(fv, 2, 0.0)
          char_fill_r = char_fill_r + mult * (ar - char_fill_r)
          char_fill_g = char_fill_g + mult * (ag - char_fill_g)
          char_fill_b = char_fill_b + mult * (ab - char_fill_b)
        }
        None => ()
      }
      match anim.properties.stroke_color {
        Some(sc_prop) => {
          let sv = self.evaluate_vec(
            sc_prop, self.current_comp_frame,
          )
          let ar = get_vec_at(sv, 0, 0.0)
          let ag = get_vec_at(sv, 1, 0.0)
          let ab = get_vec_at(sv, 2, 0.0)
          char_stroke_r = char_stroke_r + mult * (ar - char_stroke_r)
          char_stroke_g = char_stroke_g + mult * (ag - char_stroke_g)
          char_stroke_b = char_stroke_b + mult * (ab - char_stroke_b)
        }
        None => ()
      }
      match anim.properties.stroke_width {
        Some(sw_prop) => {
          let sw = self.evaluate_double(
            sw_prop, self.current_comp_frame,
          )
          char_stroke_width = char_stroke_width + mult * sw
        }
        None => ()
      }
      match anim.properties.opacity {
        Some(opacity_prop) => {
          let ov = self.evaluate_double(
            opacity_prop, self.current_comp_frame,
          ) / 100.0
          // Match lottie-web's per-selector opacity blend instead of a plain lerp.
          char_opacity = char_opacity + ((ov * mult) - char_opacity) * mult
        }
        None => ()
      }
      match anim.properties.tracking {
        Some(tracking_prop) => {
          let tv = self.evaluate_double(
            tracking_prop, self.current_comp_frame,
          )
          anim_tracking = anim_tracking + mult * tv
        }
        None => ()
      }
    }
    if ci > 0 || doc.justify != 0 {
      cursor_x = cursor_x + anim_tracking
    }
    let fill_opacity = if char_opacity < 0.0 {
      0.0
    } else if char_opacity > 1.0 {
      1.0
    } else {
      char_opacity
    }
    let fill_r = color_channel_to_u8(char_fill_r)
    let fill_g = color_channel_to_u8(char_fill_g)
    let fill_b = color_channel_to_u8(char_fill_b)
    let stroke_r = color_channel_to_u8(char_stroke_r)
    let stroke_g = color_channel_to_u8(char_stroke_g)
    let stroke_b = color_channel_to_u8(char_stroke_b)
    let stroke_width = if char_stroke_width < 0.0 {
      0.0
    } else {
      char_stroke_width
    }
    let stroke_opacity = 1.0

    // Find and render glyph
    for g in glyphs {
      if g.ch == ch_str && glyph_matches_font(g, doc.font, font_info) {
        let glyph_scale = doc.size / 100.0
        let char_scale_x = glyph_scale * anim_scale_x
        let char_scale_y = glyph_scale * anim_scale_y
        let (offf, pivot_x, pivot_y) = get_text_group_pivot(
          group_widths[ci],
          group_offsets[ci],
          align_x,
          align_y,
          y_off,
        )
        let saved_paths = self.current_paths
        self.current_paths = []
        self.renderer_save()
        let mut glyph_matrix = @math.Matrix::identity()
        glyph_matrix = glyph_matrix.translate(cursor_x, 0.0)
        glyph_matrix = glyph_matrix.translate(0.0, -doc.baseline_shift)
        glyph_matrix = glyph_matrix.translate(offf, 0.0)
        glyph_matrix = glyph_matrix.translate(pivot_x, pivot_y)
        glyph_matrix = glyph_matrix.translate(anim_pos_x, anim_pos_y)
        if anim_rotation != 0.0 {
          glyph_matrix = glyph_matrix.rotate(
            anim_rotation * 3.141592653589793 / 180.0,
          )
        }
        glyph_matrix = glyph_matrix.translate(-pivot_x, -pivot_y)
        glyph_matrix = glyph_matrix.translate(-offf, 0.0)
        glyph_matrix = glyph_matrix.scale(char_scale_x, char_scale_y)
        self.renderer_concat_transform(glyph_matrix)
        self.renderer.begin_path()
        self.emit_glyph_shape_paths(g.shapes)
        self.renderer.set_fill_rule("nonzero")
        render_text_glyph_paints(
          self,
          fill_r,
          fill_g,
          fill_b,
          fill_opacity,
          stroke_r,
          stroke_g,
          stroke_b,
          stroke_opacity,
          stroke_width,
          doc.stroke_over_fill,
        )
        self.current_paths = saved_paths
        self.renderer_restore()
        break
      }
    }

    cursor_x += advance + base_tracking
  }
}
