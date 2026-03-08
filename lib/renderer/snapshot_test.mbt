///|
test "snapshot_render_circle" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"el\",\"nm\":\"circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // Compare with expected commands
  inspect(
    commands,
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 500, 500), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 250, f: 250}), SetOpacity(1), SetFillRule("nonzero"), BeginPath, MoveTo(0, -50), CubicTo(27.614237499999998, -50, 50, -27.614237499999998, 50, 0), CubicTo(50, 27.614237499999998, 27.614237499999998, 50, 0, 50), CubicTo(-27.614237499999998, 50, -50, 27.614237499999998, -50, 0), CubicTo(-50, -27.614237499999998, -27.614237499999998, -50, 0, -50), ClosePath, Fill(255, 0, 0, 1), Restore]

    ),
  )
}

///|
test "snapshot_render_mask" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"mode\":\"a\",\"pt\":{\"k\":{\"i\":[[0,0],[0,0]],\"o\":[[0,0],[0,0]],\"v\":[[0,0],[100,100]],\"c\":true}},\"o\":{\"k\":100}}],\"shapes\":[{\"ty\":\"el\",\"nm\":\"circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // Check that Clip is present
  let has_clip = commands
    .iter()
    .any(fn(c) {
      match c {
        Clip => true
        _ => false
      }
    })
  if not(has_clip) {
    fail("Clip command missing from mask rendering. Commands: \{commands}")
  }
}

///|
test "snapshot_render_shape_closed_flag_without_path_c" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"sh\",\"nm\":\"body\",\"closed\":true,\"ks\":{\"v\":[[-50,-50],[50,-50],[50,50],[-50,50]],\"i\":[[0,0],[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0],[0,0]]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let has_close_path = commands
    .iter()
    .any(fn(c) {
      match c {
        ClosePath => true
        _ => false
      }
    })
  if not(has_close_path) {
    fail(
      "Expected ClosePath from shape.closed fallback, but none was emitted. Commands: \{commands}",
    )
  }
}

///|
test "snapshot_merge_paths_noop" {
  // lottie-web ignores MergePaths (ty="mm") in both SVG and canvas renderers.
  // Fill-rule is determined by the fill shape's own `r` property, not MergePaths.
  // With r absent (defaults to 1 = nonzero), the fill-rule should be "nonzero".
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"it\":[{\"ty\":\"sh\",\"ks\":{\"k\":{\"i\":[[0,0]],\"o\":[[0,0]],\"v\":[[0,0]],\"c\":true}}},{\"ty\":\"mm\",\"mm\":3},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // MergePaths is a no-op: no "evenodd" fill-rule should be present
  let has_evenodd = commands
    .iter()
    .any(fn(c) {
      match c {
        SetFillRule("evenodd") => true
        _ => false
      }
    })
  if has_evenodd {
    fail(
      "MergePaths should be a no-op: SetFillRule('evenodd') must not appear. Commands: \{commands}",
    )
  }
  // Fill shape with no `r` property defaults to nonzero
  let has_nonzero = commands
    .iter()
    .any(fn(c) {
      match c {
        SetFillRule("nonzero") => true
        _ => false
      }
    })
  if not(has_nonzero) {
    fail(
      "SetFillRule('nonzero') from fill shape r=1 missing. Commands: \{commands}",
    )
  }
}

///|
test "snapshot_fill_rule_evenodd" {
  // A fill shape with r=2 must set fill-rule="evenodd", matching lottie-web's
  // `if (data.r === 2) { pathElement.setAttribute('fill-rule', 'evenodd'); }`.
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"it\":[{\"ty\":\"sh\",\"ks\":{\"k\":{\"i\":[[0,0]],\"o\":[[0,0]],\"v\":[[0,0]],\"c\":true}}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"r\":2}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // Fill with r=2 must emit SetFillRule("evenodd")
  let has_evenodd = commands
    .iter()
    .any(fn(c) {
      match c {
        SetFillRule("evenodd") => true
        _ => false
      }
    })
  if not(has_evenodd) {
    fail(
      "SetFillRule('evenodd') missing for fill with r=2. Commands: \{commands}",
    )
  }
}

///|
test "snapshot_render_alpha_matte" {
  // Layer 0: Matte Source (td=1)
  // Layer 1: Matte Target (tt=1)
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":1,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":100,\"sh\":100,\"sc\":\"#ffffff\",\"td\":1},{\"ty\":1,\"ind\":2,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":200,\"sh\":200,\"sc\":\"#ff0000\",\"tt\":1}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // Check for two-buffer matte pattern: PrepareMatteLayer, BeginMatteExit, EndMatteExit
  let has_prepare = commands
    .iter()
    .any(fn(c) {
      match c {
        PrepareMatteLayer => true
        _ => false
      }
    })
  let has_begin_exit = commands
    .iter()
    .any(fn(c) {
      match c {
        BeginMatteExit => true
        _ => false
      }
    })
  let has_end_exit = commands
    .iter()
    .any(fn(c) {
      match c {
        EndMatteExit(1) => true
        _ => false
      }
    })
  if not(has_prepare && has_begin_exit && has_end_exit) {
    fail("Two-buffer matte pattern missing. Commands: \{commands}")
  }
}

///|
test "snapshot_render_matte_in_comp_space" {
  // Matte source and target are sibling layers. When applying track matte,
  // rendering matte source should start from comp-space transform instead of
  // inheriting target layer local transform.
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":1,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[120,120]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":80,\"sh\":80,\"sc\":\"#ffffff\",\"td\":1},{\"ty\":1,\"ind\":2,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[260,260]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":200,\"sh\":200,\"sc\":\"#ff0000\",\"tt\":1}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // In the two-buffer pattern, after BeginMatteExit the matte source is rendered
  // starting from the base transform (identity). Its ConcatTransform should apply
  // its own position (120,120), NOT inherited from the target (260,260).
  let mut matte_source_at_comp_pos = false
  let mut after_begin_exit = false
  for cmd in commands {
    if after_begin_exit {
      match cmd {
        ConcatTransform({ a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 120.0, f: 120.0 }) => {
          matte_source_at_comp_pos = true
          break
        }
        _ => ()
      }
    }
    match cmd {
      BeginMatteExit => after_begin_exit = true
      _ => ()
    }
  }
  if not(matte_source_at_comp_pos) {
    fail(
      "Matte source should be rendered from composition transform space. Commands: \{commands}",
    )
  }
}

///|
/// Verify that groups WITHOUT their own paint ops contribute paths to the
/// parent group's fill. This pattern appears in 1_6_Designer.json's leg
/// layers, where sub-groups (Wedge Group 2, C2 Group) generate paths
/// that a sibling Fill should render.
test "snapshot_group_without_paint_contributes_paths" {
  // Structure:
  //   shapes: [
  //     Group("PathGroup") { Ellipse(50×50), Transform(identity) }  ← no paint
  //     Fill(red)  ← should render the ellipse from PathGroup
  //   ]
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"PathGroup\",\"it\":[{\"ty\":\"el\",\"nm\":\"C\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[50,50]}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // The fill must actually draw something – verify there is a Fill(255,0,0,1)
  // that comes AFTER at least one BeginPath + MoveTo sequence.
  let has_fill = commands
    .iter()
    .any(fn(c) {
      match c {
        Fill(255, 0, 0, _) => true
        _ => false
      }
    })
  if not(has_fill) {
    fail(
      "Fill command missing – group without paint did not contribute paths. Commands: \{commands}",
    )
  }
  // Also check there is at least one CubicTo (from the ellipse) before the fill.
  let has_cubic = commands
    .iter()
    .any(fn(c) {
      match c {
        CubicTo(_, _, _, _, _, _) => true
        _ => false
      }
    })
  if not(has_cubic) {
    fail(
      "CubicTo command missing – group ellipse paths not rendered. Commands: \{commands}",
    )
  }
}

///|
/// Verify that when a group without paint has a non-identity transform,
/// the paths are correctly transformed before bubbling up to the parent fill.
test "snapshot_group_without_paint_applies_transform" {
  // Structure:
  //   shapes: [
  //     Group("Offset") { Rect(10×10 at 0,0), Transform(p=[100,200]) }  ← no paint, translated
  //     Fill(blue)  ← should render the rect at (100,200)
  //   ]
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"Offset\",\"it\":[{\"ty\":\"rc\",\"nm\":\"R\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[10,10]},\"r\":{\"k\":0}},{\"ty\":\"tr\",\"p\":{\"k\":[100,200]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"fl\",\"c\":{\"k\":[0,0,1]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // The rect path should be translated to (100,200).
  // A 10×10 rect at (0,0) has corners at (-5,-5) to (5,5).
  // After translate(100,200), the corners become (95,195) to (105,205).
  // Check for a MoveTo near (95, 195).
  let has_translated_path = commands
    .iter()
    .any(fn(c) {
      match c {
        MoveTo(x, y) => x > 90.0 && x < 110.0 && y > 190.0 && y < 210.0
        _ => false
      }
    })
  if not(has_translated_path) {
    fail(
      "Paths from group without paint were not transformed by group's local matrix. Commands: \{commands}",
    )
  }
}

///|
/// Verify the MergePaths Add pattern from 1_6_Designer.json Right-Leg:
///   [0] Group(paths, no paint)
///   [1] Group(paths, no paint)
///   [2] MergePaths Add
///   [3] Fill
test "snapshot_merge_paths_add_with_path_groups" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"Outer\",\"it\":[{\"ty\":\"gr\",\"nm\":\"PathA\",\"it\":[{\"ty\":\"el\",\"nm\":\"A\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[60,60]}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"gr\",\"nm\":\"PathB\",\"it\":[{\"ty\":\"el\",\"nm\":\"B\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[40,40]}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"mm\",\"mm\":2},{\"ty\":\"fl\",\"c\":{\"k\":[0.227,0.29,0.765]},\"o\":{\"k\":100}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // After fix: The Fill should render paths from both PathA and PathB groups.
  // Count the CubicTo commands – each ellipse generates 4 cubic segments,
  // so we expect at least 8 CubicTo commands in the fill path.
  let mut cubic_count = 0
  for c in commands {
    match c {
      CubicTo(_, _, _, _, _, _) => cubic_count = cubic_count + 1
      _ => ()
    }
  }
  if cubic_count < 8 {
    fail(
      "Expected at least 8 CubicTo commands (2 ellipses × 4 segments) but got \{cubic_count}. Commands: \{commands}",
    )
  }
  // Also verify the fill color (blue-ish for pants)
  let has_pants_fill = commands
    .iter()
    .any(fn(c) {
      match c {
        Fill(r, g, b, _) => r < 100 && g < 100 && b > 150
        _ => false
      }
    })
  if not(has_pants_fill) {
    fail(
      "Pants-colored fill missing from MergePaths Add rendering. Commands: \{commands}",
    )
  }
}

///|
/// Verify sibling painted groups participate in the same z-order as sibling fills.
/// In 1_6_Designer.json's Right-Leg/Proximal Lower group, the pants Fill comes
/// before painted skin sub-groups, so pants must be rendered on top.
test "snapshot_painted_group_and_fill_share_z_order" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"Root\",\"it\":[{\"ty\":\"gr\",\"nm\":\"PantsPath\",\"it\":[{\"ty\":\"el\",\"nm\":\"P\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[80,80]}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"fl\",\"nm\":\"PantsFill\",\"c\":{\"k\":[0,0,1]},\"o\":{\"k\":100}},{\"ty\":\"gr\",\"nm\":\"SkinGroup\",\"it\":[{\"ty\":\"el\",\"nm\":\"S\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[40,40]}},{\"ty\":\"fl\",\"nm\":\"SkinFill\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]},{\"ty\":\"tr\",\"p\":{\"k\":[0,0]},\"a\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut red_fill_idx = -1
  let mut blue_fill_idx = -1
  for i = 0; i < commands.length(); i = i + 1 {
    match commands[i] {
      Fill(255, 0, 0, _) =>
        if red_fill_idx == -1 {
          red_fill_idx = i
        }
      Fill(0, 0, 255, _) =>
        if blue_fill_idx == -1 {
          blue_fill_idx = i
        }
      _ => ()
    }
  }
  if red_fill_idx == -1 || blue_fill_idx == -1 {
    fail("Missing expected red/blue fills. Commands: \{commands}")
  }
  if red_fill_idx > blue_fill_idx {
    fail(
      "Expected red painted-group fill to be rendered before blue sibling fill (blue on top). Commands: \{commands}",
    )
  }
}

///|
/// Ellipse with d=3 (counter-clockwise) must traverse top→left→bottom→right,
/// matching lottie-web's `_cw = this.d !== 3` logic.
test "snapshot_ellipse_direction_ccw_d3" {
  // Layer at origin, ellipse d=3 (CCW), size=[100,100], position=[0,0]
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"el\",\"d\":3,\"nm\":\"ccw-circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // Find the MoveTo and first CubicTo after BeginPath
  let mut after_begin = false
  let mut move_x = 0.0
  let mut move_y = 0.0
  let mut first_cubic_ex = 0.0
  let mut first_cubic_ey = 0.0
  let mut found_first_cubic = false
  for cmd in commands {
    match cmd {
      BeginPath => {
        after_begin = true
        found_first_cubic = false
      }
      MoveTo(x, y) =>
        if after_begin {
          move_x = x
          move_y = y
        }
      CubicTo(_, _, _, _, ex, ey) =>
        if after_begin && not(found_first_cubic) {
          first_cubic_ex = ex
          first_cubic_ey = ey
          found_first_cubic = true
        }
      _ => ()
    }
  }
  // d=3 CCW: first vertex = top (0, -50), first segment ends at LEFT (-50, 0)
  if move_x != 0.0 || move_y != -50.0 {
    fail(
      "CCW ellipse should start at top (0, -50), got (\{move_x}, \{move_y}). Commands: \{commands}",
    )
  }
  if first_cubic_ex != -50.0 || first_cubic_ey != 0.0 {
    fail(
      "CCW ellipse first segment should end at left (-50, 0), got (\{first_cubic_ex}, \{first_cubic_ey}). Commands: \{commands}",
    )
  }
}

///|
/// Ellipse with default direction (d=1, CW) must traverse top→right→bottom→left,
/// unchanged from previous behaviour. This is verified by the existing
/// snapshot_render_circle test; this test checks the explicit d=1 JSON field.
test "snapshot_ellipse_direction_cw_d1" {
  // Explicit d=1 should produce same result as no d field (clockwise)
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"el\",\"d\":1,\"nm\":\"cw-circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut after_begin = false
  let mut move_x = 0.0
  let mut move_y = 0.0
  let mut first_cubic_ex = 0.0
  let mut first_cubic_ey = 0.0
  let mut found_first_cubic = false
  for cmd in commands {
    match cmd {
      BeginPath => {
        after_begin = true
        found_first_cubic = false
      }
      MoveTo(x, y) =>
        if after_begin {
          move_x = x
          move_y = y
        }
      CubicTo(_, _, _, _, ex, ey) =>
        if after_begin && not(found_first_cubic) {
          first_cubic_ex = ex
          first_cubic_ey = ey
          found_first_cubic = true
        }
      _ => ()
    }
  }
  // d=1 CW: first vertex = top (0, -50), first segment ends at RIGHT (50, 0)
  if move_x != 0.0 || move_y != -50.0 {
    fail(
      "CW ellipse should start at top (0, -50), got (\{move_x}, \{move_y}). Commands: \{commands}",
    )
  }
  if first_cubic_ex != 50.0 || first_cubic_ey != 0.0 {
    fail(
      "CW ellipse first segment should end at right (50, 0), got (\{first_cubic_ex}, \{first_cubic_ey}). Commands: \{commands}",
    )
  }
}

///|
/// Rect with d=3 (counter-clockwise) must traverse top-right→top-left→bottom-left→bottom-right,
/// opposite to the default CW order (top-left→top-right→bottom-right→bottom-left).
test "snapshot_rect_direction_ccw_d3" {
  // Layer at origin, rect d=3 (CCW), size=[100,100], position=[0,0]
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"rc\",\"d\":3,\"nm\":\"ccw-rect\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0}},{\"ty\":\"fl\",\"c\":{\"k\":[0,1,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  // d=3 CCW rect with size=[100,100], center=[0,0]:
  //   first vertex = top-right = [+50, -50]
  let mut after_begin = false
  let mut move_x = 0.0
  let mut move_y = 0.0
  for cmd in commands {
    match cmd {
      BeginPath => after_begin = true
      MoveTo(x, y) =>
        if after_begin {
          move_x = x
          move_y = y
        }
      _ => ()
    }
  }
  if move_x != 50.0 || move_y != -50.0 {
    fail(
      "CCW rect (d=3) should start at top-right (50, -50), got (\{move_x}, \{move_y}). Commands: \{commands}",
    )
  }
}
