///|
fn[R : Renderer] draw_basic(renderer : R) -> Unit {
  renderer.begin_path()
  renderer.move_to(10.0, 10.0)
  renderer.line_to(90.0, 10.0)
  renderer.line_to(90.0, 90.0)
  renderer.line_to(10.0, 90.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
}

///|
test "SvgRenderer basic" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  draw_basic(renderer)

  let output = renderer.get_output()
  // Basic check
  assert_true(output.contains("<svg"), "Output should contain svg tag")
  assert_true(
    output.contains("fill=\"#FF0000\""),
    "Output should contain red fill",
  )
  assert_true(output.contains("M10"), "Output should contain move to 10")
  assert_true(output.contains("L90"), "Output should contain line to 90")
  assert_true(output.contains("Z"), "Output should contain close path")
  assert_false(
    output.contains("<rect"),
    "Transparent SVG export should not inject a background rect",
  )
}

///|
fn[R : Renderer] draw_gradient(renderer : R) -> Unit {
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 100.0)

  let stops = [0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0] // Red to Blue
  renderer.fill_linear_gradient(0.0, 0.0, 100.0, 100.0, 2, stops, 1.0)
}

///|
test "SvgRenderer with gradient" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  draw_gradient(renderer)

  let output = renderer.get_output()
  assert_true(
    output.contains("<linearGradient"),
    "Output should contain linearGradient",
  )
  assert_true(
    output.contains("stop-color=\"#FF0000\""),
    "Output should contain red stop color",
  )
  assert_true(
    output.contains("stop-color=\"#0000FF\""),
    "Output should contain blue stop color",
  )
  assert_true(
    output.contains("id=\"grad_0\""),
    "Output should use unique gradient ids",
  )
}

///|
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

  renderer.set_fill_rule("evenodd")
  renderer.clip()

  let output = renderer.get_output()
  assert_true(
    output.contains("fill-rule=\"evenodd\""),
    "Output should contain fill-rule evenodd",
  )
  assert_true(output.contains("<clipPath"), "Output should contain clipPath")
  assert_true(
    output.contains("clip-path=\"url(#clip_0)\""),
    "Output should contain clip-path reference",
  )
}

///|
test "render_animation_to_svgs utility" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":1,\"sw\":100,\"sh\":100,\"sc\":\"#ff0000\",\"ks\":{\"p\":{\"k\":[250,250]}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { _ => fail("Parse failed") }

  let svgs = render_animation_to_svgs(ani, 3)
  assert_eq(svgs.length(), 3)
  assert_true(svgs[0].contains("<svg"), "First frame should contain svg tag")
}

///|
test "precomp rendering applies composition clipping" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"assets\":[{\"id\":\"comp_1\",\"w\":50,\"h\":50,\"layers\":[{\"ddd\":0,\"ind\":1,\"ty\":1,\"nm\":\"solid\",\"ks\":{\"a\":{\"a\":0,\"k\":[0,0,0]},\"p\":{\"a\":0,\"k\":[25,25,0]},\"s\":{\"a\":0,\"k\":[100,100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}},\"ip\":0,\"op\":10,\"st\":0,\"sc\":\"#ff0000\",\"sw\":100,\"sh\":100}]}],\"layers\":[{\"ddd\":0,\"ind\":1,\"ty\":0,\"nm\":\"precomp\",\"refId\":\"comp_1\",\"w\":50,\"h\":50,\"ks\":{\"a\":{\"a\":0,\"k\":[0,0,0]},\"p\":{\"a\":0,\"k\":[50,50,0]},\"s\":{\"a\":0,\"k\":[100,100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}},\"ip\":0,\"op\":10,\"st\":0}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { _ => fail("Parse failed") }
  let svgs = render_animation_to_svgs(ani, 1)
  assert_eq(svgs.length(), 1)
  assert_true(
    svgs[0].contains("<clipPath"),
    "Precomp layer should be clipped to its composition bounds",
  )
}

///|
test "SvgRenderer stroke style and transform attrs" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.set_transform(@math.Matrix::identity().translate(5.0, 6.0).scale(2.0, 3.0))
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(10.0, 0.0)
  renderer.set_stroke_style(2, 3, 7.0)
  renderer.set_line_dash([4.0, 2.0], 1.5)
  renderer.stroke(255, 0, 0, 0.5, 3.0)

  let output = renderer.get_output()
  assert_true(
    output.contains("stroke-linecap=\"round\""),
    "Stroke cap should be emitted",
  )
  assert_true(
    output.contains("stroke-linejoin=\"bevel\""),
    "Stroke join should be emitted",
  )
  assert_true(
    output.contains("stroke-dasharray=\"4 2\""),
    "Dash array should be emitted",
  )
  assert_true(
    output.contains("stroke-dashoffset=\"1.5\""),
    "Dash offset should be emitted",
  )
  assert_true(
    output.contains("transform=\"matrix(2 0 0 3 5 6)\""),
    "Transform should be emitted on stroked paths",
  )
}

///|
test "SvgRenderer escapes text and image attributes" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.draw_text("<moon&lottie>", "\"Font\"", 12.0, 255, 255, 255, 1.0, 0)
  renderer.draw_image("https://example.com/a?x=1&y=2", 10.0, 20.0, 0)

  let output = renderer.get_output()
  assert_true(
    output.contains("&lt;moon&amp;lottie&gt;"),
    "Text content should be XML-escaped",
  )
  assert_true(
    output.contains("font-family=\"&quot;Font&quot;\""),
    "Font attribute should be XML-escaped",
  )
  assert_true(
    output.contains("href=\"https://example.com/a?x=1&amp;y=2\""),
    "Image href should be XML-escaped",
  )
}
