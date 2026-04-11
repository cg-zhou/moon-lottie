import React, { useEffect, useRef, useState } from "react"
import { Card, Typography } from "antd"
import { MoonLottiePlayer } from "@moon-lottie/react"

const ASSET_BASE = (import.meta.env.BASE_URL || "/").replace(/\/?$/, "/")
const WASM_RUNTIME_PATH = `${ASSET_BASE}runtime/wasm/moon-lottie-runtime.wasm?v=${__MOON_LOTTIE_RUNTIME_VERSION__}`
const JS_RUNTIME_PATH = `${ASSET_BASE}runtime/js/moon-lottie-runtime.js?v=${__MOON_LOTTIE_RUNTIME_VERSION__}`

export default function FeatureExampleCard({ feature, example }) {
  const containerRef = useRef(null)
  const playerRef = useRef(null)
  const [loadError, setLoadError] = useState("")

  useEffect(() => {
    setLoadError("")
  }, [example])

  return (
    <div ref={containerRef} className="feature-example-card-wrap">
      <Card className="feature-card feature-example-card">
        <div className="feature-example-card__content">
          <div className="feature-example-card__preview-panel">
            <div className="feature-example-card__preview">
              <span className="feature-example-card__preview-badge">Moon Lottie</span>
              {loadError ? (
                <div className="feature-example-card__placeholder feature-example-card__placeholder--error">
                  预览加载失败
                </div>
              ) : (
                <MoonLottiePlayer
                  lottieRef={playerRef}
                  animationData={example.animationData}
                  name={feature}
                  autoplay={true}
                  loop
                  renderer="canvas"
                  wasmPath={WASM_RUNTIME_PATH}
                  jsRuntimePath={JS_RUNTIME_PATH}
                  className="feature-example-card__player"
                  style={{ width: "100%", height: "100%" }}
                  onLoad={() => {
                    setLoadError("")
                  }}
                  onError={(error) => {
                    setLoadError(error?.message || "预览加载失败")
                  }}
                />
              )}
            </div>
          </div>

          <div className="feature-example-card__header">
            <Typography.Paragraph className="feature-example-card__description">
              {example.description}
            </Typography.Paragraph>
          </div>
        </div>
      </Card>
    </div>
  )
}