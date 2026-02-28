
test "parser/report_unknown_keys" {
  let json = @json.parse(
    "{\"v\":\"5.5.0\",\"fr\":60,\"custom\":{\"x\":1},\"layers\":[{\"ty\":4,\"foo\":1}]}",
  )
  let unknown = @parser.report_unknown_keys(json)
  inspect(unknown.length(), content="2")
  inspect(unknown[0], content="custom")
  inspect(unknown[1], content="layers[0].foo")
}

test "parser/report_unknown_keys_with_coverage" {
  let json = @json.parse(
    "{\"v\":\"5.5.0\",\"fr\":60,\"custom\":{\"x\":1},\"layers\":[{\"ty\":4,\"foo\":1}]}",
  )
  let report = @parser.report_unknown_keys_with_coverage(json)
  inspect(report.total_keys, content="7")
  inspect(report.known_keys, content="5")
  inspect(report.unknown_paths.length(), content="2")
  inspect(report.unknown_paths[0], content="custom")
  inspect(report.unknown_paths[1], content="layers[0].foo")
}
