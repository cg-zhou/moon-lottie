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

function unwrapScalarValue(value) {
    if (Array.isArray(value) && value.length > 0) {
        return unwrapScalarValue(value[0]);
    }
    return Number(value);
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

    const lastKeyframe = keyframes[keyframes.length - 1];
    if (lastKeyframe?.s != null) {
        return clonePropertyValue(lastKeyframe.s);
    }
    if (keyframes.length >= 2) {
        const previousKeyframe = keyframes[keyframes.length - 2];
        if (previousKeyframe?.e != null) {
            return clonePropertyValue(previousKeyframe.e);
        }
        if (previousKeyframe?.s != null) {
            return clonePropertyValue(previousKeyframe.s);
        }
    }
    return 0;
}

function getLayerCollections(animationData) {
    const collections = [];
    if (Array.isArray(animationData?.layers)) {
        collections.push(animationData.layers);
    }
    if (Array.isArray(animationData?.assets)) {
        for (const asset of animationData.assets) {
            if (Array.isArray(asset?.layers)) {
                collections.push(asset.layers);
            }
        }
    }
    return collections;
}

function findLayerContextByIndex(animationData, layerIndex, expression = null) {
    const targetIndex = Number(layerIndex);
    const candidates = [];
    for (const layers of getLayerCollections(animationData)) {
        for (const layer of layers) {
            if (Number(layer?.ind) !== targetIndex) {
                continue;
            }
            const candidate = { layer, layers };
            candidates.push(candidate);
            if (!expression || findPropertyContextByExpression(layer, expression)) {
                return candidate;
            }
        }
    }
    if (candidates.length === 1) {
        return candidates[0];
    }
    return null;
}

function findLayerByIndex(animationData, layerIndex, expression = null) {
    return findLayerContextByIndex(animationData, layerIndex, expression)?.layer ?? null;
}

function findLayerInComp(layers, layerRef) {
    if (!Array.isArray(layers)) return null;
    if (typeof layerRef === 'number') {
        return layers.find((candidate) => Number(candidate?.ind) === Number(layerRef)) ?? null;
    }
    return layers.find((candidate) => candidate?.nm === layerRef) ?? null;
}

function findPropertyContextByExpression(node, expression, parents = []) {
    if (!node || typeof node !== 'object') return null;
    if (Array.isArray(node)) {
        for (const item of node) {
            const match = findPropertyContextByExpression(item, expression, parents);
            if (match) return match;
        }
        return null;
    }
    if (node.x === expression) {
        return { property: node, parents };
    }
    for (const value of Object.values(node)) {
        const match = findPropertyContextByExpression(value, expression, [...parents, node]);
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
  loopIn,
  loopOut,
  framesToTime,
  timeToFrames,
  fromCompToSurface,
  createPath,
  radiansToDegrees,
  degreesToRadians,
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

function createEffectAccessor(layer, animationData, frame, compLayers = null) {
    return (effectName) => {
        const effect = layer?.ef?.find((item) => item?.nm === effectName || item?.mn === effectName) ?? null;
        return (paramName) => {
            const param = effect?.ef?.find((item) => item?.mn === paramName || item?.nm === paramName) ?? null;
            if (!param) return 0;
            if (param.v) {
                const value = sampleKeyframedProperty(param.v, frame);
                if (param.mn === 'ADBE Layer Control-0001') {
                    const layerIndex = Number(value) || 0;
                    const targetLayer = findLayerInComp(compLayers, layerIndex) ?? findLayerByIndex(animationData, layerIndex);
                    return targetLayer ? createLayerProxy(targetLayer, animationData, frame) : {};
                }
                return value;
            }
            return clonePropertyValue(param.k ?? 0);
        };
    };
}

function getTransformPosition(transform, frame) {
    if (!transform) return [0, 0, 0];
    if (transform.p?.s === true) {
        return [
            Number(sampleKeyframedProperty(transform.x, frame) ?? sampleKeyframedProperty(transform.px, frame)) || 0,
            Number(sampleKeyframedProperty(transform.y, frame) ?? sampleKeyframedProperty(transform.py, frame)) || 0,
            Number(sampleKeyframedProperty(transform.z, frame) ?? sampleKeyframedProperty(transform.pz, frame)) || 0,
        ];
    }
    return cloneNumberArray(sampleKeyframedProperty(transform.p, frame));
}

function getTransformAnchor(transform, frame) {
    return cloneNumberArray(sampleKeyframedProperty(transform?.a, frame));
}

function getTransformScale(transform, frame) {
    const value = cloneNumberArray(sampleKeyframedProperty(transform?.s, frame));
    return value.length > 0 ? value : [100, 100, 100];
}

function getTransformRotation(transform, frame) {
    return Number(sampleKeyframedProperty(transform?.r ?? transform?.rz, frame)) || 0;
}

function multiplyMatrices(left, right) {
    return {
        a: left.a * right.a + left.c * right.b,
        b: left.b * right.a + left.d * right.b,
        c: left.a * right.c + left.c * right.d,
        d: left.b * right.c + left.d * right.d,
        e: left.a * right.e + left.c * right.f + left.e,
        f: left.b * right.e + left.d * right.f + left.f,
    };
}

function createTranslationMatrix(x, y) {
    return { a: 1, b: 0, c: 0, d: 1, e: Number(x) || 0, f: Number(y) || 0 };
}

function createScaleMatrix(x, y) {
    return { a: Number(x) || 1, b: 0, c: 0, d: Number(y) || 1, e: 0, f: 0 };
}

function createRotationMatrix(degrees) {
    const radians = (Number(degrees) || 0) * Math.PI / 180;
    const cos = Math.cos(radians);
    const sin = Math.sin(radians);
    return { a: cos, b: sin, c: -sin, d: cos, e: 0, f: 0 };
}

function applyMatrixToPoint(matrix, point) {
    const vector = cloneNumberArray(point);
    const x = vector[0] ?? 0;
    const y = vector[1] ?? 0;
    const z = vector[2] ?? 0;
    return [
        matrix.a * x + matrix.c * y + matrix.e,
        matrix.b * x + matrix.d * y + matrix.f,
        z,
    ];
}

function invertMatrix(matrix) {
    const determinant = matrix.a * matrix.d - matrix.b * matrix.c;
    if (Math.abs(determinant) <= 1e-6) {
        return { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 };
    }
    return {
        a: matrix.d / determinant,
        b: -matrix.b / determinant,
        c: -matrix.c / determinant,
        d: matrix.a / determinant,
        e: (matrix.c * matrix.f - matrix.d * matrix.e) / determinant,
        f: (matrix.b * matrix.e - matrix.a * matrix.f) / determinant,
    };
}

function findLayerParent(layer, animationData) {
    if (!layer?.parent) return null;
    return animationData?.layers?.find((candidate) => Number(candidate?.ind) === Number(layer.parent)) ?? null;
}

function evaluateLayerMatrix(layer, animationData, frame) {
    const transform = layer?.ks ?? {};
    const position = getTransformPosition(transform, frame);
    const anchor = getTransformAnchor(transform, frame);
    const scale = getTransformScale(transform, frame);
    const rotation = getTransformRotation(transform, frame);

    let matrix = createTranslationMatrix(position[0] ?? 0, position[1] ?? 0);
    matrix = multiplyMatrices(matrix, createRotationMatrix(rotation));
    matrix = multiplyMatrices(matrix, createScaleMatrix((scale[0] ?? 100) / 100, (scale[1] ?? 100) / 100));
    matrix = multiplyMatrices(matrix, createTranslationMatrix(-(anchor[0] ?? 0), -(anchor[1] ?? 0)));

    const parent = findLayerParent(layer, animationData);
    return parent ? multiplyMatrices(evaluateLayerMatrix(parent, animationData, frame), matrix) : matrix;
}

function cubicPoint(p0, p1, p2, p3, t) {
    const oneMinusT = 1 - t;
    return oneMinusT ** 3 * p0 + 3 * oneMinusT ** 2 * t * p1 + 3 * oneMinusT * t ** 2 * p2 + t ** 3 * p3;
}

function cubicDerivative(p0, p1, p2, p3, t) {
    const oneMinusT = 1 - t;
    return 3 * oneMinusT ** 2 * (p1 - p0) + 6 * oneMinusT * t * (p2 - p1) + 3 * t ** 2 * (p3 - p2);
}

function normalizePoint(point) {
    const x = Number(point[0]) || 0;
    const y = Number(point[1]) || 0;
    const length = Math.hypot(x, y);
    if (length <= 1e-9) {
        return [0, 0];
    }
    return [x / length, y / length];
}

function createBezierSegments(pathValue) {
    const vertices = clonePointArray(pathValue?.v ?? pathValue?.vertices ?? []);
    const inTangents = clonePointArray(pathValue?.i ?? pathValue?.inTangents ?? []);
    const outTangents = clonePointArray(pathValue?.o ?? pathValue?.outTangents ?? []);
    const closed = !!(pathValue?.c ?? pathValue?.closed);
    const segmentCount = closed ? vertices.length : Math.max(0, vertices.length - 1);
    const segments = [];

    for (let index = 0; index < segmentCount; index++) {
        const nextIndex = (index + 1) % vertices.length;
        const start = vertices[index];
        const end = vertices[nextIndex];
        const out = outTangents[index] ?? [0, 0];
        const incoming = inTangents[nextIndex] ?? [0, 0];
        segments.push({
            p0: start,
            p1: [(start[0] ?? 0) + (out[0] ?? 0), (start[1] ?? 0) + (out[1] ?? 0)],
            p2: [(end[0] ?? 0) + (incoming[0] ?? 0), (end[1] ?? 0) + (incoming[1] ?? 0)],
            p3: end,
        });
    }

    return { vertices, inTangents, outTangents, closed, segments };
}

function samplePathAtProgress(pathValue, progress) {
    const { segments } = createBezierSegments(pathValue);
    if (segments.length === 0) {
        return {
            point: [0, 0],
            tangent: [1, 0],
        };
    }

    const clampedProgress = Math.min(Math.max(Number(progress) || 0, 0), 1);
    const samples = [];
    let totalLength = 0;
    const subdivisions = 24;

    for (const segment of segments) {
        let previousPoint = null;
        for (let step = 0; step <= subdivisions; step++) {
            const t = step / subdivisions;
            const point = [
                cubicPoint(segment.p0[0] ?? 0, segment.p1[0] ?? 0, segment.p2[0] ?? 0, segment.p3[0] ?? 0, t),
                cubicPoint(segment.p0[1] ?? 0, segment.p1[1] ?? 0, segment.p2[1] ?? 0, segment.p3[1] ?? 0, t),
            ];
            if (previousPoint) {
                totalLength += Math.hypot(point[0] - previousPoint[0], point[1] - previousPoint[1]);
            }
            samples.push({ segment, t, point, length: totalLength });
            previousPoint = point;
        }
    }

    const targetLength = totalLength * clampedProgress;
    let selected = samples[samples.length - 1];
    for (const sample of samples) {
        if (sample.length >= targetLength) {
            selected = sample;
            break;
        }
    }

    const { segment, t, point } = selected;
    const tangent = normalizePoint([
        cubicDerivative(segment.p0[0] ?? 0, segment.p1[0] ?? 0, segment.p2[0] ?? 0, segment.p3[0] ?? 0, t),
        cubicDerivative(segment.p0[1] ?? 0, segment.p1[1] ?? 0, segment.p2[1] ?? 0, segment.p3[1] ?? 0, t),
    ]);

    return { point, tangent };
}

function createPathProxy(pathValue) {
    const {
        vertices,
        inTangents: inTangentPoints,
        outTangents: outTangentPoints,
        closed,
    } = createBezierSegments(pathValue);
    const proxyTarget = {
        vertices,
        inTangentPoints,
        outTangentPoints,
        closed,
        path: null,
        points: () => clonePointArray(vertices),
        inTangents: () => clonePointArray(inTangentPoints),
        outTangents: () => clonePointArray(outTangentPoints),
        isClosed: () => closed,
        pointOnPath: (progress) => cloneNumberArray(samplePathAtProgress(pathValue, progress).point),
        tangentOnPath: (progress) => cloneNumberArray(samplePathAtProgress(pathValue, progress).tangent),
    };
    proxyTarget.path = proxyTarget;
    return proxyTarget;
}

function createTransformProxy(layer, frame) {
    const transform = layer?.ks ?? {};
    return {
        anchorPoint: getTransformAnchor(transform, frame),
        position: getTransformPosition(transform, frame),
        scale: getTransformScale(transform, frame),
        rotation: getTransformRotation(transform, frame),
        opacity: Number(sampleKeyframedProperty(transform.o, frame)) || 0,
    };
}

function findShapeByName(items, name) {
    if (!Array.isArray(items)) return null;
    for (const item of items) {
        if (item?.nm === name) {
            return item;
        }
        const nested = findShapeByName(item?.it, name);
        if (nested) {
            return nested;
        }
    }
    return null;
}

function resolveShapeSelector(target, selector, frame) {
    if (selector == null) return null;
    if (Array.isArray(target)) {
        if (typeof selector === 'number') {
            return target[Math.max(0, Math.trunc(selector) - 1)] ?? null;
        }
        if (typeof selector === 'string') {
            return target.find((item) => item?.nm === selector || item?.mn === selector) ?? null;
        }
        return null;
    }
    if (!target || typeof target !== 'object') return null;
    if (selector === 'ADBE Root Vectors Group') {
        return target.shapes ?? null;
    }
    if (selector === 'ADBE Vectors Group') {
        return target.it ?? null;
    }
    if (selector === 'ADBE Vector Shape') {
        return target.ks ? createPathProxy(sampleKeyframedProperty(target.ks, frame)) : null;
    }
    return null;
}

function createShapeProxy(target, frame) {
    const callable = function (selector) {
        const next = resolveShapeSelector(target, selector, frame);
        return next ? createShapeProxy(next, frame) : {};
    };

    return new Proxy(callable, {
        apply(_fn, _thisArg, args) {
            return callable(args[0]);
        },
        get(_fn, prop) {
            if (prop === 'path') {
                if (target?.ks) {
                    return createPathProxy(sampleKeyframedProperty(target.ks, frame));
                }
                return undefined;
            }
            if (prop === 'points' || prop === 'inTangents' || prop === 'outTangents' || prop === 'isClosed' || prop === 'pointOnPath' || prop === 'tangentOnPath' || prop === 'vertices' || prop === 'closed') {
                const pathProxy = target?.ks ? createPathProxy(sampleKeyframedProperty(target.ks, frame)) : target;
                const value = pathProxy?.[prop];
                return typeof value === 'function' ? value.bind(pathProxy) : value;
            }
            if (typeof prop === 'string' && target && prop in target) {
                return target[prop];
            }
            return undefined;
        },
    });
}

function createMaskAccessor(layer, frame) {
    return (maskName) => {
        const masks = layer?.masksProperties ?? layer?.masks ?? [];
        const mask = masks.find((item) => item?.nm === maskName) ?? null;
        if (!mask) {
            return {};
        }
        const pathProxy = createPathProxy(sampleKeyframedProperty(mask.pt, frame));
        return {
            maskPath: pathProxy,
            opacity: Number(sampleKeyframedProperty(mask.o, frame)) || 0,
        };
    };
}

function createLayerProxy(layer, animationData, frame) {
    const callable = function (selector) {
        const next = resolveShapeSelector(layer, selector, frame);
        return next ? createShapeProxy(next, frame) : {};
    };

    return new Proxy(callable, {
        apply(_fn, _thisArg, args) {
            return callable(args[0]);
        },
        get(_fn, prop) {
            if (prop === 'effect') return createEffectAccessor(layer, animationData, frame);
            if (prop === 'mask') return createMaskAccessor(layer, frame);
            if (prop === 'content') {
                return (name) => {
                    const match = findShapeByName(layer?.shapes ?? [], name);
                    return match ? createShapeProxy(match, frame) : {};
                };
            }
            if (prop === 'transform') return createTransformProxy(layer, frame);
            if (prop === 'toComp') {
                return (point) => applyMatrixToPoint(evaluateLayerMatrix(layer, animationData, frame), point);
            }
            if (prop === 'index') return Number(layer?.ind) || 0;
            if (prop === 'name') return layer?.nm ?? '';
            if (prop === 'anchorPoint') return getTransformAnchor(layer?.ks ?? {}, frame);
            return layer?.[prop];
        },
    });
}

function createPropertyHelpers(rawProperty, frame, frameDuration) {
    const keyframes = isKeyframedProperty(rawProperty) ? rawProperty.k : [];
    const safeDuration = frameDuration > 0 ? frameDuration : DEFAULT_FRAME_DURATION;

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

function createEffectGroupAccessor(effect, animationData, frame, compLayers = null) {
    return (paramName) => {
        const param = effect?.ef?.find((item) => item?.mn === paramName || item?.nm === paramName) ?? null;
        if (!param) return 0;
        const value = param.v ? sampleKeyframedProperty(param.v, frame) : clonePropertyValue(param.k ?? 0);
        if (param.mn === 'ADBE Layer Control-0001') {
            const layerIndex = Number(value) || 0;
            const targetLayer = findLayerInComp(compLayers, layerIndex) ?? findLayerByIndex(animationData, layerIndex);
            return targetLayer ? createLayerProxy(targetLayer, animationData, frame) : {};
        }
        return value;
    };
}

function getLoopWindow(rawProperty, propertyHelpers) {
    if (!rawProperty || !isKeyframedProperty(rawProperty) || propertyHelpers.numKeys <= 1) {
        return null;
    }
    const keyframes = rawProperty.k;
    const first = Number(keyframes[0]?.t) || 0;
    const lastKeyframe = keyframes[keyframes.length - 1];
    const last = Number(lastKeyframe?.t) || first;
    const duration = last - first;
    if (duration <= 0) {
        return null;
    }
    return { first, last, duration, keyframes };
}

function wrappingModulo(value, divisor) {
    if (!Number.isFinite(value) || !Number.isFinite(divisor) || divisor === 0) {
        return 0;
    }
    return ((value % divisor) + divisor) % divisor;
}

function computeLoopValue(rawProperty, propertyHelpers, frame, frameDuration, direction, mode = 'cycle') {
    const loopWindow = getLoopWindow(rawProperty, propertyHelpers);
    if (!loopWindow) {
        return clonePropertyValue(rawProperty?.k ?? 0);
    }

    const normalizedMode = typeof mode === 'string' ? mode.toLowerCase() : 'cycle';
    const { first, last, duration } = loopWindow;
    const isOut = direction === 'out';
    const frameOutsideWindow = isOut ? frame > last : frame < first;
    if (!frameOutsideWindow) {
        return sampleKeyframedProperty(rawProperty, frame);
    }

    const distance = isOut ? frame - last : first - frame;
    const cycles = Math.floor(distance / duration);
    const remainder = wrappingModulo(distance, duration);
    const startValue = sampleKeyframedProperty(rawProperty, first);
    const endValue = sampleKeyframedProperty(rawProperty, last);

    if (normalizedMode === 'hold') {
        return isOut ? endValue : startValue;
    }

    if (normalizedMode === 'continue') {
        const sampleTime = isOut
            ? Math.max(first, last - frameDuration / 10)
            : Math.min(last, first + frameDuration / 10);
        const velocity = propertyHelpers.velocityAtTime(sampleTime * frameDuration);
        const baseValue = isOut ? endValue : startValue;
        const deltaTime = (isOut ? frame - last : frame - first) * frameDuration;
        return binaryOp(baseValue, velocity, (base, rate) => base + rate * deltaTime);
    }

    let sampleFrame;
    if (normalizedMode === 'pingpong') {
        const progressFrame = remainder === 0 && cycles > 0 ? duration : remainder;
        const reverse = cycles % 2 === 1;
        sampleFrame = reverse
            ? (isOut ? last - progressFrame : first + progressFrame)
            : (isOut ? first + progressFrame : last - progressFrame);
    } else {
        const progressFrame = remainder === 0 && cycles > 0 ? duration : remainder;
        sampleFrame = isOut ? first + progressFrame : last - progressFrame;
    }

    let sampledValue = sampleKeyframedProperty(rawProperty, sampleFrame);
    if (normalizedMode === 'offset') {
        const cycleDelta = binaryOp(endValue, startValue, (end, start) => end - start);
        const cycleCount = cycles + (remainder > 0 ? 1 : 0);
        sampledValue = binaryOp(
            sampledValue,
            cycleDelta,
            (value, delta) => value + delta * (isOut ? cycleCount : -cycleCount),
        );
    }
    return sampledValue;
}

function createThisProperty(rawProperty, rawPropertyContext, propertyHelpers, frame, frameDuration, layer, animationData, currentPath, compLayers = null) {
    const effectGroup = rawPropertyContext?.parents?.slice().reverse().find((candidate) => Array.isArray(candidate?.ef)) ?? null;
    const baseProperty = {
        numKeys: propertyHelpers.numKeys,
        key: propertyHelpers.key,
        nearestKey: propertyHelpers.nearestKey,
        velocityAtTime: propertyHelpers.velocityAtTime,
        propertyGroup: (index) => {
            if (Number(index) === 1 && effectGroup) {
                return createEffectGroupAccessor(effectGroup, animationData, frame, compLayers);
            }
            return () => 0;
        },
        loopOut: (mode = 'cycle') => computeLoopValue(rawProperty, propertyHelpers, frame, frameDuration, 'out', mode),
        loopIn: (mode = 'cycle') => computeLoopValue(rawProperty, propertyHelpers, frame, frameDuration, 'in', mode),
    };

    if (!currentPath) {
        return baseProperty;
    }

    const layerMatrix = evaluateLayerMatrix(layer ?? {}, animationData, frame);
    const inverseLayerMatrix = invertMatrix(layerMatrix);
    const currentPathGeometry = {
        vertices: currentPath.vertices,
        inTangents: currentPath.inTangents,
        outTangents: currentPath.outTangents,
        closed: currentPath.closed,
    };
    return {
        ...baseProperty,
        points: () => clonePointArray(currentPath.vertices),
        inTangents: () => clonePointArray(currentPath.inTangents),
        outTangents: () => clonePointArray(currentPath.outTangents),
        isClosed: () => !!currentPath.closed,
        pointOnPath: (progress) => cloneNumberArray(samplePathAtProgress(currentPathGeometry, progress).point),
        tangentOnPath: (progress) => cloneNumberArray(samplePathAtProgress(currentPathGeometry, progress).tangent),
        fromCompToSurface: (point) => applyMatrixToPoint(inverseLayerMatrix, point),
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
    currentCompLayers,
}) {
    const fps = Number(playbackMeta?.fps) || Number(animationData?.fr) || DEFAULT_FPS;
    const frameDuration = fps > 0 ? 1 / fps : DEFAULT_FRAME_DURATION;
    const rawPropertyContext = findPropertyContextByExpression(layer, expression);
    const rawProperty = rawPropertyContext?.property ?? null;
    const propertyHelpers = createPropertyHelpers(rawProperty, frame, frameDuration);
    const currentLayerProxy = createLayerProxy(layer ?? {}, animationData, frame);
    const currentLayerMatrix = evaluateLayerMatrix(layer ?? {}, animationData, frame);
    const currentLayerInverseMatrix = invertMatrix(currentLayerMatrix);
    const thisProperty = createThisProperty(
        rawProperty,
        rawPropertyContext,
        propertyHelpers,
        frame,
        frameDuration,
        layer,
        animationData,
        currentPath,
        currentCompLayers,
    );

    return {
        value: clonePropertyValue(value),
        time: frame * frameDuration,
        thisComp: {
            frameDuration,
            width: Number(animationData?.w) || 0,
            height: Number(animationData?.h) || 0,
            layer: (layerRef) => {
                const matchedLayer = findLayerInComp(currentCompLayers, layerRef)
                    ?? findLayerByIndex(animationData, layerRef);
                return matchedLayer ? createLayerProxy(matchedLayer, animationData, frame) : {};
            },
        },
        thisLayer: currentLayerProxy,
        thisProperty,
        effect: createEffectAccessor(layer, animationData, frame, currentCompLayers),
        numKeys: propertyHelpers.numKeys,
        key: propertyHelpers.key,
        nearestKey: propertyHelpers.nearestKey,
        velocityAtTime: propertyHelpers.velocityAtTime,
        loopIn: (mode = 'cycle') => thisProperty.loopIn(mode),
        loopOut: (mode = 'cycle') => thisProperty.loopOut(mode),
        framesToTime: (value) => (Number(value) || 0) * frameDuration,
        timeToFrames: (value) => (Number(value) || 0) / frameDuration,
        fromCompToSurface: (point) => applyMatrixToPoint(currentLayerInverseMatrix, point),
        createPath,
        radiansToDegrees: (value) => (Number(value) || 0) * 180 / Math.PI,
        degreesToRadians: (value) => (Number(value) || 0) * Math.PI / 180,
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
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression);
            const layer = layerContext?.layer ?? null;
            try {
                const result = getExpressionFunction(expression)(
                    buildContext({
                        expression,
                        frame,
                        layer,
                        value,
                        animationData,
                        playbackMeta: getPlaybackMeta(),
                        currentCompLayers: layerContext?.layers ?? animationData?.layers ?? [],
                    }),
                );
                if (Number.isFinite(result)) {
                    return result;
                }
                const scalarResult = unwrapScalarValue(result);
                return Number.isFinite(scalarResult) ? scalarResult : value;
            } catch (error) {
                console.warn('[MoonLottie] expression evaluateDouble failed', error);
                return value;
            }
        },

        evaluateVec(expression, frame, layerIndex, value) {
            const animationData = getAnimationData();
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression);
            const layer = layerContext?.layer ?? null;
            try {
                const result = getExpressionFunction(expression)(
                    buildContext({
                        expression,
                        frame,
                        layer,
                        value: cloneNumberArray(value),
                        animationData,
                        playbackMeta: getPlaybackMeta(),
                        currentCompLayers: layerContext?.layers ?? animationData?.layers ?? [],
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
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression);
            const layer = layerContext?.layer ?? null;
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
                        currentCompLayers: layerContext?.layers ?? animationData?.layers ?? [],
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
