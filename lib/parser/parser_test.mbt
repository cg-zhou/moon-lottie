///|
struct JsonTest3 {
  x : Int
  y : Int
} derive(
  FromJson(fields(x(rename="renamedX"))),
  ToJson(fields(x(rename="renamedX"))),
  Eq,
  Show,
)

///|
enum JsonTest4 {
  A(x~ : Int)
  B(x~ : Int, y~ : Int)
} derive(FromJson, ToJson, Eq, Show)

///|
test "derive rename mapping json args" {
  let input = JsonTest3::{ x: 123, y: 456 }
  let expected : Json = { "renamedX": 123, "y": 456 }
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)

  let input = JsonTest4::A(x=123)
  let expected : Json = ["A", { "x": 123 }]
  assert_eq(input.to_json(), expected)
  assert_eq(@json.from_json(expected), input)
}

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
test "parse_animation_with_optional_root_fields" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"nm\":\"demo\",\"ddd\":1,\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation optional root fields: \{e}")
  }
  inspect(ani.name, content="Some(\"demo\")")
  inspect(ani.three_d, content="Some(1)")
}

///|
test "parse_animation_fonts_and_glyph_family" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"fonts\":{\"list\":[{\"fName\":\"Montserrat-Bold\",\"fFamily\":\"Montserrat\",\"fStyle\":\"Bold\",\"ascent\":74.2}]},\"chars\":[{\"ch\":\"O\",\"style\":\"Bold\",\"fFamily\":\"Montserrat\",\"size\":56.5,\"w\":82.6,\"data\":{\"shapes\":[]}}],\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation fonts/glyph family: \{e}")
  }
  match ani.fonts {
    Some(fonts) => {
      inspect(fonts.length(), content="1")
      inspect(fonts[0].name, content="Montserrat-Bold")
      inspect(fonts[0].family, content="Montserrat")
      inspect(fonts[0].style, content="Bold")
      inspect(fonts[0].ascent, content="74.2")
    }
    None => fail("fonts should be parsed")
  }
  match ani.glyphs {
    Some(glyphs) => {
      inspect(glyphs.length(), content="1")
      inspect(glyphs[0].family, content="Montserrat")
    }
    None => fail("glyphs should be parsed")
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
test "parse_mask_with_subtract_mode" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"pt\":{\"k\":{\"v\":[[0,0],[10,0],[10,10]],\"i\":[[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0]],\"c\":true}},\"o\":{\"k\":100},\"mode\":\"s\",\"nm\":\"m1\"}],\"shapes\":[]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with mask mode: \{e}")
  }
  match ani.layers[0].masks {
    Some(masks) =>
      if masks[0].mode != @model.MaskMode::Subtract {
        fail("mask mode should be Subtract")
      }
    None => fail("masks should be parsed")
  }
}

///|
test "parse_mask_with_legacy_f_mode_treated_as_add" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"pt\":{\"k\":{\"v\":[[0,0],[10,0],[10,10]],\"i\":[[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0]],\"c\":true}},\"o\":{\"k\":100},\"mode\":\"f\",\"nm\":\"m1\"}],\"shapes\":[]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with legacy mask mode: \{e}")
  }
  match ani.layers[0].masks {
    Some(masks) =>
      if masks[0].mode != @model.MaskMode::Add {
        fail("legacy mask mode f should be treated as Add")
      }
    None => fail("masks should be parsed")
  }
}

///|
test "parse_mask_path_closed_from_mask_cl_flag" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"cl\":true,\"pt\":{\"k\":{\"v\":[[0,0],[10,0],[10,10]],\"i\":[[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0]]}},\"o\":{\"k\":100},\"mode\":\"a\",\"nm\":\"m1\"}],\"shapes\":[]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with mask closed flag: \{e}")
  }
  match ani.layers[0].masks {
    Some(masks) =>
      match masks[0].path.value {
        @model.PropertyValue::Static(path) =>
          if not(path.closed) {
            fail("Mask path should inherit closed=true from mask.cl")
          }
        _ => fail("Mask path should be static")
      }
    None => fail("masks should be parsed")
  }
}

///|
test "parse_mask_with_expansion_property" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":100.0,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"masksProperties\":[{\"inv\":false,\"pt\":{\"k\":{\"v\":[[0,0],[10,0],[10,10]],\"i\":[[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0]],\"c\":true}},\"o\":{\"k\":100},\"x\":{\"k\":2},\"mode\":\"a\",\"nm\":\"m1\"}],\"shapes\":[]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with mask expansion: \{e}")
  }
  match ani.layers[0].masks {
    Some(masks) =>
      match masks[0].expansion.value {
        @model.PropertyValue::Static(v) => assert_eq(v, 2.0)
        _ => fail("Mask expansion should be parsed as a static property")
      }
    None => fail("masks should be parsed")
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
          match p.path.value {
            @model.PropertyValue::Static(bp) => {
              if bp.vertices.length() != 2 {
                fail("Path vertices length mismatch")
              }
              if bp.closed != true {
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
test "parse_path_shape_closed_from_shape_flag" {
  let json_str = "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":100,\"w\":500,\"h\":500,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[1,1]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"sh\",\"nm\":\"path1\",\"closed\":true,\"ks\":{\"v\":[[0,0],[10,0],[10,10],[0,10]],\"i\":[[0,0],[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0],[0,0]]}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with shape closed flag: \{e}")
  }

  match ani.layers[0].data {
    @model.LayerData::Shape(shapes) =>
      match shapes[0].data {
        @model.ShapeData::Path(p) =>
          match p.path.value {
            @model.PropertyValue::Static(bp) =>
              if not(bp.closed) {
                fail("Path should inherit closed=true from shape.closed")
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
          match m.merge_mode {
            @model.MergeMode::Add => ()
            _ => fail("MergeMode mismatch")
          }
        _ => fail("First item should be MergePaths")
      }
      match items[1].data {
        @model.ShapeData::Rounding(r) =>
          match r.radius.value {
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
test "parse_repeater_shape_with_typed_tr" {
  let json_str =
    "{\"ty\":\"rp\",\"c\":{\"k\":3},\"o\":{\"k\":1},\"m\":2,\"tr\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[10,20]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}"
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse repeater shape: \{e}")
  }
  match shape.data {
    @model.ShapeData::Repeater(rp) => {
      inspect(rp.composite, content="2")
      match rp.copies.value {
        @model.PropertyValue::Static(v) => inspect(v, content="3")
        _ => fail("repeater copies should be static")
      }
      match rp.offset.value {
        @model.PropertyValue::Static(v) => inspect(v, content="1")
        _ => fail("repeater offset should be static")
      }
      match rp.transform.position.value {
        @model.PropertyValue::Static(v) => inspect(v, content="[10, 20]")
        _ => fail("repeater transform position should be static")
      }
    }
    _ => fail("shape should be repeater")
  }
}

///|
test "parse_animated_text_document_property" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":5,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"t\":{\"d\":{\"a\":1,\"k\":[{\"t\":0,\"s\":{\"s\":20,\"f\":\"Arial\",\"t\":\"A\"}},{\"t\":10,\"s\":{\"s\":24,\"f\":\"Arial\",\"t\":\"B\"}}]}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animated text property: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Text(text_data) =>
      match text_data.text.value {
        @model.PropertyValue::Animated(keyframes) => {
          inspect(keyframes.length(), content="2")
          inspect(keyframes[0].start_value.text, content="A")
          inspect(keyframes[1].start_value.text, content="B")
        }
        _ => fail("text document property should be animated")
      }
    _ => fail("layer should be text layer")
  }
}

///|
test "parse_text_animator_selector_range_start_end" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":5,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"t\":{\"d\":{\"k\":[{\"t\":0,\"s\":{\"s\":20,\"f\":\"Arial\",\"t\":\"AB\"}}]},\"a\":[{\"a\":{\"fc\":{\"k\":[1,0,0]}},\"s\":{\"s\":{\"k\":25},\"e\":{\"k\":75},\"a\":{\"k\":100},\"b\":1,\"sh\":1,\"rn\":0,\"ne\":{\"k\":0},\"xe\":{\"k\":0},\"o\":{\"k\":0}}}]}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse text animator selector ranges: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Text(text_data) => {
      inspect(text_data.animators.length(), content="1")
      let selector = text_data.animators[0].selector
      match selector.range_start.value {
        @model.PropertyValue::Static(v) => inspect(v, content="25")
        _ => fail("selector range_start should be static")
      }
      match selector.range_end.value {
        @model.PropertyValue::Static(v) => inspect(v, content="75")
        _ => fail("selector range_end should be static")
      }
      inspect(selector.range_units, content="1")
    }
    _ => fail("layer should be text layer")
  }
}

///|
test "parse_text_animator_selector_range_units" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":5,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"t\":{\"d\":{\"k\":[{\"t\":0,\"s\":{\"s\":20,\"f\":\"Arial\",\"t\":\"AB\"}}]},\"a\":[{\"a\":{\"fc\":{\"k\":[1,0,0]}},\"s\":{\"s\":{\"k\":0},\"e\":{\"k\":2},\"a\":{\"k\":100},\"b\":1,\"sh\":1,\"r\":2,\"rn\":0,\"ne\":{\"k\":0},\"xe\":{\"k\":0},\"o\":{\"k\":0}}}]}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse text animator selector range units: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Text(text_data) =>
      inspect(text_data.animators[0].selector.range_units, content="2")
    _ => fail("layer should be text layer")
  }
}

///|
test "parse_text_animator_rotation_property" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":5,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"t\":{\"d\":{\"k\":[{\"t\":0,\"s\":{\"s\":20,\"f\":\"Arial\",\"t\":\"A\"}}]},\"a\":[{\"a\":{\"r\":{\"k\":45}},\"s\":{}}]}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse text animator rotation: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Text(text_data) =>
      match text_data.animators[0].properties.rotation {
        Some(rotation) =>
          match rotation.value {
            @model.PropertyValue::Static(v) => inspect(v, content="45")
            _ => fail("text animator rotation should be static")
          }
        None => fail("text animator rotation should be parsed")
      }
    _ => fail("layer should be text layer")
  }
}

///|
test "parse_transform_property_with_bool_a_flag" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"a\":true,\"k\":[{\"t\":0,\"s\":[0,0,0],\"e\":[100,0,0]},{\"t\":10}]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse bool a-flag animated property: \{e}")
  }
  match ani.layers[0].transform.anchor.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("anchor should be animated when a is true")
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

  match ani.layers[0].transform.position.value {
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
test "parse_transform_split_position_with_x_and_y_fields" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"s\":true,\"x\":{\"k\":25},\"y\":{\"k\":40}},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse split position transform: \{e}")
  }
  let tr = ani.layers[0].transform
  assert_eq(tr.split, Some(true))
  match tr.px {
    Some(px) =>
      match px.value {
        @model.PropertyValue::Static(v) => assert_eq(v, 25.0)
        _ => fail("split x should be static")
      }
    None => fail("split x should be parsed")
  }
  match tr.py {
    Some(py) =>
      match py.value {
        @model.PropertyValue::Static(v) => assert_eq(v, 40.0)
        _ => fail("split y should be static")
      }
    None => fail("split y should be parsed")
  }
}

///|
test "parse_property_keeps_fractional_keyframe_time" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"a\":1,\"k\":[{\"t\":0.5,\"s\":[0,0,0],\"e\":[100,0,0]},{\"t\":1.5,\"s\":[100,0,0]}]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse fractional keyframe timing: \{e}")
  }
  match ani.layers[0].transform.position.value {
    @model.PropertyValue::Animated(kfs) => {
      if (kfs[0].frame - 0.5).abs() > 0.000001 ||
        (kfs[1].frame - 1.5).abs() > 0.000001 {
        fail("fractional keyframe times should be preserved")
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

  match ani.layers[0].transform.skew {
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

  match ani.layers[0].transform.skew_axis {
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
  match ani.layers[0].transform.position.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || kfs[1].start_value.length() < 1 ||
        (kfs[1].start_value[0] - 100.0).abs() > 0.000001 {
        fail("position trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("position should be animated")
  }
  match ani.layers[0].transform.scale.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || kfs[1].start_value.length() < 1 ||
        (kfs[1].start_value[0] - 50.0).abs() > 0.000001 {
        fail("scale trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("scale should be animated")
  }
  match ani.layers[0].transform.rotation.value {
    @model.PropertyValue::Animated(kfs) => {
      if kfs.length() != 2 || (kfs[1].start_value - 30.0).abs() > 0.000001 {
        fail("rotation trailing keyframe should inherit previous end value")
      }
    }
    _ => fail("rotation should be animated")
  }
}

///|
test "parse_animated_shape_path_trailing_time_marker_uses_previous_value" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":4,\"ind\":1,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"shapes\":[{\"ty\":\"sh\",\"ks\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[{\"i\":[[0,0],[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0],[0,0]],\"v\":[[0,0],[10,0],[10,10],[0,10]],\"c\":true}],\"e\":[{\"i\":[[0,0],[0,0],[0,0],[0,0]],\"o\":[[0,0],[0,0],[0,0],[0,0]],\"v\":[[0,0],[20,0],[20,20],[0,20]],\"c\":true}]},{\"t\":10}]},\"closed\":true},{\"ty\":\"fl\",\"c\":{\"k\":[1,0,0]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animated shape path trailing marker: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Shape(shapes) =>
      match shapes[0].data {
        @model.ShapeData::Path(path_shape) =>
          match path_shape.path.value {
            @model.PropertyValue::Animated(kfs) => {
              if kfs.length() != 2 || kfs[1].start_value.vertices.length() < 2 ||
                (kfs[1].start_value.vertices[1][0] - 20.0).abs() > 0.000001 {
                fail("shape path trailing keyframe should inherit previous end value")
              }
            }
            _ => fail("shape path should be animated")
          }
        _ => fail("first shape should be path")
      }
    _ => fail("layer should be shape layer")
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

  match ani.layers[0].transform.position.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("position should be treated as animated when keyframes contain t")
  }
  match ani.layers[0].transform.scale.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("scale should be treated as animated when keyframes contain t")
  }
  match ani.layers[0].transform.rotation.value {
    @model.PropertyValue::Animated(kfs) => inspect(kfs.length(), content="2")
    _ => fail("rotation should be treated as animated when keyframes contain t")
  }
}

///|
test "parse_precomp_asset_layers" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":10.0,\"w\":100,\"h\":100,\"assets\":[{\"id\":\"comp_1\",\"layers\":[{\"ty\":3,\"ind\":11,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}],\"layers\":[]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse precomp asset layers: \{e}")
  }
  match ani.assets {
    Some(assets) => {
      if assets.length() != 1 {
        fail("assets length mismatch")
      }
      match assets[0].layers {
        Some(_) => ()
        None => fail("precomp asset layers should be parsed")
      }
    }
    None => fail("assets should be parsed")
  }
}

///|
test "parse_layer_parent_and_matte" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":10.0,\"w\":100,\"h\":100,\"layers\":[{\"ty\":3,\"ind\":2,\"parent\":1,\"tt\":2,\"td\":1,\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse layer parent/matte: \{e}")
  }
  inspect(ani.layers[0].parent, content="Some(1)")
  inspect(ani.layers[0].matte_type, content="Some(2)")
  inspect(ani.layers[0].matte_inherit, content="Some(1)")
}

///|
test "parse_layer_fill_effect" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":30,\"ip\":0,\"op\":20,\"w\":100,\"h\":100,\"layers\":[{\"ty\":4,\"ind\":1,\"ip\":0,\"op\":20,\"st\":0,\"ks\":{\"a\":{\"k\":[0,0]},\"p\":{\"k\":[0,0]},\"s\":{\"k\":[100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}},\"ef\":[{\"ty\":21,\"mn\":\"ADBE Fill\",\"en\":1,\"ef\":[{\"mn\":\"ADBE Fill-0002\",\"v\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[1,0,0,1]},{\"t\":10,\"s\":[0,1,0,1]}]}},{\"mn\":\"ADBE Fill-0005\",\"v\":{\"a\":0,\"k\":50}}]}],\"shapes\":[{\"ty\":\"rc\",\"s\":{\"k\":[20,20]},\"p\":{\"k\":[0,0]},\"r\":{\"k\":0}},{\"ty\":\"fl\",\"c\":{\"k\":[1,1,1]},\"o\":{\"k\":100}}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse layer fill effect: \{e}")
  }
  match ani.layers[0].fill_effect {
    Some(effect) => {
      match effect.color.value {
        @model.PropertyValue::Animated(keys) => {
          assert_eq(keys.length(), 2)
          assert_eq(keys[0].start_value[0], 1.0)
          assert_eq(keys[1].start_value[1], 1.0)
        }
        _ => fail("Expected animated fill effect color")
      }
      match effect.opacity.value {
        @model.PropertyValue::Static(v) => assert_eq(v, 50.0)
        _ => fail("Expected static fill effect opacity")
      }
    }
    None => fail("Expected layer fill effect to be parsed")
  }
}

///|
test "parse_layer_time_remap_expression" {
  let json_str =
    "{\"v\":\"5.5.0\",\"fr\":60.0,\"ip\":0.0,\"op\":20.0,\"w\":100,\"h\":100,\"layers\":[{\"ty\":0,\"ind\":1,\"refId\":\"comp_1\",\"w\":100,\"h\":100,\"tm\":{\"a\":1,\"k\":[{\"t\":0,\"s\":[0],\"e\":[5]},{\"t\":10,\"s\":[5]}],\"x\":\"var $bm_rt; $bm_rt = loopOut('cycle');\"},\"ks\":{\"a\":{\"k\":[0,0,0]},\"p\":{\"k\":[0,0,0]},\"s\":{\"k\":[100,100,100]},\"r\":{\"k\":0},\"o\":{\"k\":100}}}],\"assets\":[{\"id\":\"comp_1\",\"layers\":[]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse layer time remap: \{e}")
  }
  match ani.layers[0].time_remap {
    Some(time_remap) => {
      inspect(time_remap.expression, content="Some(\"var $bm_rt; $bm_rt = loopOut('cycle');\")")
      match time_remap.value {
        @model.PropertyValue::Animated(keys) => {
          assert_eq(keys.length(), 2)
          assert_eq(keys[0].start_value, 0.0)
          match keys[0].end_value {
            Some(v) => assert_eq(v, 5.0)
            None => fail("time remap keyframe should preserve end value")
          }
        }
        _ => fail("Expected animated time remap property")
      }
    }
    None => fail("Expected layer time remap to be parsed")
  }
}

///|
test "parse_shape_path_expression" {
  let json_str =
    "{\"ty\":\"sh\",\"ix\":1,\"ks\":{\"a\":0,\"k\":{\"i\":[[0,0],[0,0]],\"o\":[[0,0],[0,0]],\"v\":[[0,0],[10,0]],\"c\":false},\"x\":\"var $bm_rt; $bm_rt = createPath(thisProperty.points(), thisProperty.inTangents(), thisProperty.outTangents(), false);\"}}"
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse shape path expression: \{e}")
  }
  match shape.data {
    @model.ShapeData::Path(path_shape) => {
      inspect(
        path_shape.path.expression,
        content=(
          "Some(\"var $bm_rt; $bm_rt = createPath(thisProperty.points(), thisProperty.inTangents(), thisProperty.outTangents(), false);\")"
        ),
      )
      match path_shape.path.value {
        @model.PropertyValue::Static(path) => {
          assert_eq(path.vertices, [[0.0, 0.0], [10.0, 0.0]])
          assert_eq(path.closed, false)
        }
        _ => fail("Expected static path property")
      }
    }
    _ => fail("Expected path shape")
  }
}

///|
test "parse_repeater_with_start_end_opacity" {
  let json_str =
    #|{"ty":"rp","c":{"k":4},"o":{"k":0},"m":1,"tr":{"a":{"k":[0,0]},"p":{"k":[50,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100},"so":{"k":100},"eo":{"k":20}}}
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse repeater with so/eo: \{e}")
  }
  match shape.data {
    @model.ShapeData::Repeater(rp) => {
      inspect(rp.composite, content="1")
      match rp.copies.value {
        @model.PropertyValue::Static(v) => inspect(v, content="4")
        _ => fail("repeater copies should be static")
      }
      match rp.start_opacity.value {
        @model.PropertyValue::Static(v) => inspect(v, content="100")
        _ => fail("repeater start_opacity should be static")
      }
      match rp.end_opacity.value {
        @model.PropertyValue::Static(v) => inspect(v, content="20")
        _ => fail("repeater end_opacity should be static")
      }
    }
    _ => fail("shape should be repeater")
  }
}

///|
test "parse_repeater_without_opacity_defaults" {
  let json_str =
    #|{"ty":"rp","c":{"k":3},"o":{"k":0},"m":1,"tr":{"a":{"k":[0,0]},"p":{"k":[10,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}}
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse repeater without so/eo: \{e}")
  }
  match shape.data {
    @model.ShapeData::Repeater(rp) => {
      // Should default to 100
      match rp.start_opacity.value {
        @model.PropertyValue::Static(v) => inspect(v, content="100")
        _ => fail("repeater start_opacity should default to static 100")
      }
      match rp.end_opacity.value {
        @model.PropertyValue::Static(v) => inspect(v, content="100")
        _ => fail("repeater end_opacity should default to static 100")
      }
    }
    _ => fail("shape should be repeater")
  }
}

///|
test "parse_animation_preserves_repeater_without_transform_opacity" {
  let json_str =
    #|{"v":"5.5.0","fr":30,"ip":0,"op":20,"w":100,"h":100,"layers":[{"ty":4,"ind":1,"ks":{"a":{"k":[0,0,0]},"p":{"k":[0,0,0]},"s":{"k":[100,100,100]},"r":{"k":0},"o":{"k":100}},"shapes":[{"ty":"gr","it":[{"ty":"rc","p":{"k":[0,0]},"s":{"k":[10,10]},"r":{"k":0}},{"ty":"fl","c":{"k":[1,0,0,1]},"o":{"k":100}},{"ty":"tr","a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":0},"o":{"k":100}}]},{"ty":"rp","c":{"k":12},"o":{"k":0},"m":1,"tr":{"a":{"k":[0,0]},"p":{"k":[0,0]},"s":{"k":[100,100]},"r":{"k":30},"so":{"k":100},"eo":{"k":100}}}]}]}
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse animation with repeater transform defaults: \{e}")
  }
  match ani.layers[0].data {
    @model.LayerData::Shape(shapes) => {
      inspect(shapes.length(), content="2")
      match shapes[1].data {
        @model.ShapeData::Repeater(rp) =>
          match rp.transform.opacity.value {
            @model.PropertyValue::Static(v) => inspect(v, content="100")
            _ => fail("repeater transform opacity should default to static 100")
          }
        _ => fail("second shape should be repeater")
      }
    }
    _ => fail("layer should be shape")
  }
}

///|
test "parse_stroke_with_dashes" {
  let json_str =
    #|{"ty":"st","c":{"k":[1,0,0]},"o":{"k":100},"w":{"k":2},"lc":2,"lj":2,"ml":4,"d":[{"n":"d","v":{"k":10}},{"n":"g","v":{"k":5}},{"n":"o","v":{"k":0}}]}
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse stroke with dashes: \{e}")
  }
  match shape.data {
    @model.ShapeData::Stroke(s) => {
      inspect(s.dashes.length(), content="3")
      inspect(s.dashes[0].name, content="d")
      match s.dashes[0].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="10")
        _ => fail("dash value should be static")
      }
      inspect(s.dashes[1].name, content="g")
      match s.dashes[1].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="5")
        _ => fail("gap value should be static")
      }
      inspect(s.dashes[2].name, content="o")
      match s.dashes[2].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="0")
        _ => fail("offset value should be static")
      }
    }
    _ => fail("shape should be stroke")
  }
}

///|
test "parse_stroke_without_dashes" {
  let json_str =
    #|{"ty":"st","c":{"k":[0,0,1]},"o":{"k":100},"w":{"k":3}}
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse stroke without dashes: \{e}")
  }
  match shape.data {
    @model.ShapeData::Stroke(s) => {
      inspect(s.dashes.length(), content="0")
    }
    _ => fail("shape should be stroke")
  }
}

///|
test "parse_gradient_stroke_with_dashes" {
  let json_str =
    #|{"ty":"gs","o":{"k":100},"w":{"k":2},"g":{"p":2,"k":{"k":[0,1,0,0,1,0,0,1]}},"s":{"k":[0,0]},"e":{"k":[100,0]},"t":1,"lc":2,"lj":2,"ml":4,"d":[{"n":"d","v":{"k":10}}, {"n":"g","v":{"k":5}}, {"n":"o","v":{"k":3}}]}
  let json = @json.parse(json_str)
  let shape = @parser.parse_shape(json) catch {
    e => fail("Failed to parse gradient stroke with dashes: \{e}")
  }
  match shape.data {
    @model.ShapeData::GradientStroke(s) => {
      inspect(s.dashes.length(), content="3")
      inspect(s.dashes[0].name, content="d")
      match s.dashes[0].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="10")
        _ => fail("gradient dash value should be static")
      }
      inspect(s.dashes[1].name, content="g")
      match s.dashes[1].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="5")
        _ => fail("gradient gap value should be static")
      }
      inspect(s.dashes[2].name, content="o")
      match s.dashes[2].value.value {
        @model.PropertyValue::Static(v) => inspect(v, content="3")
        _ => fail("gradient offset value should be static")
      }
    }
    _ => fail("shape should be gradient stroke")
  }
}
