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

test "shape properties use layer-local frame when layer has non-zero st" {
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
      if x < -10.0 - epsilon || x > -10.0 + epsilon {
        fail(
          "Shape property was not evaluated at layer-local frame: MoveTo x=\{x}, expected -10.0",
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
  let mut image_src : String? = None
  for cmd in commands {
    match cmd {
      DrawImage(src, _, _) => {
        image_src = Some(src)
        break
      }
      _ => ()
    }
  }
  assert_eq(image_src, Some("data:image/png;base64,AAAA"))
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
