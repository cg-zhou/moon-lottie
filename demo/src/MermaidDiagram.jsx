import { useEffect, useRef, useState } from 'react'

let nextDiagramId = 0
let mermaidReady = false
let mermaidModulePromise = null

async function loadMermaid() {
  if (!mermaidModulePromise) {
    mermaidModulePromise = import('mermaid').then((module) => module.default)
  }
  return mermaidModulePromise
}

function ensureMermaid(mermaid) {
  if (mermaidReady) {
    return
  }

  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'loose',
    theme: 'base',
    themeVariables: {
      primaryColor: '#eff6ff',
      primaryTextColor: '#1d1d1f',
      primaryBorderColor: '#93c5fd',
      lineColor: '#64748b',
      secondaryColor: '#f8fafc',
      tertiaryColor: '#ffffff',
      fontFamily: '-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif',
    },
    flowchart: {
      curve: 'basis',
      htmlLabels: true,
    },
    sequence: {
      useMaxWidth: true,
    },
  })
  mermaidReady = true
}

export default function MermaidDiagram({ title, chart }) {
  const [svg, setSvg] = useState('')
  const [error, setError] = useState('')
  const diagramId = useRef(`mermaid-diagram-${nextDiagramId++}`)

  useEffect(() => {
    let cancelled = false

    async function renderDiagram() {
      const mermaid = await loadMermaid()
      ensureMermaid(mermaid)
      try {
        const { svg: nextSvg } = await mermaid.render(diagramId.current, chart)
        if (!cancelled) {
          setSvg(nextSvg)
          setError('')
        }
      } catch (renderError) {
        if (!cancelled) {
          setSvg('')
          setError(renderError instanceof Error ? renderError.message : 'Mermaid 图渲染失败')
        }
      }
    }

    renderDiagram()

    return () => {
      cancelled = true
    }
  }, [chart])

  return (
    <article className="diagram-card">
      <div>
        {title ? <h3>{title}</h3> : null}
        <p className="diagram-card__meta">基于当前代码路径绘制，和现有实现保持一致。</p>
      </div>
      {error ? (
        <div className="diagram-surface diagram-surface--error">图表渲染失败：{error}</div>
      ) : (
        <div className="diagram-surface" dangerouslySetInnerHTML={{ __html: svg }} />
      )}
    </article>
  )
}