const expressionFunctionCache = new Map();
let externalExpressionHost = null;
const DEFAULT_FPS = 60;
const DEFAULT_FRAME_DURATION = 1 / DEFAULT_FPS;

function cloneNumberArray(values) {
    return Array.isArray(values) ? values.map((value) => Number(value) || 0) : [];
}

function clonePointArray(values) {
    return Array.isArray(values) ? values.map(cloneNumberArray) : [];
}

function copyNumberArray(target, source) {
    if (!target || typeof target.length !== 'number' || !Array.isArray(source)) {
        return;
    }
    const length = Math.min(target.length, source.length);
    for (let i = 0; i < length; i++) {
        target[i] = Number(source[i]) || 0;
    }
}

function copyPointArray(target, source) {
    if (!Array.isArray(target) || !Array.isArray(source)) {
        return;
    }
    const length = Math.min(target.length, source.length);
    for (let i = 0; i < length; i++) {
        copyNumberArray(target[i], source[i]);
    }
}

function isKeyframedProperty(prop) {
    return !!(prop && Array.isArray(prop.k) && prop.k.length > 0 && typeof prop.k[0] === 'object' && prop.k[0] !== null && 't' in prop.k[0]);
}

function clonePropertyValue(value) {
    if (Array.isArray(value)) {
        return value.map((item) => clonePropertyValue(item));
    }
    if (typeof value === 'number') {
        return Number.isFinite(value) ? value : 0;
    }
    return value;
}

function sampleKeyframedProperty(prop, frame) {
    if (!prop) return 0;
    if (!isKeyframedProperty(prop)) {
        return clonePropertyValue(prop.k);
    }

    const keyframes = prop.k;
    if (keyframes.length === 0) return 0;
    if (frame <= Number(keyframes[0].t) || keyframes.length === 1) {
        return clonePropertyValue(keyframes[0].s ?? 0);
    }

    for (let i = 0; i < keyframes.length - 1; i++) {
        const current = keyframes[i];
        const next = keyframes[i + 1];
        const currentTime = Number(current.t) || 0;
        const nextTime = Number(next.t) || currentTime;
        if (frame < nextTime) {
            const start = clonePropertyValue(current.s ?? 0);
            if (current.h === 1 || nextTime === currentTime) {
                return start;
            }
            const end = clonePropertyValue(current.e ?? next.s ?? start);
            const progress = (frame - currentTime) / (nextTime - currentTime);
            if (Array.isArray(start) && Array.isArray(end)) {
                return start.map((value, index) => (Number(value) || 0) + ((Number(end[index]) || 0) - (Number(value) || 0)) * progress);
            }
            return (Number(start) || 0) + ((Number(end) || 0) - (Number(start) || 0)) * progress;
        }
    }

    return clonePropertyValue(keyframes[keyframes.length - 1].s ?? 0);
}

function findLayerByIndex(animationData, layerIndex) {
    return animationData?.layers?.find((layer) => Number(layer?.ind) === Number(layerIndex)) ?? null;
}

function findPropertyByExpression(node, expression) {
    if (!node || typeof node !== 'object') return null;
    if (Array.isArray(node)) {
        for (const item of node) {
            const match = findPropertyByExpression(item, expression);
            if (match) return match;
        }
        return null;
    }
    if (node.x === expression) {
        return node;
    }
    for (const value of Object.values(node)) {
        const match = findPropertyByExpression(value, expression);
        if (match) return match;
    }
    return null;
}

function toVector(value) {
    return Array.isArray(value) ? value.map((item) => Number(item) || 0) : [Number(value) || 0];
}

function binaryOp(a, b, mapper) {
    const leftIsArray = Array.isArray(a);
    const rightIsArray = Array.isArray(b);
    if (!leftIsArray && !rightIsArray) {
        return mapper(Number(a) || 0, Number(b) || 0);
    }
    const left = toVector(a);
    const right = toVector(b);
    const length = Math.max(left.length, right.length);
    const result = [];
    for (let i = 0; i < length; i++) {
        result.push(mapper(left[i] ?? left[left.length - 1] ?? 0, right[i] ?? right[right.length - 1] ?? 0));
    }
    return result;
}

function createPath(vertices, inTangents, outTangents, closed) {
    return {
        vertices: clonePointArray(vertices),
        inTangents: clonePointArray(inTangents),
        outTangents: clonePointArray(outTangents),
        closed: !!closed,
    };
}

function serializeNumberArray(values) {
    return cloneNumberArray(values).join(',');
}

function parseNumberArray(input) {
    if (!input) return [];
    return String(input).split(',').filter((part) => part.length > 0).map((part) => Number(part) || 0);
}

function serializePointArray(values) {
    return clonePointArray(values).map((value) => serializeNumberArray(value)).join(';');
}

function parsePointArray(input) {
    if (!input) return [];
    return String(input).split(';').map((part) => parseNumberArray(part));
}

function serializePath(path) {
    return `${path.closed ? 1 : 0}|${serializePointArray(path.vertices)}|${serializePointArray(path.inTangents)}|${serializePointArray(path.outTangents)}`;
}

function parsePath(input) {
    const [closed = '0', vertices = '', inTangents = '', outTangents = ''] = String(input).split('|');
    return createPath(
        parsePointArray(vertices),
        parsePointArray(inTangents),
        parsePointArray(outTangents),
        closed === '1',
    );
}

function getExpressionFunction(expression) {
    if (!expressionFunctionCache.has(expression)) {
        expressionFunctionCache.set(
            expression,
            new Function(
                'context',
                `
// This fallback evaluator is only used by the demo/default host. Production
// consumers are expected to install their own expression host implementation.
const {
  value,
  time,
  thisComp,
  thisLayer,
  thisProperty,
  effect,
  numKeys,
  key,
  nearestKey,
  velocityAtTime,
  framesToTime,
  timeToFrames,
  createPath,
  clamp,
  sum,
  sub,
  mul,
  div,
  Math
} = context;
${expression}
return typeof $bm_rt === 'undefined' ? value : $bm_rt;
`,
            ),
        );
    }
    return expressionFunctionCache.get(expression);
}

function createEffectAccessor(layer, frame) {
    return (effectName) => {
        const effect = layer?.ef?.find((item) => item?.nm === effectName) ?? null;
        return (paramName) => {
            const param = effect?.ef?.find((item) => item?.mn === paramName || item?.nm === paramName) ?? null;
            if (!param) return 0;
            if (param.v) {
                return sampleKeyframedProperty(param.v, frame);
            }
            return clonePropertyValue(param.k ?? 0);
        };
    };
}

function createPropertyHelpers(rawProperty, frame, frameDuration) {
    const keyframes = isKeyframedProperty(rawProperty) ? rawProperty.k : [];
    const safeDuration = frameDuration > 0 ? frameDuration : 1 / 60;

    const key = (index) => {
        const keyframe = keyframes[Math.max(0, Math.min(keyframes.length - 1, Number(index) - 1))];
        if (!keyframe) {
            return { time: 0, value: 0, index: 0 };
        }
        return {
            time: (Number(keyframe.t) || 0) * safeDuration,
            value: clonePropertyValue(keyframe.s ?? 0),
            index: Math.max(1, Number(index) || 1),
        };
    };

    const nearestKey = (timeSeconds) => {
        const targetFrame = (Number(timeSeconds) || 0) / safeDuration;
        let nearestIndex = 1;
        let nearestDistance = Number.POSITIVE_INFINITY;
        for (let i = 0; i < keyframes.length; i++) {
            const distance = Math.abs((Number(keyframes[i].t) || 0) - targetFrame);
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestIndex = i + 1;
            }
        }
        return key(nearestIndex);
    };

    const velocityAtTime = (timeSeconds) => {
        const frameCenter = (Number(timeSeconds) || 0) / safeDuration;
        const before = sampleKeyframedProperty(rawProperty, frameCenter - 0.01);
        const after = sampleKeyframedProperty(rawProperty, frameCenter + 0.01);
        return binaryOp(after, before, (left, right) => (left - right) / 0.02);
    };

    return {
        numKeys: keyframes.length,
        key,
        nearestKey,
        velocityAtTime,
    };
}

function buildContext({
    expression,
    frame,
    layer,
    value,
    animationData,
    playbackMeta,
    currentPath,
}) {
    const fps = Number(playbackMeta?.fps) || Number(animationData?.fr) || DEFAULT_FPS;
    const frameDuration = fps > 0 ? 1 / fps : DEFAULT_FRAME_DURATION;
    const rawProperty = findPropertyByExpression(layer, expression);
    const propertyHelpers = createPropertyHelpers(rawProperty, frame, frameDuration);

    return {
        value: clonePropertyValue(value),
        time: frame * frameDuration,
        thisComp: {
            frameDuration,
            width: Number(animationData?.w) || 0,
            height: Number(animationData?.h) || 0,
        },
        thisLayer: layer ?? {},
        thisProperty: currentPath ? {
            points: () => clonePointArray(currentPath.vertices),
            inTangents: () => clonePointArray(currentPath.inTangents),
            outTangents: () => clonePointArray(currentPath.outTangents),
            isClosed: () => !!currentPath.closed,
        } : {},
        effect: createEffectAccessor(layer, frame),
        numKeys: propertyHelpers.numKeys,
        key: propertyHelpers.key,
        nearestKey: propertyHelpers.nearestKey,
        velocityAtTime: propertyHelpers.velocityAtTime,
        framesToTime: (value) => (Number(value) || 0) * frameDuration,
        timeToFrames: (value) => (Number(value) || 0) / frameDuration,
        createPath,
        clamp: (value, min, max) => Math.min(Math.max(Number(value) || 0, Number(min) || 0), Number(max) || 0),
        sum: (left, right) => binaryOp(left, right, (a, b) => a + b),
        sub: (left, right) => binaryOp(left, right, (a, b) => a - b),
        mul: (left, right) => binaryOp(left, right, (a, b) => a * b),
        div: (left, right) => binaryOp(left, right, (a, b) => b === 0 ? 0 : a / b),
        Math,
    };
}

export function setExpressionHost(host) {
    externalExpressionHost = host;
}

export function getExpressionHost() {
    return externalExpressionHost ?? globalThis.__moonLottieExpressionHost ?? null;
}

export function createDefaultExpressionHost({ getAnimationData, getPlaybackMeta }) {
    return {
        evaluateDouble(expression, frame, layerIndex, value) {
            const animationData = getAnimationData();
            const layer = findLayerByIndex(animationData, layerIndex);
            try {
                const result = getExpressionFunction(expression)(
                    buildContext({
                        expression,
                        frame,
                        layer,
                        value,
                        animationData,
                        playbackMeta: getPlaybackMeta(),
                    }),
                );
                return Number.isFinite(result) ? result : value;
            } catch (error) {
                console.warn('[MoonLottie] expression evaluateDouble failed', error);
                return value;
            }
        },

        evaluateVec(expression, frame, layerIndex, value) {
            const animationData = getAnimationData();
            const layer = findLayerByIndex(animationData, layerIndex);
            try {
                const result = getExpressionFunction(expression)(
                    buildContext({
                        expression,
                        frame,
                        layer,
                        value: cloneNumberArray(value),
                        animationData,
                        playbackMeta: getPlaybackMeta(),
                    }),
                );
                if (Array.isArray(result)) {
                    return cloneNumberArray(result);
                }
            } catch (error) {
                console.warn('[MoonLottie] expression evaluateVec failed', error);
            }
            return cloneNumberArray(value);
        },

        evaluatePath(expression, frame, layerIndex, pathValue) {
            const animationData = getAnimationData();
            const layer = findLayerByIndex(animationData, layerIndex);
            try {
                const result = getExpressionFunction(expression)(
                    buildContext({
                        expression,
                        frame,
                        layer,
                        value: pathValue,
                        animationData,
                        playbackMeta: getPlaybackMeta(),
                        currentPath: pathValue,
                    }),
                );
                if (result && Array.isArray(result.vertices) && Array.isArray(result.inTangents) && Array.isArray(result.outTangents)) {
                    return createPath(
                        result.vertices,
                        result.inTangents,
                        result.outTangents,
                        result.closed,
                    );
                }
            } catch (error) {
                console.warn('[MoonLottie] expression evaluatePath failed', error);
            }
            return pathValue;
        },
    };
}

export function createExpressionModule(options) {
    const fallbackHost = createDefaultExpressionHost(options);
    const resolveHost = () => getExpressionHost() ?? fallbackHost;

    return {
        evaluate_double: (expression, frame, layerIndex, value) =>
            resolveHost().evaluateDouble(expression, frame, layerIndex, value),
        evaluate_vec: (expression, frame, layerIndex, value) =>
            serializeNumberArray(parseNumberArray(resolveHost().evaluateVec(expression, frame, layerIndex, parseNumberArray(value)))),
        evaluate_path: (expression, frame, layerIndex, value) =>
            serializePath(resolveHost().evaluatePath(expression, frame, layerIndex, parsePath(value))),
    };
}
