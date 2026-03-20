import React from "react"

const MoonBitLink = () => (
  <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" style={{ color: "var(--primary)", textDecoration: "underline" }}>
    MoonBit
  </a>
);

export const translations = {
  zh: {
    nav: {
      overview: "概览",
      playground: "演示",
      features: "特性支持",
      architecture: "底层架构",
      roadmap: "项目路线",
    },
    common: {
      openNewWindow: "新窗口打开",
      viewRepo: "查看仓库",
      github: "GitHub",
      lottieSpec: "Lottie 规范",
      planned: "待办项",
      current: "当前版本",
      moonbit: "MoonBit 官网",
      getStarted: "开始使用",
    },
    overview: {
      title: "极速、现代的 Lottie 动画渲染引擎",
      subtitle: (
        <>
          MoonLottie 是对性能和跨平台一致性的重新思考。基于 <MoonBitLink />{" "}
          强大的类型系统与编译优化，为 Web 提供极致的渲染体验。
        </>
      ),
      visionEyebrow: "使命与愿景",
      coreValues: "TODO：",
      quickStart: "TODO：",
      step1: "1. 添加依赖",
      step2: "2. 集成",
      step3: "3. 浏览器运行",
      heroCta: "在线演示",
    },
    playground: {
      eyebrow: "Live Demo",
      title: "在线演示",
      subtitle: (
        <>
          直观感受 Moon Lottie 引擎的渲染性能，支持与官方 lottie-web 进行对比。
        </>
      ),
    },
    features: {
      eyebrow: "Compatibility",
      title: "特性支持矩阵",
      subtitle: (
        <>
          本表遵循 Airbnb 官方 Supported Features 标准，对比 7 个主流平台与 Moon Lottie 实现的特性支持情况。
        </>
      ),
      audit: "数据同步自 Airbnb 官方 Lottie 规范 v24+。",
      source: "查看官方原表",
      columns: {
        feature: "Feature",
        moon: "Moon Lottie",
      },
      legend: {
        supported: "支持",
        unsupported: "不支持",
        unknown: "未知",
      }
    },
    architecture: {
      eyebrow: "Inside MoonLottie",
      title: "底层技术设计",
      subtitle: "解析、求值与渲染逻辑完全解耦，编译为紧凑的 Wasm 指令流。",
      system: "核心系统架构",
      pipeline: "渲染流水线",
      description: (
        <>
          MoonLottie 采用 <MoonBitLink />{" "}
          开发，利用其零开销抽象和卓越的运行时性能。架构上我们通过 Wasm 内存共享技术最小化了 JS 与核心引擎间的交互开销。
        </>
      ),
      archCaption: (
        <>
          <MoonBitLink /> Wasm 内核与 JS 宿主环境的交互概览。
        </>
      ),
      pipeCaption: "从 Lottie JSON 到引擎渲染，最终输出到 Canvas 帧的完整数据流。",
    },
    roadmap: {
      eyebrow: "Milestones",
      title: "里程碑与路线图",
      subtitle: "记录 MoonLottie 的成长轨迹与未来规划。",
    },
    footer: {
      tagline: (
        <>
          由 <MoonBitLink /> 驱动的高性能 Lottie 渲染引擎。为速度和可移植性而生。
        </>
      ),
    }
  },
  en: {
    nav: {
      overview: "Overview",
      playground: "Playground",
      features: "Supported Features",
      architecture: "Architecture",
      roadmap: "Roadmap",
    },
    common: {
      openNewWindow: "Open in New Window",
      viewRepo: "View Repository",
      github: "GitHub",
      lottieSpec: "Lottie Spec",
      planned: "Planned",
      current: "Current",
      moonbit: "MoonBit Website",
      getStarted: "Quick Start",
    },
    overview: {
      title: "The Fast, Modern Lottie Animation Engine.",
      subtitle: (
        <>
          MoonLottie is a rethink of performance and consistency. Powered by <MoonBitLink />
          {"'"}s powerful type system and compiler optimizations.
        </>
      ),
      visionEyebrow: "Vision",
      coreValues: "TODO:",
      quickStart: "TODO:",
      step1: "1. Add Package",
      step2: "2. Integration",
      step3: "3. Running in Web",
      heroCta: "Live Demo",
    },
    playground: {
      eyebrow: "Live Demo",
      title: "Interactive Sandbox",
      subtitle: (
        <>
          Experience Moon Lottie engine rendering performance against official lottie-web in real-time.
        </>
      ),
    },
    features: {
      eyebrow: "Compatibility",
      title: "Capability Matrix",
      subtitle: (
        <>
          This table follows the official Airbnb Supported Features standard, comparing implemented features across 7 major platforms and Moon Lottie.
        </>
      ),
      audit: "Data synchronized from Airbnb's official Lottie specification v24+.",
      source: "View official matrix",
      columns: {
        feature: "Feature",
        moon: "Moon Lottie",
      },
      legend: {
        supported: "Supported",
        unsupported: "Unsupported",
        unknown: "Unknown",
      }
    },
    architecture: {
      eyebrow: "Inside MoonLottie",
      title: "Technical Architecture",
      subtitle: (
        <>
          A platform-agnostic core written in <MoonBitLink />, compiling to highly efficient WebAssembly.
        </>
      ),
      system: "Core System Architecture",
      pipeline: "Rendering Pipeline",
      description: (
        <>
          Built with <MoonBitLink />{" "}
          for performance and safety. Our architecture minimizes JS bridging overhead via direct Wasm memory manipulation.
        </>
      ),
      archCaption: (
        <>
          Overview of the <MoonBitLink /> Wasm core and its interaction with the JS host environment.
        </>
      ),
      pipeCaption: "Step-by-step data flow from Lottie JSON to final Canvas frame via the Wasm engine.",
    },
    roadmap: {
      eyebrow: "Milestones",
      title: "Project Roadmap",
      subtitle: "Tracking MoonLottie's evolution and future directions.",
    },
    footer: {
      tagline: (
        <>
          The high-performance Lottie engine powered by <MoonBitLink />. Built for speed and portability.
        </>
      ),
    }
  }
}
