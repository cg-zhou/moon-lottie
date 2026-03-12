// MoonLottie WASM 渲染器核心逻辑封装
// 提取自 demo/main.js，用于 React 组件调用

export const createWasmImportObject = (ctx, getColor, getJsonStr, imageAssetsByIndex, expressionModule, getViewportTransform = null) => {
    let currentGradient = null;
    let currentDash = [];
    const fillRuleStack = [];
    const offscreenStack = [];
    const matteStack = [];

    const readViewportTransform = () => {
        if (typeof getViewportTransform !== 'function') {
            return { scale: 1, offsetX: 0, offsetY: 0, dpr: window.devicePixelRatio || 1 };
        }

        const viewport = getViewportTransform() || {};
        return {
            scale: Number.isFinite(viewport.scale) ? viewport.scale : 1,
            offsetX: Number.isFinite(viewport.offsetX) ? viewport.offsetX : 0,
            offsetY: Number.isFinite(viewport.offsetY) ? viewport.offsetY : 0,
            dpr: Number.isFinite(viewport.dpr) ? viewport.dpr : (window.devicePixelRatio || 1),
        };
    };

    const wasmStringGlobals = new Proxy({}, {
        get: (_, name) => typeof name === 'string' ? name : undefined,
    });

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

    return {
        'wasm:js-string': wasmJsStringShim,
        demo: {
            get_json_string: () => {
                const s = getJsonStr();
                // console.log(`[MoonLottie-WASM] get_json_string called, length: ${s.length}`);
                return s;
            },
            log_frame: (f) => {
                // console.log(`[MoonLottie-WASM] Rendering Frame: ${f}`);
            }
        },
        _: wasmStringGlobals,
        expressions: expressionModule,
        spectest: { print_char: (c) => {} },
        canvas: {
            save: () => { 
                ctx.save(); 
                fillRuleStack.push(ctx._currentFillRule || "nonzero"); 
            },
            restore: () => { 
                ctx.restore(); 
                ctx._currentFillRule = fillRuleStack.pop() || "nonzero"; 
            },
            beginPath: () => ctx.beginPath(),
            closePath: () => ctx.closePath(),
            moveTo: (x, y) => ctx.moveTo(x, y),
            lineTo: (x, y) => ctx.lineTo(x, y),
            bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
            fill: (r, g, b, a) => { 
                ctx.save(); 
                ctx.globalAlpha *= a; 
                ctx.fillStyle = `rgb(${r},${g},${b})`; 
                ctx.fill(ctx._currentFillRule || "nonzero"); 
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
                const caps = ["butt", "round", "square"]; 
                const joins = ["miter", "round", "bevel"];
                ctx.lineCap = caps[cap - 1] || "butt"; 
                ctx.lineJoin = joins[join - 1] || "miter"; 
                ctx.miterLimit = miter;
            },
            beginDash: () => { currentDash = []; },
            addDash: (value) => { currentDash.push(value); },
            applyDash: (offset) => { ctx.setLineDash(currentDash); ctx.lineDashOffset = offset; },
            setFillRule: (rule) => { ctx._currentFillRule = rule; },
            createLinearGradient: (x1, y1, x2, y2) => { currentGradient = ctx.createLinearGradient(x1, y1, x2, y2); },
            createRadialGradient: (cx, cy, r, fx, fy, fr) => { currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r); },
            addGradientStop: (offset, r, g, b, a) => { 
                if (currentGradient) currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`); 
            },
            fillGradient: (a) => { 
                if (currentGradient) { 
                    ctx.save(); 
                    ctx.globalAlpha *= a; 
                    ctx.fillStyle = currentGradient; 
                    ctx.fill(ctx._currentFillRule || "nonzero"); 
                    ctx.restore(); 
                } 
            },
            strokeGradient: (a, w) => { 
                if (currentGradient) { 
                    ctx.save(); 
                    ctx.globalAlpha *= a; 
                    ctx.strokeStyle = currentGradient; 
                    ctx.lineWidth = w; 
                    ctx.stroke(); 
                    ctx.restore(); 
                } 
            },
            clip: () => ctx.clip(ctx._currentFillRule || "nonzero"),
            clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
            setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
            setOpacity: (a) => { ctx.globalAlpha *= a; },
            setTransform: (a, b, c, d, e, f) => {
                const viewport = readViewportTransform();
                const scale = viewport.scale;
                const dpr = viewport.dpr;
                ctx.setTransform(
                    a * scale * dpr,
                    b * scale * dpr,
                    c * scale * dpr,
                    d * scale * dpr,
                    (e * scale + viewport.offsetX) * dpr,
                    (f * scale + viewport.offsetY) * dpr,
                );
            },
            transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
            drawImage: (assetIndex, w, h) => {
                const img = imageAssetsByIndex[assetIndex] || null;
                if (img) ctx.drawImage(img, 0, 0, w, h);
            },
            drawText: (text, font, size, r, g, b, a, justify) => {
                ctx.save(); 
                ctx.globalAlpha = a; 
                ctx.fillStyle = `rgb(${r},${g},${b})`;
                ctx.font = `${size}px ${font || 'Arial'}`;
                const aligns = ["left", "right", "center"]; 
                ctx.textAlign = aligns[justify] || "left";
                ctx.fillText(text, 0, 0); 
                ctx.restore();
            },
            setGlobalCompositeOperation: (mode) => {
                ctx.globalCompositeOperation = mode;
            },
            // 补全 Lottie 遮罩 (Matte) 相关的 FFI 接口
            beginLayer: (x, y, w, h) => {
                const offscreen = document.createElement('canvas');
                offscreen.width = w || 1;
                offscreen.height = h || 1;
                const offCtx = offscreen.getContext('2d');
                offscreenStack.push({ canvas: offscreen, ctx: offCtx, oldCtx: ctx });
                ctx = offCtx;
            },
            endLayer: () => {
                const layer = offscreenStack.pop();
                if (layer) {
                    ctx = layer.oldCtx;
                    ctx.drawImage(layer.canvas, 0, 0);
                }
            },
            prepareMatteLayer: (x, y, w, h) => {
                const matteCanvas = document.createElement('canvas');
                matteCanvas.width = w || 1;
                matteCanvas.height = h || 1;
                matteStack.push({ 
                    canvas: matteCanvas, 
                    ctx: matteCanvas.getContext('2d'),
                    oldCtx: ctx 
                });
                ctx = matteStack[matteStack.length - 1].ctx;
            },
            beginMatteExit: () => {
                const matte = matteStack[matteStack.length - 1];
                ctx = matte.oldCtx;
            },
            endMatteExit: (mode) => {
                const matte = matteStack.pop();
                if (matte) {
                    const modes = ["source-over", "source-in", "source-out", "destination-in", "destination-out"];
                    ctx.save();
                    ctx.globalCompositeOperation = modes[mode] || "source-in";
                    ctx.drawImage(matte.canvas, 0, 0);
                    ctx.restore();
                }
            }
        }
    };
};
