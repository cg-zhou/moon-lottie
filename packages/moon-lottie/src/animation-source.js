export function cloneAnimationData(animationData) {
    if (typeof structuredClone !== 'undefined') {
        return structuredClone(animationData);
    }

    try {
        return JSON.parse(JSON.stringify(animationData));
    } catch (error) {
        console.warn('[MoonLottie] Failed to clone animation data; falling back to shared reference', error);
        return animationData;
    }
}

export async function loadSampleIndex() {
    const response = await fetch('sample_index.json');
    if (!response.ok) {
        throw new Error(`Failed to load sample index: ${response.status}`);
    }

    const entries = await response.json();
    return entries.map((entry) => {
        const file = typeof entry === 'object' ? entry.file : entry;
        const label = (typeof entry === 'object' ? (entry.label || entry.file) : entry).replace(/\.json$/i, '');
        const tags = Array.isArray(entry?.tags) ? entry.tags : [];
        return {
            file,
            label,
            tags,
            size: Number.isFinite(entry?.size) ? entry.size : null,
            source: typeof entry?.source === 'string' ? entry.source : '',
        };
    });
}

export async function loadRemoteAnimationSource(filename) {
    const encodedName = encodeURIComponent(filename);
    const path = `samples/${encodedName}`;
    console.log(`[MoonLottie] Fetching animation from: ${path}`);

    return loadAnimationSourceFromUrl(path, {
        filename,
    });
}

export async function loadAnimationSourceFromUrl(url, options = {}) {
    const { filename = url } = options;

    const response = await fetch(url, { cache: 'no-store' });
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    const blob = await response.blob();
    const text = await blob.text();

    return {
        filename,
        text,
        size: blob.size,
        path: url,
    };
}

export async function readFileAnimationSource(file) {
    const text = await file.text();
    return {
        filename: file.name,
        text,
        size: file.size,
        path: null,
    };
}

function resolveAssetSrc(asset) {
    const p = asset.p || '';
    const u = asset.u || '';
    return p === '' ? asset.id : (u + p);
}

export async function preloadAssets(json, { onStatusMessage } = {}) {
    if (!json.assets) {
        return [];
    }

    onStatusMessage?.('正在加载资源文件...');
    const imageAssetsByIndex = new Array(json.assets.length).fill(null);
    const promises = json.assets.map((asset, index) => {
        if (!asset.p) {
            return Promise.resolve();
        }

        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                imageAssetsByIndex[index] = img;
                resolve();
            };
            img.onerror = () => resolve();
            img.src = resolveAssetSrc(asset);
        });
    });

    await Promise.all(promises);
    return imageAssetsByIndex;
}

export function createRuntimeAnimationData(animationData) {
    const runtimeAnimationData = cloneAnimationData(animationData);
    if (runtimeAnimationData.assets) {
        runtimeAnimationData.assets.forEach((asset) => {
            if (asset && asset.e === 1 && typeof asset.p === 'string' && asset.p.startsWith('data:')) {
                asset.p = '';
            }
        });
    }

    return runtimeAnimationData;
}
