///|
struct Config {
  input_path : String
  output_dir : String?
  start_frame : Int?
  end_frame : Int?
  step : Int
}

///|
struct ArgReader {
  values : Map[String, Array[String]]
}

///|
struct ExportPlan {
  input_path : String
  output_dir : String
  start_frame : Int
  end_frame : Int
  step : Int
}

///|
fn command() -> @argparse.Command {
  @argparse.Command::new(
    "moon-lottie-svg",
    about="[Moon Lottie] Export Lottie animation frames as SVG files",
    arg_required_else_help=true,
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
          @strconv.parse_int(value)
        } catch {
          _ => fail("Invalid --\{key} value: \{value}")
        },
      )
    None => None
  }
}

///|
fn parse_config(argv : Array[String]) -> Config raise {
  let matches = @argparse.parse(command(), argv=argv[1:])
  let args = ArgReader::new(matches)

  let step = match args.int("step") {
    Some(value) => {
      guard value > 0 else {
        fail("--step must be greater than 0")
      }
      value
    }
    None => 1
  }

  {
    input_path: args.required_string("input"),
    output_dir: args.string("output_dir"),
    start_frame: args.int("start"),
    end_frame: args.int("end"),
    step,
  }
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
fn resolve_export_plan(
  config : Config,
  animation : @model.Animation,
) -> ExportPlan raise {
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

  let stem = file_stem(config.input_path)
  let base_name = if stem == "" { "animation" } else { stem }
  let output_dir = match config.output_dir {
    Some(dir) => dir
    None => ensure_unique_dir(join_path(".", base_name))
  }

  {
    input_path: config.input_path,
    output_dir,
    start_frame,
    end_frame,
    step: config.step,
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
fn print_summary(animation : @model.Animation, plan : ExportPlan, count : Int) -> Unit {
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
fn main {
  let args = @env.args()
  let config = try {
    parse_config(args)
  } catch {
    e => {
      println("Error parsing arguments: \{e}")
      return
    }
  }

  let animation = try {
    load_animation(config.input_path)
  } catch {
    e => {
      println("Failed to load animation: \{e}")
      return
    }
  }

  let plan = try {
    resolve_export_plan(config, animation)
  } catch {
    e => {
      println("Invalid export configuration: \{e}")
      return
    }
  }

  let exported = try {
    export_frames(animation, plan)
  } catch {
    e => {
      println("Failed to export SVG frames: \{e}")
      return
    }
  }

  print_summary(animation, plan, exported)
}

