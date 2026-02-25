pub struct Player[R] {
  animation : @model.Animation
  renderer : R
  mut current_frame : Double
}

pub fn[R] Player::new(
  animation : @model.Animation,
  renderer : R
) -> Player[R] {
  { animation, renderer, current_frame: 0.0 }
}

pub fn[R] Player::set_frame(self : Player[R], frame : Double) -> Unit {
  self.current_frame = frame
}

pub fn[R : Renderer] Player::render(self : Player[R]) -> Unit {
  self.renderer.set_transform(@math.Matrix::identity())
  self.renderer.clear_rect(0.0, 0.0, self.animation.w.to_double(), self.animation.h.to_double())
  
  // Lottie renders layers from bottom to top (reverse order in the array)
  let layers = self.animation.layers
  for i = layers.length() - 1; i >= 0; i = i - 1 {
    let layer = layers[i]
    match layer.hd {
      Some(true) => ()
      _ => self.render_layer(layer, layers)
    }
  }
}

fn[R : Renderer] Player::apply_parent_transform(self : Player[R], parent_ind : Int, scope : Array[@model.Layer]) -> Unit {
  for layer in scope {
    if layer.ind == parent_ind {
      match layer.parent {
        Some(p_ind) => self.apply_parent_transform(p_ind, scope)
        None => ()
      }
      let matrix = @runtime.evaluate_transform(layer.ks, self.current_frame)
      self.renderer.concat_transform(matrix)
      return
    }
  }
}

fn[R : Renderer] Player::render_layer(self : Player[R], layer : @model.Layer, scope : Array[@model.Layer]) -> Unit {
  if self.current_frame < layer.ip || self.current_frame >= layer.op {
    return
  }

  self.renderer.save()
  
  // 0. Apply Parent Transform
  match layer.parent {
    Some(p_ind) => self.apply_parent_transform(p_ind, scope)
    None => ()
  }

  // 1. Apply Layer Transform
  let matrix = @runtime.evaluate_transform(layer.ks, self.current_frame)
  self.renderer.concat_transform(matrix)
  
  // 1.5 Apply Layer Masks
  match layer.masks {
    Some(masks) => {
      let mut has_clip = false
      for mask in masks {
        match mask.mode {
          Add => {
            if not(has_clip) {
              self.renderer.begin_path()
              has_clip = true
            }
            let path_val = @runtime.evaluate_path_property(mask.pt, self.current_frame)
            self.draw_lottie_path(path_val)
          }
          _ => () // Other modes not yet supported
        }
      }
      if has_clip {
        self.renderer.clip()
      }
    }
    None => ()
  }
  
  // 2. Render Layer Content
  match layer.data {
    Shape(shapes) => {
      // Shape layers often have a group of shapes, strokes, and fills
      // Lottie processing: first collect all paths, then apply fill/stroke
      // For simplicity in this scaffold, we visit each shape.
      for shape in shapes {
        self.render_shape(shape)
      }
    }
    Solid(color, w, h) => {
      let _ = color // skip solid color parsing for simplicity or implement it
      self.renderer.begin_path()
      self.renderer.move_to(0.0, 0.0)
      self.renderer.line_to(w.to_double(), 0.0)
      self.renderer.line_to(w.to_double(), h.to_double())
      self.renderer.line_to(0.0, h.to_double())
      self.renderer.close_path()
      // Use gray for Solid if hex parsing not implemented
      self.renderer.fill(128, 128, 128, 1.0)
    }
    PreComp(ref_id, _w, _h) => {
      match self.animation.assets {
        Some(assets) =>
          for asset in assets {
            match asset {
              PreComp(id, layers) if id == ref_id =>
                for i = layers.length() - 1; i >= 0; i = i - 1 {
                  self.render_layer(layers[i], layers)
                }
              _ => ()
            }
          }
        _ => ()
      }
    }
    Image(ref_id) => {
      match self.animation.assets {
        Some(assets) =>
          for asset in assets {
            match asset {
              Image(id, _path, w, h) if id == ref_id =>
                self.renderer.draw_image(id, w.to_double(), h.to_double())
              _ => ()
            }
          }
        _ => ()
      }
    }
    _ => ()
  }
  
  self.renderer.restore()
}

fn[R : Renderer] Player::render_shape(self : Player[R], shape : @model.Shape) -> Unit {
  match shape.hd {
    Some(true) => return
    _ => ()
  }
  match shape.data {
    Group(items) => {
      self.renderer.save()
      
      // AE typically puts the group transform at the end of the shape list,
      // but it applies to all siblings. We find it and apply it first.
      for item in items {
        match item.data {
          Transform(tr) => {
            let matrix = @runtime.evaluate_transform(tr, self.current_frame)
            self.renderer.concat_transform(matrix)
            // Lottie spec: only one transform per group? usually yes.
            // If there are multiple, they are concatenated.
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
      
      self.renderer.restore()
    }
    Rect(r) => {
      let p = @runtime.evaluate_vec_property(r.p, self.current_frame)
      let s = @runtime.evaluate_vec_property(r.s, self.current_frame)
      let corner_r = @runtime.evaluate_double_property(r.r, self.current_frame)
      
      let x = p[0] - s[0] / 2.0
      let y = p[1] - s[1] / 2.0
      let w = s[0]
      let h = s[1]
      
      self.renderer.begin_path()
      if corner_r <= 0.0 {
        self.renderer.move_to(x, y)
        self.renderer.line_to(x + w, y)
        self.renderer.line_to(x + w, y + h)
        self.renderer.line_to(x, y + h)
      } else {
        // Simple rounded rect can be implemented via cubic_to or line_to
        self.renderer.move_to(x + corner_r, y)
        self.renderer.line_to(x + w - corner_r, y)
        // ... corners skipped for brevity in scaffold
        self.renderer.line_to(x + w, y + h)
        self.renderer.line_to(x, y + h)
      }
      self.renderer.close_path()
    }
    Ellipse(e) => {
      let p = @runtime.evaluate_vec_property(e.p, self.current_frame)
      let s = @runtime.evaluate_vec_property(e.s, self.current_frame)
      let cx = p[0]
      let cy = p[1]
      let rx = s[0] / 2.0
      let ry = s[1] / 2.0
      
      // Draw ellipse using 4 cubic bezier segments
      let kappa = 0.55228475
      let ox = rx * kappa
      let oy = ry * kappa
      
      self.renderer.begin_path()
      self.renderer.move_to(cx, cy - ry)
      self.renderer.cubic_to(cx + ox, cy - ry, cx + rx, cy - oy, cx + rx, cy)
      self.renderer.cubic_to(cx + rx, cy + oy, cx + ox, cy + ry, cx, cy + ry)
      self.renderer.cubic_to(cx - ox, cy + ry, cx - rx, cy + oy, cx - rx, cy)
      self.renderer.cubic_to(cx - rx, cy - oy, cx - ox, cy - ry, cx, cy - ry)
      self.renderer.close_path()
    }
    Path(p) => {
      let path = @runtime.evaluate_path_property(p.ks, self.current_frame)
      self.renderer.begin_path()
      self.draw_lottie_path(path)
    }
    Fill(f) => {
      let color_vec = @runtime.evaluate_vec_property(f.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.o, self.current_frame)
      // Lottie colors are normalized [0-1]
      let r = (color_vec[0] * 255.0).to_int()
      let g = (color_vec[1] * 255.0).to_int()
      let b = (color_vec[2] * 255.0).to_int()
      self.renderer.fill(r, g, b, opacity / 100.0)
    }
    Stroke(s) => {
      let color_vec = @runtime.evaluate_vec_property(s.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.o, self.current_frame)
      let width = @runtime.evaluate_double_property(s.w, self.current_frame)
      let r = (color_vec[0] * 255.0).to_int()
      let g = (color_vec[1] * 255.0).to_int()
      let b = (color_vec[2] * 255.0).to_int()
      self.renderer.stroke(r, g, b, opacity / 100.0, width)
    }
    GradientFill(f) => {
      let start_p = @runtime.evaluate_vec_property(f.s, self.current_frame)
      let end_p = @runtime.evaluate_vec_property(f.e, self.current_frame)
      let stops = @runtime.evaluate_vec_property(f.g.k, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.o, self.current_frame)
      match f.t {
        Linear =>
          self.renderer.fill_linear_gradient(
            start_p[0],
            start_p[1],
            end_p[0],
            end_p[1],
            stops,
            opacity / 100.0,
          )
        Radial => {
          let dx = end_p[0] - start_p[0]
          let dy = end_p[1] - start_p[1]
          let r = @math.sqrt(dx * dx + dy * dy)
          self.renderer.fill_radial_gradient(
            start_p[0],
            start_p[1],
            r,
            start_p[0],
            start_p[1],
            0.0,
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
      match s.t {
        Linear =>
          self.renderer.stroke_linear_gradient(
            start_p[0],
            start_p[1],
            end_p[0],
            end_p[1],
            stops,
            opacity / 100.0,
            width,
          )
        Radial => {
          let dx = end_p[0] - start_p[0]
          let dy = end_p[1] - start_p[1]
          let r = @math.sqrt(dx * dx + dy * dy)
          self.renderer.stroke_radial_gradient(
            start_p[0],
            start_p[1],
            r,
            start_p[0],
            start_p[1],
            0.0,
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
  }
}

fn[R : Renderer] Player::draw_lottie_path(self : Player[R], path : @model.BezierPath) -> Unit {
  let v = path.v
  if v.length() > 0 {
    let i = path.i
    let o = path.o
    self.renderer.move_to(v[0][0], v[0][1])
    for n = 1; n < v.length(); n = n + 1 {
      let cp1x = v[n - 1][0] + o[n - 1][0]
      let cp1y = v[n - 1][1] + o[n - 1][1]
      let cp2x = v[n][0] + i[n][0]
      let cp2y = v[n][1] + i[n][1]
      self.renderer.cubic_to(cp1x, cp1y, cp2x, cp2y, v[n][0], v[n][1])
    }
    if path.c {
      let n = v.length()
      let cp1x = v[n - 1][0] + o[n - 1][0]
      let cp1y = v[n - 1][1] + o[n - 1][1]
      let cp2x = v[0][0] + i[0][0]
      let cp2y = v[0][1] + i[0][1]
      self.renderer.cubic_to(cp1x, cp1y, cp2x, cp2y, v[0][0], v[0][1])
      self.renderer.close_path()
    }
  }
}

///| Create a player for the browser canvas
pub fn create_canvas_player(animation : @model.Animation) -> Player[CanvasRenderer] {
  Player::new(animation, CanvasRenderer::new())
}
