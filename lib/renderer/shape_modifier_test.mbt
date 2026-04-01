///|
test "rounding/sharp_corners_of_square" {
  // A square path with sharp corners (zero tangents)
  let path = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [100.0, 0.0], [100.0, 100.0], [0.0, 100.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    closed=true,
  )

  let rounded = apply_rounding_to_path(path, 10.0)

  // Each sharp corner should produce 2 vertices (one per edge side)
  // 4 corners * 2 = 8 vertices
  inspect(rounded.vertices.length(), content="8")

  // First corner (0,0): rounded between edges from (0,100) and (100,0)
  // Vertex on edge from (0,100)→(0,0): (0, 10) — i.e. 10 units from corner along that edge
  if (rounded.vertices[0][0] - 0.0).abs() > 0.01 {
    fail("v0 x: \{rounded.vertices[0][0]}")
  }
  if (rounded.vertices[0][1] - 10.0).abs() > 0.01 {
    fail("v0 y: \{rounded.vertices[0][1]}")
  }
  // Vertex on edge from (0,0)→(100,0): (10, 0)
  if (rounded.vertices[1][0] - 10.0).abs() > 0.01 {
    fail("v1 x: \{rounded.vertices[1][0]}")
  }
  if (rounded.vertices[1][1] - 0.0).abs() > 0.01 {
    fail("v1 y: \{rounded.vertices[1][1]}")
  }

  // Path should remain closed
  inspect(rounded.closed, content="true")
}

///|
test "rounding/radius_larger_than_edge" {
  // Small square where radius exceeds half the edge length
  let path = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [20.0, 0.0], [20.0, 20.0], [0.0, 20.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    closed=true,
  )

  // Radius 15 exceeds half edge (10), should be clamped to 10
  let rounded = apply_rounding_to_path(path, 15.0)
  inspect(rounded.vertices.length(), content="8")

  // Corner at (0,0): clamped to radius=10
  if (rounded.vertices[0][0] - 0.0).abs() > 0.01 ||
    (rounded.vertices[0][1] - 10.0).abs() > 0.01 {
    fail("Rounding radius should be clamped")
  }
  if (rounded.vertices[1][0] - 10.0).abs() > 0.01 ||
    (rounded.vertices[1][1] - 0.0).abs() > 0.01 {
    fail("Rounding radius should be clamped")
  }
}

///|
test "rounding/non_sharp_corners_preserved" {
  // Path with non-zero tangents (curved segment) should not be rounded
  let path = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [100.0, 0.0]],
    in_tangents=[[0.0, 0.0], [-30.0, 0.0]],
    out_tangents=[[30.0, 0.0], [0.0, 0.0]],
    closed=false,
  )

  let rounded = apply_rounding_to_path(path, 10.0)
  // Non-sharp corners should be preserved as-is
  inspect(rounded.vertices.length(), content="2")
  inspect(rounded.vertices[0][0], content="0")
  inspect(rounded.vertices[1][0], content="100")
}

///|
test "rounding/zero_radius_noop" {
  let path = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [100.0, 0.0], [100.0, 100.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    closed=false,
  )

  // Zero radius should be a no-op
  let rounded = apply_rounding_to_path(path, 0.0)
  inspect(rounded.vertices.length(), content="3")
}

///|
test "repeater/opacity_gradient" {
  // Test that repeater with start/end opacity produces per-copy opacity commands
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([20.0, 20.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="rp",
              data=@model.ShapeData::new_repeater(
                @model.Repeater::new(
                  copies=@model.LottieProperty::new_static(3.0),
                  offset=@model.LottieProperty::new_static(0.0),
                  composite=1,
                  transform=@model.Transform::new(
                    anchor=@model.LottieProperty::new_static([0.0, 0.0]),
                    position=@model.LottieProperty::new_static([30.0, 0.0]),
                    scale=@model.LottieProperty::new_static([100.0, 100.0]),
                    rotation=@model.LottieProperty::new_static(0.0),
                    opacity=@model.LottieProperty::new_static(100.0),
                  ),
                  start_opacity=@model.LottieProperty::new_static(100.0),
                  end_opacity=@model.LottieProperty::new_static(50.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="fl",
              data=@model.ShapeData::new_fill(
                @model.FillShape::new(
                  color=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
                  opacity=@model.LottieProperty::new_static(100.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  // Verify that SetOpacity commands from repeater per-copy opacity are present
  // (filter out layer-level opacity which is always 1.0)
  let mut opacity_count = 0
  for cmd in cmds {
    match cmd {
      SetOpacity(v) =>
        if (v - 1.0).abs() > 0.001 {
          opacity_count = opacity_count + 1
        }
      _ => ()
    }
  }
  // With start_opacity=100 and end_opacity=50, opacity varies,
  // so we should see Save/SetOpacity/Restore per copy
  if opacity_count == 0 { fail("Per-copy opacity commands should be present") }
}

///|
test "repeater/uniform_opacity_no_extra_commands" {
  // When start_opacity == end_opacity == 100, no extra opacity commands needed
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([20.0, 20.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="rp",
              data=@model.ShapeData::new_repeater(
                @model.Repeater::new(
                  copies=@model.LottieProperty::new_static(3.0),
                  offset=@model.LottieProperty::new_static(0.0),
                  composite=1,
                  transform=@model.Transform::new(
                    anchor=@model.LottieProperty::new_static([0.0, 0.0]),
                    position=@model.LottieProperty::new_static([30.0, 0.0]),
                    scale=@model.LottieProperty::new_static([100.0, 100.0]),
                    rotation=@model.LottieProperty::new_static(0.0),
                    opacity=@model.LottieProperty::new_static(100.0),
                  ),
                  // Default so=100, eo=100 → no per-copy opacity needed
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="fl",
              data=@model.ShapeData::new_fill(
                @model.FillShape::new(
                  color=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
                  opacity=@model.LottieProperty::new_static(100.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  // Only the layer-level SetOpacity(1.0) should be present, no repeater-specific ones
  let mut opacity_from_repeater = 0
  for cmd in cmds {
    match cmd {
      SetOpacity(v) =>
        if (v - 1.0).abs() > 0.001 {
          opacity_from_repeater = opacity_from_repeater + 1
        }
      _ => ()
    }
  }
  inspect(opacity_from_repeater, content="0")
}

///|
test "repeater/painted_group_is_repeated" {
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="gr",
              data=@model.ShapeData::new_group(
                [
                  @model.Shape::new(
                    shape_type="rc",
                    data=@model.ShapeData::new_rect(
                      @model.RectShape::new(
                        position=@model.LottieProperty::new_static([0.0, 0.0]),
                        size=@model.LottieProperty::new_static([10.0, 10.0]),
                        roundness=@model.LottieProperty::new_static(0.0),
                      ),
                    ),
                  ),
                  @model.Shape::new(
                    shape_type="fl",
                    data=@model.ShapeData::new_fill(
                      @model.FillShape::new(
                        color=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
                        opacity=@model.LottieProperty::new_static(100.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            @model.Shape::new(
              shape_type="rp",
              data=@model.ShapeData::new_repeater(
                @model.Repeater::new(
                  copies=@model.LottieProperty::new_static(3.0),
                  offset=@model.LottieProperty::new_static(0.0),
                  composite=1,
                  transform=@model.Transform::new(
                    anchor=@model.LottieProperty::new_static([0.0, 0.0]),
                    position=@model.LottieProperty::new_static([20.0, 0.0]),
                    scale=@model.LottieProperty::new_static([100.0, 100.0]),
                    rotation=@model.LottieProperty::new_static(0.0),
                    opacity=@model.LottieProperty::new_static(100.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  let mut fill_count = 0
  let mut translated_groups = 0
  for cmd in cmds {
    match cmd {
      Fill(255, 0, 0, opacity) => {
        if (opacity - 1.0).abs() > 0.001 {
          fail("Unexpected fill opacity: \{opacity}")
        }
        fill_count = fill_count + 1
      }
      ConcatTransform(m) =>
        if (m.e - 20.0).abs() < 0.001 || (m.e - 40.0).abs() < 0.001 {
          translated_groups = translated_groups + 1
        }
      _ => ()
    }
  }
  inspect(fill_count, content="3")
  inspect(translated_groups, content="2")
}

///|
test "dash_stroke/rendering" {
  // Test that dash stroke emits SetLineDash command
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([80.0, 80.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="st",
              data=@model.ShapeData::new_stroke(
                @model.StrokeShape::new(
                  color=@model.LottieProperty::new_static([0.0, 0.0, 0.0]),
                  opacity=@model.LottieProperty::new_static(100.0),
                  width=@model.LottieProperty::new_static(2.0),
                  dashes=[
                    @model.DashItem::new(
                      name="d",
                      value=@model.LottieProperty::new_static(10.0),
                    ),
                    @model.DashItem::new(
                      name="g",
                      value=@model.LottieProperty::new_static(5.0),
                    ),
                    @model.DashItem::new(
                      name="o",
                      value=@model.LottieProperty::new_static(3.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  // Verify SetLineDash command was emitted
  let mut found_dash = false
  for cmd in cmds {
    match cmd {
      SetLineDash(arr, offset) => {
        found_dash = true
        // dash=10, gap=5 (offset "o" is separate)
        inspect(arr.length(), content="2")
        inspect(arr[0], content="10")
        inspect(arr[1], content="5")
        inspect(offset, content="3")
      }
      _ => ()
    }
  }
  if !found_dash { fail("SetLineDash command should be emitted") }
}

///|
test "gradient_dash_stroke/rendering" {
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([80.0, 80.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="gs",
              data=@model.ShapeData::new_gradient_stroke(
                @model.GradientStrokeShape::new(
                  gradient_type=1,
                  opacity=@model.LottieProperty::new_static(100.0),
                  start_point=@model.LottieProperty::new_static([0.0, 0.0]),
                  end_point=@model.LottieProperty::new_static([100.0, 0.0]),
                  gradient_colors=@model.GradientColors::new(
                    color_count=2,
                    color_stops=@model.LottieProperty::new_static([
                      0.0,
                      1.0,
                      0.0,
                      0.0,
                      1.0,
                      0.0,
                      0.0,
                      1.0,
                    ]),
                  ),
                  width=@model.LottieProperty::new_static(2.0),
                  dashes=[
                    @model.DashItem::new(
                      name="d",
                      value=@model.LottieProperty::new_static(10.0),
                    ),
                    @model.DashItem::new(
                      name="g",
                      value=@model.LottieProperty::new_static(5.0),
                    ),
                    @model.DashItem::new(
                      name="o",
                      value=@model.LottieProperty::new_static(3.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  let mut found_dash = false
  for cmd in cmds {
    match cmd {
      SetLineDash(arr, offset) => {
        found_dash = true
        inspect(arr.length(), content="2")
        inspect(arr[0], content="10")
        inspect(arr[1], content="5")
        inspect(offset, content="3")
      }
      _ => ()
    }
  }
  if !found_dash { fail("SetLineDash command should be emitted for gradient stroke") }
}

///|
test "gradient_stroke_without_dashes_resets_canvas_dash" {
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=120,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([80.0, 80.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="gs",
              data=@model.ShapeData::new_gradient_stroke(
                @model.GradientStrokeShape::new(
                  gradient_type=1,
                  opacity=@model.LottieProperty::new_static(100.0),
                  start_point=@model.LottieProperty::new_static([0.0, 0.0]),
                  end_point=@model.LottieProperty::new_static([100.0, 0.0]),
                  gradient_colors=@model.GradientColors::new(
                    color_count=2,
                    color_stops=@model.LottieProperty::new_static([
                      0.0,
                      1.0,
                      0.0,
                      0.0,
                      1.0,
                      0.0,
                      0.0,
                      1.0,
                    ]),
                  ),
                  width=@model.LottieProperty::new_static(2.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()

  let dash_commands : Array[(Int, Double)] = []
  for cmd in cmds {
    match cmd {
      SetLineDash(arr, offset) => dash_commands.push((arr.length(), offset))
      _ => ()
    }
  }

  inspect(dash_commands.length(), content="1")
  inspect(dash_commands[0].0, content="0")
  inspect(dash_commands[0].1, content="0")
}

///|
test "merge_paths/noop" {
  // lottie-web ignores MergePaths (ty="mm") in both SVG and canvas renderers.
  // The fill-rule is determined by the fill shape's own `r` property (1=nonzero,
  // 2=evenodd). MergePaths itself must not change the fill-rule.
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([80.0, 80.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([60.0, 60.0]),
                  size=@model.LottieProperty::new_static([40.0, 40.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="mm",
              data=@model.ShapeData::new_merge_paths(
                @model.MergePaths::new(3), // Subtract mode — must be ignored
              ),
            ),
            @model.Shape::new(
              shape_type="fl",
              data=@model.ShapeData::new_fill(
                @model.FillShape::new(
                  color=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
                  opacity=@model.LottieProperty::new_static(100.0),
                  // r=1 (nonzero) is the default
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  // MergePaths must not produce "evenodd"; fill with r=1 must use "nonzero"
  let mut found_evenodd = false
  let mut found_nonzero = false
  for cmd in cmds {
    match cmd {
      SetFillRule("evenodd") => found_evenodd = true
      SetFillRule("nonzero") => found_nonzero = true
      _ => ()
    }
  }
  if found_evenodd { fail("MergePaths must not set fill-rule to evenodd") }
  if !found_nonzero { fail("Fill with r=1 should set fill-rule to nonzero") }
}

///|
test "fill_rule/evenodd_from_r_property" {
  // A fill shape with r=2 must render with fill-rule="evenodd", matching
  // lottie-web: `if (data.r === 2) { pathElement.setAttribute('fill-rule', 'evenodd'); }`
  let anim = @model.Animation::new(
    version="5.5.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=10.0,
    width=100,
    height=100,
    layers=[
      @model.Layer::new(
        index=1,
        layer_type=4,
        transform=@model.Transform::new_default(),
        in_point=0.0,
        out_point=10.0,
        start_time=0.0,
        data=@model.LayerData::Shape(
          [
            @model.Shape::new(
              shape_type="rc",
              data=@model.ShapeData::new_rect(
                @model.RectShape::new(
                  position=@model.LottieProperty::new_static([50.0, 50.0]),
                  size=@model.LottieProperty::new_static([80.0, 80.0]),
                  roundness=@model.LottieProperty::new_static(0.0),
                ),
              ),
            ),
            @model.Shape::new(
              shape_type="fl",
              data=@model.ShapeData::new_fill(
                @model.FillShape::new(
                  color=@model.LottieProperty::new_static([1.0, 0.0, 0.0]),
                  opacity=@model.LottieProperty::new_static(100.0),
                  fill_rule=2, // evenodd
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
  let recorder = CommandRecorder::new()
  let player = Player::new(anim, recorder)
  player.set_frame(0.0)
  player.render()
  let cmds = recorder.get_commands()
  let mut found_evenodd = false
  for cmd in cmds {
    match cmd {
      SetFillRule("evenodd") => found_evenodd = true
      _ => ()
    }
  }
  if !found_evenodd { fail("Fill with r=2 should set fill-rule to evenodd") }
}
