export function animationUsesExpressions(node) {
    if (!node || typeof node !== 'object') {
        return false;
    }

    if (Array.isArray(node)) {
        return node.some(animationUsesExpressions);
    }

    if (typeof node.x === 'string' && node.x.trim().length > 0) {
        return true;
    }

    return Object.values(node).some(animationUsesExpressions);
}

export function getPreferredRendererMode(animationData, { hasLottieWeb = true } = {}) {
    return animationUsesExpressions(animationData) && hasLottieWeb ? 'official' : 'wasm';
}

export function getAnimationPlaybackMeta(animationData) {
    const width = Number(animationData?.w) || 0;
    const height = Number(animationData?.h) || 0;
    const inPoint = Number(animationData?.ip) || 0;
    const outPoint = Number(animationData?.op) || inPoint;
    const fps = Number(animationData?.fr) || 0;

    return {
        version: typeof animationData?.v === 'string' ? animationData.v : '-',
        width,
        height,
        fps,
        inPoint,
        outPoint,
        totalFrames: Math.max(0, outPoint - inPoint),
        aspectRatio: `${Math.max(width, 1)} / ${Math.max(height, 1)}`,
    };
}
