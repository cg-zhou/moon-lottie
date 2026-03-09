const TRACK_MATTE_LAYER = 1;
const TRACK_MATTE_TYPES = new Set([1, 2, 3, 4]);

function isLayerVisibleAtFrame(layer, frame) {
    if (!layer || layer.hd) return false;
    const ip = Number(layer.ip ?? 0);
    const op = Number(layer.op ?? Number.POSITIVE_INFINITY);
    return frame >= ip && frame < op;
}

function collectImageRefsFromScope(layers, frame, assetById, refs) {
    if (!Array.isArray(layers)) return;
    for (let i = layers.length - 1; i >= 0; i -= 1) {
        const layer = layers[i];
        if (!isLayerVisibleAtFrame(layer, frame)) continue;
        // Mirror the current Moon renderer, which only skips direct rendering for
        // matte-source siblings marked with td === 1.
        if (layer.td === TRACK_MATTE_LAYER) continue;
        collectImageRefsFromLayer(layer, layers, i, frame, assetById, refs);
    }
}

function collectImageRefsFromLayer(layer, scopeLayers, layerIndex, frame, assetById, refs) {
    if (!isLayerVisibleAtFrame(layer, frame)) return;
    const layerFrame = frame - Number(layer.st ?? 0);

    if (layer.ty === 0 && layer.refId) {
        const asset = assetById.get(layer.refId);
        if (asset && Array.isArray(asset.layers)) {
            collectImageRefsFromScope(asset.layers, layerFrame, assetById, refs);
        }
    } else if (layer.ty === 2 && layer.refId) {
        refs.push(layer.refId);
    }

    // Mirror Player::render_layer matte exit order: target content is rendered
    // first, then the sibling matte source is rendered during exit compositing.
    if (TRACK_MATTE_TYPES.has(layer.tt) && layerIndex > 0) {
        const matteSource = scopeLayers[layerIndex - 1];
        if (matteSource?.td === TRACK_MATTE_LAYER) {
            collectImageRefsFromLayer(matteSource, scopeLayers, layerIndex - 1, frame, assetById, refs);
        }
    }
}

export function collectImageRefsForFrame(animation, frame) {
    const refs = [];
    const assetById = new Map((animation?.assets || []).map(asset => [asset.id, asset]));
    collectImageRefsFromScope(animation?.layers || [], frame, assetById, refs);
    return refs;
}
