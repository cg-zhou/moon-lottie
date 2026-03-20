import { createExpressionModule, setExpressionHost } from '../expression_host.js';
import { clearActiveCanvas, cloneActiveCanvas } from '../canvas_matte.js';
import { rasterizeMaskPath } from '../canvas_mask_expansion.js';

const wasmRuntimeModuleCache = new Map();

export function createCanvasRuntimeBridge(options = {}) {
    const {
        canvas,
        viewportTransform,
        getRuntimeAnimationJson = () => '',
        getImageAssets = () => [],
        getExpressionAnimationData = () => null,
        getExpressionMeta = () => null,
        getCanvasContext = () => canvas.getContext('2d'),
        wasmPath = 'runtime/wasm/moon-lottie-runtime.wasm',
        jsRuntimePath = '../runtime/js/moon-lottie-runtime.js',
        wasmBuiltinOptions = { builtins: ['js-string'] },
        wasmJsStringImportModule = 'wasm:js-string',
        wasmJsStringShim = {
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
                return Number.isFinite(codePoint) ? String.fromCodePoint(codePoint) : '';
            },
            fromCharCodeArray: (chars, start, end) => {
                const length = Number(chars?.length);
                if (!Number.isFinite(length) || length < 0) return '';
                const from = Math.max(0, Number(start) || 0);
                const to = Math.min(length, end == null ? length : (Number(end) || 0));
                let result = '';
                for (let i = from; i < to; i++) {
                    result += String.fromCharCode(Number(chars[i]) || 0);
                }
                return result;
            },
        },
        wasmStringGlobals = new Proxy({}, {
            get: (_, name) => typeof name === 'string' ? name : undefined,
        }),
    } = options;

    let ctx = getCanvasContext();
    let currentGradient = null;
    let currentDash = [];
    const fillRuleStack = [];
    const offscreenStack = [];
    const matteStack = [];

    const expressionModule = createExpressionModule({
        getAnimationData: () => getExpressionAnimationData(),
        getPlaybackMeta: () => getExpressionMeta(),
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

    function getCurrentOffscreenEntry() {
        return offscreenStack.length > 0 ? offscreenStack[offscreenStack.length - 1] : null;
    }

    const importObject = {
        demo: {
            get_json_string: () => getRuntimeAnimationJson(),
            log_frame: () => {},
        },
        _: wasmStringGlobals,
        expressions: expressionModule,
        spectest: { print_char: () => {} },
        canvas: {
            save: () => { ctx.save(); fillRuleStack.push(ctx._currentFillRule || 'nonzero'); },
            restore: () => { ctx.restore(); ctx._currentFillRule = fillRuleStack.pop() || 'nonzero'; },
            beginPath: () => ctx.beginPath(),
            closePath: () => ctx.closePath(),
            moveTo: (x, y) => ctx.moveTo(x, y),
            lineTo: (x, y) => ctx.lineTo(x, y),
            bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
            fill: (r, g, b, a) => {
                ctx.save();
                ctx.globalAlpha *= a;
                ctx.fillStyle = `rgb(${r},${g},${b})`;
                ctx.fill(ctx._currentFillRule || 'nonzero');
                ctx.restore();
            },
            stroke: (r, g, b, a, width) => {
                ctx.save();
                ctx.globalAlpha *= a;
                ctx.strokeStyle = `rgb(${r},${g},${b})`;
                ctx.lineWidth = width;
                ctx.stroke();
                ctx.restore();
            },
            setStrokeStyle: (cap, join, miter) => {
                const caps = ['butt', 'round', 'square'];
                const joins = ['miter', 'round', 'bevel'];
                ctx.lineCap = caps[cap - 1] || 'butt';
                ctx.lineJoin = joins[join - 1] || 'miter';
                ctx.miterLimit = miter;
            },
            beginDash: () => { currentDash = []; },
            addDash: (value) => { currentDash.push(value); },
            applyDash: (offset) => { ctx.setLineDash(currentDash); ctx.lineDashOffset = offset; },
            setFillRule: (rule) => { ctx._currentFillRule = rule; },
            createLinearGradient: (x1, y1, x2, y2) => { currentGradient = ctx.createLinearGradient(x1, y1, x2, y2); },
            createRadialGradient: (cx, cy, r, fx, fy, fr) => { currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r); },
            addGradientStop: (offset, r, g, b, a) => { if (currentGradient) currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`); },
            fillGradient: (a) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = currentGradient; ctx.fill(ctx._currentFillRule || 'nonzero'); ctx.restore(); } },
            strokeGradient: (a, w) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = currentGradient; ctx.lineWidth = w; ctx.stroke(); ctx.restore(); } },
            clip: () => ctx.clip(ctx._currentFillRule || 'nonzero'),
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
                const img = getImageAssets()[assetIndex] || null;
                if (img) ctx.drawImage(img, 0, 0, w, h);
            },
            drawText: (text, font, size, r, g, b, a, justify) => {
                ctx.save();
                ctx.globalAlpha = a;
                ctx.fillStyle = `rgb(${r},${g},${b})`;
                ctx.font = `${size}px ${font || 'Arial'}`;
                const aligns = ['left', 'right', 'center'];
                ctx.textAlign = aligns[justify] || 'left';
                ctx.fillText(text, 0, 0);
                ctx.restore();
            },
            supportsMaskComposite: () => true,
            setGlobalCompositeOperation: (mode) => {
                const modeStr = mode;
                if (modeStr === 'destination-in' && offscreenStack.length > 0) {
                    const entry = offscreenStack[offscreenStack.length - 1];
                    const w = ctx.canvas.width;
                    const h = ctx.canvas.height;
                    const contentBuffer = document.createElement('canvas');
                    contentBuffer.width = w;
                    contentBuffer.height = h;
                    contentBuffer.getContext('2d').drawImage(ctx.canvas, 0, 0);
                    ctx.save();
                    ctx.setTransform(1, 0, 0, 1, 0, 0);
                    ctx.clearRect(0, 0, w, h);
                    ctx.restore();
                    entry.matteContent = contentBuffer;
                } else if (modeStr === 'source-over' && offscreenStack.length > 0 && offscreenStack[offscreenStack.length - 1].matteContent !== null) {
                    const entry = offscreenStack[offscreenStack.length - 1];
                    const buf = entry.matteContent;
                    entry.matteContent = null;
                    ctx.save();
                    ctx.setTransform(1, 0, 0, 1, 0, 0);
                    ctx.globalCompositeOperation = 'source-in';
                    ctx.drawImage(buf, 0, 0);
                    ctx.restore();
                } else {
                    ctx.globalCompositeOperation = modeStr;
                }
            },
            beginLayer: () => {
                const offscreen = document.createElement('canvas');
                offscreen.width = canvas.width;
                offscreen.height = canvas.height;
                const offCtx = offscreen.getContext('2d');
                const t = ctx.getTransform();
                offCtx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
                offscreenStack.push({ savedCtx: ctx, offscreen, savedOpacity: ctx.globalAlpha, matteContent: null, maskState: null });
                ctx = offCtx;
                ctx.globalAlpha = 1.0;
            },
            endLayer: (mode) => {
                if (offscreenStack.length === 0) return;
                const { savedCtx, offscreen, savedOpacity } = offscreenStack.pop();
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
                const fillRule = contentCtx._currentFillRule || 'nonzero';
                state.contentCtx = contentCtx;
                state.pathCtx.setTransform(1, 0, 0, 1, 0, 0);
                state.pathCtx.clearRect(0, 0, state.pathCanvas.width, state.pathCanvas.height);
                state.pathCtx.setTransform(currentTransform.a, currentTransform.b, currentTransform.c, currentTransform.d, currentTransform.e, currentTransform.f);
                state.pathCtx.globalAlpha = 1.0;
                state.pathCtx.globalCompositeOperation = 'source-over';
                state.pathCtx._currentFillRule = fillRule;
                ctx = state.pathCtx;
            },
            applyMaskPath: (mode, opacity, inverted, expansion) => {
                const entry = getCurrentOffscreenEntry();
                const state = entry?.maskState;
                if (!state || !state.pathCtx || !state.maskCtx || !state.workCtx) return;
                const rule = state.pathCtx._currentFillRule || 'nonzero';
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
                        case 1: compositeOp = 'source-over'; break;
                        case 2: compositeOp = 'destination-out'; break;
                        case 3: compositeOp = 'destination-in'; break;
                        default: compositeOp = null; break;
                    }
                    if (compositeOp) {
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
            prepareMatteLayer: () => {
                const currentTransform = ctx.getTransform();
                const { buffer: buf0 } = cloneActiveCanvas(document, ctx, canvas);
                clearActiveCanvas(ctx, currentTransform, canvas);
                matteStack.push({ buf0, buf1: null, currentTransform });
            },
            beginMatteExit: () => {
                if (matteStack.length === 0) return;
                const state = matteStack[matteStack.length - 1];
                const { buffer: buf1 } = cloneActiveCanvas(document, ctx, canvas);
                state.buf1 = buf1;
                clearActiveCanvas(ctx, state.currentTransform, canvas);
            },
            endMatteExit: (matte_type) => {
                if (matteStack.length === 0) return;
                const { buf0, buf1, currentTransform } = matteStack.pop();
                ctx.setTransform(1, 0, 0, 1, 0, 0);
                const compositeOp = (matte_type === 1 || matte_type === 3) ? 'source-in' : 'source-out';
                ctx.globalCompositeOperation = compositeOp;
                ctx.drawImage(buf1, 0, 0);
                ctx.globalCompositeOperation = 'destination-over';
                ctx.drawImage(buf0, 0, 0);
                ctx.setTransform(currentTransform);
                ctx.globalCompositeOperation = 'source-over';
            },
        },
    };

    function installJsRuntimeGlobals() {
        window.demo = importObject.demo;
        window.canvas = importObject.canvas;
        window.expressions = expressionModule;
    }

    async function getWasmRuntimeModule() {
        if (wasmRuntimeModuleCache.has(wasmPath)) {
            return wasmRuntimeModuleCache.get(wasmPath);
        }

        const pendingModule = (async () => {
            const response = await fetch(wasmPath, { cache: 'no-store' });
            if (!response.ok) throw new Error('WASM not found');

            const buffer = await response.arrayBuffer();

            try {
                const module = await WebAssembly.compile(buffer, wasmBuiltinOptions);
                return {
                    module,
                    useBuiltinInstantiation: true,
                };
            } catch {
                const module = await WebAssembly.compile(buffer);
                return {
                    module,
                    useBuiltinInstantiation: false,
                };
            }
        })();

        wasmRuntimeModuleCache.set(wasmPath, pendingModule);

        try {
            return await pendingModule;
        } catch (error) {
            wasmRuntimeModuleCache.delete(wasmPath);
            throw error;
        }
    }

    async function loadWasmRuntime() {
        const finalImportObject = {
            ...importObject,
            [wasmJsStringImportModule]: wasmJsStringShim,
        };

        const runtimeModule = await getWasmRuntimeModule();

        if (runtimeModule.useBuiltinInstantiation) {
            const instance = await WebAssembly.instantiate(runtimeModule.module, importObject, wasmBuiltinOptions);
            return instance.exports;
        }

        const instance = await WebAssembly.instantiate(runtimeModule.module, finalImportObject);
        return instance.exports;
    }

    async function loadJsRuntime() {
        installJsRuntimeGlobals();
        const moduleUrl = new URL(jsRuntimePath, import.meta.url);
        return import(moduleUrl.href);
    }

    function renderFrame(runtime, nativePlayer, frame) {
        ctx = getCanvasContext();
        if (!runtime || !nativePlayer) {
            return;
        }

        ctx.save();
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        runtime.update_player(nativePlayer, frame);
        ctx.restore();
    }

    return {
        expressionModule,
        loadWasmRuntime,
        loadJsRuntime,
        renderFrame,
    };
}