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
  
  // Canvas size
  clear_rect(self : Self, x : Double, y : Double, w : Double, h : Double) -> Unit
}

///| A simple Mock Renderer for unit testing and logic verification
pub struct MockRenderer {
  commands : Array[String]
}

pub fn MockRenderer::new() -> MockRenderer {
  { commands: [] }
}

pub fn MockRenderer::get_commands(self : MockRenderer) -> Array[String] {
  self.commands
}

impl Renderer for MockRenderer with save(self) {
  self.commands.push("save")
}

impl Renderer for MockRenderer with restore(self) {
  self.commands.push("restore")
}

impl Renderer for MockRenderer with set_transform(self, m) {
  let _ = m
  self.commands.push("set_transform")
}

impl Renderer for MockRenderer with concat_transform(self, m) {
  let _ = m
  self.commands.push("concat_transform")
}

impl Renderer for MockRenderer with begin_path(self) {
  self.commands.push("begin_path")
}

impl Renderer for MockRenderer with close_path(self) {
  self.commands.push("close_path")
}

impl Renderer for MockRenderer with move_to(self, x, y) {
  self.commands.push("move_to(\{x}, \{y})")
}

impl Renderer for MockRenderer with line_to(self, x, y) {
  self.commands.push("line_to(\{x}, \{y})")
}

impl Renderer for MockRenderer with cubic_to(self, cp1x, cp1y, cp2x, cp2y, x, y) {
  self.commands.push("cubic_to(\{cp1x}, \{cp1y}, \{cp2x}, \{cp2y}, \{x}, \{y})")
}

impl Renderer for MockRenderer with fill(self, color, opacity) {
  self.commands.push("fill(\{color}, \{opacity})")
}

impl Renderer for MockRenderer with stroke(self, color, opacity, width) {
  self.commands.push("stroke(\{color}, \{opacity}, \{width})")
}

impl Renderer for MockRenderer with clear_rect(self, x, y, w, h) {
  self.commands.push("clear_rect(\{x}, \{y}, \{w}, \{h})")
}
