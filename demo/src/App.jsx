import React, { useEffect, useMemo, useState } from "react"
import { Button, Card, ConfigProvider, Layout, Menu, Table, Tag, Typography } from "antd"
import { supportSections, platformColumns } from "./supportMatrix"
import Playground from "./components/Playground.jsx"

const NAV_ITEMS = [
  { id: "overview", label: "概览" },
  { id: "playground", label: "演示" },
  { id: "features", label: "特性支持" },
  { id: "architecture", label: "架构设计" },
]

const PAGE_IDS = new Set(NAV_ITEMS.map((item) => item.id))
const DEFAULT_PAGE_ID = "overview"
const BASE_PATH = (import.meta.env.BASE_URL || "/").replace(/\/$/, "")

const QUICK_START_STEPS = [
  {
    icon: "solar:download-bold",
    title: "1. 添加依赖",
    code: "moon add moon-lottie",
  },
  {
    icon: "solar:code-bold",
    title: "2. 集成到运行时",
    code: `import * as lottie from \"moon-lottie/lib/runtime\"\n\nfn init {\n  let ani = lottie.load_from_string(...)\n  ani.render(ctx, time)\n}`,
  },
  {
    icon: "solar:widget-5-bold",
    title: "3. 浏览器运行",
    code: `<moon-lottie src=\"ani.json\" autoplay></moon-lottie>`,
  },
]

const STATUS_META = {
  supported: { label: "支持", color: "success", icon: "solar:check-circle-bold" },
  unsupported: { label: "不支持", color: "error", icon: "solar:close-circle-bold" },
  unknown: { label: "未知", color: "default", icon: "solar:question-circle-bold" },
}

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
    borderRadius: 6,
    borderRadiusLG: 8,
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
      borderRadius: 6,
      controlHeight: 38,
      paddingInline: 20,
      fontWeight: 500,
    }
  },
}

function IconifyIcon({ name, size = 18 }) {
  return <iconify-icon icon={name} width={size} height={size} aria-hidden="true" />
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
  const coverage = total === 0 ? 0 : Math.round((supportedCount / total) * 100)

  return { total, supportedCount, coverage }
}

function SectionHeading({ eyebrow, title, subtitle, action = null }) {
  return (
    <div className="section-heading">
      <div>
        <p className="section-kicker">{eyebrow}</p>
        <Typography.Title level={2}>{title}</Typography.Title>
        {subtitle ? <Typography.Paragraph>{subtitle}</Typography.Paragraph> : null}
      </div>
      {action}
    </div>
  )
}

function SupportCell({ value, highlight = false }) {
  const cell = normalizeStatusCell(value)
  const meta = STATUS_META[cell.status] || STATUS_META.unknown

  return (
    <div
      className={`support-status support-status--${cell.status}${highlight ? " support-status--highlight" : ""}`}
      title={cell.detail ? `${meta.label}：${cell.detail}` : meta.label}
      aria-label={cell.detail ? `${meta.label}：${cell.detail}` : meta.label}
    >
      <span className="support-status__icon">
        <IconifyIcon name={meta.icon} size={16} />
      </span>
    </div>
  )
}

function QuickStartCard({ step }) {
  return (
    <Card className="feature-card quickstart-card">
      <Typography.Title level={4}>{step.title}</Typography.Title>
      <pre className="code-block"><code>{step.code}</code></pre>
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
          MoonLottie 是对性能和跨平台一致性的重新思考。基于 <MoonBitLink /> 强大的类型系统与编译优化，为 Web 提供极致的渲染体验。
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
        <SectionHeading eyebrow="快速开始" title="接入方式" subtitle="保持最短路径接入，先跑起来，再逐步扩展能力。" />
        <div className="quickstart-grid">
          {QUICK_START_STEPS.map((step) => <QuickStartCard key={step.title} step={step} />)}
        </div>
      </section>
    </div>
  )
}

function PlaygroundPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <SectionHeading eyebrow="在线演示" title="在线演示" subtitle="直观感受 MoonLottie 引擎的渲染，并支持与官方 lottie-web 进行对比。" />
        <Playground />
      </section>
    </div>
  )
}

function FeaturesPage() {
  const columns = useMemo(() => [
    {
      title: "特性项",
      dataIndex: "feature",
      key: "feature",
      fixed: "left",
      width: 180,
      render: (value) => <Typography.Text strong>{value}</Typography.Text>,
    },
    ...platformColumns.map((column) => ({
      title: column.highlight
        ? <span className="support-col-title support-col-title--moon">MoonLottie</span>
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
  ], [])

  return (
    <div className="page-stack">
      <section className="section-block">
        <SectionHeading eyebrow="支持情况" title="特性支持" subtitle="基于 Airbnb 官方特性支持表，整理 MoonLottie 当前的支持情况。" />
        <Typography.Paragraph className="support-note">
            参考{" "}
            <a className="inline-link" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
              Airbnb 官方 Supported Features
            </a>
            。
        </Typography.Paragraph>

        <div className="matrix-sections">
          {supportSections.map((section) => {
            const { total, supportedCount, coverage } = getSectionCoverage(section)

            return (
              <Card
                key={section.id}
                className="support-table-card"
                title={section.title}
                extra={<Tag color="green">支持 {supportedCount}/{total} 项 · {coverage}%</Tag>}
              >
                <Table
                  rowKey="feature"
                  columns={columns}
                  dataSource={section.rows}
                  pagination={false}
                  size="small"
                  scroll={{ x: 980 }}
                />
              </Card>
            )
          })}
        </div>
      </section>
    </div>
  )
}

function ArchitecturePage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <SectionHeading eyebrow="架构设计" title="架构设计" subtitle="TODO：补充核心模块拆分、运行时边界与渲染链路说明。" />
        <Card className="intro-card">
          <Typography.Paragraph>
            TODO：补充架构设计说明。
          </Typography.Paragraph>
        </Card>
      </section>
    </div>
  )
}

export default function App() {
  const [currentPage, setCurrentPage] = useState(() => getPageFromPath(window.location.pathname, PAGE_IDS))
  const menuItems = useMemo(() => NAV_ITEMS.map((item) => ({
    key: item.id,
    label: item.label,
  })), [])

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

  let content = <OverviewPage onNavigate={navigateTo} />
  if (currentPage === "playground") content = <PlaygroundPage />
  else if (currentPage === "features") content = <FeaturesPage />
  else if (currentPage === "architecture") content = <ArchitecturePage />

  return (
    <ConfigProvider theme={THEME_CONFIG}>
      <Layout className="site-layout app-shell">
        <Layout.Header className="site-header">
          <div className="site-header__inner">
            <Button type="text" className="brand-button" onClick={() => navigateTo("overview")}>
              <span className="brand-mark brand-mark--minimal" />
              <span className="brand-button__label">MoonLottie</span>
            </Button>

            <Menu
              mode="horizontal"
              selectedKeys={[currentPage]}
              items={menuItems}
              onClick={({ key }) => navigateTo(key)}
              className="site-nav"
            />

            <div className="site-header__actions">
              <Button href="https://github.com/cg-zhou/moon-lottie" target="_blank" rel="noreferrer" icon={<IconifyIcon name="mdi:github" size={18} />}>
                GitHub
              </Button>
            </div>
          </div>
        </Layout.Header>

        <Layout.Content className="site-content" tabIndex="-1">
          <div className="view-shell">{content}</div>
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
