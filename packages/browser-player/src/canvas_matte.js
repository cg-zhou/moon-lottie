export function getActiveCanvas(ctx, fallbackCanvas = null) {
    return ctx?.canvas || fallbackCanvas;
}

export function cloneActiveCanvas(documentRef, ctx, fallbackCanvas = null) {
    const sourceCanvas = getActiveCanvas(ctx, fallbackCanvas);
    const buffer = documentRef.createElement('canvas');
    buffer.width = sourceCanvas?.width || 0;
    buffer.height = sourceCanvas?.height || 0;
    if (!sourceCanvas) {
        return {
            buffer,
            width: 0,
            height: 0,
        };
    }
    const bufferCtx = buffer.getContext('2d');
    if (bufferCtx) {
        bufferCtx.drawImage(sourceCanvas, 0, 0);
    }
    return {
        buffer,
        width: buffer.width,
        height: buffer.height,
    };
}

export function clearActiveCanvas(ctx, currentTransform, fallbackCanvas = null) {
    const sourceCanvas = getActiveCanvas(ctx, fallbackCanvas);
    const width = sourceCanvas?.width || 0;
    const height = sourceCanvas?.height || 0;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, width, height);
    ctx.setTransform(currentTransform);
    return { width, height };
}
