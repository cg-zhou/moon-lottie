
test "svg_renderer/regression_0" {
  let json_str = "{\"v\":\"5.5.2\",\"fr\":30,\"ip\":0,\"op\":10,\"w\":100,\"h\":100,\"nm\":\"test\",\"ddd\":0,\"assets\":[],\"layers\":[{\"ty\":4,\"ks\":{\"p\":{\"a\":0,\"k\":[50,50]},\"s\":{\"a\":0,\"k\":[100,100]},\"r\":{\"a\":0,\"k\":0},\"o\":{\"a\":0,\"k\":100},\"a\":{\"a\":0,\"k\":[0,0]}},\"nm\":\"r\",\"shapes\":[{\"ty\":\"gr\",\"it\":[{\"ty\":\"rc\",\"s\":{\"a\":0,\"k\":[20,20]},\"p\":{\"a\":0,\"k\":[0,0]},\"r\":{\"a\":0,\"k\":0},\"nm\":\"r\"},{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":[1,0,0]},\"o\":{\"a\":0,\"k\":100},\"nm\":\"f\"}]}]}]}"
  let json = @json.parse(json_str)
  let ani = @parser.parse_animation(json) catch {
    e => fail("Failed to parse: \{e}")
  }
  let renderer = @renderer.SvgRenderer::new(100.0, 100.0)
  let player = @renderer.Player::new(ani, renderer)
  player.set_frame(0.0)
  player.render() // Must call render to fill the buffer
  let svg = renderer.get_output()
  // Actual output from renderer
  let expected = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 100 100\"><g><g opacity=\"1\"><g><path d=\"M-10,-10 C-10,-10 10,-10 10,-10 C10,-10 10,10 10,10 C10,10 -10,10 -10,10 C-10,10 -10,-10 -10,-10 Z\" fill=\"#FF0000\" fill-opacity=\"1\" fill-rule=\"nonzero\" transform=\"matrix(1 0 0 1 50 50)\" /></g></g></g></svg>"
  if svg != expected {
    fail("svg output mismatch: \{svg}")
  }
}
