import { startTransition, useEffect, useState } from "react"
import MermaidDiagram from "./MermaidDiagram"
import { platformColumns, supportSections } from "./supportMatrix"
import {
  architectureDiagram,
  renderPipelineDiagram,
} from "./techDesign"
import { translations, aboutCards, roadmapPhases } from "./i18n"
import 'iconify-icon'

function GitHubRibbon({ url }) {
  return (
    <a
      href={url}
      target="_blank"
      rel="noreferrer"
      className="github-corner"
      aria-label="View source on GitHub"
    >
      <svg
        width="80"
        height="80"
        viewBox="0 0 250 250"
        style={{
          fill: "#151513",
          color: "#fff",
          position: "absolute",
          top: 0,
          border: 0,
          right: 0,
          zIndex: 100,
        }}
        aria-hidden="true"
      >
        <path d="M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z" />
        <path
          d="M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2"
          fill="currentColor"
          style={{ transformOrigin: "130px 106px" }}
          className="octo-arm"
        />
        <path
          d="M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.3 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.9 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z"
          fill="currentColor"
          className="octo-body"
        />
      </svg>
    </a>
  )
}

function normalizeStatusCell(value) {
  if (typeof value === "string") {
    return { status: value, detail: "" }
  }
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
      <span className="status-emoji" aria-label={t.support.legend[cell.status] || t.support.legend.unknown}>
        {symbol}
      </span>
      {cell.detail ? <span className="platform-cell__detail">{cell.detail}</span> : null}
    </td>
  )
}

function getPageFromHash(hash, pageIds) {
  const page = hash.replace(/^#\//, "").replace(/^#/, "")
  return pageIds.has(page) ? page : "about"
}

const statusSymbols = {
  supported: "👍",
  unsupported: "⛔️",
  unknown: "❔",
}

function PlaygroundPage({ t }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head">
          <div>
            <p className="eyebrow">Playground</p>
            <h2>{t.playground.title}</h2>
          </div>
          <a className="inline-link" href="./playground.html" target="_blank" rel="noreferrer">
            {translations.en.common.openNewWindow}
          </a>
        </div>
        <div className="playground-description">
          <p>{t.playground.description}</p>
        </div>
        <div className="playground-frame">
          <iframe title="Moon Lottie Playground" src="./playground.html" loading="lazy" />
        </div>
      </section>
    </div>
  )
}

function SupportPage({ t }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">{t.support.eyebrow}</p>
          <h2>{t.support.title}</h2>
          <p className="section-subtitle">{t.support.subtitle}</p>
          <p className="support-note">
            {t.support.audit}{" "}
            <a className="inline-link" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
              {t.support.source}
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
                      <th className="support-table__feature">{t.support.columns.feature}</th>
                      {platformColumns.map((column) => (
                        <th
                          key={column.key}
                          className={
                            column.key === "moon"
                              ? "support-table__platform matrix-th--moon"
                              : "support-table__platform"
                          }
                        >
                          {column.key === "moon" ? t.support.columns.moon : column.label}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {section.rows.map((row) => (
                      <tr key={row.feature}>
                        <td className="support-table__feature">{row.feature}</td>
                        {platformColumns.map((column) => (
                          <SupportCell
                            key={column.key}
                            value={row[column.key]}
                            t={t}
                            highlight={column.highlight}
                          />
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

function DesignPage({ t, lang }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">{t.design.eyebrow}</p>
          <h2>{t.design.title}</h2>
          <p className="section-subtitle">{t.design.subtitle}</p>
        </div>
        
        <article className="design-intro">
          <p>{t.design.description}</p>
          <p className="status-note">{t.design.ongoing}</p>
        </article>

        <div className="diagram-stack">
          <div className="diagram-item">
            <h3>{t.design.architecture}</h3>
            <MermaidDiagram chart={architectureDiagram} />
            <p className="diagram-caption">{t.design.archDesc}</p>
          </div>
          
          <div className="diagram-item">
            <h3>{t.design.pipeline}</h3>
            <MermaidDiagram chart={renderPipelineDiagram} />
            <p className="diagram-caption">{t.design.pipeDesc}</p>
          </div>
        </div>
      </section>
    </div>
  )
}

function UsagePage({ t, lang }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-head section-head--stacked">
          <p className="eyebrow">Quick Start</p>
          <h2>{t.usage.title}</h2>
          <p className="section-subtitle">{t.usage.subtitle}</p>
        </div>
        
        <div className="usage-guide">
          <article className="info-card">
            <h3>{t.usage.step1}</h3>
            <pre className="code-snippet">
              <code>moon add moon-lottie</code>
            </pre>
          </article>

          <article className="info-card">
            <h3>{t.usage.step2}</h3>
            <pre className="code-snippet">
{`import * as lottie from "moon-lottie/lib/runtime"

fn init {
  // Load and render animation
  let animation = lottie.load_from_string(...)
  animation.render(canvas_context, time)
}`}
            </pre>
          </article>

          <article className="info-card">
            <h3>{t.usage.step3}</h3>
            <p>{t.usage.webDesc}</p>
            <pre className="code-snippet">
{`<moon-lottie 
  src="animation.json" 
  autoplay 
  loop>
</moon-lottie>`}
            </pre>
          </article>
        </div>
      </section>
    </div>
  )
}

function AboutPage({ t, lang }) {
  const currentAboutCards = aboutCards[lang] || aboutCards.en
  const currentRoadmapPhases = roadmapPhases[lang] || roadmapPhases.en

  return (
    <div className="page-stack">
      <section className="hero hero--single">
        <div className="hero__copy">
          <p className="eyebrow">{t.vision.eyebrow}</p>
          <h1>{t.vision.title}</h1>
          <p className="hero__lead">{t.vision.lead}</p>
          <div className="hero__actions">
            <a className="button button--primary" href="#playground">
              {t.nav.playground}
            </a>
            <a className="button button--secondary" href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer">
              {t.common.moonbit}
            </a>
          </div>
        </div>
      </section>

      <section className="section-block">
        <div className="section-head">
          <p className="eyebrow">Core Values</p>
          <h2>{t.vision.coreValues}</h2>
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
          <p className="eyebrow">Roadmap</p>
          <h2>{t.vision.roadmap}</h2>
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

export default function App() {
  const [lang, setLang] = useState(() => {
    return localStorage.getItem("moon-lottie-lang") || "zh"
  })
  
  const handleSetLang = (newLang) => {
    setLang(newLang)
    localStorage.setItem("moon-lottie-lang", newLang)
  }

  const t = { ...translations[lang], lang }

  const navItems = [
    { id: "playground", label: t.nav.playground },
    { id: "support", label: t.nav.support },
    { id: "design", label: t.nav.design },
    { id: "usage", label: t.nav.usage },
    { id: "about", label: t.nav.about },
  ]
  const pageIds = new Set(navItems.map((item) => item.id))

  const [currentPage, setCurrentPage] = useState(() => getPageFromHash(window.location.hash, pageIds))

  useEffect(() => {
    const syncPage = () => {
      startTransition(() => {
        setCurrentPage(getPageFromHash(window.location.hash, pageIds))
      })
    }

    window.addEventListener("hashchange", syncPage)
    syncPage()
    return () => window.removeEventListener("hashchange", syncPage)
  }, [pageIds])

  const navigateTo = (pageId) => {
    if (window.location.hash === "#" + pageId) {
      startTransition(() => setCurrentPage(pageId))
      return
    }
    window.location.hash = pageId
  }

  let pageContent = <AboutPage t={t} lang={lang} />
  if (currentPage === "support") {
    pageContent = <SupportPage t={t} />
  } else if (currentPage === "design") {
    pageContent = <DesignPage t={t} lang={lang} />
  } else if (currentPage === "usage") {
    pageContent = <UsagePage t={t} lang={lang} />
  } else if (currentPage === "playground") {
    pageContent = <PlaygroundPage t={t} />
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="topbar__inner">
          <button type="button" className="brand brand--button" onClick={() => navigateTo("about")}>
            <span className="brand__dot" />
            <span>MoonLottie</span>
          </button>
          <nav className="topnav" aria-label="Main Navigation">
            {navItems.map((item) => (
              <button
                key={item.id}
                type="button"
                className={"topnav__link " + (currentPage === item.id ? "topnav__link--active" : "")}
                onClick={() => navigateTo(item.id)}
              >
                {item.label}
              </button>
            ))}
          </nav>
          <div className="topbar__actions">
            <button 
              className="lang-switch-icon" 
              onClick={() => handleSetLang(lang === "en" ? "zh" : "en")}
              title={lang === "en" ? "切换至中文" : "Switch to English"}
              style={{
                background: 'transparent',
                border: 'none',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '8px',
                cursor: 'pointer',
                minWidth: '40px',
                minHeight: '40px'
              }}
            >
              <div style={{ width: '24px', height: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <iconify-icon 
                  icon="ion:language-outline" 
                  width="24"
                  height="24"
                  style={{ color: '#1d1d1f' }}
                />
              </div>
            </button>
          </div>
        </div>
      </header>
      <GitHubRibbon url="https://github.com/cg-zhou/moon-lottie" />

      <main tabIndex="-1">
        <div className="view-shell">{pageContent}</div>

        <footer className="site-footer">
          <div className="container">
            <div className="footer__grid">
              <div>
                <strong>MoonLottie</strong>
                <p>{t.footer.tagline}</p>
              </div>
              <div className="footer-links">
                <a href="https://github.com/cg-zhou/moon-lottie" target="_blank" rel="noreferrer">GitHub</a>
                <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer">{t.common.moonbit}</a>
                <a href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">{t.common.lottieSpec}</a>
                <a href="./playground.html" target="_blank" rel="noreferrer">{t.nav.playground}</a>
              </div>
            </div>
            <div className="footer__bottom">
              <p>© 2026 MoonLottie Team. Powered by MoonBit.</p>
            </div>
          </div>
        </footer>
      </main>
    </div>
  )
}
