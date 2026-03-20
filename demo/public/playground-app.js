import {
    animationUsesExpressions,
    getAnimationPlaybackMeta,
} from './render_mode.js';
import {
    createExpressionModule,
    setExpressionHost,
} from './expression_host.js';
import {
    resizeCanvasForDpr,
} from './canvas_dpr.js';
import {
    clearActiveCanvas,
    cloneActiveCanvas,
} from './canvas_matte.js';
import {
    rasterizeMaskPath,
} from './canvas_mask_expansion.js';

// MoonLottie UI 2.0 - 现代化播放驱动

const canvas = document.getElementById('lottie-canvas');
let ctx = canvas.getContext('2d');
const statusDot = document.getElementById('status-dot');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const seekBar = document.getElementById('seek-bar');
const fileInput = document.getElementById('file-input');
const viewport = document.getElementById('viewport');
const currentFileNameEl = document.getElementById('current-file-name');
const compareToggle = document.getElementById('compare-toggle');
const wasmWrapper = document.getElementById('wasm-wrapper');
const officialWrapper = document.getElementById('official-wrapper');
const wasmStage = wasmWrapper.querySelector('.canvas-stage');
const officialStage = officialWrapper.querySelector('.canvas-stage');
const officialContainer = document.getElementById('official-lottie-container');
const infoRuntimeEl = document.getElementById('info-runtime');
const openFileBtn = document.getElementById('open-file-btn');
const prevAnimationBtn = document.getElementById('prev-animation');
const nextAnimationBtn = document.getElementById('next-animation');
const prevFrameBtn = document.getElementById('prev-frame');
const nextFrameBtn = document.getElementById('next-frame');
const speedInput = document.getElementById('speed-input');
const speedButtons = Array.from(document.querySelectorAll('.speed-btn'));
const bgButtons = Array.from(document.querySelectorAll('.bg-btn'));
const runtimeButtons = Array.from(document.querySelectorAll('.runtime-btn'));
const playlistDrawer = document.getElementById('playlist-drawer');
const playlistBackdrop = document.getElementById('playlist-backdrop');
const playlistToggle = document.getElementById('playlist-toggle');
const playlistClose = document.getElementById('playlist-close');
const playlistSearch = document.getElementById('playlist-search');
const playlistList = document.getElementById('playlist-list');
const detailsPanel = document.getElementById('details-panel');
const detailsToggle = document.getElementById('details-toggle');
const detailsClose = document.getElementById('details-close');
const panelBackdrop = document.getElementById('panel-backdrop');
const dropOverlay = document.getElementById('drop-overlay');

const isProd = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';
const wasmBuiltinOptions = { builtins: ['js-string'] };
const wasmJsStringImportModule = 'wasm:js-string';
const wasmJsStringShim = {
    length: (s) => (typeof s === 'string' ? s.length : 0),
    charCodeAt: (s, i) => {
        if (typeof s !== 'string') return 0;
        const index = Number(i);
        if (!Number.isInteger(index) || index < 0 || index >= s.length) return 0;
        return s.charCodeAt(index);
    },
    equals: (s1, s2) => s1 === s2,
    concat: (s1, s2) => `${s1 ?? ''}${s2 ?? ''}`,
    fromCodePoint: (cp) => {
        const codePoint = Number(cp);
        return Number.isFinite(codePoint) ? String.fromCodePoint(codePoint) : "";
    },
    fromCharCodeArray: (chars, start, end) => {
        const length = Number(chars?.length);
        if (!Number.isFinite(length) || length < 0) return "";
        const from = Math.max(0, Number(start) || 0);
        const to = Math.min(length, end == null ? length : (Number(end) || 0));
        let result = "";
        for (let i = from; i < to; i++) {
            result += String.fromCharCode(Number(chars[i]) || 0);
        }
        return result;
    },
};
const wasmStringGlobals = new Proxy({}, {
    get: (_, name) => typeof name === 'string' ? name : undefined,
});

let isPlaying = true;
let currentFrame = 0;
let lastTimestamp = 0;
let player = null;
let officialPlayer = null;
let currentJsonStr = "";
let currentFileName = "";
let currentFileSize = 0;
let imageAssetsByIndex = [];
let moonLottieRuntime = null;
let moonLottieBackend = "uninitialized";
let runtimePreference = 'auto';
let compareEnabled = true;
let currentSpeed = 1;
let currentBackground = 'grid';
let currentAnimationRequestId = null;
let currentAnimationData = null;
let currentAnimationMeta = null;
let currentExpressionAnimationData = null;
let currentExpressionMeta = null;
let sampleEntries = [];
let pendingCanvasResizeFrame = null;
let viewportResizeObserver = null;
const viewportTransform = {
    scale: 1,
    offsetX: 0,
    offsetY: 0,
    dpr: 1,
};

function getRuntimePreference() {
    const searchParams = new URLSearchParams(window.location.search);
    const runtimeParam = searchParams.get('runtime');
    if (runtimeParam === 'js' || runtimeParam === 'wasm' || runtimeParam === 'auto') {
        localStorage.setItem('moon-lottie-runtime', runtimeParam);
        return runtimeParam;
    }

    const storedPreference = localStorage.getItem('moon-lottie-runtime');
    if (storedPreference === 'js' || storedPreference === 'wasm' || storedPreference === 'auto') {
        return storedPreference;
    }

    return 'auto';
}

function describeRuntimePreference(preference) {
    if (preference === 'js') return 'JS';
    if (preference === 'wasm') return 'Wasm';
    return 'Auto';
}

function setStatusMessage(message) {
    console.log(`[Status] ${message}`);
}

function updateCurrentFileLabel() {
    currentFileNameEl.innerText = currentFileName || '选择一个样例或打开本地 JSON';
}

function updateRuntimeBadges() {
    const actual = moonLottieBackend === 'uninitialized'
        ? '未初始化'
        : (moonLottieBackend === 'wasm' ? 'Wasm' : 'JS');
    infoRuntimeEl.innerText = actual;
    runtimeButtons.forEach((button) => {
        button.classList.toggle('is-active', button.dataset.runtime === runtimePreference);
    });
}

function applyBackgroundSelection() {
    viewport.classList.remove('bg-white', 'bg-black');
    if (currentBackground === 'white') {
        viewport.classList.add('bg-white');
    } else if (currentBackground === 'black') {
        viewport.classList.add('bg-black');
    }
    bgButtons.forEach((button) => {
        button.classList.toggle('is-active', button.dataset.bg === currentBackground);
    });
}

function updateCompareUI() {
    compareToggle.classList.toggle('is-active', compareEnabled);
    compareToggle.setAttribute('aria-pressed', compareEnabled ? 'true' : 'false');
    officialWrapper.style.display = compareEnabled ? 'flex' : 'none';
    scheduleViewportRefresh();
}

function normalizeSpeed(value) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
        return currentSpeed;
    }
    return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10));
}

function updateSpeedInput() {
    speedInput.value = currentSpeed.toFixed(1);
    speedButtons.forEach(btn => {
        btn.classList.toggle('is-active', Math.abs(Number(btn.dataset.speed) - currentSpeed) < 0.01);
    });
}

function getCurrentSampleIndex() {
    return sampleEntries.findIndex((entry) => entry.file === currentFileName);
}

function stepAnimation(direction) {
    if (sampleEntries.length === 0) {
        return;
    }

    const currentIndex = getCurrentSampleIndex();
    const baseIndex = currentIndex >= 0 ? currentIndex : 0;
    const nextIndex = (baseIndex + direction + sampleEntries.length) % sampleEntries.length;
    const nextEntry = sampleEntries[nextIndex];
    localStorage.setItem('moon-lottie-last-anim', nextEntry.file);
    loadRemoteAnimation(nextEntry.file);
}

function openPlaylistDrawer() {
    document.body.classList.add('drawer-open');
    playlistDrawer.classList.add('is-open');
    playlistBackdrop.classList.add('is-open');
    playlistDrawer.setAttribute('aria-hidden', 'false');
}

function closePlaylistDrawer() {
    playlistDrawer.classList.remove('is-open');
    playlistBackdrop.classList.remove('is-open');
    playlistDrawer.setAttribute('aria-hidden', 'true');
    if (!detailsPanel.classList.contains('is-open')) {
        document.body.classList.remove('drawer-open');
    }
}

function openDetailsPanel() {
    document.body.classList.add('drawer-open');
    detailsPanel.classList.add('is-open');
    panelBackdrop.classList.add('is-open');
    detailsPanel.setAttribute('aria-hidden', 'false');
    detailsToggle.classList.add('is-active');
}

function closeDetailsPanel() {
    detailsPanel.classList.remove('is-open');
    panelBackdrop.classList.remove('is-open');
    detailsPanel.setAttribute('aria-hidden', 'true');
    detailsToggle.classList.remove('is-active');
    if (!playlistDrawer.classList.contains('is-open')) {
        document.body.classList.remove('drawer-open');
    }
}

function renderPlaylist() {
    const query = (playlistSearch.value || '').trim().toLowerCase();
    const filtered = sampleEntries.filter((entry) => {
        const searchText = `${entry.label} ${entry.file}`.toLowerCase();
        return !query || searchText.includes(query);
    });

    if (filtered.length === 0) {
        playlistList.innerHTML = '<div class="playlist-empty">没有匹配的样例。</div>';
        return;
    }

    playlistList.innerHTML = '';
    filtered.forEach((entry) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'playlist-item';
        if (entry.file === currentFileName) {
            button.classList.add('is-active');
        }
        button.innerHTML = `<span class="playlist-item__title">${entry.label}</span><span class="playlist-item__meta">${entry.file}</span>`;
        button.onclick = () => {
            localStorage.setItem('moon-lottie-last-anim', entry.file);
            closePlaylistDrawer();
            loadRemoteAnimation(entry.file);
        };
        playlistList.appendChild(button);
    });
}

async function restartCurrentAnimation() {
    if (!currentJsonStr && !currentAnimationData) {
        return;
    }
    const source = currentAnimationData ? JSON.stringify(currentAnimationData) : currentJsonStr;
    await startPlayer(source);
}

async function switchRuntime(preference) {
    if (preference !== 'auto' && preference !== 'wasm' && preference !== 'js') {
        return;
    }
    if (runtimePreference === preference && moonLottieRuntime) {
        return;
    }

    runtimePreference = preference;
    localStorage.setItem('moon-lottie-runtime', preference);
    updateRuntimeBadges();
    setStatusMessage(`切换运行时到 ${describeRuntimePreference(preference)}...`);

    try {
        if (preference === 'js') {
            const runtime = await loadJsRuntime();
            setActiveMoonLottieRuntime(runtime, 'js');
        } else if (preference === 'wasm') {
            const runtime = await loadWasmRuntime();
            setActiveMoonLottieRuntime(runtime, 'wasm');
        } else {
            try {
                const runtime = await loadWasmRuntime();
                setActiveMoonLottieRuntime(runtime, 'wasm');
            } catch (wasmErr) {
                console.warn('[MoonLottie] WASM runtime init failed during runtime switch, switching to JS runtime', wasmErr);
                const runtime = await loadJsRuntime();
                setActiveMoonLottieRuntime(runtime, 'js');
            }
        }

        updateRuntimeBadges();
        if (currentAnimationData) {
            await restartCurrentAnimation();
        } else {
            setStatusMessage(`已切换到 ${moonLottieBackend === 'wasm' ? 'Wasm' : 'JS'} 后端`);
        }
    } catch (error) {
        statusDot.style.background = '#ff3b30';
        setStatusMessage(`运行时切换失败: ${error.message}`);
    }
}

function readDevicePixelRatio() {
    return window.devicePixelRatio || 1;
}

function parsePixelValue(value) {
    const parsed = Number.parseFloat(value || '0');
    return Number.isFinite(parsed) ? parsed : 0;
}

function getWrapperChromeHeight(wrapper) {
    const head = wrapper.querySelector('.canvas-head');
    const wrapperStyle = window.getComputedStyle(wrapper);
    const gap = parsePixelValue(wrapperStyle.rowGap || wrapperStyle.gap);
    return Math.ceil((head?.offsetHeight || 0) + gap);
}

function fitStage(maxWidth, maxHeight, aspectRatio) {
    if (maxWidth <= 0 || maxHeight <= 0 || aspectRatio <= 0) {
        return { width: 0, height: 0, area: 0 };
    }

    const width = Math.min(maxWidth, maxHeight * aspectRatio);
    const height = width / aspectRatio;

    return {
        width,
        height,
        area: width * height,
    };
}

function applyWrapperLayout(wrapper, stage, width, height) {
    if (!wrapper || !stage) {
        return;
    }

    const chromeHeight = getWrapperChromeHeight(wrapper);
    wrapper.style.flex = '0 0 auto';
    wrapper.style.width = `${Math.max(0, width)}px`;
    wrapper.style.height = `${Math.max(0, chromeHeight + height)}px`;
    stage.style.width = `${Math.max(0, width)}px`;
    stage.style.height = `${Math.max(0, height)}px`;
}

function resetWrapperLayout(wrapper, stage) {
    if (!wrapper || !stage) {
        return;
    }

    wrapper.style.flex = '';
    wrapper.style.width = '';
    wrapper.style.height = '';
    stage.style.width = '';
    stage.style.height = '';
}

function layoutViewport(meta) {
    const animWidth = meta?.width || canvas.width || 1;
    const animHeight = meta?.height || canvas.height || 1;
    const aspectRatio = animWidth / animHeight;
    const viewportStyle = window.getComputedStyle(viewport);
    const horizontalPadding = parsePixelValue(viewportStyle.paddingLeft) + parsePixelValue(viewportStyle.paddingRight);
    const verticalPadding = parsePixelValue(viewportStyle.paddingTop) + parsePixelValue(viewportStyle.paddingBottom);
    const gap = parsePixelValue(viewportStyle.columnGap || viewportStyle.gap);
    const availableWidth = Math.max(0, viewport.clientWidth - horizontalPadding);
    const availableHeight = Math.max(0, viewport.clientHeight - verticalPadding);
    const compareActive = compareEnabled;
    const wasmChrome = getWrapperChromeHeight(wasmWrapper);
    const officialChrome = compareActive ? getWrapperChromeHeight(officialWrapper) : 0;
    const chromeHeight = Math.max(wasmChrome, officialChrome);

    let direction = 'row';
    let stageSize = fitStage(availableWidth, availableHeight - chromeHeight, aspectRatio);

    if (compareActive) {
        const rowStage = fitStage(
            (availableWidth - gap) / 2,
            availableHeight - chromeHeight,
            aspectRatio,
        );
        const columnStage = fitStage(
            availableWidth,
            (availableHeight - gap) / 2 - chromeHeight,
            aspectRatio,
        );

        if (columnStage.area > rowStage.area) {
            direction = 'column';
            stageSize = columnStage;
        } else {
            direction = 'row';
            stageSize = rowStage;
        }
    }

    viewport.style.flexDirection = direction;

    applyWrapperLayout(wasmWrapper, wasmStage, stageSize.width, stageSize.height);
    canvas.style.width = `${Math.max(0, stageSize.width)}px`;
    canvas.style.height = `${Math.max(0, stageSize.height)}px`;

    if (compareActive) {
        applyWrapperLayout(officialWrapper, officialStage, stageSize.width, stageSize.height);
        officialContainer.style.width = `${Math.max(0, stageSize.width)}px`;
        officialContainer.style.height = `${Math.max(0, stageSize.height)}px`;
    } else {
        resetWrapperLayout(officialWrapper, officialStage);
        officialContainer.style.width = '';
        officialContainer.style.height = '';
    }

    return stageSize;
}

function updateViewportTransform(meta) {
    const animWidth = meta?.width || canvas.width || 100;
    const animHeight = meta?.height || canvas.height || 100;
    const stageSize = layoutViewport(meta);
    const dpr = readDevicePixelRatio();
    const viewportWidth = stageSize.width > 0 ? stageSize.width : animWidth;
    const viewportHeight = stageSize.height > 0 ? stageSize.height : animHeight;
    const scale = Math.min(viewportWidth / animWidth, viewportHeight / animHeight) || 1;

    viewportTransform.scale = scale;
    viewportTransform.offsetX = (viewportWidth - animWidth * scale) / 2;
    viewportTransform.offsetY = (viewportHeight - animHeight * scale) / 2;
    viewportTransform.dpr = dpr;

    return {
        width: viewportWidth,
        height: viewportHeight,
        dpr,
    };
}

let lastMetadata = null;

function scheduleViewportRefresh() {
    if (!lastMetadata || pendingCanvasResizeFrame !== null) {
        return;
    }

    pendingCanvasResizeFrame = requestAnimationFrame(() => {
        pendingCanvasResizeFrame = null;
        if (!lastMetadata) {
            return;
        }
        applyAnimationMetadata(lastMetadata);
        renderCurrentFrame();
    });
}

// Canvas FFI implementation (省略大部分不变的渲染逻辑，直接进入业务逻辑控制)
let currentGradient = null;
let currentDash = [];
const fillRuleStack = [];
/**
 * @typedef {Object} OffscreenEntry
 * @property {CanvasRenderingContext2D} savedCtx
 * @property {HTMLCanvasElement} offscreen
 * @property {number} savedOpacity
 * @property {HTMLCanvasElement|null} matteContent
 * @property {{
 *   contentCtx: CanvasRenderingContext2D,
 *   maskCanvas: HTMLCanvasElement,
 *   maskCtx: CanvasRenderingContext2D,
 *   pathCanvas: HTMLCanvasElement,
 *   pathCtx: CanvasRenderingContext2D,
 *   hasMask: boolean,
 * } | null} maskState
 */
const offscreenStack = [];
// Stack for two-buffer track matte compositing (lottie-web prepareLayer/exitLayer pattern)
const matteStack = [];
const expressionModule = createExpressionModule({
    getAnimationData: () => currentExpressionAnimationData,
    getPlaybackMeta: () => currentExpressionMeta,
});

window.setMoonLottieExpressionHost = setExpressionHost;
if (window.__moonLottieExpressionHost) {
    setExpressionHost(window.__moonLottieExpressionHost);
}

function createBlankCanvasLike(doc, sourceCanvas) {
    const buffer = doc.createElement('canvas');
    buffer.width = sourceCanvas?.width || 0;
    buffer.height = sourceCanvas?.height || 0;
    return buffer;
}

/** @returns {OffscreenEntry|null} */
function getCurrentOffscreenEntry() {
    return offscreenStack.length > 0 ? offscreenStack[offscreenStack.length - 1] : null;
}

const importObject = {
  demo: {
    get_json_string: () => currentJsonStr,
    log_frame: (f) => {
        // if (Math.floor(f) % 30 === 0) console.log("WASM Frame:", f);
    }
  },
  _: wasmStringGlobals,
  expressions: expressionModule,
  spectest: { print_char: (c) => {} },
  canvas: {
    save: () => { ctx.save(); fillRuleStack.push(ctx._currentFillRule || "nonzero"); },
    restore: () => { ctx.restore(); ctx._currentFillRule = fillRuleStack.pop() || "nonzero"; },
    beginPath: () => ctx.beginPath(),
    closePath: () => ctx.closePath(),
    moveTo: (x, y) => ctx.moveTo(x, y),
    lineTo: (x, y) => ctx.lineTo(x, y),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
    fill: (r, g, b, a) => { 
        ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = `rgb(${r},${g},${b})`; 
        ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore();
    },
    stroke: (r, g, b, a, width) => { 
        ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = `rgb(${r},${g},${b})`; 
        ctx.lineWidth = width; ctx.stroke(); ctx.restore();
    },
    setStrokeStyle: (cap, join, miter) => {
        const caps = ["butt", "round", "square"]; const joins = ["miter", "round", "bevel"];
        ctx.lineCap = caps[cap - 1] || "butt"; ctx.lineJoin = joins[join - 1] || "miter"; ctx.miterLimit = miter;
    },
    beginDash: () => { currentDash = []; },
    addDash: (value) => { currentDash.push(value); },
    applyDash: (offset) => { ctx.setLineDash(currentDash); ctx.lineDashOffset = offset; },
    setFillRule: (rule) => { ctx._currentFillRule = rule; },
    createLinearGradient: (x1, y1, x2, y2) => { currentGradient = ctx.createLinearGradient(x1, y1, x2, y2); },
    createRadialGradient: (cx, cy, r, fx, fy, fr) => { currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r); },
    addGradientStop: (offset, r, g, b, a) => { if (currentGradient) currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`); },
    fillGradient: (a) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = currentGradient; ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore(); } },
    strokeGradient: (a, w) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = currentGradient; ctx.lineWidth = w; ctx.stroke(); ctx.restore(); } },
    clip: () => ctx.clip(ctx._currentFillRule || "nonzero"),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
    setOpacity: (a) => { ctx.globalAlpha *= a; },
    setTransform: (a, b, c, d, e, f) => {
        const { scale, offsetX, offsetY, dpr } = viewportTransform;
        ctx.setTransform(
            a * scale * dpr,
            b * scale * dpr,
            c * scale * dpr,
            d * scale * dpr,
            (e * scale + offsetX) * dpr,
            (f * scale + offsetY) * dpr,
        );
    },
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (assetIndex, w, h) => {
        const img = imageAssetsByIndex[assetIndex] || null;
        if (img) ctx.drawImage(img, 0, 0, w, h);
    },
    drawText: (text, font, size, r, g, b, a, justify) => {
        ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = `rgb(${r},${g},${b})`;
        ctx.font = `${size}px ${font || 'Arial'}`;
        const aligns = ["left", "right", "center"]; ctx.textAlign = aligns[justify] || "left";
        ctx.fillText(text, 0, 0); ctx.restore();
    },
    supportsMaskComposite: () => true,
    setGlobalCompositeOperation: (mode) => {
        const modeStr = mode;
        // Alpha matte (tt=1) fix: match lottie-web's buffer approach exactly.
        // lottie-web saves layer content to buffer1, clears the canvas, renders the matte
        // with source-over, then applies source-in with buffer1 so that ALL canvas pixels
        // are zeroed outside the matte region.  A plain destination-in drawImage only
        // affects pixels within the drawn primitive's bounding box – everything else
        // would bleed through unchanged, causing the dark-Bg-fills-canvas bug.
        //
        // The guard `offscreenStack.length > 0` ensures this only applies inside an
        // isolated layer (beginLayer context).  Alpha mattes in moon-lottie always
        // trigger beginLayer for the matted layer, so this guard is always satisfied.
        // matteContent is stored on the current offscreen stack entry so that nested
        // layers (e.g. a matte source with its own fill effect) do not accidentally
        // consume each other's saved buffers.
        if (modeStr === 'destination-in' && offscreenStack.length > 0) {
            const entry = offscreenStack[offscreenStack.length - 1];
            const w = ctx.canvas.width;
            const h = ctx.canvas.height;
            // Step 1: snapshot the current layer content at identity pixel coordinates.
            const contentBuffer = document.createElement('canvas');
            contentBuffer.width = w;
            contentBuffer.height = h;
            contentBuffer.getContext('2d').drawImage(ctx.canvas, 0, 0);
            // Step 2: clear the offscreen so the matte renders onto a blank surface.
            ctx.save();
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(0, 0, w, h);
            ctx.restore();
            entry.matteContent = contentBuffer;
            // Leave globalCompositeOperation as source-over so the matte draws normally.
        } else if (modeStr === 'source-over' && offscreenStack.length > 0 &&
                   offscreenStack[offscreenStack.length - 1].matteContent !== null) {
            // The matte has just been rendered onto the cleared offscreen with source-over.
            // Apply lottie-web's source-in step: draw the saved layer content through the
            // matte.  Because the saved buffer is full-canvas size, source-in processes
            // every pixel – zeroing anything outside the matte region.
            const entry = offscreenStack[offscreenStack.length - 1];
            const buf = entry.matteContent;
            entry.matteContent = null;
            ctx.save();
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.globalCompositeOperation = 'source-in';
            ctx.drawImage(buf, 0, 0);
            ctx.restore();
            // restore() returns the transform to what it was just before this save().
            // globalCompositeOperation is also restored to its pre-save value (source-over,
            // since we did not change it between clearing the offscreen and now).
        } else {
            ctx.globalCompositeOperation = modeStr;
        }
    },
    beginLayer: () => {
        // Create an offscreen canvas for isolated compositing (track matte support).
        // We copy the current accumulated transform so drawing coordinates are unchanged.
        // matteContent holds the saved layer pixels during the destination-in matte phase
        // (see setGlobalCompositeOperation); it is null when no matte phase is active.
        const offscreen = document.createElement('canvas');
        offscreen.width = canvas.width;
        offscreen.height = canvas.height;
        const offCtx = offscreen.getContext('2d');
        const t = ctx.getTransform();
        offCtx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
        offscreenStack.push({
            savedCtx: ctx,
            offscreen,
            savedOpacity: ctx.globalAlpha,
            matteContent: null,
            maskState: null,
        });
        ctx = offCtx;
        ctx.globalAlpha = 1.0;
    },
    endLayer: (mode) => {
        if (offscreenStack.length === 0) return;
        const { savedCtx, offscreen, savedOpacity } = offscreenStack.pop();
        // Composite the offscreen layer onto the main canvas using identity transform.
        savedCtx.save();
        savedCtx.setTransform(1, 0, 0, 1, 0, 0);
        savedCtx.globalCompositeOperation = mode;
        savedCtx.globalAlpha = savedOpacity;
        savedCtx.drawImage(offscreen, 0, 0);
        savedCtx.restore();
        ctx = savedCtx;
    },
    beginMaskComposite: () => {
        const entry = getCurrentOffscreenEntry();
        if (!entry || entry.maskState) return;
        const sourceCanvas = ctx?.canvas || entry.offscreen;
        const maskCanvas = createBlankCanvasLike(document, sourceCanvas);
        const pathCanvas = createBlankCanvasLike(document, sourceCanvas);
        const workCanvas = createBlankCanvasLike(document, sourceCanvas);
        entry.maskState = {
            contentCtx: ctx,
            maskCanvas,
            maskCtx: maskCanvas.getContext('2d'),
            pathCanvas,
            pathCtx: pathCanvas.getContext('2d'),
            workCanvas,
            workCtx: workCanvas.getContext('2d'),
            hasMask: false,
        };
    },
    beginMaskPath: () => {
        const entry = getCurrentOffscreenEntry();
        const state = entry?.maskState;
        if (!state || !state.pathCtx) return;
        const contentCtx = state.contentCtx || ctx;
        const currentTransform = contentCtx.getTransform();
        const fillRule = contentCtx._currentFillRule || "nonzero";
        state.contentCtx = contentCtx;
        state.pathCtx.setTransform(1, 0, 0, 1, 0, 0);
        state.pathCtx.clearRect(0, 0, state.pathCanvas.width, state.pathCanvas.height);
        state.pathCtx.setTransform(
            currentTransform.a,
            currentTransform.b,
            currentTransform.c,
            currentTransform.d,
            currentTransform.e,
            currentTransform.f,
        );
        state.pathCtx.globalAlpha = 1.0;
        state.pathCtx.globalCompositeOperation = 'source-over';
        state.pathCtx._currentFillRule = fillRule;
        ctx = state.pathCtx;
    },
    applyMaskPath: (mode, opacity, inverted, expansion) => {
        const entry = getCurrentOffscreenEntry();
        const state = entry?.maskState;
        if (!state || !state.pathCtx || !state.maskCtx || !state.workCtx) return;
        const rule = state.pathCtx._currentFillRule || "nonzero";
        rasterizeMaskPath(state.pathCtx, state.workCtx, rule, opacity, inverted, expansion);

        state.maskCtx.save();
        state.maskCtx.setTransform(1, 0, 0, 1, 0, 0);
        if (!state.hasMask) {
            state.maskCtx.clearRect(0, 0, state.maskCanvas.width, state.maskCanvas.height);
            if (mode === 2) {
                state.maskCtx.globalCompositeOperation = 'source-over';
                state.maskCtx.globalAlpha = 1.0;
                state.maskCtx.fillStyle = '#ffffff';
                state.maskCtx.fillRect(0, 0, state.maskCanvas.width, state.maskCanvas.height);
                state.maskCtx.globalCompositeOperation = 'destination-out';
                state.maskCtx.drawImage(state.pathCanvas, 0, 0);
            } else {
                state.maskCtx.globalCompositeOperation = 'source-over';
                state.maskCtx.globalAlpha = 1.0;
                state.maskCtx.drawImage(state.pathCanvas, 0, 0);
            }
            state.hasMask = true;
        } else {
            let compositeOp = null;
            switch (mode) {
                case 1:
                    compositeOp = 'source-over';
                    break;
                case 2:
                    compositeOp = 'destination-out';
                    break;
                case 3:
                    compositeOp = 'destination-in';
                    break;
                default:
                    compositeOp = null;
                    break;
            }
            if (compositeOp) {
                // Known follow-up: inverted masks in the composite path are not
                // fully aligned with lottie-web yet (e.g. 4_cactus.json frame 8).
                state.maskCtx.globalCompositeOperation = compositeOp;
                state.maskCtx.globalAlpha = 1.0;
                state.maskCtx.drawImage(state.pathCanvas, 0, 0);
            }
        }
        state.maskCtx.restore();
        ctx = state.contentCtx;
    },
    endMaskComposite: () => {
        const entry = getCurrentOffscreenEntry();
        const state = entry?.maskState;
        if (!state || !state.contentCtx) return;
        if (state.hasMask) {
            state.contentCtx.save();
            state.contentCtx.setTransform(1, 0, 0, 1, 0, 0);
            state.contentCtx.globalCompositeOperation = 'destination-in';
            state.contentCtx.drawImage(state.maskCanvas, 0, 0);
            state.contentCtx.restore();
        }
        entry.maskState = null;
        ctx = state.contentCtx;
    },
    // Two-buffer track matte compositing (lottie-web prepareLayer/exitLayer pattern).
    // Called before save() and layer transforms: saves background to buffer[0],
    // captures currentTransform, clears canvas.
    prepareMatteLayer: () => {
        const currentTransform = ctx.getTransform();
        const { buffer: buf0 } = cloneActiveCanvas(document, ctx, canvas);
        clearActiveCanvas(ctx, currentTransform, canvas);
        matteStack.push({ buf0, buf1: null, currentTransform });
    },
    // Called after restore(): saves layer content to buffer[1],
    // clears canvas, restores base transform for matte source rendering.
    beginMatteExit: () => {
        if (matteStack.length === 0) return;
        const state = matteStack[matteStack.length - 1];
        const { buffer: buf1 } = cloneActiveCanvas(document, ctx, canvas);
        state.buf1 = buf1;
        clearActiveCanvas(ctx, state.currentTransform, canvas);
    },
    // Called after matte source has been rendered on canvas.
    // Composites: source-in(layer content, matte), destination-over(background), restore.
    endMatteExit: (matte_type) => {
        if (matteStack.length === 0) return;
        const { buf0, buf1, currentTransform } = matteStack.pop();
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        // operationsMap: 1=source-in, 2=source-out, 3=source-in, 4=source-out
        const compositeOp = (matte_type === 1 || matte_type === 3) ? 'source-in' : 'source-out';
        ctx.globalCompositeOperation = compositeOp;
        ctx.drawImage(buf1, 0, 0);
        ctx.globalCompositeOperation = 'destination-over';
        ctx.drawImage(buf0, 0, 0);
        ctx.setTransform(currentTransform);
        ctx.globalCompositeOperation = 'source-over';
    }
  }
};

function getActiveMoonLottieRuntime() {
        return moonLottieRuntime || window.moonLottie || null;
}

function setActiveMoonLottieRuntime(runtime, backend) {
        moonLottieRuntime = runtime;
        moonLottieBackend = backend;
        window.moonLottie = runtime;
        window.moonLottieBackend = backend;
}

function installJsRuntimeGlobals() {
        window.demo = importObject.demo;
        window.canvas = importObject.canvas;
        window.expressions = expressionModule;
}

async function loadWasmRuntime() {
    const wasmPath = 'runtime/wasm/moon-lottie-runtime.wasm';
        console.log(`[MoonLottie] Fetching WASM from: ${wasmPath}`);
        const response = await fetch(wasmPath, { cache: 'no-store' });
        if (!response.ok) throw new Error("WASM not found");

        const buffer = await response.arrayBuffer();
        const finalImportObject = {
            ...importObject,
            [wasmJsStringImportModule]: wasmJsStringShim,
        };

        try {
            const module = await WebAssembly.compile(buffer, wasmBuiltinOptions);
            const instance = await WebAssembly.instantiate(module, importObject, wasmBuiltinOptions);
            return instance.exports;
        } catch (builtinErr) {
            console.warn('[MoonLottie] Wasm builtin string path failed, retrying with shim fallback', builtinErr);
            const module = await WebAssembly.compile(buffer);
            const instance = await WebAssembly.instantiate(module, finalImportObject);
            return instance.exports;
        }
}

async function loadJsRuntime() {
        installJsRuntimeGlobals();
    const moduleUrl = new URL('./runtime/js/moon-lottie-runtime.js', import.meta.url);
        console.warn(`[MoonLottie] Falling back to JS runtime: ${moduleUrl.href}`);
        return import(moduleUrl.href);
}

async function init() {
  try {
        runtimePreference = getRuntimePreference();
        updateCurrentFileLabel();
        applyBackgroundSelection();
        updateCompareUI();
        updateSpeedInput();
        updateRuntimeBadges();
        setStatusMessage('初始化 MoonLottie 运行时...');
    console.log(`[MoonLottie] Runtime preference: ${describeRuntimePreference(runtimePreference)}`);

    if (runtimePreference === 'js') {
        const runtime = await loadJsRuntime();
        setActiveMoonLottieRuntime(runtime, 'js');
    } else if (runtimePreference === 'wasm') {
        const runtime = await loadWasmRuntime();
        setActiveMoonLottieRuntime(runtime, 'wasm');
    } else {
        try {
            const runtime = await loadWasmRuntime();
            setActiveMoonLottieRuntime(runtime, 'wasm');
        } catch (wasmErr) {
            console.warn('[MoonLottie] WASM runtime init failed, switching to JS runtime', wasmErr);
            const runtime = await loadJsRuntime();
            setActiveMoonLottieRuntime(runtime, 'js');
        }
        }

    statusDot.style.background = "#34c759"; // Green
        updateRuntimeBadges();
        setStatusMessage(moonLottieBackend === 'wasm'
            ? `已就绪，请打开 Lottie JSON (${describeRuntimePreference(runtimePreference)})`
            : `已就绪，当前使用 JS 兼容后端 (${describeRuntimePreference(runtimePreference)})`);
    
    // 动态加载动画列表
    await initAnimList();
  } catch (err) {
    statusDot.style.background = "#ff3b30"; // Red
        setStatusMessage("错误: " + err.message);
  }
}

function destroyOfficialPlayer() {
    if (officialPlayer) {
        officialPlayer.destroy();
        officialPlayer = null;
    }
    officialContainer.innerHTML = '';
}

function cloneAnimationData(animationData) {
    if (typeof structuredClone !== 'undefined') {
        return structuredClone(animationData);
    }
    try {
        return JSON.parse(JSON.stringify(animationData));
    } catch (error) {
        console.warn('[MoonLottie] Failed to clone animation data for expression isolation; continuing with shared state may reintroduce expression mismatches', error);
        return animationData;
    }
}

function createOfficialPlayer(animationData) {
    if (!window.lottie || typeof window.lottie.loadAnimation !== 'function') {
        return null;
    }

    destroyOfficialPlayer();

    try {
        officialPlayer = window.lottie.loadAnimation({
            container: officialContainer,
            renderer: 'svg',
            loop: false,
            autoplay: false,
            animationData,
            rendererSettings: {
                preserveAspectRatio: 'xMidYMid meet',
                clearCanvas: true,
            },
        });
        return officialPlayer;
    } catch (e) {
        console.warn("Official renderer init failed:", e);
        officialPlayer = null;
        return null;
    }
}

function renderCurrentFrame() {
    const runtime = getActiveMoonLottieRuntime();
    if (player && runtime) {
        ctx.save();
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        runtime.update_player(player, currentFrame);
        ctx.restore();
    }

    if (officialPlayer) {
        officialPlayer.goToAndStop(currentFrame, true);
    }
}

function applyAnimationMetadata(meta) {
    lastMetadata = meta;
    const { width, height, fps, totalFrames, inPoint, aspectRatio, version } = meta;

    wasmStage.style.aspectRatio = aspectRatio;
    officialStage.style.aspectRatio = aspectRatio;
    officialContainer.style.aspectRatio = aspectRatio;

    const viewportSize = updateViewportTransform(meta);
    resizeCanvasForDpr(canvas, viewportSize.width, viewportSize.height, viewportSize.dpr);

    document.getElementById('info-filename').innerText = currentFileName || "未知";
    document.getElementById('info-filesize').innerText = (currentFileSize / 1024).toFixed(2) + " KB";
    document.getElementById('info-size').innerText = `${width} x ${height}`;
    document.getElementById('info-fps').innerText = fps.toFixed(2) + " fps";
    document.getElementById('info-total-frames').innerText = Math.floor(totalFrames);
    document.getElementById('info-duration').innerText = fps > 0 ? (totalFrames / fps).toFixed(2) + "s" : "-";
    document.getElementById('info-version').innerText = version;
    updateCurrentFileLabel();

    seekBar.min = inPoint;
    seekBar.max = inPoint + totalFrames;
    seekBar.value = inPoint;
}

async function initAnimList() {
    try {
        const response = await fetch('sample_index.json');
        
        let entries = [];
        if (response.ok) {
            entries = await response.json();
        } else {
            console.warn("sample_index.json not found, using default fallback");
            entries = [{ file: '1-1 Super Mario.json', label: '1-1 Super Mario' }];
        }

        sampleEntries = entries.map((entry) => {
            const file = typeof entry === 'object' ? entry.file : entry;
            const label = (typeof entry === 'object' ? (entry.label || entry.file) : entry).replace(/\.json$/i, '');
            return { file, label };
        });
        renderPlaylist();
        
        const lastSelected = localStorage.getItem('moon-lottie-last-anim');
        const hasLastInList = lastSelected && sampleEntries.some((entry) => entry.file === lastSelected);
        
        if (hasLastInList) {
            loadRemoteAnimation(lastSelected);
        } else if (sampleEntries.length > 0) {
            loadRemoteAnimation(sampleEntries[0].file);
        }
    } catch (e) {
        console.error("Failed to initialize animation list:", e);
        // Minimal fallback to ensure something is loaded
        loadSample();
    }
}

function loadSample() {
    loadRemoteAnimation('1_1_Super_Mario.json');
}

function loadRemoteAnimation(filename) {
    // 始终从本地 samples 目录加载，该目录由 sync-assets.js 自动从根目录同步
    const encodedName = encodeURIComponent(filename);
    const path = `samples/${encodedName}`;
    
    console.log(`[MoonLottie] Fetching animation from: ${path}`);
    fetch(path, { cache: 'no-store' }).then(r => {
        if (!r.ok) throw new Error(`HTTP error! status: ${r.status}`);
        currentFileName = filename;
        updateCurrentFileLabel();
        renderPlaylist();
        return r.blob();
    }).then(blob => {
        currentFileSize = blob.size;
        return blob.text();
    }).then(text => {
        startPlayer(text);
    }).catch(e => {
        console.warn(`Failed to load ${filename} from ${path}:`, e.message);
    });
}

function resolveAssetSrc(asset) {
    const p = asset.p || '';
    const u = asset.u || '';
    return p === '' ? asset.id : (u + p);
}

async function preloadAssets(json) {
    if (!json.assets) return;
    setStatusMessage("正在加载资源文件...");
    imageAssetsByIndex = new Array(json.assets.length).fill(null);
    const promises = json.assets.map((asset, index) => {
        if (asset.p) {
            return new Promise((resolve) => {
                const img = new Image();
                img.onload = () => {
                    imageAssetsByIndex[index] = img;
                    resolve();
                };
                img.onerror = resolve;
                img.src = resolveAssetSrc(asset);
            });
        }
        return Promise.resolve();
    });
    await Promise.all(promises);
}

async function startPlayer(jsonStr) {
    let animationData;
    try { animationData = JSON.parse(jsonStr); } catch (e) { alert("无效的 JSON 文件"); return; }
    const runtime = getActiveMoonLottieRuntime();
    if (!runtime) {
        setStatusMessage("运行时尚未初始化");
        return;
    }

    console.log(`[MoonLottie] Starting new animation: ${currentFileName}`);
    setStatusMessage("初始化渲染引擎...");
    currentAnimationData = animationData;
    currentAnimationMeta = getAnimationPlaybackMeta(animationData);
    currentExpressionAnimationData = cloneAnimationData(animationData);
    currentExpressionMeta = getAnimationPlaybackMeta(currentExpressionAnimationData);
    const usesExpressions = animationUsesExpressions(animationData);
    
    // Stop any existing render loop and reset timing
    if (currentAnimationRequestId) {
        console.log(`[MoonLottie] Cancelling existing animation loop (ID: ${currentAnimationRequestId})`);
        cancelAnimationFrame(currentAnimationRequestId);
        currentAnimationRequestId = null;
    }
    lastTimestamp = 0; 

    destroyOfficialPlayer();
    player = null;

    await preloadAssets(animationData);
    // For embedded image assets, pass id-only metadata to Wasm to avoid copying huge base64 strings.
    // The actual image data has already been preloaded into imageAssetsByIndex by JS.
    const wasmAnimationData = cloneAnimationData(animationData);
    if (wasmAnimationData.assets) {
        wasmAnimationData.assets.forEach(asset => {
            if (asset && asset.e === 1 && typeof asset.p === 'string' && asset.p.startsWith('data:')) {
                asset.p = '';
            }
        });
    }
    currentJsonStr = JSON.stringify(wasmAnimationData);
    player = runtime.create_player_from_js();
    if (!player) {
        setStatusMessage("动画解析失败");
        return;
    }
    if (compareEnabled) {
        createOfficialPlayer(animationData);
    }
    setExpressionHost(null);
    updateCompareUI();
    applyAnimationMetadata(currentAnimationMeta);
    currentFrame = currentAnimationMeta.inPoint;
    isPlaying = true;
    lastTimestamp = performance.now();
    updatePlayPauseButton();
    renderCurrentFrame();

    if (usesExpressions) {
        setStatusMessage("检测到 expressions，moon-lottie 将通过内置 JS 表达式宿主执行表达式");
    } else {
        const backendLabel = moonLottieBackend === 'wasm' ? 'Wasm' : 'JS';
        setStatusMessage(`正在播放 (${backendLabel}): ` + (animationData.nm || "未命名动画"));
    }
    renderPlaylist();
    
    currentAnimationRequestId = requestAnimationFrame(renderLoop);
    console.log(`[MoonLottie] New animation loop started (ID: ${currentAnimationRequestId})`);
}

function renderLoop(timestamp) {
    if (!player) return;
    
    if (isPlaying) {
        if (!lastTimestamp) {
            console.log(`[MoonLottie] Render loop iteration starting with new timestamp: ${timestamp}`);
            lastTimestamp = timestamp;
        }
        const deltaTime = (timestamp - lastTimestamp) / 1000;
        lastTimestamp = timestamp;

        const fps = currentAnimationMeta?.fps || 0;
        const speed = currentSpeed;
        
        // 基于真实时间计算应该前进的帧数
        // delta_frames = delta_time(s) * fps * speed
        const frameDelta = deltaTime * fps * speed;
        
        currentFrame += frameDelta;
        
        const inPoint = currentAnimationMeta?.inPoint || 0;
        const totalFrames = currentAnimationMeta?.totalFrames || 0;
        if (currentFrame >= inPoint + totalFrames) currentFrame = inPoint;

        renderCurrentFrame();
        updateUI();
    } else {
        lastTimestamp = 0;
    }
    
    currentAnimationRequestId = requestAnimationFrame(renderLoop);
}

function updateUI() {
    const inPoint = currentAnimationMeta?.inPoint || 0;
    const totalFrames = currentAnimationMeta?.totalFrames || 0;
    const relativeFrame = currentFrame - inPoint;
    frameInfoEl.innerText = `${Math.floor(relativeFrame)} / ${Math.floor(totalFrames)}`;
    seekBar.value = currentFrame;
}

function updatePlayPauseButton() {
    playPauseBtn.innerText = isPlaying ? "‖" : "▶";
}

function isEditableTarget(target) {
    return target instanceof HTMLInputElement
        || target instanceof HTMLTextAreaElement
        || target instanceof HTMLSelectElement
        || target?.isContentEditable;
}

// UI Event Handlers
seekBar.oninput = () => {
    if (!player) return;
    currentFrame = parseFloat(seekBar.value);
    renderCurrentFrame();
    updateUI();
};

playPauseBtn.onclick = () => {
    isPlaying = !isPlaying;
    updatePlayPauseButton();
};

prevFrameBtn.onclick = () => {
    if (!player || !currentAnimationMeta) return;
    isPlaying = false;
    currentFrame = Math.max(currentAnimationMeta.inPoint, currentFrame - 1);
    renderCurrentFrame();
    updateUI();
    updatePlayPauseButton();
};

nextFrameBtn.onclick = () => {
    if (!player || !currentAnimationMeta) return;
    isPlaying = false;
    const endFrame = currentAnimationMeta.inPoint + currentAnimationMeta.totalFrames;
    currentFrame = Math.min(endFrame, currentFrame + 1);
    renderCurrentFrame();
    updateUI();
    updatePlayPauseButton();
};

prevAnimationBtn.onclick = () => {
    stepAnimation(-1);
};

nextAnimationBtn.onclick = () => {
    stepAnimation(1);
};

window.addEventListener('keydown', (e) => {
    if (isEditableTarget(e.target)) {
        return;
    }

    if (e.code === 'Space') {
        isPlaying = !isPlaying;
        updatePlayPauseButton();
        e.preventDefault();
    } else if (e.code === 'Escape') {
        closePlaylistDrawer();
        closeDetailsPanel();
    } else if (e.code === 'ArrowLeft') {
        prevFrameBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowRight') {
        nextFrameBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowUp') {
        prevAnimationBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowDown') {
        nextAnimationBtn.click();
        e.preventDefault();
    }
});

speedInput.onchange = () => {
    currentSpeed = normalizeSpeed(speedInput.value);
    updateSpeedInput();
};

speedInput.onblur = () => {
    currentSpeed = normalizeSpeed(speedInput.value);
    updateSpeedInput();
};

// Speed Shortcuts
speedButtons.forEach((btn) => {
    btn.onclick = () => {
        currentSpeed = parseFloat(btn.dataset.speed);
        updateSpeedInput();
    };
});

// Bg Switcher
bgButtons.forEach((btn) => {
    btn.onclick = () => {
        currentBackground = btn.dataset.bg || 'grid';
        applyBackgroundSelection();
    };
});

// Comparison Toggle
compareToggle.onclick = () => {
    compareEnabled = !compareEnabled;
    updateCompareUI();

    if (!currentAnimationData) return;

    if (compareEnabled) {
        createOfficialPlayer(currentAnimationData);
    } else {
        destroyOfficialPlayer();
    }
    renderCurrentFrame();
    updateUI();
};

runtimeButtons.forEach((button) => {
    button.onclick = () => {
        switchRuntime(button.dataset.runtime);
    };
});

playlistToggle.onclick = openPlaylistDrawer;
playlistClose.onclick = closePlaylistDrawer;
playlistBackdrop.onclick = closePlaylistDrawer;
playlistSearch.oninput = () => renderPlaylist();

detailsToggle.onclick = () => {
    if (detailsPanel.classList.contains('is-open')) {
        closeDetailsPanel();
    } else {
        openDetailsPanel();
    }
};
detailsClose.onclick = closeDetailsPanel;
panelBackdrop.onclick = closeDetailsPanel;

openFileBtn.onclick = () => fileInput.click();

window.addEventListener('resize', scheduleViewportRefresh);

if (typeof ResizeObserver === 'function') {
    viewportResizeObserver = new ResizeObserver(() => {
        scheduleViewportRefresh();
    });
    viewportResizeObserver.observe(viewport);
}

function initDeployTime() {
    const deployTimeEl = document.getElementById('deploy-time');
    if (deployTimeEl && deployTimeEl.dataset.utc) {
        const utcStr = deployTimeEl.dataset.utc;
        const date = new Date(utcStr);
        if (!isNaN(date.getTime())) {
            deployTimeEl.innerText = date.toLocaleString();
            deployTimeEl.title = `UTC: ${utcStr}`;
        }
    }
}

fileInput.onchange = (e) => {
    const file = e.target.files[0];
    if (file) handleFile(file);
    fileInput.value = '';
};

window.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropOverlay.classList.add('is-open');
    dropOverlay.setAttribute('aria-hidden', 'false');
});

window.addEventListener('dragleave', (e) => {
    if (e.clientX === 0 && e.clientY === 0) {
        dropOverlay.classList.remove('is-open');
        dropOverlay.setAttribute('aria-hidden', 'true');
    }
});

window.addEventListener('drop', (e) => {
    e.preventDefault();
    dropOverlay.classList.remove('is-open');
    dropOverlay.setAttribute('aria-hidden', 'true');
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
});

function handleFile(file) {
    currentFileName = file.name;
    currentFileSize = file.size;
    updateCurrentFileLabel();
    renderPlaylist();
    closePlaylistDrawer();
    const reader = new FileReader();
    reader.onload = (e) => startPlayer(e.target.result);
    reader.readAsText(file);
}

init().then(() => {
    initDeployTime();
});
