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
    output.contains("overflow=\"hidden\""),
    "Root svg should hide content outside the canvas",
  )
  assert_true(
    output.contains("fill=\"#FF0000\""),
    "Output should contain red fill",
  )
  assert_true(output.contains("M10"), "Output should contain move to 10")
  assert_true(output.contains("L90"), "Output should contain line to 90")
  assert_true(output.contains("Z"), "Output should contain close path")
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
}

///|
test "SvgRenderer uses unique gradient ids" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  draw_gradient(renderer)
  draw_gradient(renderer)
  let output = renderer.get_output()
  assert_true(
    output.contains("id=\"grad_0\""),
    "First gradient should use its own id",
  )
  assert_true(
    output.contains("id=\"grad_1\""),
    "Second gradient should use its own id",
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
test "SvgRenderer escapes text content" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.draw_text("A&B<test>\"'", "Arial\"'", 16.0, 255, 255, 255, 1.0, 0)
  let output = renderer.get_output()
  assert_true(output.contains("A&amp;B&lt;test&gt;"), "Text content should be XML escaped")
  assert_true(output.contains("&quot;&#39;"), "Quotes should be XML escaped")
}

///|
test "SvgRenderer scales stroke width with current transform" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.concat_transform(@math.Matrix::identity().scale(0.5, 0.5))
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(20.0, 0.0)
  renderer.set_line_dash([4.0, 2.0], 1.0)
  renderer.stroke(255, 0, 0, 1.0, 10.0)
  let output = renderer.get_output()
  assert_true(output.contains("stroke-width=\"5\""), "Stroke width should scale with the current matrix")
  assert_true(output.contains("stroke-dasharray=\"2,1\""), "Dash pattern should scale with the current matrix")
  assert_true(output.contains("stroke-dashoffset=\"0.5\""), "Dash offset should scale with the current matrix")
}

///|
test "SvgRenderer applies image transforms" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.concat_transform(@math.Matrix::identity().translate(12.0, 34.0))
  renderer.draw_image("data:image/png;base64,abc", 20.0, 10.0, 0)
  let output = renderer.get_output()
  assert_true(
    output.contains("xmlns:xlink=\"http://www.w3.org/1999/xlink\""),
    "SVG output should declare the xlink namespace for image compatibility",
  )
  assert_true(
    output.contains("xlink:href=\"data:image/png;base64,abc\""),
    "Images should include a legacy xlink:href for embedded asset compatibility",
  )
  assert_true(
    output.contains("transform=\"matrix(1 0 0 1 12 34)\""),
    "Images should carry the current transform matrix",
  )
  assert_true(
    output.contains("width=\"20\" height=\"10\""),
    "Images should preserve their requested dimensions",
  )
}

///|
test "SvgRenderer layer source-atop masks replacement paint" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.begin_layer()
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(10.0, 0.0)
  renderer.line_to(10.0, 10.0)
  renderer.line_to(0.0, 10.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
  renderer.set_blend_mode("source-atop")
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(20.0, 0.0)
  renderer.line_to(20.0, 20.0)
  renderer.line_to(0.0, 20.0)
  renderer.close_path()
  renderer.fill(0, 0, 255, 1.0)
  renderer.set_blend_mode("source-over")
  renderer.end_layer("source-over")
  let output = renderer.get_output()
  assert_true(output.contains("<mask id=\"blend_mask_0\""), "source-atop should create a mask")
  assert_true(output.contains("mask=\"url(#blend_mask_0)\""), "replacement paint should be masked by prior content")
  assert_true(output.contains("fill=\"#0000FF\""), "replacement paint should remain visible")
}

///|
test "SvgRenderer track matte outputs masked content" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.prepare_matte_layer()
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(20.0, 0.0)
  renderer.line_to(20.0, 20.0)
  renderer.line_to(0.0, 20.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
  renderer.begin_matte_exit()
  renderer.begin_path()
  renderer.move_to(5.0, 5.0)
  renderer.line_to(15.0, 5.0)
  renderer.line_to(15.0, 15.0)
  renderer.line_to(5.0, 15.0)
  renderer.close_path()
  renderer.fill(255, 255, 255, 1.0)
  renderer.end_matte_exit(1)
  let output = renderer.get_output()
  assert_true(
    output.contains("<mask id=\"matte_0\""),
    "track matte should create a mask",
  )
  assert_true(
    output.contains("mask-type=\"alpha\""),
    "track matte should create an alpha mask so matte color does not affect opacity",
  )
  assert_true(output.contains("mask=\"url(#matte_0)\""), "content should reference the matte mask")
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
