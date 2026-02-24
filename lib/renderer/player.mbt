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
  self.renderer.clear_rect(0.0, 0.0, self.animation.w.to_double(), self.animation.h.to_double())
  
  // Lottie renders layers from bottom to top (reverse order in the array)
  let layers = self.animation.layers
  for i = layers.length() - 1; i >= 0; i = i - 1 {
    self.render_layer(layers[i])
  }
}

fn[R : Renderer] Player::render_layer(self : Player[R], layer : @model.Layer) -> Unit {
  if self.current_frame < layer.ip || self.current_frame >= layer.op {
    return
  }

  self.renderer.save()
  
  // 1. Apply Layer Transform
  let matrix = @runtime.evaluate_transform(layer.ks, self.current_frame)
  self.renderer.concat_transform(matrix)
  
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
    _ => () // Solid, PreComp, etc. to be implemented
  }
  
  self.renderer.restore()
}

fn[R : Renderer] Player::render_shape(self : Player[R], shape : @model.Shape) -> Unit {
  match shape.data {
    Group(items) => {
      for item in items {
        self.render_shape(item)
      }
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
    Fill(f) => {
      let color_vec = @runtime.evaluate_vec_property(f.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(f.o, self.current_frame)
      // Lottie colors are normalized [0-1]
      let r = (color_vec[0] * 255.0).to_int()
      let g = (color_vec[1] * 255.0).to_int()
      let b = (color_vec[2] * 255.0).to_int()
      let color_str = "rgb(\{r}, \{g}, \{b})"
      self.renderer.fill(color_str, opacity / 100.0)
    }
    Stroke(s) => {
      let color_vec = @runtime.evaluate_vec_property(s.c, self.current_frame)
      let opacity = @runtime.evaluate_double_property(s.o, self.current_frame)
      let width = @runtime.evaluate_double_property(s.w, self.current_frame)
      let r = (color_vec[0] * 255.0).to_int()
      let g = (color_vec[1] * 255.0).to_int()
      let b = (color_vec[2] * 255.0).to_int()
      let color_str = "rgb(\{r}, \{g}, \{b})"
      self.renderer.stroke(color_str, opacity / 100.0, width)
    }
    Transform(tr) => {
      let matrix = @runtime.evaluate_transform(tr, self.current_frame)
      self.renderer.concat_transform(matrix)
    }
    _ => ()
  }
}
