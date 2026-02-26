
test "parser/dump_unknown_keys" {
  // Manual check for now to fill the table
  let _ = @json.parse("{}")
  // ripple.json usually contains "tm" (Trim Paths) and "rp" (Repeaters)
  // simple.json is fully covered
}
