fn non_whitespace_cells(output : String) -> Int {
  let mut count = 0
  for _, char in output {
    if char != ' ' && char != '\n' && char != '\r' {
      count = count + 1
    }
  }
  count
}

fn rendered_dimensions(output : String) -> (Int, Int) {
  let mut width = 0
  let mut current_width = 0
  let mut height = 0
  for _, char in output {
    if char == '\r' {
      continue
    }
    if char == '\n' {
      if current_width > width {
        width = current_width
      }
      height = height + 1
      current_width = 0
      continue
    }
    current_width = current_width + 1
  }
  if current_width > 0 {
    if current_width > width {
      width = current_width
    }
    height = height + 1
  }
  (width, height)
}

test "DrawilleRenderer stroke renders visible braille" {
  let renderer = DrawilleRenderer::new(20.0, 20.0, target_width=20, target_height=20, enable_ansi=false)
  renderer.begin_path()
  renderer.move_to(2.0, 2.0)
  renderer.line_to(18.0, 18.0)
  renderer.stroke(255, 255, 255, 1.0, 1.0)

  let output = renderer.get_output()
  if non_whitespace_cells(output) == 0 {
    fail("Expected stroke output to contain visible terminal content")
  }
}

test "DrawilleRenderer dash reduces visible stroke coverage" {
  let solid = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  solid.begin_path()
  solid.move_to(2.0, 12.0)
  solid.line_to(22.0, 12.0)
  solid.stroke(255, 255, 255, 1.0, 4.0)

  let dashed = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  dashed.begin_path()
  dashed.move_to(2.0, 12.0)
  dashed.line_to(22.0, 12.0)
  dashed.set_line_dash([3.0, 2.0], 0.0)
  dashed.stroke(255, 255, 255, 1.0, 4.0)

  let solid_count = non_whitespace_cells(solid.get_output())
  let dashed_count = non_whitespace_cells(dashed.get_output())
  if dashed_count >= solid_count {
    fail("Expected dashed stroke to cover fewer cells than a solid stroke")
  }
}

test "DrawilleRenderer line caps affect short stroke coverage" {
  let butt = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  butt.begin_path()
  butt.move_to(6.0, 12.0)
  butt.line_to(18.0, 12.0)
  butt.set_stroke_style(1, 1, 4.0)
  butt.stroke(255, 255, 255, 1.0, 6.0)

  let round = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  round.begin_path()
  round.move_to(6.0, 12.0)
  round.line_to(18.0, 12.0)
  round.set_stroke_style(2, 1, 4.0)
  round.stroke(255, 255, 255, 1.0, 6.0)

  let square = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  square.begin_path()
  square.move_to(6.0, 12.0)
  square.line_to(18.0, 12.0)
  square.set_stroke_style(3, 1, 4.0)
  square.stroke(255, 255, 255, 1.0, 6.0)

  let butt_count = non_whitespace_cells(butt.get_output())
  let round_count = non_whitespace_cells(round.get_output())
  let square_count = non_whitespace_cells(square.get_output())
  if round_count <= butt_count {
    fail("Expected round cap to add visible coverage beyond butt cap")
  }
  if square_count <= butt_count {
    fail("Expected square cap to add visible coverage beyond butt cap")
  }
}

test "DrawilleRenderer line joins affect corner coverage" {
  let bevel = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  bevel.begin_path()
  bevel.move_to(6.0, 20.0)
  bevel.line_to(12.0, 8.0)
  bevel.line_to(18.0, 20.0)
  bevel.set_stroke_style(1, 3, 4.0)
  bevel.stroke(255, 255, 255, 1.0, 6.0)

  let miter = DrawilleRenderer::new(24.0, 24.0, target_width=24, target_height=24, enable_ansi=false)
  miter.begin_path()
  miter.move_to(6.0, 20.0)
  miter.line_to(12.0, 8.0)
  miter.line_to(18.0, 20.0)
  miter.set_stroke_style(1, 1, 4.0)
  miter.stroke(255, 255, 255, 1.0, 6.0)

  let bevel_count = non_whitespace_cells(bevel.get_output())
  let miter_count = non_whitespace_cells(miter.get_output())
  if miter_count <= bevel_count {
    fail("Expected miter join to cover more cells than bevel join")
  }
}

test "DrawilleRenderer fill renders non-empty output" {
  let renderer = DrawilleRenderer::new(20.0, 20.0, target_width=20, target_height=20, enable_ansi=false)
  renderer.begin_path()
  renderer.move_to(4.0, 4.0)
  renderer.line_to(16.0, 4.0)
  renderer.line_to(16.0, 16.0)
  renderer.line_to(4.0, 16.0)
  renderer.close_path()
  renderer.fill(255, 255, 255, 1.0)

  let output = renderer.get_output()
  if non_whitespace_cells(output) == 0 {
    fail("Expected filled output to be non-empty")
  }
}

test "DrawilleRenderer evenodd fill preserves holes" {
  let nonzero_renderer = DrawilleRenderer::new(40.0, 40.0, target_width=40, target_height=40, enable_ansi=false)
  nonzero_renderer.begin_path()
  nonzero_renderer.move_to(2.0, 2.0)
  nonzero_renderer.line_to(38.0, 2.0)
  nonzero_renderer.line_to(38.0, 38.0)
  nonzero_renderer.line_to(2.0, 38.0)
  nonzero_renderer.close_path()
  nonzero_renderer.move_to(10.0, 10.0)
  nonzero_renderer.line_to(30.0, 10.0)
  nonzero_renderer.line_to(30.0, 30.0)
  nonzero_renderer.line_to(10.0, 30.0)
  nonzero_renderer.close_path()
  nonzero_renderer.fill(255, 255, 255, 1.0)

  let evenodd_renderer = DrawilleRenderer::new(40.0, 40.0, target_width=40, target_height=40, enable_ansi=false)
  evenodd_renderer.set_fill_rule("evenodd")
  evenodd_renderer.begin_path()
  evenodd_renderer.move_to(2.0, 2.0)
  evenodd_renderer.line_to(38.0, 2.0)
  evenodd_renderer.line_to(38.0, 38.0)
  evenodd_renderer.line_to(2.0, 38.0)
  evenodd_renderer.close_path()
  evenodd_renderer.move_to(10.0, 10.0)
  evenodd_renderer.line_to(30.0, 10.0)
  evenodd_renderer.line_to(30.0, 30.0)
  evenodd_renderer.line_to(10.0, 30.0)
  evenodd_renderer.close_path()
  evenodd_renderer.fill(255, 255, 255, 1.0)

  let nonzero_count = non_whitespace_cells(nonzero_renderer.get_output())
  let evenodd_count = non_whitespace_cells(evenodd_renderer.get_output())
  if evenodd_count >= nonzero_count {
    fail("Expected evenodd fill to leave a visible hole")
  }
}

test "DrawilleRenderer pins output to requested viewport" {
  let renderer = DrawilleRenderer::new(20.0, 20.0, target_width=40, target_height=24, enable_ansi=false)
  let (width, height) = rendered_dimensions(renderer.get_output())
  if width != 20 || height != 6 {
    fail("Expected fixed 20x6 braille viewport, got \{width}x\{height}")
  }
}