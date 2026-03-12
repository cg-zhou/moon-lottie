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

test "trim path after painted group trims deferred stroke paths" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":200,"layers":[{"ty":4,"ind":1,"nm":"trim-after-group","ip":0,"op":10,"st":0,"ks":{"p":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100},"a":{"a":0,"k":[0,0]}},"shapes":[{"ty":"gr","nm":"path-group","it":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[0,0],[100,0]],"c":false}}},{"ty":"st","c":{"a":0,"k":[1,0,0]},"o":{"a":0,"k":100},"w":{"a":0,"k":2},"lc":2,"lj":1,"ml":4},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"tm","s":{"a":0,"k":25},"e":{"a":0,"k":75},"o":{"a":0,"k":0},"m":2}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  let epsilon = 0.02

  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut first_move : (Double, Double)? = None
  let mut first_path_end : (Double, Double)? = None
  for cmd in commands {
    match cmd {
      MoveTo(x, y) =>
        if first_move is None {
          first_move = Some((x, y))
        }
      LineTo(x, y) =>
        if first_path_end is None {
          first_path_end = Some((x, y))
        }
      CubicTo(_, _, _, _, x, y) =>
        if first_path_end is None {
          first_path_end = Some((x, y))
        }
      _ => ()
    }
  }

  match first_move {
    Some((x, y)) => {
      if x < 25.0 - epsilon || x > 25.0 + epsilon || y != 0.0 {
        fail("Trimmed stroke start mismatch: (\{x}, \{y}), expected (25, 0)")
      }
    }
    None => fail("Expected MoveTo command for trimmed stroke")
  }

  match first_path_end {
    Some((x, y)) => {
      if x < 75.0 - epsilon || x > 75.0 + epsilon || y != 0.0 {
        fail("Trimmed stroke end mismatch: (\{x}, \{y}), expected (75, 0)")
      }
    }
    None => fail("Expected path segment command for trimmed stroke end")
  }
}

///| Verify layer transform is evaluated at composition frame.
///|
///| Layer: st=10, ip=10, op=50, keyframes at t=10→[0,0], t=30→[100,0].
///| At composition frame 20, transform should sample frame 20 (x≈50),
///| not layer-local frame 10 (x=0).
test "layer transform uses composition frame timing" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":50,"w":200,"h":200,"assets":[{"id":"comp_1","layers":[{"ty":1,"ind":1,"ip":0,"op":50,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"sw":200,"sh":200,"sc":"#ff0000"}]}],"layers":[{"ty":0,"ind":1,"refId":"comp_1","w":200,"h":200,"ip":10,"op":50,"st":10,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"a":1,"k":[{"t":10,"s":[0,0]},{"t":30,"s":[100,0]}]}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)

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
      // x should be ~50 at comp frame 20.
      if x < 49.999 || x > 50.001 {
        fail(
          "Layer transform timing mismatch: x=\{x}, expected around 50 at composition frame 20",
        )
      }
    None => fail("No non-zero ConcatTransform found in commands")
  }
}

///| Verify that shape properties inside a layer with non-zero st are evaluated
///| at composition frame (matching lottie-web's behaviour).
///|
///| lottie-web computes: frameNum = comp.renderedFrame - offsetTime (offsetTime = st)
///| and compares against kf.t - offsetTime, which is mathematically equivalent
///| to evaluating at comp.renderedFrame vs raw kf.t values.
///|
///| Layer: ip=10, op=30, st=10. Rect p keyframes at t=10→[0,0], t=30→[100,0].
///| At comp_frame=20: progress=(20-10)/(30-10)=0.5 → p=[50,0] → rect corner x=40.
test "shape properties use composition frame timing" {
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
  // At comp_frame=20: progress=(20-10)/(30-10)=0.5 → p=[50,0] → rect corner x=40.
  // (lottie-web evaluates at comp_frame vs raw kf.t, not layer_frame vs raw kf.t)
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

///| Verify that precomp layer transform keyframes are sampled in composition time.
///|
///| Layer: ip=89, op=150, st=89, keyframes at t=89→[0,0], t=149→[600,0].
///| At comp_frame=110, progress=(110-89)/(149-89)=0.35 → x≈210.
test "precomp layer with global keyframes animates after start" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":150,"w":600,"h":400,"assets":[{"id":"comp_walk","layers":[{"ty":1,"ind":1,"ip":0,"op":150,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"sw":600,"sh":400,"sc":"#ff0000"}]}],"layers":[{"ty":0,"ind":1,"refId":"comp_walk","w":600,"h":400,"ip":89,"op":150,"st":89,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"a":1,"k":[{"t":89,"s":[0,0]},{"t":149,"s":[600,0]}]}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)

  // At comp_frame=110: progress = 21/60 = 0.35 → x ≈ 210
  player.set_frame(110.0)
  player.render()

  let commands = recorder.get_commands()
  let mut translate_x : Double? = None
  for cmd in commands {
    match cmd {
      ConcatTransform(m) =>
        if m.e != 0.0 || m.f != 0.0 {
          translate_x = Some(m.e)
        }
      _ => ()
    }
  }
  match translate_x {
    Some(x) =>
      if x < 209.999 || x > 210.001 {
        fail(
          "Walk layer position timing mismatch: x=\{x}, expected around 210 at comp frame 110",
        )
      }
    None => fail("No non-zero ConcatTransform found")
  }
}

test "track matte uses composition frame timing" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":60,"w":200,"h":200,"layers":[{"ty":4,"ind":1,"nm":"matte-src","ip":0,"op":60,"st":0,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"a":1,"k":[{"t":0,"s":[0,0]},{"t":20,"s":[100,0]}]}},"shapes":[{"ty":"rc","s":{"k":[40,40]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,1,1]},"o":{"k":100}}]},{"ty":4,"ind":2,"nm":"content","ip":0,"op":60,"st":30,"tt":1,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},"shapes":[{"ty":"rc","s":{"k":[80,80]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,0,0]},"o":{"k":100}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(20.0)
  player.render()

  let commands = recorder.get_commands()
  let mut max_translate_x = 0.0
  for cmd in commands {
    match cmd {
      ConcatTransform(m) =>
        if m.e > max_translate_x {
          max_translate_x = m.e
        }
      _ => ()
    }
  }

  // Matte source keyframes are local t=0 -> x=0 and t=20 -> x=100.
  // At composition frame 20, source should be evaluated with comp-frame timing,
  // regardless of target layer st=30, so x should be near 100.
  // Use a generous [80, 120] range to tolerate interpolation/float differences.
  if max_translate_x < 80.0 || max_translate_x > 120.0 {
    fail(
      "Track matte source transform evaluated at wrong frame: max x=\{max_translate_x}, expected around 100 at comp frame 20",
    )
  }
}

test "precomp layer time remap expression drives child frame" {
  let handler_received_layer_context : Ref[Bool] = { val: false }
  @runtime.install_expression_handlers(
    (expression, frame, layer_index, comp_id, value) =>
      if expression == "cycle-tm" {
        if layer_index == 1 && comp_id == "" {
          handler_received_layer_context.val = true
        }
        if frame >= 10.0 { frame - 10.0 } else { frame }
      } else {
        value
      },
    (_expression, _frame, _layer_index, _comp_id, value) => value,
    (_expression, _frame, _layer_index, _comp_id, value) => value,
  )
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":20,"w":200,"h":100,"assets":[{"id":"comp_1","layers":[{"ty":1,"ind":1,"ip":0,"op":20,"st":0,"ks":{"a":{"k":[0,0]},"p":{"a":1,"k":[{"t":0,"s":[0,0]},{"t":10,"s":[100,0]}]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"sw":20,"sh":20,"sc":"#ff0000"}]}],"layers":[{"ty":0,"ind":1,"refId":"comp_1","w":200,"h":100,"ip":0,"op":20,"st":0,"tm":{"a":0,"k":0,"x":"cycle-tm"},"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => {
      @runtime.clear_expression_handlers()
      fail("Failed to parse: \{e}")
    }
  }

  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(15.0)
  player.render()
  @runtime.clear_expression_handlers()

  let commands = recorder.get_commands()
  let mut translate_x : Double? = None
  for cmd in commands {
    match cmd {
      ConcatTransform(m) =>
        if m.e != 0.0 || m.f != 0.0 {
          translate_x = Some(m.e)
        }
      _ => ()
    }
  }
  match translate_x {
    Some(x) =>
      if x < 49.999 || x > 50.001 {
        fail(
          "Time-remapped precomp should sample child frame 5 at outer frame 15: x=\{x}, expected around 50",
        )
      }
    None => fail("No translated child transform found")
  }
  if not(handler_received_layer_context.val) {
    fail("Time remap expression handler should receive the current layer context")
  }
}

test "image layers use resolved asset source instead of asset id" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":100,"h":100,"assets":[{"id":"img_0","w":10,"h":20,"u":"data:image/png;base64,","p":"AAAA"}],"layers":[{"ty":2,"ind":1,"refId":"img_0","ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut image_info : (String, Int)? = None
  for cmd in commands {
    match cmd {
      DrawImage(src, _, _, asset_index) => {
        image_info = Some((src, asset_index))
        break
      }
      _ => ()
    }
  }
  assert_eq(image_info, Some(("data:image/png;base64,AAAA", 0)))
}

test "image layers preserve matched asset index for wasm bridge" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":100,"h":100,"assets":[{"id":"comp_0","layers":[]},{"id":"img_1","w":10,"h":20,"u":"data:image/png;base64,","p":"BBBB"}],"layers":[{"ty":2,"ind":1,"refId":"img_1","ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut image_info : (String, Int)? = None
  for cmd in commands {
    match cmd {
      DrawImage(src, _, _, asset_index) => {
        image_info = Some((src, asset_index))
        break
      }
      _ => ()
    }
  }
  assert_eq(image_info, Some(("data:image/png;base64,BBBB", 1)))
}

test "fill color accepts byte-range channels without rescaling" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":100,"h":100,"layers":[{"ty":4,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"shapes":[{"ty":"rc","s":{"k":[20,20]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[255,128,0]},"o":{"k":100}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut fill : DrawCommand? = None
  for cmd in commands {
    match cmd {
      Fill(_, _, _, _) => {
        fill = Some(cmd)
        break
      }
      _ => ()
    }
  }
  match fill {
    Some(Fill(r, g, b, _)) => {
      assert_eq(r, 255)
      assert_eq(g, 128)
      assert_eq(b, 0)
    }
    _ => fail("Expected Fill command")
  }
}

///| Verify that TrimPath inside a layer with non-zero st is evaluated at
///| composition frame — matching lottie-web offsetTime behaviour.
///|
///| Layer: ip=21, op=30, st=21.  Path is a horizontal line [-50, 50].
///| TrimPath s: keyframes t=23→0%, t=30→100%.
///| TrimPath e: keyframes t=21→0%, t=28→100%.
///| At comp_frame=28 (= last e-keyframe):
///|   lottie-web: frameNum = 28-21 = 7; kf_e_adj = {0, 7}; e = 100%
///|                                      kf_s_adj = {2, 9}; s = (7-2)/(9-2)*100 ≈ 71.4%
///|   → visible segment from ~71.4% to 100% of the path.
///|   Visible MoveTo ≈ x = -50 + 71.4% * 100 = 21.4
test "trim path uses composition frame timing for layer with non-zero st" {
  // Minimal composition mirroring the rocket flame structure:
  // one shape layer with st=21, ip=21, op=30 containing a horizontal stroke
  // and a TrimPath that animates with keyframes in composition time.
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":30,"w":100,"h":100,"layers":[{"ty":4,"ind":1,"nm":"sl7","ip":21,"op":30,"st":21,"ks":{"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"p":{"k":[0,0]}},"shapes":[{"ty":"gr","nm":"g1","it":[{"ty":"sh","nm":"path1","ks":{"a":0,"k":{"i":[[0,0],[0,0]],"o":[[0,0],[0,0]],"v":[[-50,0],[50,0]],"c":false}}},{"ty":"st","c":{"k":[1,0,0]},"o":{"k":100},"w":{"k":5},"lc":2,"lj":1,"ml":4},{"ty":"tr","p":{"k":[0,0]},"a":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}]},{"ty":"tm","s":{"a":1,"k":[{"i":{"x":[0.833],"y":[0.833]},"o":{"x":[0.167],"y":[0.167]},"t":23,"s":[0]},{"t":30,"s":[100]}],"ix":1},"e":{"a":1,"k":[{"i":{"x":[0.833],"y":[0.833]},"o":{"x":[0.167],"y":[0.167]},"t":21,"s":[0]},{"t":28,"s":[100]}],"ix":2},"o":{"a":0,"k":0,"ix":3},"m":1}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)

  // At comp_frame=28: e=100%, s≈71.4% (with cubic easing; exact value below)
  // The visible path starts around x≈21.4 (= -50 + 71.4% * 100).
  player.set_frame(28.0)
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
  // Path should start around x=21.4 (not at -50 which would happen if
  // evaluated at layer_frame=7 < first-keyframe → s=0%, e=0%).
  // lottie-web gives x≈21.43 at frame 28 for this exact animation.
  match first_move_x {
    Some(x) => {
      // lottie-web: x ≈ 21.43.  Accept a loose range around that value.
      if x < 15.0 || x > 35.0 {
        fail(
          "TrimPath start x=\{x} is outside expected range [15, 35] (lottie-web gives ≈21.4); composition-frame timing is broken",
        )
      }
    }
    None =>
      fail(
        "Expected a visible trimmed stroke at comp_frame=28; got no MoveTo — TrimPath evaluated to zero (wrong: layer-local frame used instead of comp frame)",
      )
  }
}

test "layer fill effect applies source-atop color overlay" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":20,"w":100,"h":100,"layers":[{"ty":4,"ind":1,"ip":0,"op":20,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"ef":[{"ty":21,"mn":"ADBE Fill","en":1,"ef":[{"mn":"ADBE Fill-0002","v":{"a":1,"k":[{"t":0,"s":[1,0,0,1]},{"t":10,"s":[0,1,0,1]}]}},{"mn":"ADBE Fill-0005","v":{"k":50}}]}],"shapes":[{"ty":"rc","s":{"k":[20,20]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[0,0,1]},"o":{"k":100}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(10.0)
  player.render()

  let commands = recorder.get_commands()
  let mut saw_layer = false
  let mut saw_source_atop = false
  let mut saw_overlay_fill = false
  for cmd in commands {
    match cmd {
      BeginLayer => saw_layer = true
      SetBlendMode(mode) =>
        if mode == "source-atop" {
          saw_source_atop = true
        }
      Fill(r, g, b, opacity) =>
        if saw_source_atop && r == 0 && g == 255 && b == 0 && opacity == 0.5 {
          saw_overlay_fill = true
        }
      _ => ()
    }
  }
  assert_eq(saw_layer, true)
  assert_eq(saw_source_atop, true)
  assert_eq(saw_overlay_fill, true)
}

test "text animator opacity affects glyph fill opacity" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"B","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"AB","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"o":{"a":0,"k":0}},"s":{}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut fill_count = 0
  for cmd in commands {
    match cmd {
      Fill(_, _, _, opacity) => {
        fill_count = fill_count + 1
        if opacity > 0.000001 {
          fail("Expected glyph fill opacity to be 0, got \{opacity}")
        }
      }
      _ => ()
    }
  }
  assert_eq(fill_count, 2)
}

test "text animator tracking shifts glyph positions" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"B","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"AB","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"t":{"a":0,"k":20}},"s":{}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let positions = first_move_positions_for_fills(recorder.get_commands())
  assert_eq(positions.length(), 2)
  let (first_x, _) = positions[0]
  let (second_x, _) = positions[1]
  let advance_delta = second_x - first_x
  if advance_delta < 69.999 || advance_delta > 70.001 {
    fail(
      "Expected second glyph advance delta around 70 (50 advance + 20 tracking), got \{advance_delta}",
    )
  }
}

fn first_move_positions_for_fills(
  commands : Array[DrawCommand],
) -> Array[(Double, Double)] {
  let positions : Array[(Double, Double)] = []
  let matrix_stack : Array[@math.Matrix] = []
  let mut current_matrix = @math.Matrix::identity()
  let mut current_path_first_move : (Double, Double)? = None
  let mut path_open = false
  for cmd in commands {
    match cmd {
      Save => matrix_stack.push(current_matrix)
      Restore =>
        match matrix_stack.pop() {
          Some(prev) => current_matrix = prev
          None => ()
        }
      SetTransform(m) => current_matrix = m
      ConcatTransform(m) => current_matrix = current_matrix.multiply(m)
      BeginPath => {
        path_open = true
        current_path_first_move = None
      }
      MoveTo(x, y) =>
        if path_open {
          match current_path_first_move {
            Some(_) => ()
            None => current_path_first_move = Some(current_matrix.transform_point(x, y))
          }
        }
      Fill(_, _, _, _) => {
        path_open = false
        match current_path_first_move {
          Some(pos) => positions.push(pos)
          None => ()
        }
      }
      _ => ()
    }
  }
  positions
}

fn bounds_for_fills(
  commands : Array[DrawCommand],
) -> Array[(Double, Double, Double, Double)] {
  let bounds : Array[(Double, Double, Double, Double)] = []
  let matrix_stack : Array[@math.Matrix] = []
  let mut current_matrix = @math.Matrix::identity()
  let mut path_open = false
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let mut has_point = false
  let add_point = fn(x : Double, y : Double) {
    let (tx, ty) = current_matrix.transform_point(x, y)
    if not(has_point) {
      min_x = tx
      min_y = ty
      max_x = tx
      max_y = ty
      has_point = true
    } else {
      if tx < min_x {
        min_x = tx
      }
      if ty < min_y {
        min_y = ty
      }
      if tx > max_x {
        max_x = tx
      }
      if ty > max_y {
        max_y = ty
      }
    }
  }
  for cmd in commands {
    match cmd {
      Save => matrix_stack.push(current_matrix)
      Restore =>
        match matrix_stack.pop() {
          Some(prev) => current_matrix = prev
          None => ()
        }
      SetTransform(m) => current_matrix = m
      ConcatTransform(m) => current_matrix = current_matrix.multiply(m)
      BeginPath => {
        path_open = true
        has_point = false
      }
      MoveTo(x, y) =>
        if path_open {
          add_point(x, y)
        }
      LineTo(x, y) =>
        if path_open {
          add_point(x, y)
        }
      CubicTo(cp1x, cp1y, cp2x, cp2y, x, y) =>
        if path_open {
          add_point(cp1x, cp1y)
          add_point(cp2x, cp2y)
          add_point(x, y)
        }
      Fill(_, _, _, _) => {
        path_open = false
        if has_point {
          bounds.push((min_x, min_y, max_x, max_y))
        }
      }
      _ => ()
    }
  }
  bounds
}

test "glyph text advances are not scaled by glyph size" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"fonts":{"list":[{"fName":"Test Bold","fFamily":"Test","fStyle":"Bold","ascent":75}]},"chars":[{"ch":"A","size":16,"style":"Bold","fFamily":"Test","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[100,0],[100,100],[0,100]],"c":true}}}]}},{"ch":"B","size":16,"style":"Bold","fFamily":"Test","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[100,0],[100,100],[0,100]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":16,"f":"Test Bold","t":"AB","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let positions = first_move_positions_for_fills(recorder.get_commands())
  assert_eq(positions.length(), 2)
  let epsilon = 0.001
  let (first_x, first_y) = positions[0]
  let (second_x, second_y) = positions[1]
  let advance_delta = second_x - first_x
  if advance_delta < 15.999 - epsilon || advance_delta > 16.001 + epsilon {
    fail("Expected second glyph advance delta to be x≈16, got \{advance_delta}")
  }
  if second_y < first_y - epsilon || second_y > first_y + epsilon {
    fail("Expected glyphs to share the same y, got first=\{first_y} second=\{second_y}")
  }
}

test "glyph rendering scales text size with 100-unit lottie basis" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"fonts":{"list":[{"fName":"Test Bold","fFamily":"Test","fStyle":"Bold","ascent":75}]},"chars":[{"ch":"A","size":50,"style":"Bold","fFamily":"Test","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[100,0],[100,100],[0,100]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"A","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let bounds = bounds_for_fills(recorder.get_commands())
  assert_eq(bounds.length(), 1)
  let (min_x, min_y, max_x, max_y) = bounds[0]
  let width = max_x - min_x
  let height = max_y - min_y
  let epsilon = 0.001
  if width < 49.999 - epsilon || width > 50.001 + epsilon {
    fail("Expected scaled glyph width to be ≈50, got \{width}")
  }
  if height < 49.999 - epsilon || height > 50.001 + epsilon {
    fail("Expected scaled glyph height to be ≈50, got \{height}")
  }
}

test "glyph rendering matches family as well as style" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"fonts":{"list":[{"fName":"Family B Regular","fFamily":"Family B","fStyle":"Regular","ascent":75}]},"chars":[{"ch":"A","size":100,"style":"Regular","fFamily":"Family A","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"A","size":100,"style":"Regular","fFamily":"Family B","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[40,0],[40,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Family B Regular","t":"A","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut matched_family_b = false
  for cmd in commands {
    match cmd {
      LineTo(x, y) =>
        if x == 40.0 && y == 0.0 {
          matched_family_b = true
        }
      CubicTo(_, _, _, _, x, y) =>
        if x == 40.0 && y == 0.0 {
          matched_family_b = true
        }
      _ => ()
    }
  }
  assert_eq(matched_family_b, true)
}

test "text animator rotation rotates glyph around its center" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[20,0],[20,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"A","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"r":{"a":0,"k":90}},"s":{}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut saw_rotation = false
  for cmd in commands {
    match cmd {
      ConcatTransform(m) => {
        // The glyph matrix composes a 90° animator rotation with the text size scale
        // (doc size 50 => 0.5), so the effective rotation entries have magnitude 0.5.
        if m.a.abs() < 0.000001 && m.d.abs() < 0.000001 &&
            (m.b - 0.5).abs() < 0.000001 &&
            (m.c + 0.5).abs() < 0.000001 {
          saw_rotation = true
        }
      }
      _ => ()
    }
  }
  assert_eq(saw_rotation, true)
}

test "text animator opacity uses lottie-web multiplier blending" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":100,"f":"Test Bold","t":"A","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"o":{"a":0,"k":50}},"s":{"s":{"a":0,"k":0},"e":{"a":0,"k":100},"a":{"a":0,"k":100},"b":1,"sh":2,"rn":0,"ne":{"a":0,"k":0},"xe":{"a":0,"k":0},"o":{"a":0,"k":0}}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let mut fill_opacity = -1.0
  for cmd in recorder.get_commands() {
    match cmd {
      Fill(_, _, _, opacity) => fill_opacity = opacity
      _ => ()
    }
  }
  let epsilon = 0.000001
  if fill_opacity < 0.625 - epsilon || fill_opacity > 0.625 + epsilon {
    fail("Expected glyph fill opacity to be 0.625, got \{fill_opacity}")
  }
}

test "text animator randomize changes selector order" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":240,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"B","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"C","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"D","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"ABCD","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"o":{"a":0,"k":0}},"s":{"s":{"a":0,"k":0},"e":{"a":0,"k":100},"a":{"a":0,"k":100},"b":1,"sh":2,"rn":1,"ne":{"a":0,"k":0},"xe":{"a":0,"k":0},"o":{"a":0,"k":0}}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let opacities : Array[Double] = []
  for cmd in commands {
    match cmd {
      Fill(_, _, _, opacity) => opacities.push(opacity)
      _ => ()
    }
  }
  inspect(opacities, content="[0.625, 0.875, 0.125, 0.375]")
}

test "text animator selector based on words shares word index" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":240,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"B","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"C","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"A B","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"o":{"a":0,"k":0}},"s":{"s":{"a":0,"k":0},"e":{"a":0,"k":100},"a":{"a":0,"k":100},"b":3,"sh":2,"rn":0,"ne":{"a":0,"k":0},"xe":{"a":0,"k":0},"o":{"a":0,"k":0}}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let opacities : Array[Double] = []
  for cmd in commands {
    match cmd {
      Fill(_, _, _, opacity) => opacities.push(opacity)
      _ => ()
    }
  }
  inspect(opacities, content="[0.75, 0.25]")
}

test "text animator selector range units index uses raw indices" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":240,"h":100,"chars":[{"ch":"A","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"B","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}},{"ch":"C","size":100,"style":"Bold","w":100,"data":{"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[0,0],[0,0],[0,0],[0,0]],"o":[[0,0],[0,0],[0,0],[0,0]],"v":[[0,0],[10,0],[10,10],[0,10]],"c":true}}}]}}],"layers":[{"ty":5,"ind":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"t":{"d":{"k":[{"t":0,"s":{"s":50,"f":"Test Bold","t":"ABC","j":0,"tr":0,"fc":[1,1,1]}}]},"a":[{"a":{"o":{"a":0,"k":0}},"s":{"s":{"a":0,"k":1},"e":{"a":0,"k":3},"a":{"a":0,"k":100},"b":1,"sh":2,"r":2,"rn":0,"ne":{"a":0,"k":0},"xe":{"a":0,"k":0},"o":{"a":0,"k":0}}}]}}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let opacities : Array[Double] = []
  for cmd in commands {
    match cmd {
      Fill(_, _, _, opacity) => opacities.push(opacity)
      _ => ()
    }
  }
  inspect(opacities, content="[1, 0.75, 0.25]")
}

test "matte source render resets transform to identity during matte exit" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":10,"w":200,"h":200,"layers":[{"ty":4,"ind":1,"td":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[10,10]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"shapes":[{"ty":"rc","s":{"k":[80,80]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,1,1]},"o":{"k":100}}]},{"ty":4,"ind":2,"tt":1,"ip":0,"op":10,"st":0,"ks":{"a":{"k":[0,0]},"p":{"k":[60,20]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}},"shapes":[{"ty":"rc","s":{"k":[120,120]},"p":{"k":[0,0]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,0,0]},"o":{"k":100}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch { e => fail("Failed to parse: \{e}") }
  let recorder = CommandRecorder::new()
  let player = Player::new(ani, recorder)
  player.set_frame(0.0)
  player.render()

  let commands = recorder.get_commands()
  let mut in_matte_exit = false
  let mut saw_identity_set_transform = false
  for cmd in commands {
    match cmd {
      BeginMatteExit => in_matte_exit = true
      EndMatteExit(_) => in_matte_exit = false
      SetTransform(m) =>
        if in_matte_exit && m == @math.Matrix::identity() {
          saw_identity_set_transform = true
        }
      _ => ()
    }
  }
  assert_eq(saw_identity_set_transform, true)
}
