///|
fn run_frame_test(
  json_str : String,
  frame : Double,
) -> Array[DrawCommand] raise {
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }

  let recorder = @renderer.CommandRecorder::new()
  let player = @renderer.Player::new(ani, recorder)

  player.set_frame(frame)
  player.render()

  recorder.get_commands()
}

///|
test "regression_starfish" {
  let json = starfish_json
  // Sample 0%, 50%, 100%
  // Starfish op=301
  inspect(
    run_frame_test(json, 0.0),
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 800, 600), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 397.96, f: 286.023}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 2.04, f: 13.977}), SetOpacity(1), BeginPath, MoveTo(71, 20), CubicTo(71, -17.083, 103.315, 130.97, 103.315, 130.97), CubicTo(103.315, 130.97, 6.234, 75.734, 2.919, 73.705), CubicTo(-97.477, 16.439999999999998, -92.634, 138.73, -92.634, 138.73), CubicTo(-92.634, 138.73, -30.698999999999998, 27.076999999999998, -69.196, 25.552), CubicTo(-197.327, 49.056, -160.566, -45.23, -160.566, -45.23), CubicTo(-160.566, -45.23, -42.319, -55.178, -45.685, -57.913), CubicTo(-22.247000000000003, -171.091, -6.601, -166.684, -6.601, -166.684), CubicTo(-6.601, -166.684, 54.307, -97.48599999999999, 40.961, -61.345), CubicTo(27.615, -25.204, 156.486, -57.787, 156.486, -57.787), CubicTo(156.486, -57.787, 71, 57.083, 71, 20), ClosePath, Fill(255, 214, 102, 1), Restore, Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 1228.969, f: 286.031}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: -8.969000000000001, f: 38.468999999999994}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 25.289, f: -0.43700000000000117}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore, Save, ConcatTransform({a: 0.5, b: 0, c: 0, d: 0.5, e: 63.343999999999994, f: 59.873000000000005}), SetOpacity(1), BeginPath, MoveTo(1.5308084989341915e-15, -25), CubicTo(1.5308084989341915e-15, -25, 21.65063509461097, 12.499999999999996, 21.65063509461097, 12.499999999999996), CubicTo(21.65063509461097, 12.499999999999996, -21.650635094610962, 12.500000000000009, -21.650635094610962, 12.500000000000009), CubicTo(-21.650635094610962, 12.500000000000009, 1.5308084989341915e-15, -25, 1.5308084989341915e-15, -25), ClosePath, Fill(59, 59, 57, 1), Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 83.32, f: 15.591000000000001}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore]
    ),
  )
  inspect(
    run_frame_test(json, 150.0),
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 800, 600), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 397.96, f: 286.023}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 2.04, f: 13.977}), SetOpacity(1), BeginPath, MoveTo(71, 20), CubicTo(71, -17.083, 103.315, 130.97, 103.315, 130.97), CubicTo(103.315, 130.97, 6.234, 75.734, 2.919, 73.705), CubicTo(-97.477, 16.439999999999998, -92.634, 138.73, -92.634, 138.73), CubicTo(-92.634, 138.73, -30.698999999999998, 27.076999999999998, -69.196, 25.552), CubicTo(-197.327, 49.056, -160.566, -45.23, -160.566, -45.23), CubicTo(-160.566, -45.23, -42.319, -55.178, -45.685, -57.913), CubicTo(-22.247000000000003, -171.091, -6.601, -166.684, -6.601, -166.684), CubicTo(-6.601, -166.684, 54.307, -97.48599999999999, 40.961, -61.345), CubicTo(27.615, -25.204, 156.486, -57.787, 156.486, -57.787), CubicTo(156.486, -57.787, 71, 57.083, 71, 20), ClosePath, Fill(255, 214, 102, 1), Restore, Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 1228.969, f: 286.031}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: -8.969000000000001, f: 38.468999999999994}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 25.289, f: -0.43700000000000117}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore, Save, ConcatTransform({a: 0.5, b: 0, c: 0, d: 0.5, e: 63.343999999999994, f: 59.873000000000005}), SetOpacity(1), BeginPath, MoveTo(1.5308084989341915e-15, -25), CubicTo(1.5308084989341915e-15, -25, 21.65063509461097, 12.499999999999996, 21.65063509461097, 12.499999999999996), CubicTo(21.65063509461097, 12.499999999999996, -21.650635094610962, 12.500000000000009, -21.650635094610962, 12.500000000000009), CubicTo(-21.650635094610962, 12.500000000000009, 1.5308084989341915e-15, -25, 1.5308084989341915e-15, -25), ClosePath, Fill(59, 59, 57, 1), Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 83.32, f: 15.591000000000001}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore]
    ),
  )
  inspect(
    run_frame_test(json, 300.0),
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 800, 600), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 397.96, f: 286.023}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 2.04, f: 13.977}), SetOpacity(1), BeginPath, MoveTo(71, 20), CubicTo(71, -17.083, 103.315, 130.97, 103.315, 130.97), CubicTo(103.315, 130.97, 6.234, 75.734, 2.919, 73.705), CubicTo(-97.477, 16.439999999999998, -92.634, 138.73, -92.634, 138.73), CubicTo(-92.634, 138.73, -30.698999999999998, 27.076999999999998, -69.196, 25.552), CubicTo(-197.327, 49.056, -160.566, -45.23, -160.566, -45.23), CubicTo(-160.566, -45.23, -42.319, -55.178, -45.685, -57.913), CubicTo(-22.247000000000003, -171.091, -6.601, -166.684, -6.601, -166.684), CubicTo(-6.601, -166.684, 54.307, -97.48599999999999, 40.961, -61.345), CubicTo(27.615, -25.204, 156.486, -57.787, 156.486, -57.787), CubicTo(156.486, -57.787, 71, 57.083, 71, 20), ClosePath, Fill(255, 214, 102, 1), Restore, Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 1228.969, f: 286.031}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: -8.969000000000001, f: 38.468999999999994}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 25.289, f: -0.43700000000000117}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore, Save, ConcatTransform({a: 0.5, b: 0, c: 0, d: 0.5, e: 63.343999999999994, f: 59.873000000000005}), SetOpacity(1), BeginPath, MoveTo(1.5308084989341915e-15, -25), CubicTo(1.5308084989341915e-15, -25, 21.65063509461097, 12.499999999999996, 21.65063509461097, 12.499999999999996), CubicTo(21.65063509461097, 12.499999999999996, -21.650635094610962, 12.500000000000009, -21.650635094610962, 12.500000000000009), CubicTo(-21.650635094610962, 12.500000000000009, 1.5308084989341915e-15, -25, 1.5308084989341915e-15, -25), ClosePath, Fill(59, 59, 57, 1), Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 83.32, f: 15.591000000000001}), SetOpacity(1), BeginPath, MoveTo(0, -8), CubicTo(4.97056275, -8, 9, -4.418278, 9, 0), CubicTo(9, 4.418278, 4.97056275, 8, 0, 8), CubicTo(-4.97056275, 8, -9, 4.418278, -9, 0), CubicTo(-9, -4.418278, -4.97056275, -8, 0, -8), ClosePath, Fill(59, 59, 57, 1), Restore, Restore]
    ),
  )
}

///|
test "regression_bacon" {
  let json = bacon_json
  inspect(
    run_frame_test(json, 0.0),
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 500, 500), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 250, f: 250}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), SetOpacity(1), BeginPath, MoveTo(19, 0), CubicTo(19, -10.493, 10.493, -19, 0, -19), CubicTo(-10.493, -19, -19, -10.493, -19, 0), CubicTo(-19, 10.493, -10.493, 19, 0, 19), CubicTo(10.493, 19, 19, 10.493, 19, 0), ClosePath, Fill(255, 127, 0, 1), Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), SetOpacity(1), BeginPath, MoveTo(-115.5, -123), CubicTo(-115.5, -123, -115.5, 123, -115.5, 123), CubicTo(-115.5, 123, 115.5, 123, 115.5, 123), CubicTo(115.5, 123, 115.5, -123, 115.5, -123), CubicTo(115.5, -123, -115.5, -123, -115.5, -123), ClosePath, Fill(243, 155, 35, 1), Restore, Restore]
    ),
  )
  inspect(
    run_frame_test(json, 20.0),
    content=(
      #|[SetTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), ClearRect(0, 0, 500, 500), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 250, f: 250}), SetOpacity(1), Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), SetOpacity(1), BeginPath, MoveTo(19, 0), CubicTo(19, -10.493, 10.493, -19, 0, -19), CubicTo(-10.493, -19, -19, -10.493, -19, 0), CubicTo(-19, 10.493, -10.493, 19, 0, 19), CubicTo(10.493, 19, 19, 10.493, 19, 0), ClosePath, Fill(255, 127, 0, 1), Restore, Save, ConcatTransform({a: 1, b: 0, c: 0, d: 1, e: 0, f: 0}), SetOpacity(1), BeginPath, MoveTo(-115.5, -123), CubicTo(-115.5, -123, -115.5, 123, -115.5, 123), CubicTo(-115.5, 123, 115.5, 123, 115.5, 123), CubicTo(115.5, 123, 115.5, -123, 115.5, -123), CubicTo(115.5, -123, -115.5, -123, -115.5, -123), ClosePath, Fill(243, 155, 35, 1), Restore, Restore]
    ),
  )
}
