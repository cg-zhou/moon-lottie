import { animationUsesExpressions, getAnimationPlaybackMeta } from '../render_mode.js';
import { resizeCanvasForDpr } from '../canvas_dpr.js';
import { createCanvasRuntimeBridge } from './canvas-runtime-bridge.js';
import { createOfficialPlayerController } from './official-player.js';
import { createPlayer } from './create-player.js';
import { createViewportPresenter } from './viewport-presenter.js';

function normalizeSpeed(value) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
        return 1;
    }

    return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10));
}

function createNoopOfficialPlayerController() {
    return createOfficialPlayerController({ container: null, getLottie: () => null });
}

export class MoonLottieElement extends HTMLElement {
    static get observedAttributes() {
        return ['src', 'autoplay', 'speed', 'background'];
    }

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
        this._runtimeJson = '';
        this._imageAssets = [];
        this._speed = normalizeSpeed(this.getAttribute('speed') || '1');
        this._autoplay = this.getAttribute('autoplay') !== 'false';
        this._background = this.getAttribute('background') || 'transparent';
        this._state = null;
        this._resizeObserver = null;
        this._mounted = false;

        this._shadow.innerHTML = `
            <style>
                :host {
                    display: block;
                    min-width: 0;
                    min-height: 0;
                }

                .viewport {
                    width: 100%;
                    height: 100%;
                    min-height: 120px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 0;
                    overflow: hidden;
                    background: transparent;
                }

                .viewport[data-background="grid"] {
                    background-color: #eef1f6;
                    background-image:
                        linear-gradient(45deg, #dce1e9 25%, transparent 25%),
                        linear-gradient(-45deg, #dce1e9 25%, transparent 25%),
                        linear-gradient(45deg, transparent 75%, #dce1e9 75%),
                        linear-gradient(-45deg, transparent 75%, #dce1e9 75%);
                    background-size: 20px 20px;
                    background-position: 0 0, 0 10px, 10px -10px, -10px 0;
                }

                .viewport[data-background="white"] {
                    background: #ffffff;
                }

                .viewport[data-background="black"] {
                    background: #05070b;
                }

                .wrapper {
                    flex: 0 1 auto;
                    min-width: 0;
                    min-height: 0;
                    max-width: 100%;
                    max-height: 100%;
                    display: flex;
                    flex-direction: column;
                    gap: 0;
                }

                .stage {
                    flex: 1;
                    min-height: 0;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    overflow: hidden;
                }

                canvas {
                    max-width: 100%;
                    max-height: 100%;
                    display: block;
                    object-fit: contain;
                }
            </style>
            <div class="viewport" data-background="${this._background}">
                <div class="wrapper">
                    <div class="stage">
                        <canvas></canvas>
                    </div>
                </div>
            </div>
        `;

        this._viewport = this._shadow.querySelector('.viewport');
        this._wrapper = this._shadow.querySelector('.wrapper');
        this._stage = this._shadow.querySelector('.stage');
        this._canvas = this._shadow.querySelector('canvas');
        this._ctx = this._canvas.getContext('2d');
        this._viewportTransform = { scale: 1, offsetX: 0, offsetY: 0, dpr: 1 };

        const viewportPresenter = createViewportPresenter({
            viewport: this._viewport,
            canvas: this._canvas,
            wasmWrapper: this._wrapper,
            officialWrapper: null,
            wasmStage: this._stage,
            officialStage: null,
            officialContainer: null,
            seekBar: null,
            resizeCanvasForDpr,
            viewportTransform: this._viewportTransform,
            getCompareEnabled: () => false,
            requestRender: () => this._renderCurrentFrame(),
            updateCurrentFileLabel: () => {},
            infoElements: {},
        });

        const runtimeBridge = createCanvasRuntimeBridge({
            canvas: this._canvas,
            viewportTransform: this._viewportTransform,
            getRuntimeAnimationJson: () => this._runtimeJson,
            getImageAssets: () => this._imageAssets,
            getExpressionAnimationData: () => this._state?.currentExpressionAnimationData || null,
            getExpressionMeta: () => this._state?.currentExpressionMeta || null,
            getCanvasContext: () => this._ctx,
        });

        this._player = createPlayer({
            loadWasmRuntime: runtimeBridge.loadWasmRuntime,
            loadJsRuntime: runtimeBridge.loadJsRuntime,
            officialPlayerController: createNoopOfficialPlayerController(),
            viewportPresenter,
            getAnimationPlaybackMeta,
            animationUsesExpressions,
            setStatusMessage: () => {},
            setExpressionHost: () => {},
            setRuntimeAnimationJson: (value) => {
                this._runtimeJson = value;
            },
            setImageAssets: (assets) => {
                this._imageAssets = assets;
            },
            getSpeed: () => this._speed,
            getCompareEnabled: () => false,
            renderFrame: (frame, state) => {
                runtimeBridge.renderFrame(state.runtime, state.nativePlayer, frame);
            },
            createNativePlayer: (runtime) => runtime.create_player_from_js(),
            onRuntimeChanged: ({ runtime, backend }) => {
                this.dispatchEvent(new CustomEvent('runtimechange', { detail: { runtime, backend } }));
            },
            onStateChange: (state) => {
                this._state = state;
            },
            onFrameChange: ({ currentFrame, state }) => {
                this.dispatchEvent(new CustomEvent('enterframe', { detail: { currentFrame, state } }));
            },
            onPlayStateChange: ({ isPlaying, state }) => {
                this.dispatchEvent(new CustomEvent(isPlaying ? 'play' : 'pause', { detail: { state } }));
            },
        });
    }

    connectedCallback() {
        if (this._mounted) {
            return;
        }

        this._mounted = true;
        this._player.initialize().then(() => {
            const src = this.getAttribute('src');
            if (src) {
                this.load(src);
            }
        }).catch((error) => {
            this.dispatchEvent(new CustomEvent('error', { detail: { error } }));
        });

        if (typeof ResizeObserver === 'function') {
            this._resizeObserver = new ResizeObserver(() => {
                this._player.scheduleViewportRefresh();
            });
            this._resizeObserver.observe(this);
        }
    }

    disconnectedCallback() {
        this._resizeObserver?.disconnect();
        this._resizeObserver = null;
        this._player.destroy();
        this._mounted = false;
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue) {
            return;
        }

        if (name === 'src' && this._mounted && newValue) {
            this.load(newValue);
        }

        if (name === 'autoplay') {
            this._autoplay = newValue !== 'false';
        }

        if (name === 'speed') {
            this._speed = normalizeSpeed(newValue || '1');
        }

        if (name === 'background') {
            this._background = newValue || 'transparent';
            this._viewport.dataset.background = this._background;
        }
    }

    async load(src) {
        const state = await this._player.loadFromUrl(src, { filename: src });
        this._state = state;
        if (!this._autoplay) {
            this.pause();
        }
        this.dispatchEvent(new CustomEvent('load', { detail: { state } }));
        return state;
    }

    play() {
        this._player.play();
    }

    pause() {
        this._player.pause();
    }

    stop() {
        this._player.stop();
        this._renderCurrentFrame();
    }

    setSpeed(speed) {
        this._speed = normalizeSpeed(speed);
        this.setAttribute('speed', String(this._speed));
    }

    _renderCurrentFrame() {
        if (!this._state?.runtime || !this._state?.nativePlayer) {
            return;
        }
        const frame = this._player.getCurrentFrame();
        this._player.render();
        this.dispatchEvent(new CustomEvent('render', { detail: { frame } }));
    }
}

export function defineMoonLottieElement(tagName = 'moon-lottie') {
    if (!customElements.get(tagName)) {
        customElements.define(tagName, MoonLottieElement);
    }

    return customElements.get(tagName);
}