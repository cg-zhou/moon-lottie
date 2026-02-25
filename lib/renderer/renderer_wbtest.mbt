pub struct TestRenderer {
  commands : Array[String]
}

pub fn TestRenderer::new() -> TestRenderer {
  { commands: [] }
}

impl Renderer for TestRenderer with set_stroke_style(_self, _lc, _lj, _ml) {
  ()
}

impl Renderer for TestRenderer with save(self) {
  self.commands.push("save")
}
impl Renderer for TestRenderer with restore(self) {
  self.commands.push("restore")
}
impl Renderer for TestRenderer with set_transform(self, _m) {
  let _ = _m
  self.commands.push("set_transform")
}
impl Renderer for TestRenderer with concat_transform(self, _m) {
  let _ = _m
  self.commands.push("concat_transform")
}
impl Renderer for TestRenderer with begin_path(self) {
  self.commands.push("begin_path")
}
impl Renderer for TestRenderer with close_path(self) {
  self.commands.push("close_path")
}
impl Renderer for TestRenderer with move_to(self, x, y) {
  self.commands.push("move_to(\{x}, \{y})")
}
impl Renderer for TestRenderer with line_to(self, x, y) {
  self.commands.push("line_to(\{x}, \{y})")
}
impl Renderer for TestRenderer with cubic_to(self, _cp1, _cp2, _cp3, _cp4, x, y) {
  self.commands.push("cubic_to(\{x}, \{y})")
}
impl Renderer for TestRenderer with fill(self, r, g, b, opacity) {
  self.commands.push("fill(\{r}, \{g}, \{b}, \{opacity})")
}
impl Renderer for TestRenderer with stroke(self, r, g, b, opacity, width) {
  self.commands.push("stroke(\{r}, \{g}, \{b}, \{opacity}, \{width})")
}
impl Renderer for TestRenderer with fill_linear_gradient(self, x1, y1, x2, y2, _stops, opacity) {
  self.commands.push("fill_linear_gradient(\{x1}, \{y1}, \{x2}, \{y2}, \{opacity})")
}
impl Renderer for TestRenderer with stroke_linear_gradient(self, x1, y1, x2, y2, _stops, opacity, width) {
  self.commands.push("stroke_linear_gradient(\{x1}, \{y1}, \{x2}, \{y2}, \{opacity}, \{width})")
}
impl Renderer for TestRenderer with fill_radial_gradient(self, cx, cy, r, _fx, _fy, _fr, _stops, opacity) {
  self.commands.push("fill_radial_gradient(\{cx}, \{cy}, \{r}, \{opacity})")
}
impl Renderer for TestRenderer with stroke_radial_gradient(self, cx, cy, r, _fx, _fy, _fr, _stops, opacity, width) {
  self.commands.push("stroke_radial_gradient(\{cx}, \{cy}, \{r}, \{opacity}, \{width})")
}
impl Renderer for TestRenderer with clip(self) {
  self.commands.push("clip")
}
impl Renderer for TestRenderer with clear_rect(self, _x, _y, _w, _h) {
  self.commands.push("clear")
}
impl Renderer for TestRenderer with draw_image(self, id, _w, _h) {
  self.commands.push("draw_image(\{id})")
}
impl Renderer for TestRenderer with set_blend_mode(self, mode) {
  self.commands.push("set_blend_mode(\{mode})")
}

test "player_mock_render" {
  // 1. Setup a simple animation with one rect layer
  let tr = @model.Transform::new(
    anchor=@model.LottieProperty::new_static([0.0, 0.0]),
    position=@model.LottieProperty::new_static([100.0, 100.0]),
    scale=@model.LottieProperty::new_static([100.0, 100.0]),
    rotation=@model.LottieProperty::new_static(0.0),
    opacity=@model.LottieProperty::new_static(100.0),
  )
  
  let rect = @model.Shape::new(
    ty="rc",
    data=@model.ShapeData::new_rect(
      @model.RectShape::new(
        p=@model.LottieProperty::new_static([0.0, 0.0]),
        s=@model.LottieProperty::new_static([50.0, 50.0]),
        r=@model.LottieProperty::new_static(0.0)
      )
    )
  )
  
  let fill = @model.Shape::new(
    ty="fl",
    data=@model.ShapeData::new_fill(
      @model.FillShape::new(
        c=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
        o=@model.LottieProperty::new_static(100.0)
      )
    )
  )
  
  let layer = @model.Layer::new(
    ind=1,
    ty=4,
    ks=tr,
    ip=0.0,
    op=100.0,
    st=0.0,
    data=@model.LayerData::new_shape([rect, fill])
  )
  
  let animation = @model.Animation::new(
    v="5.5.0",
    fr=60.0,
    ip=0.0,
    op=100.0,
    w=500,
    h=500,
    layers=[layer]
  )
  
  // 2. Play and Render
  let mock = TestRenderer::new()
  let player = Player::new(animation, mock)
  
  player.set_frame(10.0)
  player.render()
  
  let cmds = mock.commands
  
  // 3. Verify commands
  if cmds.length() == 0 { fail("No commands generated") }
  
  // Should contains save, concat_transform, begin_path, close_path, fill, restore
  let mut has_transform = false
  let mut has_fill = false
  for c in cmds {
    if c == "concat_transform" { has_transform = true }
    if c.contains("fill") { has_fill = true }
  }
  
  if not(has_transform) { fail("Missing transform command") }
  if not(has_fill) { fail("Missing fill command") }
}

test "player_path_render" {
  // 1. Setup a triangle path
  let path_data = @model.BezierPath::new(
    v=[[0.0, 0.0], [100.0, 0.0], [50.0, 100.0]],
    i=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    o=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    c=true
  )
  
  let path_shape = @model.Shape::new(
    ty="sh",
    data=@model.ShapeData::new_path(
      @model.PathShape::new(ks=@model.LottieProperty::new_static(path_data))
    )
  )
  
  let stroke = @model.Shape::new(
    ty="st",
    data=@model.ShapeData::new_stroke(
      @model.StrokeShape::new(
        c=@model.LottieProperty::new_static([0.0, 1.0, 0.0]),
        o=@model.LottieProperty::new_static(100.0),
        w=@model.LottieProperty::new_static(2.0)
      )
    )
  )
  
  let layer = @model.Layer::new(
    ind=2,
    ty=4,
    ks=@model.Transform::new_default(),
    ip=0.0,
    op=100.0,
    st=0.0,
    data=@model.LayerData::new_shape([path_shape, stroke])
  )
  
  let animation = @model.Animation::new(
    v="5.5.0",
    fr=60.0,
    ip=0.0,
    op=100.0,
    w=500,
    h=500,
    layers=[layer]
  )
  
  let mock = TestRenderer::new()
  let player = Player::new(animation, mock)
  player.render()
  
  let cmds = mock.commands
  let mut has_cubic_to = false
  for c in cmds {
    if c.contains("cubic_to") { has_cubic_to = true }
  }
  
  // Actually triangle with no tangents will still use cubic_to in our logic
  if not(has_cubic_to) { fail("Missing cubic_to command for path") }
}
