import React, { startTransition, useEffect, useMemo, useState } from "react"
import { Button, Card, ConfigProvider, Layout, Menu, Table, Tag, Timeline, Typography } from "antd"
import { supportSections, platformColumns } from "./supportMatrix"
import { architectureDiagram, renderPipelineDiagram } from "./techDesign"
import MermaidDiagram from "./MermaidDiagram"
import Playground from "./components/Playground.jsx"

const NAV_ITEMS = [
  { id: "overview", label: "概览", icon: "solar:home-angle-bold" },
  { id: "playground", label: "演示", icon: "solar:play-circle-bold" },
  { id: "features", label: "特性支持", icon: "solar:list-check-bold" },
  { id: "architecture", label: "底层架构", icon: "solar:cpu-bolt-bold" },
  { id: "roadmap", label: "项目路线", icon: "solar:map-arrow-right-bold" },
]

const PAGE_IDS = new Set(NAV_ITEMS.map((item) => item.id))

const ABOUT_CARDS = [
  {
    icon: "solar:flash-circle-bold",
    title: "极速性能",
    description: "利用 MoonBit 的编译优化，提供接近原生的渲染速度。",
  },
  {
    icon: "solar:box-minimalistic-bold",
    title: "轻量化",
    description: "极小的 Wasm 二进制体积，适合在各种 Web 场景快速分发。",
  },
  {
    icon: "solar:global-bold",
    title: "跨平台",
    description: "通过 Wasm 指令集实现一次编写，各端表现完全一致。",
  },
  {
    icon: "solar:shield-check-bold",
    title: "类型安全",
    description: "借助 MoonBit 的强类型检查，从源头减少运行时错误。",
  },
]

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

const ROADMAP_PHASES = [
  {
    icon: "solar:rocket-bold",
    title: "阶段 1：核心引擎与 MVP",
    items: [
      "完成 MoonBit 核心渲染管线",
      "支持导出 Wasm-GC 目标",
      "实现基础 Shapes（矩形、圆形、路径）",
      "集成第一版特性审计矩阵",
    ],
  },
  {
    icon: "solar:sidebar-code-bold",
    title: "阶段 2：表达式与进阶特性",
    items: [
      "基于 JS 宿主的表达式引擎",
      "支持更多蒙版与混合模式",
      "优化 Wasm 内存共享效率",
      "Playground 像素级对比工具",
    ],
  },
  {
    icon: "solar:planet-bold",
    title: "阶段 3：多后端与生态",
    items: [
      "WebGL / WebGPU 渲染后端支持",
      "支持动画导出为不同平台 Native 库",
      "更完善的文档与集成指南",
    ],
  },
]

const STATUS_META = {
  supported: { label: "支持", color: "success", icon: "solar:check-circle-bold" },
  unsupported: { label: "不支持", color: "error", icon: "solar:close-circle-bold" },
  unknown: { label: "未知", color: "default", icon: "solar:question-circle-bold" },
}

const THEME_CONFIG = {
  token: {
    colorPrimary: "#2563eb",
    colorInfo: "#2563eb",
    colorSuccess: "#10b981",
    colorWarning: "#f59e0b",
    colorError: "#ef4444",
    colorBgLayout: "#f3f7fb",
    colorBgContainer: "#ffffff",
    colorText: "#0f172a",
    colorTextSecondary: "#52607a",
    borderRadius: 18,
    borderRadiusLG: 24,
    boxShadowSecondary: "0 16px 48px rgba(15, 23, 42, 0.08)",
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
  components: {
    Layout: {
      headerBg: "rgba(243, 247, 251, 0.82)",
      bodyBg: "#f3f7fb",
      footerBg: "transparent",
    },
    Menu: {
      itemBg: "transparent",
      itemSelectedBg: "rgba(37, 99, 235, 0.10)",
      itemSelectedColor: "#1d4ed8",
      itemHoverColor: "#1d4ed8",
      horizontalItemSelectedColor: "#1d4ed8",
      horizontalItemHoverColor: "#1d4ed8",
      activeBarBorderWidth: 0,
    },
    Card: {
      bodyPadding: 24,
    },
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
  const tagColor = highlight
    ? (cell.status === "supported" ? "blue" : cell.status === "unsupported" ? "red" : "default")
    : meta.color

  return (
    <div className={`support-status${highlight ? " support-status--highlight" : ""}`}>
      <Tag color={tagColor} className="support-status__tag">
        <span className="support-status__tag-inner">
          <IconifyIcon name={cell.symbol ? "solar:question-circle-bold" : meta.icon} size={14} />
          <span>{cell.symbol || meta.label}</span>
        </span>
      </Tag>
      {cell.detail ? <span className="support-status__detail">{cell.detail}</span> : null}
    </div>
  )
}

function QuickStartCard({ step }) {
  return (
    <Card className="feature-card quickstart-card">
      <div className="feature-card__icon">
        <IconifyIcon name={step.icon} size={22} />
      </div>
      <Typography.Title level={4}>{step.title}</Typography.Title>
      <pre className="code-block"><code>{step.code}</code></pre>
    </Card>
  )
}

function getPageFromHash(hash, pageIds) {
  const pageId = hash.replace("#", "")
  return pageIds.has(pageId) ? pageId : "overview"
}

function OverviewPage({ onNavigate }) {
  return (
    <div className="page-stack">
      <Card className="hero-card" bordered={false}>
        <div className="hero-card__badge">使命与愿景</div>
        <Typography.Title className="hero-card__title">极速、现代的 Lottie 动画渲染引擎</Typography.Title>
        <Typography.Paragraph className="hero-card__lead">
            MoonLottie 是对性能和跨平台一致性的重新思考。基于 <MoonBitLink /> 强大的类型系统与编译优化，为 Web 提供极致的渲染体验。
        </Typography.Paragraph>
        <div className="hero-card__actions">
          <Button type="primary" size="large" icon={<IconifyIcon name="solar:play-bold" />} onClick={() => onNavigate("playground")}>
            在线演示
          </Button>
          <Button size="large" icon={<IconifyIcon name="solar:list-check-bold" />} onClick={() => onNavigate("features")}>
            查看支持矩阵
          </Button>
        </div>
        <div className="hero-metrics">
          <Card size="small" className="metric-card">
            <Typography.Text type="secondary">运行时目标</Typography.Text>
            <Typography.Title level={3}>Wasm / JS</Typography.Title>
          </Card>
          <Card size="small" className="metric-card">
            <Typography.Text type="secondary">交付形态</Typography.Text>
            <Typography.Title level={3}>Web + Runtime</Typography.Title>
          </Card>
          <Card size="small" className="metric-card">
            <Typography.Text type="secondary">设计重点</Typography.Text>
            <Typography.Title level={3}>性能一致性</Typography.Title>
          </Card>
        </div>
      </Card>

      <section className="section-block">
        <SectionHeading eyebrow="核心价值" title="为什么选择 MoonLottie" />
        <div className="card-grid card-grid--double">
          {ABOUT_CARDS.map((item) => (
            <Card key={item.title} className="feature-card">
              <div className="feature-card__icon">
                <IconifyIcon name={item.icon} size={22} />
              </div>
              <Typography.Title level={4}>{item.title}</Typography.Title>
              <Typography.Paragraph>{item.description}</Typography.Paragraph>
            </Card>
          ))}
        </div>
      </section>

      <section className="section-block">
        <SectionHeading eyebrow="快速开始" title="接入方式" subtitle="优先使用标准组件组织说明区，减少后续维护自由样式的成本。" />
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
        <SectionHeading eyebrow="在线演示" title="在线演示" subtitle="直观感受 MoonLottie 引擎的渲染性能，并支持与官方 `lottie-web` 进行对比。" />
        <Card className="intro-card">
          <Typography.Title level={4}>演示区说明</Typography.Title>
          <Typography.Paragraph>
            这里嵌入的是主站正式 Playground。动画列表、工具栏、控制栏和信息面板都属于主站 UI，
            不属于 Web Component、浏览器播放器或 React 封装的通用交付面。
          </Typography.Paragraph>
        </Card>
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
      width: 160,
      className: column.highlight ? "support-col support-col--moon" : "support-col",
      render: (value) => <SupportCell value={value} highlight={column.highlight} />,
    })),
  ], [])

  return (
    <div className="page-stack">
      <section className="section-block">
        <SectionHeading eyebrow="兼容性" title="特性支持矩阵" subtitle="本表遵循 Airbnb 官方 Supported Features 标准，对比 7 个主流平台与 MoonLottie 实现的特性支持情况。" />
        <Typography.Paragraph className="support-note">
            数据同步自 Airbnb 官方 Lottie 规范 v24+。{" "}
            <a className="inline-link" href="https://lottie.airbnb.tech/#/supported-features" target="_blank" rel="noreferrer">
              查看官方原表
            </a>
        </Typography.Paragraph>

        <div className="matrix-sections">
          {supportSections.map((section) => (
            <Card
              key={section.id}
              className="support-table-card"
              title={section.title}
              extra={<Tag color="blue">{section.rows.length} 项</Tag>}
            >
              <Table
                rowKey="feature"
                columns={columns}
                dataSource={section.rows}
                pagination={false}
                size="small"
                scroll={{ x: 1320 }}
              />
            </Card>
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
        <SectionHeading eyebrow="底层架构" title="底层技术设计" subtitle="解析、求值与渲染逻辑完全解耦，编译为紧凑的 Wasm 指令流。" />
        <Card className="intro-card">
          <Typography.Paragraph>
            MoonLottie 采用 <MoonBitLink /> 开发，利用其零开销抽象和卓越的运行时性能。架构上我们通过 Wasm 内存共享技术最小化了 JS 与核心引擎间的交互开销。
          </Typography.Paragraph>
        </Card>
        <div className="diagram-stack">
          <Card className="diagram-panel" title="核心系统架构">
            <MermaidDiagram chart={architectureDiagram} />
            <Typography.Paragraph className="diagram-caption"><MoonBitLink /> Wasm 内核与 JS 宿主环境的交互概览。</Typography.Paragraph>
          </Card>
          <Card className="diagram-panel" title="渲染流水线">
            <MermaidDiagram chart={renderPipelineDiagram} />
            <Typography.Paragraph className="diagram-caption">从 Lottie JSON 到引擎渲染，最终输出到 Canvas 帧的完整数据流。</Typography.Paragraph>
          </Card>
        </div>
      </section>
    </div>
  )
}

function RoadmapPage() {
  return (
    <div className="page-stack">
      <section className="section-block">
        <SectionHeading eyebrow="里程碑" title="里程碑与路线图" subtitle="记录 MoonLottie 的成长轨迹与未来规划。" />
        <Card className="roadmap-panel">
          <Timeline
            className="roadmap-timeline"
            items={ROADMAP_PHASES.map((phase) => ({
              icon: <span className="roadmap-dot"><IconifyIcon name={phase.icon} size={16} /></span>,
              content: (
                <Card size="small" className="roadmap-phase-card">
                  <Typography.Title level={4}>{phase.title}</Typography.Title>
                  <ul className="bullet-list">
                    {phase.items.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </Card>
              ),
            }))}
          />
        </Card>
      </section>
    </div>
  )
}

export default function App() {
  const [currentPage, setCurrentPage] = useState(() => getPageFromHash(window.location.hash, PAGE_IDS))
  const menuItems = useMemo(() => NAV_ITEMS.map((item) => ({
    key: item.id,
    icon: <IconifyIcon name={item.icon} size={18} />,
    label: item.label,
  })), [])

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
    <ConfigProvider theme={THEME_CONFIG}>
      <Layout className="site-layout app-shell">
        <Layout.Header className="site-header">
          <div className="site-header__inner">
            <Button type="text" className="brand-button" onClick={() => navigateTo("overview")}>
              <span className="brand-mark"><IconifyIcon name="solar:stars-bold" size={18} /></span>
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
              <Button href="https://www.moonbitlang.cn/" target="_blank" rel="noreferrer" icon={<IconifyIcon name="simple-icons:moonbit" size={16} />}>
                MoonBit
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
              {new Date().getFullYear()} ©{" "}
              <a href="https://cg-zhou.top/" target="_blank" rel="noreferrer" className="inline-link inline-link--strong">
                cg-zhou
              </a>
            </Typography.Text>
            <span className="footer-divider">·</span>
            <Typography.Text>
              技术驱动：
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
