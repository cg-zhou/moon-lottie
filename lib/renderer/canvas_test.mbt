#cfg(any(target = "wasm", target = "wasm-gc"))
test "canvas_renderer_impl" {
  let r = CanvasRenderer::new()
  // This should compile if the impl is visible here
  let _player = Player::new(@model.Animation::new(v="5.5.0", fr=30.0, ip=0.0, op=100.0, w=500, h=500, layers=[]), r)
}
