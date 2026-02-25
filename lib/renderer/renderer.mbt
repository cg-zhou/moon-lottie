///| Renderer Trait
///| Defines the interface for drawing Lottie primitives.
pub trait Renderer {
  save(self : Self) -> Unit
  restore(self : Self) -> Unit
  
  // Transform
  set_transform(self : Self, matrix : @math.Matrix) -> Unit
  concat_transform(self : Self, matrix : @math.Matrix) -> Unit
  
  // Path creation
  begin_path(self : Self) -> Unit
  close_path(self : Self) -> Unit
  move_to(self : Self, x : Double, y : Double) -> Unit
  line_to(self : Self, x : Double, y : Double) -> Unit
  cubic_to(self : Self, cp1x : Double, cp1y : Double, cp2x : Double, cp2y : Double, x : Double, y : Double) -> Unit
  
  // Painting
  fill(self : Self, color : String, opacity : Double) -> Unit
  stroke(self : Self, color : String, opacity : Double, width : Double) -> Unit
  
  // Images
  draw_image(self : Self, id : String, width : Double, height : Double) -> Unit
  
  // Canvas size
  clear_rect(self : Self, x : Double, y : Double, w : Double, h : Double) -> Unit
}
