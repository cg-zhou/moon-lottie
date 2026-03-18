///|
test "Color::from_array rgb" {
  let c = @model.Color::from_array([1.0, 0.0, 0.0])
  if c.r != 1.0 || c.g != 0.0 || c.b != 0.0 || c.a != 1.0 {
    fail("Color::from_array rgb failed")
  }
}

///|
test "Color::from_array rgba" {
  let c = @model.Color::from_array([0.0, 1.0, 0.0, 0.5])
  if c.r != 0.0 || c.g != 1.0 || c.b != 0.0 || c.a != 0.5 {
    fail("Color::from_array rgba failed")
  }
}

///|
test "Color::from_array empty" {
  let c = @model.Color::from_array([])
  if c.r != 0.0 || c.g != 0.0 || c.b != 0.0 || c.a != 1.0 {
    fail("Color::from_array empty defaults failed")
  }
}

///|
test "Color::to_hex_string red" {
  let c = @model.Color::new(1.0, 0.0, 0.0, 1.0)
  if c.to_hex_string() != "#FF0000" {
    fail("Color::to_hex_string red failed: \{c.to_hex_string()}")
  }
}

///|
test "Color::to_hex_string black" {
  let c = @model.Color::black()
  if c.to_hex_string() != "#000000" {
    fail("Color::to_hex_string black failed: \{c.to_hex_string()}")
  }
}

///|
test "Color::to_hex_string white" {
  let c = @model.Color::white()
  if c.to_hex_string() != "#FFFFFF" {
    fail("Color::to_hex_string white failed: \{c.to_hex_string()}")
  }
}

///|
test "Color::lerp midpoint" {
  let black = @model.Color::black()
  let white = @model.Color::white()
  let mid = black.lerp(white, 0.5)
  if (mid.r - 0.5).abs() > 0.001 ||
    (mid.g - 0.5).abs() > 0.001 ||
    (mid.b - 0.5).abs() > 0.001 {
    fail("Color::lerp midpoint failed")
  }
}

///|
test "Color::lerp t=0" {
  let red = @model.Color::new(1.0, 0.0, 0.0, 1.0)
  let blue = @model.Color::new(0.0, 0.0, 1.0, 1.0)
  let c = red.lerp(blue, 0.0)
  if c.r != 1.0 || c.b != 0.0 {
    fail("Color::lerp t=0 should return first color")
  }
}

///|
test "Color::lerp t=1" {
  let red = @model.Color::new(1.0, 0.0, 0.0, 1.0)
  let blue = @model.Color::new(0.0, 0.0, 1.0, 1.0)
  let c = red.lerp(blue, 1.0)
  if c.r != 0.0 || c.b != 1.0 {
    fail("Color::lerp t=1 should return second color")
  }
}

///|
test "Color::to_array roundtrip" {
  let arr = [0.2, 0.4, 0.6, 0.8]
  let c = @model.Color::from_array(arr)
  let out = c.to_array()
  if (out[0] - 0.2).abs() > 0.001 ||
    (out[1] - 0.4).abs() > 0.001 ||
    (out[2] - 0.6).abs() > 0.001 ||
    (out[3] - 0.8).abs() > 0.001 {
    fail("Color::to_array roundtrip failed")
  }
}

///|
test "BlendMode::from_int roundtrip" {
  let modes = [0, 1, 5, 10, 16, 17]
  for v in modes {
    let bm = @model.BlendMode::from_int(v)
    if bm.to_int() != v {
      fail("BlendMode roundtrip failed for \{v}")
    }
  }
}

///|
test "BlendMode::from_int unknown defaults to Normal" {
  let bm = @model.BlendMode::from_int(99)
  if bm.to_int() != 0 {
    fail("Unknown BlendMode should default to Normal (0)")
  }
}

///|
test "MatteMode::from_int roundtrip" {
  let modes = [0, 1, 2, 3, 4]
  for v in modes {
    let mm = @model.MatteMode::from_int(v)
    if mm.to_int() != v {
      fail("MatteMode roundtrip failed for \{v}")
    }
  }
}

///|
test "MatteMode::from_int unknown defaults to Normal" {
  let mm = @model.MatteMode::from_int(99)
  if mm.to_int() != 0 {
    fail("Unknown MatteMode should default to Normal (0)")
  }
}

///|
test "FillRule::from_int" {
  let nz = @model.FillRule::from_int(1)
  let eo = @model.FillRule::from_int(2)
  if nz.to_int() != 1 {
    fail("FillRule NonZeroFill to_int should be 1")
  }
  if eo.to_int() != 2 {
    fail("FillRule EvenOddFill to_int should be 2")
  }
}

///|
test "FillRule::to_svg_string" {
  let nz = @model.FillRule::from_int(1)
  let eo = @model.FillRule::from_int(2)
  if nz.to_svg_string() != "nonzero" {
    fail("FillRule NonZeroFill svg string mismatch")
  }
  if eo.to_svg_string() != "evenodd" {
    fail("FillRule EvenOddFill svg string mismatch")
  }
}

///|
test "LineCap::from_int roundtrip" {
  let caps = [1, 2, 3]
  for v in caps {
    let lc = @model.LineCap::from_int(v)
    if lc.to_int() != v {
      fail("LineCap roundtrip failed for \{v}")
    }
  }
}

///|
test "LineJoin::from_int roundtrip" {
  let joins = [1, 2, 3]
  for v in joins {
    let lj = @model.LineJoin::from_int(v)
    if lj.to_int() != v {
      fail("LineJoin roundtrip failed for \{v}")
    }
  }
}

///|
fn static_double(v : Double) -> @model.LottieProperty[Double] {
  @model.LottieProperty::new_static(v)
}

///|
fn static_vec2(x : Double, y : Double) -> @model.LottieProperty[Array[Double]] {
  @model.LottieProperty::new_static([x, y])
}

///|
test "Color::new_u8" {
  let c = @model.Color::new_u8(255, 128, 0, 64)
  if (c.r - 1.0).abs() > 0.000001 ||
    (c.g - (128.0 / 255.0)).abs() > 0.000001 ||
    c.b != 0.0 ||
    (c.a - (64.0 / 255.0)).abs() > 0.000001 {
    fail("Color::new_u8 failed")
  }
}

///|
test "Property constructors and tangents" {
  let bz_single = @model.BezierValue::new_single(0.3)
  let bz_multi = @model.BezierValue::new_multi([0.1, 0.2])
  let bz = @model.Bezier::new(bz_single, bz_multi)
  let kf = @model.LottieKeyframe::new(
    frame=10.0,
    start_value=[1.0, 2.0],
    end_value=Some([3.0, 4.0]),
    in_tangent=Some(bz),
    out_tangent=Some(bz),
    value_in_tangent=Some([0.5, 0.5]),
    value_out_tangent=Some([0.6, 0.6]),
    hold=Some(1),
  )
  if kf.frame != 10.0 || kf.hold != Some(1) {
    fail("LottieKeyframe::new failed")
  }
  let static_p = @model.LottieProperty::new_static(9.0, expression=Some("x"))
  let anim_p = @model.LottieProperty::new_animated([kf], expression=Some("y"))
  if static_p.animated != 0 || anim_p.animated != 1 {
    fail("LottieProperty constructor flags failed")
  }
}

///|
test "Shape and transform/layer/mask/animation constructors" {
  let opacity = static_double(100.0)
  let transform = @model.Transform::new(
    anchor=static_vec2(0.0, 0.0),
    position=static_vec2(10.0, 20.0),
    scale=static_vec2(100.0, 100.0),
    rotation=static_double(0.0),
    opacity=opacity,
    px=Some(static_double(10.0)),
    py=Some(static_double(20.0)),
    split=Some(true),
    skew=Some(static_double(0.0)),
    skew_axis=Some(static_double(0.0)),
  )
  let default_transform = @model.Transform::new_default()
  if transform.split != Some(true) || default_transform.split != None {
    fail("Transform constructors failed")
  }

  let path = @model.BezierPath::new_rect(10.0, 10.0, 20.0, 30.0)
  let path2 = @model.BezierPath::new(
    vertices=[[0.0, 0.0], [1.0, 0.0]],
    in_tangents=[[0.0, 0.0], [0.0, 0.0]],
    out_tangents=[[0.0, 0.0], [0.0, 0.0]],
    closed=false,
  )
  if path.vertices.length() != 4 || path2.closed != false {
    fail("BezierPath constructors failed")
  }

  let path_shape = @model.PathShape::new(path=@model.LottieProperty::new_static(path))
  let rect_shape = @model.RectShape::new(
    position=static_vec2(1.0, 2.0),
    size=static_vec2(3.0, 4.0),
    roundness=static_double(5.0),
  )
  let ellipse_shape = @model.EllipseShape::new(
    position=static_vec2(1.0, 2.0),
    size=static_vec2(3.0, 4.0),
  )
  let fill_shape = @model.FillShape::new(
    color=@model.LottieProperty::new_static([1.0, 0.0, 0.0, 1.0]),
    opacity=static_double(100.0),
  )
  let stroke_shape = @model.StrokeShape::new(
    color=@model.LottieProperty::new_static([0.0, 0.0, 1.0, 1.0]),
    opacity=static_double(100.0),
    width=static_double(2.0),
  )
  let gradient_colors = @model.GradientColors::new(
    color_count=2,
    color_stops=@model.LottieProperty::new_static([0.0, 1.0, 0.0, 0.0, 1.0, 0.0]),
  )
  let gradient_fill = @model.GradientFillShape::new(
    gradient_type=1,
    opacity=static_double(100.0),
    start_point=static_vec2(0.0, 0.0),
    end_point=static_vec2(100.0, 0.0),
    gradient_colors=gradient_colors,
  )
  let gradient_stroke = @model.GradientStrokeShape::new(
    gradient_type=2,
    opacity=static_double(100.0),
    start_point=static_vec2(0.0, 0.0),
    end_point=static_vec2(100.0, 0.0),
    gradient_colors=gradient_colors,
    width=static_double(1.0),
  )
  let trim = @model.TrimPath::new(
    start=static_double(0.0),
    end=static_double(100.0),
    offset=static_double(0.0),
  )
  let polystar = @model.PolystarShape::new(
    points=static_double(5.0),
    position=static_vec2(0.0, 0.0),
    rotation=static_double(0.0),
    inner_radius=static_double(10.0),
    inner_roundness=static_double(0.0),
    outer_radius=static_double(20.0),
    outer_roundness=static_double(0.0),
    star_type=1,
  )
  let repeater = @model.Repeater::new(
    copies=static_double(3.0),
    offset=static_double(0.0),
    transform=default_transform,
  )
  let merge = @model.MergePaths::new(3)
  let rounding = @model.Rounding::new(radius=static_double(4.0))

  let _group_data = @model.ShapeData::new_group([])
  let _rect_data = @model.ShapeData::new_rect(rect_shape)
  let _ellipse_data = @model.ShapeData::new_ellipse(ellipse_shape)
  let _path_data = @model.ShapeData::new_path(path_shape)
  let _fill_data = @model.ShapeData::new_fill(fill_shape)
  let _stroke_data = @model.ShapeData::new_stroke(stroke_shape)
  let _gradient_fill_data = @model.ShapeData::new_gradient_fill(gradient_fill)
  let _gradient_stroke_data = @model.ShapeData::new_gradient_stroke(gradient_stroke)
  let _transform_data = @model.ShapeData::new_transform(default_transform)
  let _trim_data = @model.ShapeData::new_trim_path(trim)
  let _polystar_data = @model.ShapeData::new_polystar(polystar)
  let _repeater_data = @model.ShapeData::new_repeater(repeater)
  let _merge_data = @model.ShapeData::new_merge_paths(merge)
  let _rounding_data = @model.ShapeData::new_rounding(rounding)

  let shape = @model.Shape::new(
    shape_type="gr",
    data=@model.ShapeData::new_group([]),
    name=Some("g"),
    direction=Some(1),
    hidden=Some(false),
  )
  if shape.shape_type != "gr" {
    fail("Shape::new failed")
  }

  match @model.GradientType::from_int(1) {
    Linear => ()
    _ => fail("GradientType::from_int(1) should be Linear")
  }
  match @model.GradientType::from_int(2) {
    Radial => ()
    _ => fail("GradientType::from_int(2) should be Radial")
  }

  let mask = @model.Mask::new(
    inverted=false,
    path=@model.LottieProperty::new_static(path2),
    opacity=static_double(100.0),
    expansion=static_double(0.0),
    mode=@model.MaskMode::Add,
    name=Some("m"),
  )
  let layer = @model.Layer::new(
    index=1,
    layer_type=4,
    transform=default_transform,
    in_point=0.0,
    out_point=60.0,
    start_time=0.0,
    masks=Some([mask]),
    data=@model.LayerData::new_shape([shape]),
  )
  let anim = @model.Animation::new(
    version="5.7.0",
    frame_rate=30.0,
    in_point=0.0,
    out_point=60.0,
    width=512,
    height=512,
    layers=[layer],
  )
  if anim.layers.length() != 1 {
    fail("Animation/Layer/Mask constructors failed")
  }

  let layer_solid = @model.LayerData::new_solid("#FFFFFF", 100, 100)
  let layer_null = @model.LayerData::new_null()
  match (layer_solid, layer_null) {
    (Solid(_, _, _), Null) => ()
    _ => fail("LayerData constructors failed")
  }
}
