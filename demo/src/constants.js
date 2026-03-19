// Roadmap milestones
export const roadmapPhases = {
  zh: [
    {
      title: 'Phase 1: 核心引擎与 MVP',
      items: [
        '完成 MoonBit 核心渲染管线',
        '支持导出 Wasm-GC 目标',
        '实现基础 Shapes (矩形, 圆形, 路径)',
        '集成第一版特性审计矩阵',
      ],
    },
    {
      title: 'Phase 2: 表达式与进阶特性',
      items: [
        '基于 JS 宿主的表达式引擎',
        '支持更多蒙版与混合模式',
        '优化 Wasm 内存共享效率',
        'Playground 像素级对比工具',
      ],
    },
    {
      title: 'Phase 3: 多后端与生态',
      items: [
        'WebGL/WebGPU 渲染后端支持',
        '支持动画导出为不同平台 Native 库',
        '更完善的文档与集成指南',
      ],
    },
  ],
  en: [
    {
      title: 'Phase 1: Core Engine & MVP',
      items: [
        'MoonBit core rendering pipeline',
        'Wasm-GC target support',
        'Basic Shapes (Rect, Circle, Path)',
        'First-pass feature audit matrix',
      ],
    },
    {
      title: 'Phase 2: Expressions & Advanced',
      items: [
        'JS-host based Expression engine',
        'Rich Masks and Blend Modes support',
        'Optimization of Wasm memory sharing',
        'Pixel-diff tool in Playground',
      ],
    },
    {
      title: 'Phase 3: Multi-backend & Eco',
      items: [
        'WebGL/WebGPU rendering backends',
        'Exporting animations as Native libraries',
        'Comprehensive docs and guides',
      ],
    },
  ],
}

// Vision/About Cards
export const aboutCards = {
  zh: [
    {
      title: '极速性能',
      description: '利用 MoonBit 的编译优化，提供接近原生的渲染速度。',
    },
    {
      title: '轻量化',
      description: '极小的 Wasm 二进制体积，适合在各种 Web 场景快速分发。',
    },
    {
      title: '跨平台',
      description: '通过 Wasm 指令集实现一次编写，各端表现完全一致。',
    },
    {
      title: '类型安全',
      description: '借助 MoonBit 的强类型检查，从源头减少运行时错误。',
    },
  ],
  en: [
    {
      title: 'Turbo Performance',
      description: 'Leveraging MoonBit optimizations for near-native rendering speeds.',
    },
    {
      title: 'Ultra Lightweight',
      description: 'Tiny Wasm footprint, ideal for fast delivery in Web environments.',
    },
    {
      title: 'Cross Platform',
      description: 'Consistent behavior across all platforms via standard Wasm instructions.',
    },
    {
      title: 'Type Safe',
      description: 'MoonBit s strong type system catches errors before they reach production.',
    },
  ],
}
