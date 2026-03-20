import { createEventEmitter } from './event-emitter.js';
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

function normalizeDirection(value) {
    return Number(value) < 0 ? -1 : 1;
}

function resolveFrameFromValue(value, isFrame, meta) {
    const numericValue = Number(value);
    if (!Number.isFinite(numericValue)) {
        return meta?.inPoint || 0;
    }

    if (isFrame) {
        return numericValue;
    }

    const fps = meta?.fps || 0;
    const inPoint = meta?.inPoint || 0;
    return inPoint + (numericValue * fps) / 1000;
}

function createPlayerDom(container, rendererSettings = {}) {
    container.innerHTML = '';

    const viewport = document.createElement('div');
    const wrapper = document.createElement('div');
    const stage = document.createElement('div');
    const canvas = document.createElement('canvas');

    viewport.className = rendererSettings.viewportClassName || 'moon-lottie-player__viewport';
    wrapper.className = rendererSettings.wrapperClassName || 'moon-lottie-player__wrapper';
    stage.className = rendererSettings.stageClassName || 'moon-lottie-player__stage';
    canvas.className = rendererSettings.canvasClassName || 'moon-lottie-player__canvas';

    Object.assign(viewport.style, {
        width: '100%',
        height: '100%',
        minHeight: '120px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
        background: 'transparent',
    });
    Object.assign(wrapper.style, {
        flex: '0 1 auto',
        minWidth: '0',
        minHeight: '0',
        maxWidth: '100%',
        maxHeight: '100%',
        display: 'flex',
        flexDirection: 'column',
    });
    Object.assign(stage.style, {
        flex: '1',
        minHeight: '0',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
    });
    Object.assign(canvas.style, {
        maxWidth: '100%',
        maxHeight: '100%',
        display: 'block',
        objectFit: 'contain',
    });

    stage.appendChild(canvas);
    wrapper.appendChild(stage);
    viewport.appendChild(wrapper);
    container.appendChild(viewport);

    if (rendererSettings.className) {
        container.classList.add(rendererSettings.className);
    }

    return {
        viewport,
        wrapper,
        stage,
        canvas,
    };
}

function applyBackground(viewport, background) {
    viewport.style.background = 'transparent';
    viewport.style.backgroundColor = '';
    viewport.style.backgroundImage = '';
    viewport.style.backgroundSize = '';
    viewport.style.backgroundPosition = '';

    if (background === 'white') {
        viewport.style.background = '#ffffff';
        return;
    }

    if (background === 'black') {
        viewport.style.background = '#05070b';
        return;
    }

    if (background === 'grid') {
        viewport.style.backgroundColor = '#eef1f6';
        viewport.style.backgroundImage = [
            'linear-gradient(45deg, #dce1e9 25%, transparent 25%)',
            'linear-gradient(-45deg, #dce1e9 25%, transparent 25%)',
            'linear-gradient(45deg, transparent 75%, #dce1e9 75%)',
            'linear-gradient(-45deg, transparent 75%, #dce1e9 75%)',
        ].join(',');
        viewport.style.backgroundSize = '20px 20px';
        viewport.style.backgroundPosition = '0 0, 0 10px, 10px -10px, -10px 0';
    }
}

export function createBrowserPlayer(options = {}) {
    const {
        container,
        animationData = null,
        path = null,
        autoplay = true,
        loop = true,
        speed = 1,
        direction = 1,
        background = 'transparent',
        renderer = 'canvas',
        rendererSettings = {},
        onError = () => {},
    } = options;

    if (!container) {
        throw new Error('createBrowserPlayer requires a container element');
    }

    if (renderer !== 'canvas') {
        throw new Error(`Unsupported renderer: ${renderer}`);
    }

    const emitter = createEventEmitter();
    const dom = createPlayerDom(container, rendererSettings);
    const viewportTransform = { scale: 1, offsetX: 0, offsetY: 0, dpr: 1 };
    const ctx = dom.canvas.getContext('2d');
    let runtimeJson = '';
    let imageAssets = [];
    let currentState = null;
    let currentSpeed = normalizeSpeed(speed);
    let currentDirection = normalizeDirection(direction);
    let currentLoop = loop !== false;
    let currentBackground = background;
    let readyPromise = null;
    let resizeObserver = null;

    applyBackground(dom.viewport, currentBackground);

    const viewportPresenter = createViewportPresenter({
        viewport: dom.viewport,
        canvas: dom.canvas,
        wasmWrapper: dom.wrapper,
        officialWrapper: null,
        wasmStage: dom.stage,
        officialStage: null,
        officialContainer: null,
        seekBar: null,
        resizeCanvasForDpr,
        viewportTransform,
        getCompareEnabled: () => false,
        requestRender: () => {
            player.render();
        },
        updateCurrentFileLabel: () => {},
        infoElements: {},
    });

    const runtimeBridge = createCanvasRuntimeBridge({
        canvas: dom.canvas,
        viewportTransform,
        getRuntimeAnimationJson: () => runtimeJson,
        getImageAssets: () => imageAssets,
        getExpressionAnimationData: () => currentState?.currentExpressionAnimationData || null,
        getExpressionMeta: () => currentState?.currentExpressionMeta || null,
        getCanvasContext: () => ctx,
    });

    const internalPlayer = createPlayer({
        loadWasmRuntime: runtimeBridge.loadWasmRuntime,
        loadJsRuntime: runtimeBridge.loadJsRuntime,
        officialPlayerController: createOfficialPlayerController({ container: null, getLottie: () => null }),
        viewportPresenter,
        getAnimationPlaybackMeta,
        animationUsesExpressions,
        setStatusMessage: () => {},
        setExpressionHost: () => {},
        setRuntimeAnimationJson: (value) => {
            runtimeJson = value;
        },
        setImageAssets: (assets) => {
            imageAssets = assets;
        },
        getSpeed: () => currentSpeed,
        getDirection: () => currentDirection,
        getLoop: () => currentLoop,
        getCompareEnabled: () => false,
        renderFrame: (frame, state) => {
            runtimeBridge.renderFrame(state.runtime, state.nativePlayer, frame);
        },
        createNativePlayer: (runtime) => runtime.create_player_from_js(),
        onRuntimeChanged: ({ runtime, backend, preference }) => {
            emitter.dispatchEvent('runtimechange', { runtime, backend, preference });
        },
        onStateChange: (state) => {
            currentState = state;
        },
        onFrameChange: ({ currentFrame, state }) => {
            emitter.dispatchEvent('enterframe', { currentFrame, state });
        },
        onPlayStateChange: ({ isPlaying, state }) => {
            emitter.dispatchEvent(isPlaying ? 'play' : 'pause', { state });
        },
    });

    async function ensureReady() {
        if (!readyPromise) {
            readyPromise = internalPlayer.initialize();
        }
        return readyPromise;
    }

    async function loadSource(loadOptions = {}) {
        await ensureReady();

        const nextAutoplay = loadOptions.autoplay ?? autoplay;
        currentLoop = loadOptions.loop ?? currentLoop;
        currentSpeed = normalizeSpeed(loadOptions.speed ?? currentSpeed);
        currentDirection = normalizeDirection(loadOptions.direction ?? currentDirection);
        currentBackground = loadOptions.background ?? currentBackground;
        applyBackground(dom.viewport, currentBackground);

        let state;
        if (loadOptions.animationData) {
            state = await internalPlayer.loadFromText(JSON.stringify(loadOptions.animationData), {
                filename: loadOptions.name || currentState?.currentFileName || 'animation.json',
            });
        } else if (loadOptions.path) {
            state = await internalPlayer.loadFromUrl(loadOptions.path, {
                filename: loadOptions.name || loadOptions.path,
            });
        } else {
            throw new Error('loadAnimation requires animationData or path');
        }

        currentState = state;

        if (Array.isArray(loadOptions.initialSegment) && loadOptions.initialSegment.length >= 2) {
            internalPlayer.seek(Number(loadOptions.initialSegment[0]) || 0);
        }

        if (!nextAutoplay) {
            internalPlayer.pause();
        }

        emitter.dispatchEvent('load', { state });
        return state;
    }

    const player = {
        whenReady: () => ensureReady(),
        loadAnimation: (loadOptions = {}) => loadSource(loadOptions),
        render: () => internalPlayer.render(),
        play: () => internalPlayer.play(),
        pause: () => internalPlayer.pause(),
        stop: () => {
            internalPlayer.stop();
            internalPlayer.render();
        },
        setSpeed: (value) => {
            currentSpeed = normalizeSpeed(value);
            return currentSpeed;
        },
        setDirection: (value) => {
            currentDirection = normalizeDirection(value);
            return currentDirection;
        },
        setLoop: (value) => {
            currentLoop = Boolean(value);
            return currentLoop;
        },
        setBackground: (value) => {
            currentBackground = value || 'transparent';
            applyBackground(dom.viewport, currentBackground);
            return currentBackground;
        },
        goToAndStop: (value, isFrame = false) => {
            const frame = resolveFrameFromValue(value, isFrame, currentState?.currentAnimationMeta);
            internalPlayer.pause();
            internalPlayer.seek(frame);
        },
        goToAndPlay: (value, isFrame = false) => {
            const frame = resolveFrameFromValue(value, isFrame, currentState?.currentAnimationMeta);
            internalPlayer.seek(frame);
            internalPlayer.play();
        },
        getDuration: (inFrames = false) => {
            const meta = currentState?.currentAnimationMeta;
            if (!meta) {
                return 0;
            }
            return inFrames ? meta.totalFrames : (meta.fps > 0 ? meta.totalFrames / meta.fps : 0);
        },
        resize: () => internalPlayer.scheduleViewportRefresh(),
        getCurrentFrame: () => internalPlayer.getCurrentFrame(),
        getState: () => currentState,
        getContainer: () => container,
        getCanvas: () => dom.canvas,
        addEventListener: (type, listener) => emitter.addEventListener(type, listener),
        removeEventListener: (type, listener) => emitter.removeEventListener(type, listener),
        destroy: () => {
            resizeObserver?.disconnect();
            resizeObserver = null;
            internalPlayer.destroy();
            container.innerHTML = '';
            emitter.dispatchEvent('destroy', {});
            emitter.clear();
        },
    };

    if (typeof ResizeObserver === 'function') {
        resizeObserver = new ResizeObserver(() => {
            internalPlayer.scheduleViewportRefresh();
        });
        resizeObserver.observe(container);
    }

    ensureReady().then(async () => {
        if (animationData || path) {
            await loadSource({
                animationData,
                path,
                autoplay,
                loop: currentLoop,
                speed: currentSpeed,
                direction: currentDirection,
            });
        }
    }).catch((error) => {
        onError(error);
        emitter.dispatchEvent('error', { error });
    });

    return player;
}

export function loadAnimation(options = {}) {
    return createBrowserPlayer(options);
}