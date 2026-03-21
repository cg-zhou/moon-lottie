import React, { startTransition, useEffect, useState } from "react"
import { supportSections, platformColumns, statusSymbols } from "./supportMatrix"
import { architectureDiagram, renderPipelineDiagram } from "./techDesign"
import MermaidDiagram from "./MermaidDiagram"
import Playground from "./components/Playground.jsx"

const NAV_ITEMS = [
  { id: "overview", label: "概览" },
  { id: "playground", label: "演示" },
  { id: "features", label: "特性支持" },
  { id: "architecture", label: "底层架构" },
  { id: "roadmap", label: "项目路线" },
]

const PAGE_IDS = new Set(NAV_ITEMS.map((item) => item.id))

const ABOUT_CARDS = [
  {
    title: "极速性能",
    description: "利用 MoonBit 的编译优化，提供接近原生的渲染速度。",
  },
  {
    title: "轻量化",
    description: "极小的 Wasm 二进制体积，适合在各种 Web 场景快速分发。",
  },
  {
    title: "跨平台",
    description: "通过 Wasm 指令集实现一次编写，各端表现完全一致。",
  },
  {
    title: "类型安全",
    description: "借助 MoonBit 的强类型检查，从源头减少运行时错误。",
  },
]

const ROADMAP_PHASES = [
  {
    title: "阶段 1：核心引擎与 MVP",
    items: [
      "完成 MoonBit 核心渲染管线",
      "支持导出 Wasm-GC 目标",
      "实现基础 Shapes（矩形、圆形、路径）",
      "集成第一版特性审计矩阵",
    ],
  },
  {
    title: "阶段 2：表达式与进阶特性",
    items: [
      "基于 JS 宿主的表达式引擎",
      "支持更多蒙版与混合模式",
      "优化 Wasm 内存共享效率",
      "Playground 像素级对比工具",
    ],
  },
  {
    title: "阶段 3：多后端与生态",
    items: [
      "WebGL / WebGPU 渲染后端支持",
      "支持动画导出为不同平台 Native 库",
      "更完善的文档与集成指南",
    ],
  },
]

const STATUS_LABELS = {
  supported: "支持",
  unsupported: "不支持",
  unknown: "未知",
}

function MoonBitLink() {
  return (
    <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" style={{ color: "var(--primary)", textDecoration: "underline" }}>
      MoonBit
    </a>
  )
}

function normalizeStatusCell(value) {
  if (typeof value === "string") return { status: value, detail: "" }
  return value
}

function SupportCell({ value, highlight = false }) {
  const cell = normalizeStatusCell(value)
  const symbol = cell.symbol || statusSymbols[cell.status] || statusSymbols.unknown
  const cellClassName = [
    "platform-cell",
    highlight ? "platform-cell--moon" : "",
    highlight && cell.status === "supported" ? "platform-cell--moon-supported" : "",
    highlight && cell.status === "unsupported" ? "platform-cell--moon-unsupported" : "",
  ].filter(Boolean).join(" ")

  return (
    <td className={cellClassName}>
      <span className="status-emoji" aria-label={STATUS_LABELS[cell.status] || STATUS_LABELS.unknown}>
        {symbol}
      </span>
      {cell.detail ? <span className="platform-cell__detail">{cell.detail}</span> : null}
    </td>
  )
}

function getPageFromHash(hash, pageIds) {
  const pageId = hash.replace("#", "")
  return pageIds.has(pageId) ? pageId : "overview"
}

function OverviewPage({ onNavigate }) {
  return (
    <div className="page-stack">
      <section className="hero hero--single">
        <div className="hero__copy">
          <p className="eyebrow">使命与愿景</p>
          <h1>极速、现代的 Lottie 动画渲染引擎</h1>
          <p className="hero__lead">
            MoonLottie 是对性能和跨平台一致性的重新思考。基于 <MoonBitLink /> 强大的类型系统与编译优化，为 Web 提供极致的渲染体验。
          </p>
          <div className="hero__actions">
            <button className="button button--primary" onClick={() => onNavigate("playground")}>
              在线演示
            </button>
          </div>
        </div>
      </section>

      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">核心价值</p>
          <h2>为什么选择 MoonLottie</h2>
        </div>
        <div className="card-grid card-grid--double">
          {ABOUT_CARDS.map((item) => (
            <article key={item.title} className="info-card">
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">快速开始</p>
          <h2>接入方式</h2>
        </div>
        <div className="usage-guide">
          <article className="info-card">
            <h3>1. 添加依赖</h3>
            <pre className="code-snippet"><code>moon add moon-lottie</code></pre>
          </article>
          <article className="info-card">
            <h3>2. 集成</h3>
            <pre className="code-snippet">
{`import * as lottie from "moon-lottie/lib/runtime"

fn init {
  let ani = lottie.load_from_string(...)
  ani.render(ctx, time)
}`}
            </pre>
          </article>
          <article className="info-card">
            <h3>3. 浏览器运行</h3>
            <pre className="code-snippet">
{`<moon-lottie src="ani.json" autoplay></moon-lottie>`}
            </pre>
          </article>
        </div>
      </section>
    </div>
  )
}

function PlaygroundPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">在线演示</p>
          <h2>在线演示</h2>
          <p className="section-subtitle">直观感受 MoonLottie 引擎的渲染性能，并支持与官方 `lottie-web` 进行对比。</p>
        </div>
        <article className="info-card">
          <h3>演示区说明</h3>
          <p>
            这里嵌入的是主站正式 Playground。动画列表、工具栏、控制栏和信息面板都属于主站 UI，
            不属于 Web Component、浏览器播放器或 React 封装的通用交付面。
          </p>
        </article>
        <Playground />
      </section>
    </div>
  )
}

function FeaturesPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">兼容性</p>
          <h2>特性支持矩阵</h2>
          <p className="section-subtitle">本表遵循 Airbnb 官方 Supported Features 标准，对比 7 个主流平台与 MoonLottie 实现的特性支持情况。</p>
          <p className="support-note">
            数据同步自 Airbnb 官方 Lottie 规范 v24+。{" "}
            <a className="inline-link" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
              查看官方原表
            </a>
          </p>
        </div>

        <div className="matrix-sections">
          {supportSections.map((section) => (
            <article key={section.id} className="matrix-card">
              <div className="matrix-card__header">
                <h3>{section.title}</h3>
              </div>
              <div className="table-wrap">
                <table className="support-table">
                  <thead>
                    <tr>
                      <th className="support-table__feature">特性项</th>
                      {platformColumns.map((column) => (
                        <th
                          key={column.key}
                          className={column.key === "moon" ? "support-table__platform matrix-th--moon" : "support-table__platform"}
                        >
                          {column.key === "moon" ? "MoonLottie" : column.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {section.rows.map((row) => (
                      <tr key={row.feature}>
                        <td className="support-table__feature">{row.feature}</td>
                        {platformColumns.map((column) => (
                          <SupportCell key={column.key} value={row[column.key]} highlight={column.highlight} />
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </article>
          ))}
        </div>
      </section>
    </div>
  )
}

function ArchitecturePage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">底层架构</p>
          <h2>底层技术设计</h2>
          <p className="section-subtitle">解析、求值与渲染逻辑完全解耦，编译为紧凑的 Wasm 指令流。</p>
        </div>
        <article className="design-intro">
          <p>
            MoonLottie 采用 <MoonBitLink /> 开发，利用其零开销抽象和卓越的运行时性能。架构上我们通过 Wasm 内存共享技术最小化了 JS 与核心引擎间的交互开销。
          </p>
        </article>
        <div className="diagram-stack">
          <div className="diagram-item">
            <h3>核心系统架构</h3>
            <MermaidDiagram chart={architectureDiagram} />
            <p className="diagram-caption"><MoonBitLink /> Wasm 内核与 JS 宿主环境的交互概览。</p>
          </div>
          <div className="diagram-item">
            <h3>渲染流水线</h3>
            <MermaidDiagram chart={renderPipelineDiagram} />
            <p className="diagram-caption">从 Lottie JSON 到引擎渲染，最终输出到 Canvas 帧的完整数据流。</p>
          </div>
        </div>
      </section>
    </div>
  )
}

function RoadmapPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">里程碑</p>
          <h2>里程碑与路线图</h2>
          <p className="section-subtitle">记录 MoonLottie 的成长轨迹与未来规划。</p>
        </div>
        <div className="roadmap-grid roadmap-grid--triple">
          {ROADMAP_PHASES.map((phase) => (
            <article key={phase.title} className="roadmap-card">
              <h3>{phase.title}</h3>
              <ul className="bullet-list">
                {phase.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </section>
    </div>
  )
}

function GitHubRibbon({ url }) {
  return (
    <a href={url} target="_blank" rel="noreferrer" className="github-corner" aria-label="在 GitHub 上查看">
      <svg width="80" height="80" viewBox="0 0 250 250" style={{ fill: "#151513", color: "#fff", position: "absolute", top: 0, border: 0, right: 0, zIndex: 100 }} aria-hidden="true">
        <path d="M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z" />
        <path d="M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2" fill="currentColor" style={{ transformOrigin: "130px 106px" }} className="octo-arm" />
        <path d="M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.3 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.9 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z" fill="currentColor" className="octo-body" />
      </svg>
    </a>
  )
}

export default function App() {
  const [currentPage, setCurrentPage] = useState(() => getPageFromHash(window.location.hash, PAGE_IDS))

  useEffect(() => {
    const sync = () => { startTransition(() => setCurrentPage(getPageFromHash(window.location.hash, PAGE_IDS))) }
    window.addEventListener("hashchange", sync)
    sync()
    return () => window.removeEventListener("hashchange", sync)
  }, [])

  const navigateTo = (id) => { window.location.hash = id }

  let content = <OverviewPage onNavigate={navigateTo} />
  if (currentPage === "playground") content = <PlaygroundPage />
  else if (currentPage === "features") content = <FeaturesPage />
  else if (currentPage === "architecture") content = <ArchitecturePage />
  else if (currentPage === "roadmap") content = <RoadmapPage />

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar__inner">
          <button type="button" className="brand brand--button" onClick={() => navigateTo("overview")}>
            <span className="brand__dot" /><span style={{fontWeight:800, letterSpacing:"-0.02em"}}>MoonLottie</span>
          </button>
          <nav className="topnav">
            {NAV_ITEMS.map(i => (
              <button key={i.id} type="button" className={"topnav__link "+(currentPage===i.id?"topnav__link--active":"")} onClick={() => navigateTo(i.id)}>{i.label}</button>
            ))}
          </nav>
        </div>
      </header>
      <GitHubRibbon url="https://github.com/cg-zhou/moon-lottie" />
      <main tabIndex="-1"><div className="view-shell">{content}</div></main>
      <footer className="site-footer">
        <div className="container footer-content">
          <div className="footer-credits">
            <span>
              {new Date().getFullYear()} ©{" "}
              <a href="https://cg-zhou.top/" target="_blank" rel="noreferrer" className="inline-link">
                cg-zhou
              </a>
            </span>
            <span className="footer-divider">|</span>
            <span className="footer-powered-text">技术驱动：</span>
            <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" className="moonbit-link">
              MoonBit
            </a>
          </div>
        </div>
      </footer>
    </div>
  )
}
