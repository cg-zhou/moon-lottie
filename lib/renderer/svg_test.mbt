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
    output.contains("<clipPath id=\"frame_clip\" clipPathUnits=\"userSpaceOnUse\">"),
    "Frame clip should use explicit user-space units for mobile browser compatibility",
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
test "SvgRenderer emits sibling clip paths for segmented nonzero clips" {
  let renderer = SvgRenderer::new(100.0, 100.0)

  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(10.0, 0.0)
  renderer.line_to(10.0, 10.0)
  renderer.close_path()
  renderer.begin_path_segment()
  renderer.move_to(20.0, 20.0)
  renderer.line_to(30.0, 20.0)
  renderer.line_to(30.0, 30.0)
  renderer.close_path()
  renderer.set_fill_rule("nonzero")
  renderer.clip()

  let output = renderer.get_output()
  assert_true(
    output.contains("<clipPath id=\"clip_0\" clipPathUnits=\"userSpaceOnUse\"><path d=\"M0,0 L10,0 L10,10 Z\" fill-rule=\"nonzero\" /><path d=\"M20,20 L30,20 L30,30 Z\" fill-rule=\"nonzero\" /></clipPath>"),
    "Segmented nonzero clips should emit sibling path nodes",
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
test "SvgRenderer reuses renderer state without duplicating previous frame markup" {
  let json_str = "{\"v\":\"5.5.2\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"nm\":\"test\",\"ddd\":0,\"assets\":[],\"layers\":[{\"ty\":4,\"ks\":{\"p\":{\"a\":0,\"k\":[50,50]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100},\"a\":{\"a\":0,\"k\":[0,0]}},\"nm\":\"r\",\"shapes\":[{\"ty\":\"gr\",\"it\":[{\"ty\":\"rc\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[0,0]},\"r\":{\"a\":0,\"k\":0},\"nm\":\"r\"},{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":[1,0,0]},\"o\":{\"a\":0,\"k\":100},\"nm\":\"f\"}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { _ => fail("Parse failed") }
  let renderer = SvgRenderer::new(100.0, 100.0)
  let player = @renderer.Player::new(ani, renderer)
  player.set_frame(0.0)
  player.render()
  let first = renderer.get_output()
  player.set_frame(0.0)
  player.render()
  let second = renderer.get_output()
  assert_eq(second, first)
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
test "SvgRenderer mask composite uses luminance root mask for subtract stacks" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 0.0)
  renderer.line_to(100.0, 100.0)
  renderer.line_to(0.0, 100.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)

  renderer.begin_mask_composite()
  renderer.begin_mask_path()
  renderer.begin_path()
  renderer.move_to(10.0, 10.0)
  renderer.line_to(90.0, 10.0)
  renderer.line_to(90.0, 90.0)
  renderer.line_to(10.0, 90.0)
  renderer.close_path()
  renderer.apply_mask_path(1, 1.0, false, 0.0)
  renderer.begin_mask_path()
  renderer.begin_path()
  renderer.move_to(30.0, 30.0)
  renderer.line_to(70.0, 30.0)
  renderer.line_to(70.0, 70.0)
  renderer.line_to(30.0, 70.0)
  renderer.close_path()
  renderer.apply_mask_path(2, 1.0, false, 0.0)
  renderer.end_mask_composite()

  let output = renderer.get_output()
  assert_true(
    output.contains("<mask id=\"mask_0\" maskUnits=\"userSpaceOnUse\">"),
    "subtract stacks should create a root SVG mask in user space",
  )
  assert_true(
    !output.contains("<mask id=\"mask_0\" mask-type=\"alpha\">"),
    "root SVG masks should use luminance semantics so black subtract paths remove alpha",
  )
  assert_true(
    output.contains("fill=\"#000000\""),
    "subtract masks should emit black mask paths",
  )
  assert_true(
    output.contains("fill-rule=\"nonzero\""),
    "mask paths should emit fill-rule so SVG mask winding matches lottie-web",
  )
  assert_true(
    !output.contains("clip-rule=\"nonzero\""),
    "mask paths should not emit clip-rule on <path> elements",
  )
}

///|
test "SvgRenderer intersect mask nests prior stack inside alpha mask" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 0.0)
  renderer.line_to(100.0, 100.0)
  renderer.line_to(0.0, 100.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)

  renderer.begin_mask_composite()
  renderer.begin_mask_path()
  renderer.begin_path()
  renderer.move_to(10.0, 10.0)
  renderer.line_to(90.0, 10.0)
  renderer.line_to(90.0, 90.0)
  renderer.line_to(10.0, 90.0)
  renderer.close_path()
  renderer.apply_mask_path(1, 1.0, false, 0.0)
  renderer.begin_mask_path()
  renderer.begin_path()
  renderer.move_to(20.0, 20.0)
  renderer.line_to(80.0, 20.0)
  renderer.line_to(80.0, 80.0)
  renderer.line_to(20.0, 80.0)
  renderer.close_path()
  renderer.apply_mask_path(3, 1.0, false, 0.0)
  renderer.end_mask_composite()

  let output = renderer.get_output()
  assert_true(
    output.contains("id=\"mask_intersect_0\" maskUnits=\"userSpaceOnUse\" mask-type=\"alpha\""),
    "intersect masks should use nested alpha masks in user space like lottie-web",
  )
  assert_true(
    output.contains("<g mask=\"url(#mask_intersect_0)\">"),
    "intersect masks should wrap the prior stack in the nested alpha mask",
  )
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
test "SvgRenderer get_output always includes frame boundary clip" {
  let renderer = SvgRenderer::new(200.0, 150.0)
  renderer.begin_path()
  renderer.move_to(-50.0, -50.0)
  renderer.line_to(300.0, -50.0)
  renderer.line_to(300.0, 200.0)
  renderer.line_to(-50.0, 200.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
  let output = renderer.get_output()
  assert_true(
    output.contains("id=\"frame_clip\""),
    "SVG output should always contain a frame_clip clipPath element",
  )
  assert_true(
    output.contains("clip-path=\"url(#frame_clip)\""),
    "SVG root content should be wrapped in the frame_clip",
  )
  assert_true(
    output.contains("width=\"200\" height=\"150\""),
    "frame_clip should use the animation dimensions",
  )
}

///|
test "SvgRenderer source-atop with matte preserves destination alpha" {
  // Simulate the pattern used for track-matte with fill-effect on a solid
  // layer: the matte source (solid black) is drawn first, then a fill effect
  // applies source-atop to recolor it. The resulting matte buffer must retain
  // full alpha (from the solid) so the matte mask is not nearly transparent.
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.prepare_matte_layer()
  // Content: shape to be masked
  renderer.begin_path()
  renderer.move_to(20.0, 20.0)
  renderer.line_to(80.0, 20.0)
  renderer.line_to(80.0, 80.0)
  renderer.line_to(20.0, 80.0)
  renderer.close_path()
  renderer.fill(0, 0, 255, 1.0)
  renderer.begin_matte_exit()
  // Matte source step 1: draw solid (like a Solid layer)
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 0.0)
  renderer.line_to(100.0, 100.0)
  renderer.line_to(0.0, 100.0)
  renderer.close_path()
  renderer.fill(0, 0, 0, 1.0)
  // Matte source step 2: fill effect applies source-atop recolor at low opacity
  renderer.set_blend_mode("source-atop")
  renderer.begin_path()
  renderer.move_to(-10000.0, -10000.0)
  renderer.line_to(10000.0, -10000.0)
  renderer.line_to(10000.0, 10000.0)
  renderer.line_to(-10000.0, 10000.0)
  renderer.close_path()
  renderer.fill(0, 0, 1, 0.01)
  renderer.set_blend_mode("source-over")
  renderer.end_matte_exit(1)
  let output = renderer.get_output()
  // The matte mask must contain BOTH the original solid (alpha=1) AND the
  // source-atop overlay. If the solid is absent, the mask would only have
  // fill-opacity=0.01, making the content 99% invisible.
  assert_true(
    output.contains("<mask id=\"matte_"),
    "matte mask should exist",
  )
  assert_true(
    output.contains("fill=\"#000000\""),
    "matte mask must contain the original solid content to preserve alpha=1",
  )
  assert_true(
    output.contains("blend_mask"),
    "matte mask should contain source-atop blend mask for the fill overlay",
  )
}

///|
test "SvgRenderer invert matte uses alpha inversion filter" {
  // For invert-alpha matte (tt=2), lottie-web inverts the matte alpha with
  // feComponentTransfer instead of relying on destination-out inside <mask>.
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.prepare_matte_layer()
  // Content: blue rectangle
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(100.0, 0.0)
  renderer.line_to(100.0, 100.0)
  renderer.line_to(0.0, 100.0)
  renderer.close_path()
  renderer.fill(0, 0, 255, 1.0)
  renderer.begin_matte_exit()
  // Matte source: small white square (at 20,20 – 80,80)
  renderer.begin_path()
  renderer.move_to(20.0, 20.0)
  renderer.line_to(80.0, 20.0)
  renderer.line_to(80.0, 80.0)
  renderer.line_to(20.0, 80.0)
  renderer.close_path()
  renderer.fill(255, 255, 255, 1.0)
  renderer.end_matte_exit(2) // invert matte
  let output = renderer.get_output()
  assert_true(
    output.contains("<feFuncA type=\"table\" tableValues=\"1.0 0.0\" />"),
    "invert matte should invert alpha through feComponentTransfer",
  )
  assert_true(
    output.contains("fill=\"#FFFFFF\" opacity=\"0\""),
    "invert matte should include a transparent full-frame rect to expand filter bounds",
  )
  assert_true(
    output.contains("filter=\"url(#matte_invert_1)\""),
    "invert matte should wrap the matte content in the alpha-inversion filter",
  )
  assert_true(
    output.contains("<use href=\"#matte_content_2\" xlink:href=\"#matte_content_2\" />"),
    "invert matte should reference the matte content through a defs-backed use element",
  )
}

///|
test "SvgRenderer matte source restores captured base transform" {
  let renderer = SvgRenderer::new(100.0, 100.0)
  renderer.set_transform(@math.Matrix::identity().translate(10.0, 20.0))
  renderer.prepare_matte_layer()
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(30.0, 0.0)
  renderer.line_to(30.0, 30.0)
  renderer.line_to(0.0, 30.0)
  renderer.close_path()
  renderer.fill(255, 0, 0, 1.0)
  renderer.begin_matte_exit()
  renderer.save()
  renderer.set_transform(@math.Matrix::identity())
  renderer.begin_path()
  renderer.move_to(0.0, 0.0)
  renderer.line_to(10.0, 0.0)
  renderer.line_to(10.0, 10.0)
  renderer.line_to(0.0, 10.0)
  renderer.close_path()
  renderer.fill(255, 255, 255, 1.0)
  renderer.restore()
  renderer.end_matte_exit(2)
  let output = renderer.get_output()
  assert_true(
    output.contains("d=\"M10,20 L20,20 L20,30 L10,30 Z\" fill=\"#FFFFFF\""),
    "matte source content should inherit the captured base transform during matte exit",
  )
}
