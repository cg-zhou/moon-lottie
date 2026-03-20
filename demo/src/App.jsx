import React, { useState, useEffect, startTransition } from "react"
import "iconify-icon"
import { translations } from "./i18n.jsx"
import { supportSections, platformColumns, statusSymbols } from "./supportMatrix"
import { architectureDiagram, renderPipelineDiagram } from "./techDesign"
import { roadmapPhases, aboutCards } from "./constants"
import MermaidDiagram from "./MermaidDiagram"
import MoonLottiePlayer from "./components/MoonLottiePlayer.jsx"

function ReactPlayerPreviewCard() {
  const [sample, setSample] = useState("samples/1_1_Super_Mario.json")
  const [speed, setSpeed] = useState(1)
  const [direction, setDirection] = useState(1)
  const [loop, setLoop] = useState(true)
  const [background, setBackground] = useState("grid")
  const [status, setStatus] = useState("加载中")
  const [runtime, setRuntime] = useState("-")
  const [frame, setFrame] = useState("-")
  const [duration, setDuration] = useState("-")

  return (
    <article className="react-player-card info-card">
      <div className="react-player-card__header">
        <div>
          <p className="eyebrow">React Wrapper</p>
          <h3>React Thin Wrapper Preview</h3>
          <p className="diagram-card__meta">这个预览直接通过 React 组件消费 public/player 中的 browser player API。</p>
        </div>
      </div>
      <div className="react-player-card__layout">
        <div className="react-player-stage">
          <MoonLottiePlayer
            src={sample}
            autoplay={true}
            loop={loop}
            speed={speed}
            direction={direction}
            background={background}
            onLoad={(event) => {
              setStatus("已加载")
              const meta = event?.state?.currentAnimationMeta
              if (meta?.fps > 0) {
                setDuration(`${(meta.totalFrames / meta.fps).toFixed(2)}s`)
              } else {
                setDuration("-")
              }
            }}
            onRuntimeChange={(event) => {
              setRuntime(event.backend || "-")
            }}
            onEnterFrame={(event) => {
              const nextFrame = event.currentFrame
              setFrame(Number.isFinite(nextFrame) ? nextFrame.toFixed(1) : "-")
            }}
            onPlay={() => setStatus("播放中")}
            onPause={() => setStatus("已暂停")}
            onError={() => setStatus("加载失败")}
          />
        </div>
        <div className="react-player-controls">
          <label>
            <span>Sample</span>
            <select value={sample} onChange={(event) => setSample(event.target.value)}>
              <option value="samples/1_1_Super_Mario.json">1_1_Super_Mario.json</option>
              <option value="samples/2_3_banner.json">2_3_banner.json</option>
              <option value="samples/4_Boat_Loader.json">4_Boat_Loader.json</option>
              <option value="samples/4_fireworks.json">4_fireworks.json</option>
            </select>
          </label>
          <label>
            <span>Speed</span>
            <input type="number" min="0.1" max="4" step="0.1" value={speed} onChange={(event) => setSpeed(Number(event.target.value) || 1)} />
          </label>
          <label>
            <span>Direction</span>
            <select value={direction} onChange={(event) => setDirection(Number(event.target.value) || 1)}>
              <option value={1}>Forward</option>
              <option value={-1}>Reverse</option>
            </select>
          </label>
          <label>
            <span>Loop</span>
            <select value={String(loop)} onChange={(event) => setLoop(event.target.value === "true")}>
              <option value="true">On</option>
              <option value="false">Off</option>
            </select>
          </label>
          <label>
            <span>Background</span>
            <select value={background} onChange={(event) => setBackground(event.target.value)}>
              <option value="grid">Grid</option>
              <option value="white">White</option>
              <option value="black">Black</option>
              <option value="transparent">Transparent</option>
            </select>
          </label>
          <div className="react-player-stats">
            <div><strong>Status:</strong> {status}</div>
            <div><strong>Runtime:</strong> {runtime}</div>
            <div><strong>Frame:</strong> {frame}</div>
            <div><strong>Duration:</strong> {duration}</div>
          </div>
        </div>
      </div>
    </article>
  )
}

function normalizeStatusCell(value) {
  if (typeof value === "string") return { status: value, detail: "" }
  return value
}

function SupportCell({ value, t, highlight = false }) {
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
      <span className="status-emoji" aria-label={t.features.legend[cell.status] || t.features.legend.unknown}>
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

// 1. Overview Page (Vision + Quick Start)
function OverviewPage({ t, lang, onNavigate }) {
  const currentAboutCards = aboutCards[lang] || aboutCards.en
  return (
    <div className="page-stack">
      <section className="hero hero--single">
        <div className="hero__copy">
          <p className="eyebrow">{t.overview.visionEyebrow}</p>
          <h1>{t.overview.title}</h1>
          <p className="hero__lead">{t.overview.subtitle}</p>
          <div className="hero__actions">
            <button className="button button--primary" onClick={() => onNavigate("playground")}>
              {t.overview.heroCta}
            </button>
          </div>
        </div>
      </section>

      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">{t.overview.coreValues}</p>
          <h2>Core Values</h2>
        </div>
        <div className="card-grid card-grid--double">
          {currentAboutCards.map((item) => (
            <article key={item.title} className="info-card">
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">Usage</p>
          <h2>{t.overview.quickStart}</h2>
        </div>
        <div className="usage-guide">
          <article className="info-card">
            <h3>{t.overview.step1}</h3>
            <pre className="code-snippet"><code>moon add moon-lottie</code></pre>
          </article>
          <article className="info-card">
            <h3>{t.overview.step2}</h3>
            <pre className="code-snippet">
{`import * as lottie from "moon-lottie/lib/runtime"

fn init {
  let ani = lottie.load_from_string(...)
  ani.render(ctx, time)
}`}
            </pre>
          </article>
          <article className="info-card">
            <h3>{t.overview.step3}</h3>
            <pre className="code-snippet">
{`<moon-lottie src="ani.json" autoplay></moon-lottie>`}
            </pre>
          </article>
        </div>
      </section>
    </div>
  )
}

// 2. Playground Page
function PlaygroundPage({ t }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">{t.playground.eyebrow}</p>
          <h2>{t.playground.title}</h2>
          <p className="section-subtitle">{t.playground.subtitle}</p>
          <p className="section-subtitle">
            <a className="inline-link" href="./moon-lottie-element-preview.html" target="_blank" rel="noreferrer">
              Web Component Preview
            </a>
            {" · "}
            <a className="inline-link" href="./browser-player-preview.html" target="_blank" rel="noreferrer">
              Browser Player Preview
            </a>
          </p>
        </div>
        <div className="playground-frame">
          <iframe title="Moon Lottie Playground" src="./playground.html" loading="lazy" />
        </div>
        <ReactPlayerPreviewCard />
      </section>
    </div>
  )
}

// 3. Supported Features Page
function FeaturesPage({ t }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">{t.features.eyebrow}</p>
          <h2>{t.features.title}</h2>
          <p className="section-subtitle">{t.features.subtitle}</p>
          <p className="support-note">
            {t.features.audit}{" "}
            <a className="inline-link" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
              {t.features.source}
            </a>
          </p>
        </div>

        <div className="matrix-sections">
          {supportSections.map((section) => (
            <article key={section.id} className="matrix-card">
              <div className="matrix-card__header">
                <h3>{section.title[t.lang] || section.title.en}</h3>
              </div>
              <div className="table-wrap">
                <table className="support-table">
                  <thead>
                    <tr>
                      <th className="support-table__feature">{t.features.columns.feature}</th>
                      {platformColumns.map((column) => (
                        <th
                          key={column.key}
                          className={column.key === "moon" ? "support-table__platform matrix-th--moon" : "support-table__platform"}
                        >
                          {column.key === "moon" ? t.features.columns.moon : column.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {section.rows.map((row) => (
                      <tr key={row.feature}>
                        <td className="support-table__feature">{row.feature}</td>
                        {platformColumns.map((column) => (
                          <SupportCell key={column.key} value={row[column.key]} t={t} highlight={column.highlight} />
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

// 4. Architecture Page
function ArchitecturePage({ t }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">{t.architecture.eyebrow}</p>
          <h2>{t.architecture.title}</h2>
          <p className="section-subtitle">{t.architecture.subtitle}</p>
        </div>
        <article className="design-intro"><p>{t.architecture.description}</p></article>
        <div className="diagram-stack">
          <div className="diagram-item">
            <h3>{t.architecture.system}</h3>
            <MermaidDiagram chart={architectureDiagram} />
            <p className="diagram-caption">{t.architecture.archCaption}</p>
          </div>
          <div className="diagram-item">
            <h3>{t.architecture.pipeline}</h3>
            <MermaidDiagram chart={renderPipelineDiagram} />
            <p className="diagram-caption">{t.architecture.pipeCaption}</p>
          </div>
        </div>
      </section>
    </div>
  )
}

// 5. Roadmap Page
function RoadmapPage({ t, lang }) {
  const currentRoadmapPhases = roadmapPhases[lang] || roadmapPhases.en
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">{t.roadmap.eyebrow}</p>
          <h2>{t.roadmap.title}</h2>
          <p className="section-subtitle">{t.roadmap.subtitle}</p>
        </div>
        <div className="roadmap-grid roadmap-grid--triple">
          {currentRoadmapPhases.map((phase) => (
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
    <a href={url} target="_blank" rel="noreferrer" className="github-corner" aria-label="View on GitHub">
      <svg width="80" height="80" viewBox="0 0 250 250" style={{ fill: "#151513", color: "#fff", position: "absolute", top: 0, border: 0, right: 0, zIndex: 100 }} aria-hidden="true">
        <path d="M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z" />
        <path d="M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2" fill="currentColor" style={{ transformOrigin: "130px 106px" }} className="octo-arm" />
        <path d="M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.3 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.9 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z" fill="currentColor" className="octo-body" />
      </svg>
    </a>
  )
}

export default function App() {
  const [lang, setLang] = useState(() => localStorage.getItem("moon-lottie-lang") || "zh")
  const handleSetLang = (l) => { setLang(l); localStorage.setItem("moon-lottie-lang", l); }
  const t = { ...translations[lang], lang }
  const navItems = [
    { id: "overview", label: t.nav.overview },
    { id: "playground", label: t.nav.playground },
    { id: "features", label: t.nav.features },
    { id: "architecture", label: t.nav.architecture },
    { id: "roadmap", label: t.nav.roadmap },
  ]
  const pageIds = new Set(navItems.map(i => i.id))
  const [currentPage, setCurrentPage] = useState(() => getPageFromHash(window.location.hash, pageIds))

  useEffect(() => {
    const sync = () => { startTransition(() => setCurrentPage(getPageFromHash(window.location.hash, pageIds))); }
    window.addEventListener("hashchange", sync); sync();
    return () => window.removeEventListener("hashchange", sync);
  }, [pageIds])

  const navigateTo = (id) => { window.location.hash = id; }

  let content = <OverviewPage t={t} lang={lang} onNavigate={navigateTo} />
  if (currentPage === "playground") content = <PlaygroundPage t={t} />
  else if (currentPage === "features") content = <FeaturesPage t={t} />
  else if (currentPage === "architecture") content = <ArchitecturePage t={t} />
  else if (currentPage === "roadmap") content = <RoadmapPage t={t} lang={lang} />

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar__inner">
          <button type="button" className="brand brand--button" onClick={() => navigateTo("overview")}>
            <span className="brand__dot" /><span style={{fontWeight:800, letterSpacing:"-0.02em"}}>MoonLottie</span>
          </button>
          <nav className="topnav">
            {navItems.map(i => (
              <button key={i.id} type="button" className={"topnav__link "+(currentPage===i.id?"topnav__link--active":"")} onClick={() => navigateTo(i.id)}>{i.label}</button>
            ))}
          </nav>
          <div className="topbar__actions">
            <button className="lang-switch-icon" onClick={() => handleSetLang(lang==="en"?"zh":"en")} title={lang==="en"?"ZH":"EN"}>
              <iconify-icon icon="ion:language-outline" width="22" height="22" />
            </button>
          </div>
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
            <span className="footer-powered-text">Powered by</span>
            <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" className="moonbit-link">
              MoonBit
            </a>
          </div>
        </div>
      </footer>
    </div>
  )
}
