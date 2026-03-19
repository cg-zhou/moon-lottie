export const translations = {
  zh: {
    nav: {
      playground: '编辑器',
      support: '特性矩阵',
      design: '架构设计',
      usage: '快速开始',
      about: '项目路线',
    },
    common: {
      openNewWindow: '新窗口打开',
      viewRepo: '查看仓库',
      github: 'GitHub',
      lottieSpec: 'Lottie 规范',
      planned: '计划中',
      current: '当前版本',
      moonbit: 'MoonBit 官网',
    },
     playground: {
      title: '交互式沙盒',
      description: '在 MoonBit 引擎中测试 Lottie 文件，并与官方 lottie-web 播放器进行实时对比。',
    },
    support: {
      eyebrow: '特性矩阵',
      title: '标准合规性与能力',
      subtitle: '表格结构与官方 Supported Features 页面保持一致，仅额外补入 MoonLottie 一列。',
      audit: '前 7 列严格按 Airbnb 官方 Supported Features 表整理；MoonLottie 列基于当前源码实现审计。',
      source: '查看官方原表',
      total: '收录特性',
      supported: '已完成',
      partial: '部分',
      backlog: '计划中',
      columns: {
        feature: 'Feature',
        moon: 'Moon Lottie',
      },
      legend: {
        supported: '支持',
        unsupported: '不支持',
        unknown: '未知',
      }
    },
    design: {
      eyebrow: '架构',
      title: '技术架构',
      subtitle: '基于 MoonBit 编写的跨平台内核，编译为高效的 WebAssembly 环境。',
      architecture: '核心架构',
      pipeline: '渲染流水线',
      archDesc: '展示 MoonBit Wasm 内核与 JS 宿主环境的交互概览。',
      pipeDesc: '从 Lottie JSON 数据到 Wasm 引擎渲染，最终输出到 Canvas 帧的完整数据流。',
      description: 'MoonLottie 采用 MoonBit 开发，利用其紧凑的二进制输出和卓越的运行时性能。架构上我们将解析、求值与渲染解耦，以便后续支持多后端渲染。',
      ongoing: '我们将持续优化性能并完善标准对齐。',
      expressionTitle: '表达式',
      expressionSubtitle: '通过重建 JS 宿主上下文来处理 After Effects 表达式。',
      expressionFlow: '表达式执行流',
      risks: '技术限制',
    },
    usage: {
      title: '接入 MoonLottie',
      subtitle: '了解集成方式并运行你的第一个 MoonBit 动画。',
      step1: '1. 添加依赖',
      step2: '2. MoonBit 集成',
      step3: '3. Web 互操作',
      webDesc: '您很快就能像使用标准 HTML 标签一样调用 MoonLottie：',
    },
    vision: {
      eyebrow: 'Roadmap',
      title: '极速、现代的 Lottie 播放器',
      lead: 'MoonLottie 是对性能和跨平台一致性的重新思考。核心驱动力源自 MoonBit 强大的类型系统与编译优化。',
      coreValues: '项目哲学',
      roadmap: '路线图',
    },
    footer: {
      tagline: '由 MoonBit 驱动的高性能 Lottie 渲染引擎。为速度和可移植性而生。',
    }
  },
  en: {
    nav: {
      playground: 'Playground',
      support: 'Capability',
      design: 'Architecture',
      usage: 'Quick Start',
      about: 'Roadmap',
    },
    common: {
      openNewWindow: 'Open in New Window',
      viewRepo: 'View Repository',
      github: 'GitHub',
      lottieSpec: 'Lottie Spec',
      planned: 'Planned',
      current: 'Current',
      moonbit: 'MoonBit Website',
    },
    playground: {
      title: 'Interactive Sandbox',
      description: 'Test your Lottie files against our MoonBit engine and compare results with the official lottie-web player in real-time.',
    },
    support: {
      eyebrow: 'Feature Matrix',
      title: 'Standard Compliance',
      subtitle: 'This table mirrors the official Supported Features matrix, with one additional MoonLottie column.',
      audit: 'The first 7 columns are kept in lockstep with Airbnb\'s official Supported Features table. The MoonLottie column is derived from a code audit of the current implementation.',
      source: 'Open the official matrix',
      total: 'Features',
      supported: 'Done',
      partial: 'Partial',
      backlog: 'Backlog',
      columns: {
        feature: 'Feature',
        moon: 'Moon Lottie',
      },
      legend: {
        supported: 'Supported',
        unsupported: 'Unsupported',
        unknown: 'Unknown',
      }
    },
    design: {
      eyebrow: 'Architecture',
      title: 'Under the Hood',
      subtitle: 'A platform-agnostic core written in MoonBit, compiling to highly efficient WebAssembly.',
      architecture: 'System Architecture',
      pipeline: 'Rendering Pipeline',
      archDesc: 'Overview of the MoonBit Wasm core and its interaction with the JS host environment.',
      pipeDesc: 'Step-by-step data flow from Lottie JSON to final Canvas frame via the Wasm engine.',
      description: 'MoonLottie core is built with MoonBit, leveraging its compact binary size and superior runtime efficiency. Our modular design decouples parsing, evaluation, and rendering for multi-backend support.',
      ongoing: 'We are continuously improving performance and broadening specification coverage.',
      expressionTitle: 'Expressions',
      expressionSubtitle: 'Handling After Effects expressions by piping calls through a reconstructed JS host context.',
      expressionFlow: 'Expression Execution Flow',
      risks: 'Technical Constraints',
    },
    usage: {
      title: 'Integrating MoonLottie',
      subtitle: 'How to pull the library and get your first animation running.',
      step1: '1. Add Package',
      step2: '2. MoonBit Integration',
      step3: '3. Web Interop',
      webDesc: 'Soon you will be able to use MoonLottie as a standard Web Component:',
    },
    vision: {
      eyebrow: 'Roadmap',
      title: 'The Fast, Modern Lottie Player.',
      lead: 'MoonLottie is a rethink of performance and consistency. Driven by MoonBit\'s powerful type system and compiler optimizations.',
      coreValues: 'Philosophy',
      roadmap: 'Future Milestones',
    },
    footer: {
      tagline: 'The high-performance Lottie engine powered by MoonBit. Built for speed and portability.',
    }
  }
}

export const overviewCards = {
  zh: [
    { title: '高性能', description: '由 MoonBit & WebAssembly 驱动，提供接近原生的插值和渲染速度。' },
    { title: '平台无关', description: '内核 Wasm 实现，只需少量的宿主粘合代码即可移植到 Web、移动端和桌面端。' },
    { title: '现代生态', description: '为 Web 未来而生，支持 js-string builtins 并拥有更小的二进制体积。' },
  ],
  en: [
    { title: 'High Performance', description: 'Powered by MoonBit & WebAssembly, delivering near-native Lottie interpolation and rendering speeds.' },
    { title: 'Platform Agnostic', description: 'Core logic in Wasm. Easily portable to Web, Mobile, and Desktop with minimal host glue code.' },
    { title: 'Modern Ecosystem', description: 'Built for the future of the web with js-string builtins and optimized small binary footprint.' },
  ]
}

export const aboutCards = {
  zh: [
    { title: '什么是 MoonLottie?', description: '一个完全用 MoonBit 编写的跨平台 Lottie 播放引擎。目标是成为最快、最轻量的运行时。' },
    { title: 'Wasm 优先设计', description: '通过编译为 WebAssembly，确保在不同浏览器和硬件上表现一致。' },
    { title: 'MoonBit 优势', description: '利用 MoonBit 的内存安全、简洁的 FFI 和卓越的编译性能。' },
    { title: 'Roadmap 重点', description: '逐步构建完整的 SDK，包括 Web Component、React 封装以及强大的表达式支持。' },
  ],
  en: [
    { title: 'What is MoonLottie?', description: 'A cross-platform Lottie player engine written entirely in MoonBit. It aims to be the fastest and most lightweight Lottie runtime.' },
    { title: 'Wasm-First Design', description: 'By compiling to WebAssembly, we ensure consistent behavior across different browsers and hardware.' },
    { title: 'The MoonBit Advantage', description: 'Leveraging MoonBit for memory safety, clean FFI, and excellent build performance.' },
    { title: 'Roadmap Focus', description: 'Moving towards a full SDK including Web Components, React wrappers, and robust expression support.' },
  ]
}

export const roadmapPhases = {
  zh: [
    { title: 'V0.1: 核心引擎 (当前)', items: ['JSON 解析与模型', '时间轴求值', 'Canvas 2D 渲染', 'JS 表达式桥接'] },
    { title: 'V0.2: 开发者体验', items: ['NPM 包发布', '<moon-lottie> Web Component', 'React SDK 封装', '安卓兼容层优化'] },
    { title: 'V0.3: 全规格对齐', items: ['高级混合模式', 'Luma Matte 支持', '完整 AE 表达式宿主', 'SVG/WebGL 后端'] },
  ],
  en: [
    { title: 'V0.1: Core Engine (Current)', items: ['JSON Parser & Model', 'Timeline Evaluation', 'Canvas 2D Rendering', 'JS Expression Bridge'] },
    { title: 'V0.2: Developer Experience', items: ['NPM Package Release', '<moon-lottie> Web Component', 'React SDK Wrapper', 'Android Compatibility Layer'] },
    { title: 'V0.3: Full Spec Parity', items: ['Advanced Blend Modes', 'Luma Matte Support', 'Full AE Expression Host', 'SVG/WebGL Backends'] },
  ]
}
