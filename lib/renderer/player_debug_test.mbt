///| Validate Player debug log context for minimal render repro.
test "player debug logs are toggleable with layer/shape/property/frame context" {
  let json_str = "{\"v\":\"5.5.2\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"nm\":\"debug-test\",\"ddd\":0,\"assets\":[],\"layers\":[{\"ty\":4,\"ind\":1,\"nm\":\"layer-a\",\"ip\":0,\"op\":10,\"st\":0,\"ks\":{\"p\":{\"a\":0,\"k\":[50,50]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100},\"a\":{\"a\":0,\"k\":[0,0]}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"group-a\",\"it\":[{\"ty\":\"rc\",\"nm\":\"rect-a\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[0,0]},\"r\":{\"a\":0,\"k\":0}},{\"ty\":\"fl\",\"nm\":\"fill-a\",\"c\":{\"a\":0,\"k\":[1,0,0]},\"o\":{\"a\":0,\"k\":100}},{\"ty\":\"tr\",\"nm\":\"tr-a\",\"p\":{\"a\":0,\"k\":[0,0]},\"a\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let player = Player::new(ani, CommandRecorder::new())

  player.set_frame(0.0)
  player.render()
  assert_eq(player.get_debug_logs().length(), 0)

  player.set_debug(true)
  player.render()

  let logs = player.get_debug_logs()
  assert_true(logs.length() > 0, "debug logs should be recorded when enabled")
  assert_true(
    logs[0].contains("frame=0"),
    "debug log should include frame context",
  )
  assert_true(
    logs[0].contains("layer=layer-a#1"),
    "debug log should include layer context",
  )
  assert_true(
    logs[1].contains("shape=group-a:gr"),
    "debug log should include shape context",
  )
  assert_true(
    logs[1].contains("property=gr"),
    "debug log should include property context",
  )
}

test "sibling groups with own fill should not leak paths to next group" {
  let json_str = "{\"v\":\"5.5.2\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"nm\":\"group-scope-test\",\"ddd\":0,\"assets\":[],\"layers\":[{\"ty\":4,\"ind\":1,\"nm\":\"layer-a\",\"ip\":0,\"op\":10,\"st\":0,\"ks\":{\"p\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100},\"a\":{\"a\":0,\"k\":[0,0]}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"group-red\",\"it\":[{\"ty\":\"rc\",\"nm\":\"rect-red\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[10,10]},\"r\":{\"a\":0,\"k\":0}},{\"ty\":\"fl\",\"nm\":\"fill-red\",\"c\":{\"a\":0,\"k\":[1,0,0]},\"o\":{\"a\":0,\"k\":100}},{\"ty\":\"tr\",\"nm\":\"tr-red\",\"p\":{\"a\":0,\"k\":[0,0]},\"a\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}}]},{\"ty\":\"gr\",\"nm\":\"group-blue\",\"it\":[{\"ty\":\"rc\",\"nm\":\"rect-blue\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[60,10]},\"r\":{\"a\":0,\"k\":0}},{\"ty\":\"fl\",\"nm\":\"fill-blue\",\"c\":{\"a\":0,\"k\":[0,0,1]},\"o\":{\"a\":0,\"k\":100}},{\"ty\":\"tr\",\"nm\":\"tr-blue\",\"p\":{\"a\":0,\"k\":[0,0]},\"a\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut fill_count = 0
  let mut in_path = false
  let mut move_count_in_current_path = 0
  let mut second_fill_path_move_count : Int? = None

  for command in commands {
    match command {
      BeginPath => {
        in_path = true
        move_count_in_current_path = 0
      }
      MoveTo(_, _) =>
        if in_path {
          move_count_in_current_path = move_count_in_current_path + 1
        }
      Fill(_, _, _, _) => {
        fill_count = fill_count + 1
        if fill_count == 2 {
          second_fill_path_move_count = Some(move_count_in_current_path)
        }
        in_path = false
      }
      _ => ()
    }
  }

  assert_eq(fill_count, 2)
  assert_eq(second_fill_path_move_count, Some(1))
}

test "svg-exported layer renders top-level groups in reverse order" {
  let json_str = "{\"v\":\"5.5.2\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"nm\":\"shape-order-test\",\"ddd\":0,\"assets\":[],\"layers\":[{\"ty\":4,\"ind\":1,\"nm\":\"Shape Layer - SVG\",\"ip\":0,\"op\":10,\"st\":0,\"ks\":{\"p\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100},\"a\":{\"a\":0,\"k\":[0,0]}},\"shapes\":[{\"ty\":\"gr\",\"nm\":\"foreground-red\",\"it\":[{\"ty\":\"rc\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[10,10]},\"r\":{\"a\":0,\"k\":0}},{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":[1,0,0]},\"o\":{\"a\":0,\"k\":100}},{\"ty\":\"tr\",\"p\":{\"a\":0,\"k\":[0,0]},\"a\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}}]},{\"ty\":\"gr\",\"nm\":\"background-blue\",\"it\":[{\"ty\":\"rc\",\"s\":{\"a\":0,\"k\":[100,100]},\"p\":{\"a\":0,\"k\":[0,0]},\"r\":{\"a\":0,\"k\":0}},{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":[0,0,1]},\"o\":{\"a\":0,\"k\":100}},{\"ty\":\"tr\",\"p\":{\"a\":0,\"k\":[0,0]},\"a\":{\"a\":0,\"k\":[0,0]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100}}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut last_fill : DrawCommand? = None
  for command in commands {
    match command {
      Fill(_, _, _, _) => last_fill = Some(command)
      _ => ()
    }
  }
  match last_fill {
    Some(Fill(r, g, b, _)) => {
      assert_eq(r, 255)
      assert_eq(g, 0)
      assert_eq(b, 0)
    }
    _ => fail("Expected last fill to be red, got \{last_fill}")
  }
}

///| Verify layer transform is evaluated at composition frame, not local frame.
///|
///| A precomp layer with st=10 and animated position:
///|   t=10 → [0, 0], t=30 → [100, 0]
///| At composition frame 20, the correct position is [50, 0] (50% interpolation).
///| Before the fix, it was evaluated at local_frame=10 (= 20 - st=10),
///| which is exactly at the first keyframe (t=10), returning [0, 0].
test "layer transform uses composition frame not local frame" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":50,"w":200,"h":200,"assets":[{"id":"comp_1","layers":[{"ty":1,"ind":1,"ip":0,"op":50,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"sw":200,"sh":200,"sc":"#ff0000"}]}],"layers":[{"ty":0,"ind":1,"refId":"comp_1","w":200,"h":200,"ip":10,"op":30,"st":10,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"a":1,"k":[{"t":10,"s":[0,0]},{"t":30,"s":[100,0]}]}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)

  // At composition frame 20: layer st=10, so local_frame=10.
  // Keyframes are at t=10 and t=30 in composition time.
  // Progress = (20-10)/(30-10) = 0.5 → position x should be 50 (midpoint).
  player.set_frame(20.0)
  player.render()

  let commands = recorder.get_commands()
  let mut found_translate_x : Double? = None
  for cmd in commands {
    match cmd {
      ConcatTransform(m) =>
        if m.e != 0.0 || m.f != 0.0 {
          found_translate_x = Some(m.e)
        }
      _ => ()
    }
  }
  match found_translate_x {
    Some(x) =>
      // x should be ~50 (interpolated at 50%), not 0 (stuck at start)
      if x < 1.0 {
        fail(
          "Layer transform was not interpolated correctly: x=\{x} (expected ~50). Transform is being evaluated at local_frame instead of comp_frame.",
        )
      }
    None => fail("No non-zero ConcatTransform found in commands")
  }
}

test "shape properties use composition frame when layer has non-zero st" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":50,"w":200,"h":200,"layers":[{"ty":4,"ind":1,"nm":"shape-st-layer","ip":10,"op":30,"st":10,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},"shapes":[{"ty":"rc","s":{"k":[20,20]},"p":{"a":1,"k":[{"t":10,"s":[0,0]},{"t":30,"s":[100,0]}]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,0,0]},"o":{"k":100}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  let epsilon = 0.0001

  player.set_frame(20.0)
  player.render()

  let commands = recorder.get_commands()
  let mut first_move_x : Double? = None
  for cmd in commands {
    match cmd {
      MoveTo(x, _) => {
        first_move_x = Some(x)
        break
      }
      _ => ()
    }
  }
  match first_move_x {
    Some(x) => {
      if x < 40.0 - epsilon || x > 40.0 + epsilon {
        fail(
          "Shape property was not evaluated at composition frame: MoveTo x=\{x}, expected 40.0",
        )
      }
    }
    None => fail("Expected MoveTo command for rectangle path")
  }
}

test "image layer uses asset source path for draw_image" {
  let json_str =
    #|{"v":"5.5.2","fr":30,"ip":0,"op":10,"w":100,"h":100,"assets":[{"id":"img_0","w":8,"h":8,"u":"","p":"data:image/png;base64,abc"}],"layers":[{"ty":2,"ind":1,"refId":"img_0","ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut image_href : String? = None
  for cmd in commands {
    match cmd {
      DrawImage(src, _, _) => {
        image_href = Some(src)
        break
      }
      _ => ()
    }
  }
  assert_eq(image_href, Some("data:image/png;base64,abc"))
}
