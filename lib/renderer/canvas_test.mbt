///|
#cfg(any(target="wasm", target="wasm-gc"))
test "canvas_renderer_impl" {
  let r = CanvasRenderer::new()
  // This should compile if the impl is visible here
  let _player = Player::new(
    @model.Animation::new(
      version="5.5.0",
      frame_rate=30.0,
      in_point=0.0,
      out_point=100.0,
      width=500,
      height=500,
      layers=[],
    ),
    r,
  )
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
test "canvas renderer keeps clip-based layer masks" {
  let r = CanvasRenderer::new()
  assert_false(r.supports_mask_composite())
}
