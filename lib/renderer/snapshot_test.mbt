test "snapshot_render_circle" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"el\",\"nm\":\"circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = try {
    @parser.parse_animation(json)
  } catch {
    e => fail("Failed to parse: \{e}")
  }
  
  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  
  player.set_frame(0.0)
  player.render()
  
  let commands = recorder.get_commands()
  // Compare with expected commands
  inspect(commands, content=(
    #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 500, 500), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 250, f: 250}), BeginPath, MoveTo(0, -50), CubicTo(27.614237499999998, -50, 50, -27.614237499999998, 50, 0), CubicTo(50, 27.614237499999998, 27.614237499999998, 50, 0, 50), CubicTo(-27.614237499999998, 50, -50, 27.614237499999998, -50, 0), CubicTo(-50, -27.614237499999998, -27.614237499999998, -50, 0, -50), ClosePath, Fill(255, 0, 0, 1), Restore]
  ))
}

test "snapshot_render_mask" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"mode\":\"a\",\"pt\":{\"k\":{\"i\":[[0,0],[0,0]],\"o\":[[0,0],[0,0]],\"v\":[[0,0],[100,100]],\"c\":true}},\"o\":{\"k\":100}}],\"shapes\":[{\"ty\":\"el\",\"nm\":\"circle\",\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]}},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]}}]}]}"
  let json = @json.parse(json_str)
  let ani = try {
    @parser.parse_animation(json)
  } catch {
    e => fail("Failed to parse: \{e}")
  }
  
  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  
  player.set_frame(0.0)
  player.render()
  
  let commands = recorder.get_commands()
  // Check that Clip is present
  let has_clip = commands.iter().any(fn(c) {
    match c {
      Clip => true
      _ => false
    }
  })
  if not(has_clip) {
    fail("Clip command missing from mask rendering. Commands: \{commands}")
  }
}

test "snapshot_render_alpha_matte" {
  // Layer 0: Matte Source (td=1)
  // Layer 1: Matte Target (tt=1)
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":1,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":100,\"sh\":100,\"sc\":\"#ffffff\",\"td\":1},{\"ty\":1,\"ind\":2,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[250,250]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"sw\":200,\"sh\":200,\"sc\":\"#ff0000\",\"tt\":1}]}"
  let json = @json.parse(json_str)
  let ani = try {
    @parser.parse_animation(json)
  } catch {
    e => fail("Failed to parse: \{e}")
  }
  
  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)
  
  player.set_frame(0.0)
  player.render()
  
  let commands = recorder.get_commands()
  // Check for SetBlendMode("destination-in")
  let has_matte_mode = commands.iter().any(fn(c) {
    match c {
      SetBlendMode("destination-in") => true
      _ => false
    }
  })
  if not(has_matte_mode) {
    fail("Matte blend mode missing. Commands: \{commands}")
  }
}