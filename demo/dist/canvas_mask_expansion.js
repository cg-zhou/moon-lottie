function normalizeExpansion(expansion) {
    const value = Number(expansion);
    return Number.isFinite(value) ? value : 0;
}

export function applyAlphaMorphology(alpha, width, height, radius, operation = 'erode') {
    const pixelRadius = Math.max(0, Math.round(Math.abs(Number(radius) || 0)));
    const source = alpha instanceof Uint8ClampedArray ? alpha : new Uint8ClampedArray(alpha);
    if (pixelRadius === 0) {
        return new Uint8ClampedArray(source);
    }
    const result = new Uint8ClampedArray(source.length);
    const dilate = operation === 'dilate';
    for (let y = 0; y < height; y += 1) {
        const minY = Math.max(0, y - pixelRadius);
        const maxY = Math.min(height - 1, y + pixelRadius);
        for (let x = 0; x < width; x += 1) {
            const minX = Math.max(0, x - pixelRadius);
            const maxX = Math.min(width - 1, x + pixelRadius);
            let alphaValue = dilate ? 0 : 255;
            for (let sampleY = minY; sampleY <= maxY; sampleY += 1) {
                for (let sampleX = minX; sampleX <= maxX; sampleX += 1) {
                    const sampleAlpha = source[(sampleY * width + sampleX) * 4 + 3];
                    alphaValue = dilate
                        ? Math.max(alphaValue, sampleAlpha)
                        : Math.min(alphaValue, sampleAlpha);
                }
            }
            const offset = (y * width + x) * 4;
            result[offset] = 255;
            result[offset + 1] = 255;
            result[offset + 2] = 255;
            result[offset + 3] = alphaValue;
        }
    }
    return result;
}

function applyNegativeExpansion(pathCtx, expansion) {
    const radius = Math.abs(normalizeExpansion(expansion));
    if (radius === 0) return;
    const { width, height } = pathCtx.canvas;
    const image = pathCtx.getImageData(0, 0, width, height);
    image.data.set(applyAlphaMorphology(image.data, width, height, radius, 'erode'));
    pathCtx.putImageData(image, 0, 0);
}

function invertMaskAlpha(pathCtx, workCtx, alpha) {
    const { width, height } = pathCtx.canvas;
    workCtx.setTransform(1, 0, 0, 1, 0, 0);
    workCtx.clearRect(0, 0, width, height);
    workCtx.globalCompositeOperation = 'source-over';
    workCtx.globalAlpha = 1.0;
    workCtx.drawImage(pathCtx.canvas, 0, 0);

    pathCtx.setTransform(1, 0, 0, 1, 0, 0);
    pathCtx.clearRect(0, 0, width, height);
    pathCtx.globalCompositeOperation = 'source-over';
    pathCtx.globalAlpha = alpha;
    pathCtx.fillStyle = '#ffffff';
    pathCtx.fillRect(0, 0, width, height);
    pathCtx.globalCompositeOperation = 'destination-out';
    pathCtx.globalAlpha = 1.0;
    pathCtx.drawImage(workCtx.canvas, 0, 0);
}

export function rasterizeMaskPath(pathCtx, workCtx, fillRule, opacity, inverted, expansion) {
    const alpha = Math.max(0, Math.min(1, Number(opacity) || 0));
    const normalizedExpansion = normalizeExpansion(expansion);

    pathCtx.save();
    pathCtx.globalCompositeOperation = 'source-over';
    pathCtx.globalAlpha = alpha;
    pathCtx.fillStyle = '#ffffff';
    pathCtx.fill(fillRule);
    if (normalizedExpansion !== 0) {
        pathCtx.strokeStyle = '#ffffff';
        pathCtx.lineCap = 'butt';
        pathCtx.lineJoin = 'miter';
        pathCtx.miterLimit = 4;
        // lottie-web's SVG mask source keeps a stroked path for any non-zero
        // expansion. Positive values widen that stroke to 2*x, while negative
        // values erode the default 1px stroked source graphic via
        // feMorphology(operator="erode").
        pathCtx.lineWidth = normalizedExpansion > 0 ? normalizedExpansion * 2 : 1;
        pathCtx.stroke();
    }
    pathCtx.restore();

    if (normalizedExpansion < 0) {
        // Known follow-up: this is closer to lottie-web for negative expansion,
        // but animated expansion still has a small residual mismatch on
        // 3_2_monster(expr).json frame 0.
        applyNegativeExpansion(pathCtx, normalizedExpansion);
    }

    if (inverted) {
        invertMaskAlpha(pathCtx, workCtx, alpha);
    }
}
