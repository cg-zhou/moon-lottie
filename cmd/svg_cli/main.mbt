///|
struct Config {
  input_path : String
  start_frame : Double
  end_frame : Double
}

///|
fn command() -> @argparse.Command {
  @argparse.Command::new(
    "moon-lottie-svg",
    about="MoonBit Lottie SVG CLI",
    options=[
      @argparse.OptionArg::new(
        "start",
        short='s',
        about="Start frame",
      ),
      @argparse.OptionArg::new(
        "end",
        short='e',
        about="End frame",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new("input", about="Lottie JSON file path"),
    ],
  )
}

///|
fn parse_config(argv : Array[String]) -> Config raise {
  let matches = @argparse.parse(command(), argv=argv[1:])
  let values = matches.values
  
  guard values is { "input": [input_path, ..], .. } else {
    fail("Missing input file path")
  }
  
  let start_frame = match values.get("start") {
    Some([s, ..]) => try { @strconv.parse_double(s) } catch { _ => 0.0 }
    _ => 0.0
  }
  
  let end_frame = match values.get("end") {
    Some([e, ..]) => try { @strconv.parse_double(e) } catch { _ => start_frame }
    _ => start_frame
  }
  
  { input_path, start_frame, end_frame }
}

///|
fn main {
  let args = @env.args()
  println("Original args: \{args}")
  let config = try {
    parse_config(args)
  } catch {
    e => {
      println("Error parsing arguments: \{e}")
      return
    }
  }

  // Read JSON file
  let json_str = try {
    @fs.read_file_to_string(config.input_path)
  } catch {
    e => {
      println("Failed to read file: \{e}")
      return
    }
  }

  let json = try {
    @json.parse(json_str)
  } catch {
    e => {
      println("Failed to parse JSON: \{e}")
      return
    }
  }

  // Parse Lottie animation
  let animation = try {
    @parser.parse_animation(json)
  } catch {
    e => {
      println("Failed to parse Lottie: \{e}")
      return
    }
  }

  // Render frames in range
  let mut f = config.start_frame
  while f <= config.end_frame {
    // Initialize SVG renderer for each frame
    let renderer = @renderer.SvgRenderer::new(
      animation.width.to_double(),
      animation.height.to_double(),
    )

    // Initialize Player
    let player = @renderer.Player::new(animation, renderer)
    player.set_frame(f)

    // Render
    player.render()

    // Output SVG
    if config.start_frame != config.end_frame {
      println("--- Frame \{f} ---")
    }
    println(renderer.get_output())

    if f >= config.end_frame {
      break
    }
    f = f + 1.0
  }
}

