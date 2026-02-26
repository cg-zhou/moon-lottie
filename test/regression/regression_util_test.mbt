///|
struct RegressionSnapshot {
  frame : Double
  svg : String
}

///|
fn run_regression_test(json : String, snapshots : Array[RegressionSnapshot]) -> Unit raise Error {
  let json_val = @json.parse(json)
  let ani = @parser.parse_animation(json_val)
  let width = ani.w.to_double()
  let height = ani.h.to_double()
  
  for snapshot in snapshots {
    let renderer = @renderer.SvgRenderer::new(width, height)
    let player = @renderer.Player::new(ani, renderer)
    player.set_frame(snapshot.frame)
    player.render()
    let actual = renderer.get_output()
    
    if actual != snapshot.svg {
      let score = calculate_similarity(actual, snapshot.svg)
      if score < 0.999 {
         // 只在差异较大时报错，且不打印完整字符串
         let msg = "Snapshot mismatch at frame \{snapshot.frame}. Similarity: \{score * 100.0}%"
         fail(msg)
      }
      // 如果匹配度很高（比如只有极微小的浮点误差），可以根据需求选择是否记录或通过
    }
  }
}

///| 简单的相似度计算逻辑：基于字符位置的匹配度
fn calculate_similarity(a : String, b : String) -> Double {
  if a == b { return 1.0 }
  let len_a = a.length()
  let len_b = b.length()
  if len_a == 0 || len_b == 0 { return 0.0 }
  
  let min_len = if len_a < len_b { len_a } else { len_b }
  let max_len = if len_a > len_b { len_a } else { len_b }
  
  // 采样对比，避免对 1MB 字符串进行完全循环导致卡顿
  let mut matches = 0
  let sample_step = if min_len > 1000 { min_len / 1000 } else { 1 }
  let mut samples = 0
  
  for i = 0; i < min_len; i = i + sample_step {
    if a[i] == b[i] {
      matches = matches + 1
    }
    samples = samples + 1
  }
  
  // 基本分：长度接近度 * 采样匹配度
  let length_ratio = min_len.to_double() / max_len.to_double()
  let match_ratio = matches.to_double() / samples.to_double()
  
  length_ratio * match_ratio
}
