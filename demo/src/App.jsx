import React, { useEffect, useMemo, useState } from "react"
import { Button, Card, ConfigProvider, Layout, Menu, Modal, Table, Tag, Typography, message } from "antd"
import { Check, CircleCheck, CircleX, Copy, HelpCircle } from "lucide-react"
import { supportSections, platformColumns } from "./supportMatrix"
import Playground from "./components/Playground.jsx"
import FeatureExampleCard from "./components/FeatureExampleCard.jsx"
import { featureExampleMap } from "./featureExamples"

const NAV_ITEMS = [
  { id: "overview", label: "快速开始" },
  { id: "playground", label: "在线演示" },
  { id: "features", label: "特性支持" },
]

const PAGE_IDS = new Set(NAV_ITEMS.map((item) => item.id))
const DEFAULT_PAGE_ID = "overview"
const BASE_PATH = (import.meta.env.BASE_URL || "/").replace(/\/$/, "")

const STATUS_META = {
  supported: { label: "支持", color: "success", Icon: CircleCheck },
  unsupported: { label: "不支持", color: "error", Icon: CircleX },
  unknown: { label: "未知", color: "default", Icon: HelpCircle },
}

const ALL_FEATURES_WITH_EXAMPLES = supportSections.flatMap((section) => 
  section.rows
    .filter(row => !!(featureExampleMap[section.id]?.[row.feature]))
    .map((row) => ({
      ...row,
      sectionId: section.id,
      sectionTitle: section.title,
    }))
)

function THEME_CONFIG_STUB() {} // Placeholder to avoid match issues

const THEME_CONFIG = {
  token: {
    colorPrimary: "#000000",
    colorInfo: "#000000",
    colorSuccess: "#10b981",
    colorWarning: "#f59e0b",
    colorError: "#ef4444",
    colorBgLayout: "#ffffff",
    colorBgContainer: "#ffffff",
    colorText: "#000000",
    colorTextSecondary: "#666666",
    borderRadius: 4,
    borderRadiusLG: 6,
    boxShadowSecondary: "0 4px 12px rgba(0, 0, 0, 0.08)",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Inter', system-ui, sans-serif",
  },
  components: {
    Layout: {
      headerBg: "#ffffff",
      bodyBg: "#ffffff",
      footerBg: "transparent",
    },
    Menu: {
      itemBg: "transparent",
      itemSelectedBg: "transparent",
      itemSelectedColor: "#000000",
      itemHoverColor: "#000000",
      horizontalItemSelectedColor: "#000000",
      horizontalItemHoverColor: "#000000",
    },
    Card: {
      bodyPadding: 24,
      headerBg: "transparent",
      headerBorderColor: "#eaeaea",
    },
    Button: {
      borderRadius: 4,
      controlHeight: 38,
      paddingInline: 20,
      fontWeight: 500,
    }
  },
}

function CodeBlock({ code, language = 'javascript' }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      message.success('已复制到剪切板');
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      message.error('复制失败');
    }
  };

  return (
    <div className="code-block-wrapper">
      <pre className="code-block">
        <code>{code}</code>
      </pre>
      <button 
        className={`code-block-copy-btn ${copied ? 'copied' : ''}`} 
        onClick={handleCopy}
        title="复制代码"
      >
        {copied ? <Check size={14} /> : <Copy size={14} />}
      </button>
    </div>
  );
}

function GitHubMarkIcon({ size = 16 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
      focusable="false"
      className="github-mark-icon"
    >
      <path d="M12 .5C5.73.5.65 5.58.65 11.85c0 5.02 3.26 9.27 7.78 10.78.57.1.78-.25.78-.56 0-.28-.01-1.02-.01-2-3.17.69-3.84-1.53-3.84-1.53-.52-1.32-1.27-1.67-1.27-1.67-1.04-.71.08-.7.08-.7 1.15.08 1.75 1.18 1.75 1.18 1.02 1.76 2.68 1.25 3.33.96.1-.74.4-1.25.73-1.54-2.53-.29-5.2-1.27-5.2-5.64 0-1.25.45-2.27 1.18-3.07-.12-.29-.51-1.46.11-3.04 0 0 .96-.31 3.15 1.17a10.9 10.9 0 0 1 5.74 0c2.19-1.48 3.15-1.17 3.15-1.17.62 1.58.23 2.75.11 3.04.74.8 1.18 1.82 1.18 3.07 0 4.38-2.68 5.34-5.23 5.62.41.35.77 1.04.77 2.1 0 1.52-.01 2.75-.01 3.13 0 .31.2.67.79.55 4.51-1.5 7.77-5.76 7.77-10.78C23.35 5.58 18.27.5 12 .5Z" />
    </svg>
  )
}

function GuideSection({ id, title, description, sections, actions = [] }) {
  return (
    <article id={id} className="guide-section">
      <div className="guide-section__header">
        <Typography.Title level={3} className="guide-section__title">{title}</Typography.Title>
      </div>

      <Typography.Paragraph className="guide-section__description">{description}</Typography.Paragraph>

      <div className="guide-section__sections">
        {sections.map((section) => (
          <div className="guide-section__section" key={`${title}-${section.title}`}>
            <Typography.Text strong className="guide-section__section-title">
              {section.title}
            </Typography.Text>
            {section.text ? (
              <Typography.Paragraph className="guide-section__section-text">
                {section.text}
              </Typography.Paragraph>
            ) : null}
            {section.code ? <CodeBlock code={section.code} /> : null}
          </div>
        ))}
      </div>

      {actions.length > 0 ? (
        <div className="guide-section__actions">
          {actions.map((action) => (
            <Button
              key={`${title}-${action.label}`}
              className="guide-section__action"
              type={action.primary ? "primary" : "default"}
              href={action.href}
              target="_blank"
              rel="noreferrer"
            >
              {action.label}
            </Button>
          ))}
        </div>
      ) : null}
    </article>
  )
}

function MoonBitLink() {
  return (
    <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" className="inline-link inline-link--strong">
      MoonBit
    </a>
  )
}

function normalizeStatusCell(value) {
  if (typeof value === "string") return { status: value, detail: "" }
  return value
}

function getSectionCoverage(section) {
  const total = section.rows.length
  const supportedCount = section.rows.reduce((count, row) => {
    const cell = normalizeStatusCell(row.moon)
    return count + (cell.status === "supported" ? 1 : 0)
  }, 0)

  return { total, supportedCount }
}

function SupportCell({ value, highlight = false }) {
  const cell = normalizeStatusCell(value)
  const meta = STATUS_META[cell.status] || STATUS_META.unknown
  const StatusIcon = meta.Icon

  return (
    <div
      className={`support-status support-status--${cell.status}${highlight ? " support-status--highlight" : ""}`}
      title={cell.detail ? `${meta.label}：${cell.detail}` : meta.label}
      aria-label={cell.detail ? `${meta.label}：${cell.detail}` : meta.label}
    >
      <span className="support-status__icon">
        <StatusIcon size={16} strokeWidth={2.2} />
      </span>
    </div>
  )
}

function FeatureSupportSection({ section }) {
  const { total, supportedCount } = getSectionCoverage(section)
  const [globalFeatureIndex, setGlobalFeatureIndex] = useState(-1)
  const isModalVisible = globalFeatureIndex !== -1

  const columns = useMemo(() => [
    {
      title: "特性项",
      dataIndex: "feature",
      key: "feature",
      fixed: "left",
      width: 180,
      render: (value, record) => {
        const hasExample = !!featureExampleMap[section.id]?.[record.feature]
        return <Typography.Text strong className={hasExample ? "support-feature-link" : undefined}>{value}</Typography.Text>
      },
    },
    ...platformColumns.map((column) => ({
      title: column.highlight
        ? <span className="support-col-title support-col-title--moon">Moon Lottie</span>
        : column.label,
      dataIndex: column.key,
      key: column.key,
      align: "center",
      width: column.highlight ? 108 : 92,
      className: column.highlight ? "support-col support-col--moon" : "support-col",
      onCell: (record) => {
        if (!column.highlight) return {}
        const cell = normalizeStatusCell(record[column.key])
        return {
          className: `support-cell support-cell--moon support-cell--${cell.status}`,
        }
      },
      render: (value) => <SupportCell value={value} highlight={column.highlight} />,
    })),
  ], [section.id])

  const handlePrev = (e) => {
    e?.stopPropagation()
    if (globalFeatureIndex > 0) {
      setGlobalFeatureIndex(globalFeatureIndex - 1)
    }
  }

  const handleNext = (e) => {
    e?.stopPropagation()
    if (globalFeatureIndex < ALL_FEATURES_WITH_EXAMPLES.length - 1) {
      setGlobalFeatureIndex(globalFeatureIndex + 1)
    }
  }

  const currentRecord = globalFeatureIndex !== -1 ? ALL_FEATURES_WITH_EXAMPLES[globalFeatureIndex] : null
  const currentExample = currentRecord ? featureExampleMap[currentRecord.sectionId]?.[currentRecord.feature] : null
  const prevRecord = globalFeatureIndex > 0 ? ALL_FEATURES_WITH_EXAMPLES[globalFeatureIndex - 1] : null
  const nextRecord = globalFeatureIndex < ALL_FEATURES_WITH_EXAMPLES.length - 1 ? ALL_FEATURES_WITH_EXAMPLES[globalFeatureIndex + 1] : null

  return (
    <Card
      className="support-table-card"
      title={section.title}
    >
      <Table
        rowKey="feature"
        columns={columns}
        dataSource={section.rows}
        pagination={false}
        size="small"
        scroll={{ x: 980 }}
        onRow={(record) => {
          const globalIdx = ALL_FEATURES_WITH_EXAMPLES.findIndex(
            f => f.sectionId === section.id && f.feature === record.feature
          )
          const hasExample = globalIdx !== -1
          
          return {
            className: hasExample ? "support-table-row--clickable" : "",
            onClick: () => {
              if (hasExample) {
                setGlobalFeatureIndex(globalIdx)
              }
            },
          }
        }}
      />

      <Modal
        title={currentRecord?.sectionTitle}
        open={isModalVisible}
        onCancel={() => setGlobalFeatureIndex(-1)}
        footer={null}
        width={640}
        centered
        destroyOnHidden
        className="feature-detail-modal"
      >
        <div className="feature-modal-content">
          {currentExample && (
            <FeatureExampleCard
              key={`${currentRecord.sectionId}:${currentRecord.feature}`}
              feature={currentRecord.feature}
              example={currentExample}
            />
          )}
          
          <div className="feature-modal-navigation">
            <Button 
              type="text" 
              disabled={!prevRecord} 
              onClick={handlePrev}
              className="nav-btn nav-btn--prev"
            >
              <div className="nav-btn-content">
                <span className="nav-btn-label">{prevRecord ? "← 上一个特性" : "已是第一个"}</span>
                <span className="nav-btn-title">{prevRecord?.feature || " "}</span>
              </div>
            </Button>
            <Button 
              type="text" 
              disabled={!nextRecord} 
              onClick={handleNext}
              className="nav-btn nav-btn--next"
            >
              <div className="nav-btn-content">
                <span className="nav-btn-label">{nextRecord ? "下一个特性 →" : "已是最后一个"}</span>
                <span className="nav-btn-title">{nextRecord?.feature || " "}</span>
              </div>
            </Button>
          </div>
        </div>
      </Modal>
    </Card>
  )
}

function getPageFromPath(pathname, pageIds) {
  let relativePath = pathname || "/"

  if (BASE_PATH && relativePath.startsWith(BASE_PATH)) {
    relativePath = relativePath.slice(BASE_PATH.length) || "/"
  }

  if (!relativePath.startsWith("/")) {
    relativePath = `/${relativePath}`
  }

  const normalizedPath = relativePath === "/" ? DEFAULT_PAGE_ID : relativePath.replace(/^\//, "")
  return pageIds.has(normalizedPath) ? normalizedPath : DEFAULT_PAGE_ID
}

function getPathForPage(pageId) {
  const prefix = BASE_PATH || ""
  if (pageId === DEFAULT_PAGE_ID) {
    return `${prefix}/`
  }
  return `${prefix}/${pageId}`
}

function OverviewPage({ onNavigate }) {
  return (
    <div className="page-stack">
      <Typography.Title className="hero-card__title">极速、现代的 Lottie 动画渲染引擎</Typography.Title>
      <Typography.Paragraph className="hero-card__lead">
          Moon Lottie 是对性能和跨平台一致性的重新思考。基于 <MoonBitLink /> 强大的类型系统与编译优化，为 Web 提供极致的渲染体验。
      </Typography.Paragraph>
      <div className="hero-card__actions">
        <Button type="primary" size="large" onClick={() => onNavigate("playground")}>
          在线演示
        </Button>
        <Button size="large" onClick={() => onNavigate("features")}>
          查看支持矩阵
        </Button>
      </div>

      <section className="section-block">
        <div className="section-heading">
          <div>
            <Typography.Title level={2}>接入指南</Typography.Title>
            <Typography.Paragraph>
              Moon Lottie 提供多种接入方式：
              <a className="inline-link inline-link--strong" href="#guide-react">React 接入</a>
              、
              <a className="inline-link inline-link--strong" href="#guide-web-components">Web Components 接入</a>
              、
              <a className="inline-link inline-link--strong" href="#guide-cli">命令行工具 CLI</a>
              、
              <a className="inline-link inline-link--strong" href="#guide-moonbit">MoonBit 原生库</a>
            </Typography.Paragraph>
          </div>
        </div>
        <div className="guide-stack">
          <GuideSection
            id="guide-react"
            title="React 接入"
            description={<>通过 React 组件库 <a href="https://www.npmjs.com/package/@moon-lottie/react" target="_blank" rel="noreferrer">@moon-lottie/react</a> 快速集成 Moon Lottie。</>}
            sections={[
              { title: "1. 安装包", code: "npm install @moon-lottie/react" },
              { title: "2. 使用组件", code: '<MoonLottie src="path/to/animation.json" autoplay loop />' },
            ]}
            actions={[
              { label: "查看示例", href: "https://lottie.cg-zhou.top/examples/moon-lottie-react/", primary: true },
              { label: "查看文档", href: "https://github.com/cg-zhou/moon-lottie/blob/main/packages/moon-lottie-react/README.md" },
            ]}
          />

          <GuideSection
            id="guide-web-components"
            title="Web Component 接入"
            description={<>基于原生 Web Component 的自定义元素包 <a href="https://www.npmjs.com/package/@moon-lottie/core" target="_blank" rel="noreferrer">@moon-lottie/core</a>，适合无框架或多框架场景。</>}
            sections={[
              { title: "1. 安装包", code: "npm install @moon-lottie/core" },
              { title: "2. 使用组件", code: `import { register } from '@moon-lottie/core';\nregister(); // 然后在 HTML 中使用 <moon-lottie> 标签` },
            ]}
            actions={[
              { label: "查看示例", href: "https://lottie.cg-zhou.top/examples/moon-lottie-core/", primary: true },
              { label: "查看文档", href: "https://github.com/cg-zhou/moon-lottie/blob/main/packages/moon-lottie/README.md" },
            ]}
          />

          <GuideSection
            id="guide-cli"
            title="命令行工具 CLI"
            description={<>使用 <a href="https://www.npmjs.com/package/@moon-lottie/cli" target="_blank" rel="noreferrer">@moon-lottie/cli</a>，可以在终端预览动画或导出 SVG 资源。</>}
            sections={[
              { title: "1. 安装包", code: "npm install -g @moon-lottie/cli" },
              { title: "2. 终端预览", code: "moon-lottie play ani.json" },
              { title: "3. 导出 SVG", code: "moon-lottie render ani.json -o out.svg" },
            ]}
          />

          <GuideSection
            id="guide-moonbit"
            title="MoonBit 原生库"
            description={<>在 MoonBit 项目中引入 <a href="https://mooncakes.io/packages/cg-zhou/moon-lottie" target="_blank" rel="noreferrer">moon-lottie</a>，直接调用底层运行时和渲染接口。</>}
            sections={[
              { title: "1. 添加依赖", code: "moon add moon-lottie" },
              { title: "2. 调用运行时", code: `import * as lottie from "moon-lottie/lib/runtime"\n\nfn init {\n  let ani = lottie.load_from_string(...)\n  ani.render(ctx, time)\n}` },
            ]}
            actions={[
              { label: "查看文档", href: "https://github.com/cg-zhou/moon-lottie/blob/main/README.mbt.md", primary: true },
            ]}
          />
        </div>
      </section>
    </div>
  )
}

function PlaygroundPage({ active = true }) {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-heading">
          <div>
            <Typography.Title level={2}>在线演示</Typography.Title>
            <Typography.Paragraph>对比 Moon Lottie 与官方 lottie-web 的渲染表现。</Typography.Paragraph>
          </div>
        </div>
        <Playground active={active} />
      </section>
    </div>
  )
}

function FeaturesPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <div className="section-heading">
          <div>
            <Typography.Title level={2}>特性支持</Typography.Title>
            <Typography.Paragraph className="support-note">
              基于 Airbnb 官方特性支持表（
              <a className="inline-link inline-link--strong" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
                Airbnb 官方 Supported Features
              </a>
              ），整理了 Moon Lottie 当前的动画特性支持情况，点击特性可以查看特性动画说明。这里主要列出对动画还原影响较大的核心特性，未逐条展开的细碎兼容项建议直接对照官方表查看差异。
            </Typography.Paragraph>
          </div>
        </div>

        <div className="matrix-sections">
          {supportSections.map((section) => <FeatureSupportSection key={section.id} section={section} />)}
        </div>
      </section>
    </div>
  )
}

export default function App() {
  const [currentPage, setCurrentPage] = useState(() => getPageFromPath(window.location.pathname, PAGE_IDS))
  const [hasVisitedPlayground, setHasVisitedPlayground] = useState(() => getPageFromPath(window.location.pathname, PAGE_IDS) === "playground")
  const menuItems = useMemo(() => NAV_ITEMS.map((item) => ({
    key: item.id,
    label: item.label,
  })), [])

  useEffect(() => {
    if (currentPage === "playground") {
      setHasVisitedPlayground(true)
    }
  }, [currentPage])

  useEffect(() => {
    const syncCurrentPage = () => {
      setCurrentPage(getPageFromPath(window.location.pathname, PAGE_IDS))
    }

    window.addEventListener("popstate", syncCurrentPage)

    return () => {
      window.removeEventListener("popstate", syncCurrentPage)
    }
  }, [])

  const navigateTo = (id) => {
    const nextPath = getPathForPage(id)

    if (window.location.pathname !== nextPath) {
      window.history.pushState(null, "", nextPath)
      setCurrentPage(id)
    }
  }

  return (
    <ConfigProvider theme={THEME_CONFIG}>
      <Layout className="site-layout app-shell">
        <Layout.Header className="site-header">
          <div className="site-header__inner">
            <Button type="text" className="brand-button" onClick={() => navigateTo("overview")}>
              <img src="/logo.svg" alt="Moon Lottie Logo" className="brand-logo" />
              <span className="brand-button__label">Moon Lottie</span>
            </Button>

            <Menu
              mode="horizontal"
              selectedKeys={[currentPage]}
              items={menuItems}
              onClick={({ key }) => navigateTo(key)}
              className="site-nav"
            />

            <div className="site-header__actions">
              <Button className="site-header__github" href="https://github.com/cg-zhou/moon-lottie" target="_blank" rel="noreferrer" icon={<GitHubMarkIcon size={16} />}>
                GitHub
              </Button>
            </div>
          </div>
        </Layout.Header>

        <Layout.Content className="site-content" tabIndex="-1">
          <div className="view-shell">
            {currentPage === "overview" ? <OverviewPage onNavigate={navigateTo} /> : null}
            {hasVisitedPlayground ? (
              <div hidden={currentPage !== "playground"} aria-hidden={currentPage !== "playground"}>
                <PlaygroundPage active={currentPage === "playground"} />
              </div>
            ) : null}
            {currentPage === "features" ? <FeaturesPage /> : null}
          </div>
        </Layout.Content>

        <Layout.Footer className="site-footer">
          <div className="site-footer__inner">
            <Typography.Text>
              {new Date().getFullYear()}{" © "}
              <a href="https://cg-zhou.top/" target="_blank" rel="noreferrer" className="inline-link inline-link--strong">
                cg-zhou
              </a>
            </Typography.Text>
            <span className="footer-divider">·</span>
            <Typography.Text>
              {"Powered by "}
              <a href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" className="inline-link inline-link--strong">
                MoonBit
              </a>
            </Typography.Text>
          </div>
        </Layout.Footer>
      </Layout>
    </ConfigProvider>
  )
}
