///|
priv struct ArgReader {
  values : Map[String, Array[String]]
}

///|
priv struct FrameWindowConfig {
  start_frame : Int?
  end_frame : Int?
  step : Int
}

///|
priv struct FrameWindow {
  start_frame : Int
  end_frame : Int
  step : Int
}

///|
priv struct ExportSvgRequest {
  input_path : String
  output_dir : String?
  frame_window : FrameWindowConfig
}

///|
priv struct PlayRequest {
  input_path : String
  target_width : Int?
  target_height : Int?
  ansi : Bool
}

///|
priv struct AnimationInfoRequest {
  input_path : String
}

///|
priv enum CliRequest {
  ShowInfo(AnimationInfoRequest)
  ExportSvg(ExportSvgRequest)
  Play(PlayRequest)
}

///|
priv struct ExportPlan {
  input_path : String
  output_dir : String
  start_frame : Int
  end_frame : Int
  step : Int
}

///|
fn command() -> @argparse.Command {
  @argparse.Command::new(
    "cli",
    about="[Moon Lottie] Inspect animations, export SVG frames, or play them in the console",
    arg_required_else_help=true,
    subcommand_required=true,
    subcommands=[play_command(), svg_command()],
  )
}

///|
fn svg_command() -> @argparse.Command {
  @argparse.Command::new(
    "svg",
    about="Export animation frames as SVG files",
    options=[
      @argparse.OptionArg::new(
        "output_dir",
        short='o',
        long="output-dir",
        about="Base directory where the export folder will be created",
      ),
      @argparse.OptionArg::new(
        "start",
        short='s',
        about="Start frame index, inclusive",
        allow_hyphen_values=true,
      ),
      @argparse.OptionArg::new(
        "end",
        short='e',
        about="End frame index, inclusive",
        allow_hyphen_values=true,
      ),
      @argparse.OptionArg::new(
        "step",
        short='t',
        about="Frame increment between exports",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new(
        "input",
        about="Lottie JSON file path",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
}

///|
fn play_command() -> @argparse.Command {
  @argparse.Command::new(
    "play",
    about="Render braille frames in the terminal via Drawille",
    options=[
      @argparse.OptionArg::new(
        "width",
        long="width",
        about="Console render width in logical pixels",
      ),
      @argparse.OptionArg::new(
        "height",
        long="height",
        about="Console render height in logical pixels",
      ),
      @argparse.OptionArg::new(
        "ansi",
        long="ansi",
        about="ANSI output: on or off",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new(
        "input",
        about="Lottie JSON file path",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
}

///|
fn ArgReader::new(matches : @argparse.Matches) -> ArgReader {
  { values: matches.values }
}

///|
fn ArgReader::string(self : ArgReader, key : String) -> String? {
  match self.values.get(key) {
    Some([value, ..]) => Some(value)
    _ => None
  }
}

///|
fn ArgReader::required_string(
  self : ArgReader,
  key : String,
) -> String raise {
  match self.values.get(key) {
    Some([value, ..]) => value
    _ => fail("Missing required argument: \{key}")
  }
}

///|
fn ArgReader::int(self : ArgReader, key : String) -> Int? raise {
  match self.string(key) {
    Some(value) =>
      Some(
        try {
          @string.parse_int(value)
        } catch {
          _ => fail("Invalid --\{key} value: \{value}")
        },
      )
    None => None
  }
}

///|
fn parse_step(args : ArgReader) -> Int raise {
  match args.int("step") {
    Some(value) => {
      guard value > 0 else {
        fail("--step must be greater than 0")
      }
      value
    }
    None => 1
  }
}

///|
fn is_option_token(value : String) -> Bool {
  value.length() > 0 && value[0].to_int().unsafe_to_char() == '-'
}

///|
fn looks_like_json_path(value : String) -> Bool {
  value.length() >= 5 && value[value.length() - 5:value.length()].to_string() == ".json"
}

///|
fn parse_ansi(args : ArgReader) -> Bool raise {
  match args.string("ansi") {
    Some("off") => false
    Some("false") => false
    Some("0") => false
    Some("on") => true
    Some("true") => true
    Some("1") => true
    Some(value) => fail("Invalid --ansi value: \{value}")
    None => true
  }
}

///|
fn parse_frame_window(args : ArgReader) -> FrameWindowConfig raise {
  {
    start_frame: args.int("start"),
    end_frame: args.int("end"),
    step: parse_step(args),
  }
}

///|
fn should_show_animation_info(argv : Array[String]) -> Bool {
  if argv.length() != 2 {
    return false
  }

  let candidate = argv[1]
  !is_option_token(candidate) &&
  candidate != "play" &&
  candidate != "svg" &&
  looks_like_json_path(candidate)
}

///|
fn parse_request(argv : Array[String]) -> CliRequest raise {
  if should_show_animation_info(argv) {
    return ShowInfo({ input_path: argv[1] })
  }

  let matches = @argparse.parse(command(), argv=argv[1:])
  match matches.subcommand {
    Some((name, svg_matches)) if name == "svg" => parse_svg_request(svg_matches)
    Some((name, play_matches)) if name == "play" => parse_play_request(play_matches)
    Some((name, _)) => fail("Unsupported command: \{name}")
    None => fail("Missing command")
  }
}

///|
fn parse_svg_request(matches : @argparse.Matches) -> CliRequest raise {
  let args = ArgReader::new(matches)
  ExportSvg({
    input_path: args.required_string("input"),
    output_dir: args.string("output_dir"),
    frame_window: parse_frame_window(args),
  })
}

///|
fn parse_play_request(matches : @argparse.Matches) -> CliRequest raise {
  let args = ArgReader::new(matches)
  Play({
    input_path: args.required_string("input"),
    target_width: args.int("width"),
    target_height: args.int("height"),
    ansi: parse_ansi(args),
  })
}

///|
fn is_path_separator(ch : Char) -> Bool {
  ch == '/' || ch == '\\'
}

///|
fn join_path(dir : String, name : String) -> String {
  if dir == "" || dir == "." {
    name
  } else if is_path_separator(dir[dir.length() - 1].to_int().unsafe_to_char()) {
    dir + name
  } else {
    dir + "/" + name
  }
}

///|
fn file_stem(path : String) -> String {
  if path == "" {
    return ""
  }

  let mut name_start = 0
  for i = 0; i < path.length(); i = i + 1 {
    if is_path_separator(path[i].to_int().unsafe_to_char()) {
      name_start = i + 1
    }
  }

  let mut dot_index = -1
  for i = name_start; i < path.length(); i = i + 1 {
    if path[i].to_int().unsafe_to_char() == '.' {
      dot_index = i
    }
  }

  if dot_index > name_start {
    path[name_start:dot_index].to_string()
  } else {
    path[name_start:path.length()].to_string()
  }
}

///|
fn ensure_dir_all(path : String) -> Unit raise {
  if path == "" || path == "." {
    return
  }

  if @fs.path_exists(path) {
    let path_is_dir = try { @fs.is_dir(path) } catch { _ => false }
    if !path_is_dir {
      fail("Output path exists and is not a directory: \{path}")
    }
    return
  }

  let mut current = ""
  let mut index = 0
  if path.length() >= 2 && path[1].to_int().unsafe_to_char() == ':' {
    current = path[0:2].to_string()
    index = 2
    if index < path.length() && is_path_separator(path[index].to_int().unsafe_to_char()) {
      current = current + "/"
      index = index + 1
    }
  } else if is_path_separator(path[0].to_int().unsafe_to_char()) {
    current = "/"
    index = 1
  }

  let mut segment_start = index
  while index <= path.length() {
    if index == path.length() ||
      is_path_separator(path[index].to_int().unsafe_to_char()) {
      if index > segment_start {
        let segment = path[segment_start:index].to_string()
        current = join_path(current, segment)
        if @fs.path_exists(current) {
          let current_is_dir = try { @fs.is_dir(current) } catch { _ => false }
          if !current_is_dir {
            fail("Path component is not a directory: \{current}")
          }
        } else {
          @fs.create_dir(current)
        }
      }
      segment_start = index + 1
    }
    index = index + 1
  }
}

///|
fn ensure_unique_dir(base_path : String) -> String {
  if !@fs.path_exists(base_path) {
    return base_path
  }

  let mut suffix = 1
  let mut candidate = "\{base_path}_\{suffix}"
  while @fs.path_exists(candidate) {
    suffix = suffix + 1
    candidate = "\{base_path}_\{suffix}"
  }
  candidate
}

///|
fn count_digits(value : Int) -> Int {
  let mut n = if value < 0 { -value } else { value }
  let mut digits = 1
  while n >= 10 {
    n = n / 10
    digits = digits + 1
  }
  digits
}

///|
fn repeat_char(ch : Char, count : Int) -> String {
  let buffer = StringBuilder::new()
  for i = 0; i < count; i = i + 1 {
    buffer.write_char(ch)
  }
  buffer.to_string()
}

///|
fn format_frame_index(frame : Int, width : Int) -> String {
  let negative = frame < 0
  let abs_frame = if negative { -frame } else { frame }
  let number = abs_frame.to_string()
  let zeros = if width > number.length() {
    repeat_char('0', width - number.length())
  } else {
    ""
  }
  if negative {
    "-" + zeros + number
  } else {
    zeros + number
  }
}

///|
fn resolve_frame_window(
  config : FrameWindowConfig,
  animation : @model.Animation,
) -> FrameWindow raise {
  let default_start = animation.in_point.floor().to_int()
  let default_end = {
    let last_frame = animation.out_point.ceil().to_int() - 1
    if last_frame < default_start { default_start } else { last_frame }
  }

  let start_frame = match config.start_frame {
    Some(value) => value
    None => default_start
  }
  let end_frame = match (config.start_frame, config.end_frame) {
    (Some(start), None) => start
    (_, Some(value)) => value
    _ => default_end
  }

  guard start_frame <= end_frame else {
    fail("start frame must be less than or equal to end frame")
  }

  {
    start_frame,
    end_frame,
    step: config.step,
  }
}

///|
fn resolve_export_plan(
  request : ExportSvgRequest,
  animation : @model.Animation,
) -> ExportPlan raise {
  let frame_window = resolve_frame_window(request.frame_window, animation)
  let stem = file_stem(request.input_path)
  let base_name = if stem == "" { "animation" } else { stem }
  let output_dir = match request.output_dir {
    Some(dir) => dir
    None => ensure_unique_dir(join_path(".", base_name))
  }

  {
    input_path: request.input_path,
    output_dir,
    start_frame: frame_window.start_frame,
    end_frame: frame_window.end_frame,
    step: frame_window.step,
  }
}

///|
fn resolve_console_size(
  request : PlayRequest,
  animation : @model.Animation,
) -> (Int, Int) raise {
  let source_width = animation.width.to_double().max(1.0)
  let source_height = animation.height.to_double().max(1.0)

  let width = match request.target_width {
    Some(value) => {
      guard value > 0 else {
        fail("--width must be greater than 0")
      }
      value
    }
    None => 0
  }
  let height = match request.target_height {
    Some(value) => {
      guard value > 0 else {
        fail("--height must be greater than 0")
      }
      value
    }
    None => 0
  }

  match (width, height) {
    (0, 0) => (160, 80)
    (0, resolved_height) => (
      ((resolved_height.to_double() * source_width) / source_height).round().to_int().max(1),
      resolved_height,
    )
    (resolved_width, 0) => (
      resolved_width,
      ((resolved_width.to_double() * source_height) / source_width).round().to_int().max(1),
    )
    (resolved_width, resolved_height) => (resolved_width, resolved_height)
  }
}

///|
fn render_svg_frame(animation : @model.Animation, frame : Int) -> String {
  let renderer = @renderer.SvgRenderer::new(
    animation.width.to_double(),
    animation.height.to_double(),
  )
  let player = @renderer.Player::new(animation, renderer)
  player.set_frame(frame.to_double())
  player.render()
  renderer.get_output()
}

///|
fn render_console_frame(
  animation : @model.Animation,
  frame : Int,
  request : PlayRequest,
  target_width : Int,
  target_height : Int,
) -> String {
  let renderer = @renderer.DrawilleRenderer::new(
    animation.width.to_double(),
    animation.height.to_double(),
    target_width=target_width,
    target_height=target_height,
    enable_ansi=request.ansi,
  )
  let player = @renderer.Player::new(animation, renderer)
  player.set_frame(frame.to_double())
  player.render()
  renderer.get_output()
}

///|
fn export_frames(animation : @model.Animation, plan : ExportPlan) -> Int raise {
  ensure_dir_all(plan.output_dir)

  let max_digits = {
    let start_digits = count_digits(plan.start_frame)
    let end_digits = count_digits(plan.end_frame)
    let digits = if start_digits > end_digits { start_digits } else { end_digits }
    if digits < 4 { 4 } else { digits }
  }

  let mut exported = 0
  let mut frame = plan.start_frame
  while frame <= plan.end_frame {
    let file_name = "frame_\{format_frame_index(frame, max_digits)}.svg"
    let file_path = join_path(plan.output_dir, file_name)

    let svg = render_svg_frame(animation, frame)
    @fs.write_string_to_file(file_path, svg)
    exported = exported + 1
    frame = frame + plan.step
  }
  exported
}

///|
fn load_animation(input_path : String) -> @model.Animation raise {
  let json_str = @fs.read_file_to_string(input_path)
  let json = @json.parse(json_str)
  @parser.parse_animation(json)
}

///|
fn print_export_summary(
  animation : @model.Animation,
  plan : ExportPlan,
  count : Int,
) -> Unit {
  println("Input: \{plan.input_path}")
  println("Output directory: \{plan.output_dir}")
  println(
    "Frames: \{plan.start_frame}..\{plan.end_frame} step \{plan.step} (exported \{count} file(s))",
  )
  println(
    "Animation: \{animation.width}x\{animation.height} @ \{animation.frame_rate}fps",
  )
}

///|
fn strip_trailing_line_endings(text : String) -> String {
  let mut end = text.length()
  while end > 0 {
    let ch = text[end - 1].to_int().unsafe_to_char()
    if ch == '\n' || ch == '\r' {
      end = end - 1
    } else {
      break
    }
  }
  text[0:end].to_string()
}

///|
fn print_animation_info(
  input_path : String,
  animation : @model.Animation,
) -> Unit raise {
  let frame_window = resolve_frame_window(
    { start_frame: None, end_frame: None, step: 1 },
    animation,
  )
  let frame_count = frame_window.end_frame - frame_window.start_frame + 1
  let animation_name = match animation.name {
    Some(value) if value != "" => value
    _ => "(unnamed)"
  }
  let asset_count = match animation.assets {
    Some(assets) => assets.length()
    None => 0
  }
  let duration_seconds = if animation.frame_rate > 0.0 {
    (animation.out_point - animation.in_point) / animation.frame_rate
  } else {
    0.0
  }

  println("Input: \{input_path}")
  println("Name: \{animation_name}")
  println("Version: \{animation.version}")
  println("Canvas: \{animation.width}x\{animation.height}")
  println(
    "Frames: \{frame_window.start_frame}..\{frame_window.end_frame} (\{frame_count} total) @ \{animation.frame_rate}fps",
  )
  println("Duration: \{duration_seconds}s")
  println("Layers: \{animation.layers.length()} | Assets: \{asset_count}")
}

///|
fn resolve_playback_delay(animation : @model.Animation) -> UInt64 {
  let fps = if animation.frame_rate > 0.0 { animation.frame_rate } else { 12.0 }
  let delay_ms = (1000.0 / fps).round().to_int()
  let clamped_delay = if delay_ms <= 0 { 1 } else { delay_ms }
  clamped_delay.to_uint64()
}

///|
fn render_console(
  animation : @model.Animation,
  request : PlayRequest,
) -> Unit raise {
  let frame_window = resolve_frame_window(
    { start_frame: None, end_frame: None, step: 1 },
    animation,
  )
  let (target_width, target_height) = resolve_console_size(request, animation)
  let frame_delay = resolve_playback_delay(animation)

  let mut frame = frame_window.start_frame
  while frame <= frame_window.end_frame {
    let output = strip_trailing_line_endings(
      render_console_frame(animation, frame, request, target_width, target_height),
    )
    println("\u001b[2J\u001b[H\{output}")
    let start = @env.now()
    while @env.now() - start < frame_delay {

    }
    frame = frame + frame_window.step
  }
}

///|
fn run_show_info(request : AnimationInfoRequest) -> Unit raise {
  let animation = load_animation(request.input_path)
  print_animation_info(request.input_path, animation)
}

///|
fn run_export(request : ExportSvgRequest) -> Unit raise {
  let animation = load_animation(request.input_path)
  let plan = resolve_export_plan(request, animation)
  let exported = export_frames(animation, plan)
  print_export_summary(animation, plan, exported)
}

///|
fn run_play(request : PlayRequest) -> Unit raise {
  let animation = load_animation(request.input_path)
  render_console(animation, request)
}

///|
pub fn run() -> Unit {
  let request = try {
    parse_request(@env.args())
  } catch {
    e => {
      println("Error parsing arguments: \{e}")
      return
    }
  }

  let result = try {
    match request {
      ShowInfo(info_request) => run_show_info(info_request)
      ExportSvg(export_request) => run_export(export_request)
      Play(play_request) => run_play(play_request)
    }
  } catch {
    e => {
      match request {
        ShowInfo(_) => println("Failed to inspect animation: \{e}")
        ExportSvg(_) => println("Failed to export SVG frames: \{e}")
        Play(_) => println("Failed to play console animation: \{e}")
      }
      return
    }
  }
  let _ = result
}