fn[R : Renderer] draw_basic(renderer : R) -> Unit {
  renderer.begin_path()
  renderer.move_to(10.0, 10.0)
  renderer.line_to(90.0, 10.0)
  renderer.line_to(90.0, 90.0)
  renderer.line_to(10.0, 90.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
}

test "SvgRenderer basic" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  draw_basic(renderer)
  
  let output = renderer.get_output()
  // Basic check
  assert_true(output.contains("<svg"))
  assert_true(output.contains("fill=\"#FF0000\""))
  assert_true(output.contains("M10"))
  assert_true(output.contains("L90"))
  assert_true(output.contains("Z"))
}

fn[R : Renderer] draw_gradient(renderer : R) -> Unit {
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 100.0)
  
  let stops = [0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0] // Red to Blue
  renderer.fill_linear_gradient(0.0, 0.0, 100.0, 100.0, stops, 1.0)
}

test "SvgRenderer with gradient" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  draw_gradient(renderer)
  
  let output = renderer.get_output()
  assert_true(output.contains("<linearGradient"))
  assert_true(output.contains("stop-color=\"#FF0000\""))
  assert_true(output.contains("stop-color=\"#0000FF\""))
}

test "SvgRenderer subtract mask logic" {
  let renderer = SvgRenderer::new(500.0, 500.0)
  
  // Simulate what player would do for a subtract mask
  renderer.begin_path()
  // Giant rect
  renderer.move_to(-10000.0, -10000.0)
  renderer.line_to(10000.0, -10000.0)
  renderer.line_to(10000.0, 10000.0)
  renderer.line_to(-10000.0, 10000.0)
  renderer.close_path()
  
  // Mask path (circle-like)
  renderer.move_to(100.0, 100.0)
  renderer.line_to(200.0, 100.0)
  renderer.line_to(200.0, 200.0)
  renderer.line_to(100.0, 200.0)
  renderer.close_path()
  
  renderer.clip()
  
  let output = renderer.get_output()
  assert_true(output.contains("fill-rule=\"evenodd\""))
  assert_true(output.contains("<clipPath"))
  assert_true(output.contains("clip-path=\"url(#clip_0)\""))
}

test "render_animation_to_svgs utility" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":1,\"sw\":100,\"sh\":100,\"sc\":\"#ff0000\",\"ks\":{\"p\":{\"k\":[250,250]}}}]}"
  let json = @json.parse(json_str)
  let ani = try {
    @parser.parse_animation(json)
  } catch {
    _ => fail("Parse failed")
  }
  
  let svgs = render_animation_to_svgs(ani, 3)
  assert_eq!(svgs.length(), 3)
  assert_true(svgs[0].contains("<svg"))
}
