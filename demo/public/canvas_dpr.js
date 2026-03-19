export function normalizeDevicePixelRatio(dpr) {
    return Number.isFinite(dpr) && dpr > 0 ? dpr : 1;
}

export function getCanvasPixelSize(width, height, dpr = 1) {
    const normalizedDpr = normalizeDevicePixelRatio(dpr);
    return {
        cssWidth: width,
        cssHeight: height,
        dpr: normalizedDpr,
        pixelWidth: Math.max(1, Math.round(width * normalizedDpr)),
        pixelHeight: Math.max(1, Math.round(height * normalizedDpr)),
    };
}

export function resizeCanvasForDpr(canvas, width, height, dpr = 1) {
    const size = getCanvasPixelSize(width, height, dpr);
    canvas.width = size.pixelWidth;
    canvas.height = size.pixelHeight;
    return size;
}

export function applyDprTransform(ctx, a, b, c, d, e, f, dpr = 1) {
    const normalizedDpr = normalizeDevicePixelRatio(dpr);
    ctx.setTransform(
        a * normalizedDpr,
        b * normalizedDpr,
        c * normalizedDpr,
        d * normalizedDpr,
        e * normalizedDpr,
        f * normalizedDpr,
    );
}
