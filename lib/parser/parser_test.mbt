///|
test "parse_animation_basic" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation: \{e}")
  }

  // Guardrails: Full field assertion for root animation
  if ani.version != "5.5.0" {
    fail("version mismatch: expected 5.5.0")
  }
  if ani.frame_rate != 60.0 {
    fail("frame_rate mismatch: expected 60.0")
  }
  if ani.in_point != 0.0 {
    fail("in_point mismatch: expected 0.0")
  }
  if ani.out_point != 100.0 {
    fail("out_point mismatch: expected 100.0")
  }
  if ani.width != 500 {
    fail("width mismatch: expected 500")
  }
  if ani.height != 500 {
    fail("height mismatch: expected 500")
  }
  if ani.layers.length() != 0 {
    fail("layers length mismatch: expected 0")
  }
}

///|
test "parse_animation_missing_required_field_fails" {
  let cases = [
    ("v", "{\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"),
    ("fr", "{\"v\":\"5.5.0\",\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"),
    ("ip", "{\"v\":\"5.5.0\",\"fr\":60.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[]}"),
    ("op", "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"w\":500,\"h\":500,\"layers\":[]}"),
    ("w", "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"h\":500,\"layers\":[]}"),
    ("h", "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"layers\":[]}"),
  ]
  for case in cases {
    let (missing_key, json_str) = case
    let json = @json.parse(json_str)
    try @parser.parse_animation(json) catch {
      e => {
        let _ = e
      }
    } noraise {
      _ =>
        fail(
          "Expected parse_animation to fail when required field \{missing_key} is missing",
        )
    }
  }
}

///|
test "parse_shape_layer" {
  // ... (existing test code)
}

///|
test "parse_simple_path_shape" {
  // A shape layer with a path that doesn't use "k" wrapper
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[1,1]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"sh\",\"nm\":\"path1\",\"ks\":{\"v\":[[0,0],[10,10]],\"i\":[[0,0],[0,0]],\"o\":[[0,0],[0,0]],\"c\":true}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with simple path: \{e}")
  }

  match ani.layers[0].data {
    @model.LayerData::Shape(shapes) =>
      match shapes[0].data {
        @model.ShapeData::Path(p) =>
          match p.ks.value {
            @model.PropertyValue::Static(bp) => {
              if bp.v.length() != 2 {
                fail("Path vertices length mismatch")
              }
              if bp.c != true {
                fail("Path closed mismatch")
              }
            }
            _ => fail("Path should be static")
          }
        _ => fail("Should be a Path shape")
      }
    _ => fail("Should be a Shape layer")
  }
}

///|
test "parse_merge_paths_and_rounding" {
  let json_str = "{\"ty\":\"gr\",\"it\":[{\"ty\":\"mm\",\"mm\":2},{\"ty\":\"rd\",\"r\":{\"k\":5}}]}"
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse group with mm and rd: \{e}")
  }

  match shape.data {
    @model.ShapeData::Group(items) => {
      if items.length() != 2 {
        fail("Items length mismatch")
      }
      match items[0].data {
        @model.ShapeData::MergePaths(m) =>
          match m.mm {
            @model.MergeMode::Add => ()
            _ => fail("MergeMode mismatch")
          }
        _ => fail("First item should be MergePaths")
      }
      match items[1].data {
        @model.ShapeData::Rounding(r) =>
          match r.r.value {
            @model.PropertyValue::Static(val) =>
              if val != 5.0 {
                fail("Rounding value mismatch")
              }
            _ => fail("Rounding should be static")
          }
        _ => fail("Second item should be Rounding")
      }
    }
    _ => fail("Should be a Group")
  }
}

///|
test "parse_position_keyframe_infra_fields" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":100,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"nm\":\"null\",\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[0,0,0],\"e\":[100,50,0],\"i\":{\"x\":[0.42],\"y\":[0]},\"o\":{\"x\":[0.58],\"y\":[1]},\"to\":[10,0,0],\"ti\":[-10,0,0],\"h\":1},{\"t\":100,\"s\":[100,50,0]}]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animated position keyframes: \{e}")
  }

  match ani.layers[0].ks.position.value {
    @model.PropertyValue::Animated(keyframes) => {
      inspect(keyframes.length(), content="2")
      let kf = keyframes[0]
      inspect(kf.hold, content="Some(1)")
      inspect(kf.value_out_tangent, content="Some([10, 0, 0])")
      inspect(kf.value_in_tangent, content="Some([-10, 0, 0])")
      match (kf.in_tangent, kf.out_tangent) {
        (Some(it), Some(ot)) => {
          match (it.x, ot.x) {
            (@model.BezierValue::Multi(ix), @model.BezierValue::Multi(ox)) => {
              if (ix[0] - 0.42).abs() > 0.000001 || (ox[0] - 0.58).abs() > 0.000001 {
                fail("bezier tangent x mismatch")
              }
            }
            _ => fail("bezier tangent x should be multi values")
          }
        }
        _ => fail("missing bezier tangents")
      }
    }
    _ => fail("position should be animated")
  }
}

///|
test "parse_transform_skew_fields" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100},\"sk\":{\"k\":15.5},\"sa\":{\"k\":45.0}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse transform skew fields: \{e}")
  }

  match ani.layers[0].ks.skew {
    Some(skew) =>
      match skew.value {
        @model.PropertyValue::Static(value) =>
          if (value - 15.5).abs() > 0.000001 {
            fail("skew value mismatch")
          }
        _ => fail("skew should be static")
      }
    None => fail("skew should be parsed")
  }

  match ani.layers[0].ks.skew_axis {
    Some(skew_axis) =>
      match skew_axis.value {
        @model.PropertyValue::Static(value) =>
          if (value - 45.0).abs() > 0.000001 {
            fail("skew_axis value mismatch")
          }
        _ => fail("skew_axis should be static")
      }
    None => fail("skew_axis should be parsed")
  }
}

///|
test "parse_animated_transform_trailing_time_marker_uses_previous_value" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":146,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[0,0,0],\"e\":[100,0,0]},{\"t\":10}]},\"s\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[100,100,100],\"e\":[50,50,100]},{\"t\":10}]},\"r\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[0],\"e\":[30]},{\"t\":10}]},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse trailing time marker keyframes: \{e}")
  }
  match ani.layers[0].ks.position.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || kfs[1].start_value.length() < 1 ||
        (kfs[1].start_value[0] - 100.0).abs() > 0.000001 {
        fail("position trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("position should be animated")
  }
  match ani.layers[0].ks.scale.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || kfs[1].start_value.length() < 1 ||
        (kfs[1].start_value[0] - 50.0).abs() > 0.000001 {
        fail("scale trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("scale should be animated")
  }
  match ani.layers[0].ks.rotation.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || (kfs[1].start_value - 30.0).abs() > 0.000001 {
        fail("rotation trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("rotation should be animated")
  }
}

///|
test "parse_animated_transform_without_a_flag" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[{\"t\":0,\"s\":[0,0,0],\"e\":[100,0,0]},{\"t\":10}]},\"s\":{\"k\":[{\"t\":0,\"s\":[100,100,100],\"e\":[50,50,100]},{\"t\":10}]},\"r\":{\"k\":[{\"t\":0,\"s\":[0],\"e\":[30]},{\"t\":10}]},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse keyframes without a flag: \{e}")
  }

  match ani.layers[0].ks.position.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("position should be treated as animated when keyframes contain t")
  }
  match ani.layers[0].ks.scale.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("scale should be treated as animated when keyframes contain t")
  }
  match ani.layers[0].ks.rotation.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("rotation should be treated as animated when keyframes contain t")
  }
}
