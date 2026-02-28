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
