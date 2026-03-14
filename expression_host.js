const expressionFunctionCache = new Map();
let externalExpressionHost = null;
const DEFAULT_FPS = 60;
const DEFAULT_FRAME_DURATION = 1 / DEFAULT_FPS;
const layerExpressionContextCache = new WeakMap();

// Guard against infinite expression recursion (e.g., A→B→A chains).
let _expressionCallDepth = 0;
const MAX_EXPRESSION_CALL_DEPTH = 16;

// CSS cubic-bezier solver used for keyframe easing.
// Finds t such that BezierX(t) = targetX, then returns BezierY(t).
// Control points are P0=(0,0), P1=(x1,y1), P2=(x2,y2), P3=(1,1).
function solveCubicBezierEasing(x1, y1, x2, y2, targetX) {
    if (targetX <= 0) return 0;
    if (targetX >= 1) return 1;
    const cx = 3 * x1;
    const bx = 3 * (x2 - x1) - cx;
    const ax = 1 - cx - bx;
    const cy = 3 * y1;
    const by = 3 * (y2 - y1) - cy;
    const ay = 1 - cy - by;
    // Newton's method to solve ax*t^3 + bx*t^2 + cx*t - targetX = 0
    let t = targetX;
    for (let i = 0; i < 8; i++) {
        const x = ((ax * t + bx) * t + cx) * t - targetX;
        const dx = (3 * ax * t + 2 * bx) * t + cx;
        if (Math.abs(dx) < 1e-6) break;
        t -= x / dx;
    }
    return ((ay * t + by) * t + cy) * t;
}

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
            // Apply cubic-bezier easing: CP1 = current.o (out), CP2 = next.i (in).
            // This matches the standard lottie / lottie-web convention.
            let easedProgress = progress;
            const ox = current.o?.x;
            const oy = current.o?.y;
            const ix = next.i?.x;
            const iy = next.i?.y;
            if (typeof ox === 'number' && typeof oy === 'number' &&
                typeof ix === 'number' && typeof iy === 'number') {
                easedProgress = solveCubicBezierEasing(ox, oy, ix, iy, progress);
            }
            if (Array.isArray(start) && Array.isArray(end)) {
                return start.map((value, index) => (Number(value) || 0) + ((Number(end[index]) || 0) - (Number(value) || 0)) * easedProgress);
            }
            return (Number(start) || 0) + ((Number(end) || 0) - (Number(start) || 0)) * easedProgress;
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

function findLayerContextByIndex(animationData, layerIndex, expression = null, compId = '') {
    const targetIndex = Number(layerIndex);
    const preferredLayers = findLayerCollectionForCompId(animationData, compId);
    const collections = preferredLayers
        ? [preferredLayers, ...getLayerCollections(animationData).filter((layers) => layers !== preferredLayers)]
        : getLayerCollections(animationData);
    const candidates = [];
    for (const layers of collections) {
        for (const layer of layers) {
            if (Number(layer?.ind) !== targetIndex) {
                continue;
            }
            const candidate = { layer, layers };
            candidates.push(candidate);
            if (!expression || getCachedPropertyContextsByExpression(layer, expression).length > 0) {
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

function findLayerCollectionForCompId(animationData, compId) {
    if (!compId) {
        return Array.isArray(animationData?.layers) ? animationData.layers : null;
    }
    if (!Array.isArray(animationData?.assets)) {
        return null;
    }
    const asset = animationData.assets.find((candidate) => candidate?.id === compId);
    return Array.isArray(asset?.layers) ? asset.layers : null;
}

function findLayerInComp(layers, layerRef) {
    if (!Array.isArray(layers)) return null;
    if (typeof layerRef === 'number') {
        return layers.find((candidate) => Number(candidate?.ind) === Number(layerRef)) ?? null;
    }
    return layers.find((candidate) => candidate?.nm === layerRef) ?? null;
}

function findCompAsset(animationData, compRef) {
    if (!compRef || !Array.isArray(animationData?.assets)) {
        return null;
    }
    const normalizedRef = String(compRef);
    return animationData.assets.find((candidate) =>
        Array.isArray(candidate?.layers)
        && (candidate.id === normalizedRef
            || candidate.nm === normalizedRef
            || candidate.p === normalizedRef),
    ) ?? null;
}

function flattenPropertyMatchValue(value, result = []) {
    if (Array.isArray(value)) {
        for (const item of value) {
            flattenPropertyMatchValue(item, result);
        }
        return result;
    }
    if (value && typeof value === 'object') {
        if (Array.isArray(value.vertices)) {
            flattenPropertyMatchValue(value.vertices, result);
            flattenPropertyMatchValue(value.inTangents, result);
            flattenPropertyMatchValue(value.outTangents, result);
            result.push(value.closed ? 1 : 0);
        }
        return result;
    }
    const numeric = Number(value);
    if (Number.isFinite(numeric)) {
        result.push(numeric);
    }
    return result;
}

function scorePropertyContextMatch(property, frame, value) {
    const expected = flattenPropertyMatchValue(value);
    const sampled = flattenPropertyMatchValue(sampleKeyframedProperty(property, frame));
    if (expected.length === 0 && sampled.length === 0) {
        return 0;
    }
    if (expected.length === 0 || sampled.length === 0) {
        return Number.POSITIVE_INFINITY;
    }
    let score = Math.abs(expected.length - sampled.length) * 1000;
    const length = Math.min(expected.length, sampled.length);
    for (let index = 0; index < length; index++) {
        score += Math.abs(expected[index] - sampled[index]);
    }
    return score;
}

function findPropertyContextsByExpression(node, expression, parents = [], matches = []) {
    if (!node || typeof node !== 'object' || !expression) {
        return matches;
    }
    if (Array.isArray(node)) {
        for (const item of node) {
            findPropertyContextsByExpression(item, expression, parents, matches);
        }
        return matches;
    }
    if (node.x === expression) {
        matches.push({ property: node, parents });
    }
    for (const value of Object.values(node)) {
        findPropertyContextsByExpression(value, expression, [...parents, node], matches);
    }
    return matches;
}

function getCachedPropertyContextsByExpression(layer, expression) {
    if (!layer || typeof layer !== 'object' || !expression) {
        return [];
    }
    let expressionCache = layerExpressionContextCache.get(layer);
    if (!expressionCache) {
        expressionCache = new Map();
        layerExpressionContextCache.set(layer, expressionCache);
    }
    if (!expressionCache.has(expression)) {
        expressionCache.set(expression, findPropertyContextsByExpression(layer, expression));
    }
    return expressionCache.get(expression) ?? [];
}

function resolvePropertyContextByExpression(layer, expression, frame, value) {
    const contexts = getCachedPropertyContextsByExpression(layer, expression);
    if (contexts.length <= 1) {
        return contexts[0] ?? null;
    }
    let bestContext = contexts[0] ?? null;
    let bestScore = Number.POSITIVE_INFINITY;
    for (const context of contexts) {
        const score = scorePropertyContextMatch(context.property, frame, value);
        if (score < bestScore) {
            bestScore = score;
            bestContext = context;
        }
    }
    return bestContext;
}

function coerceExpressionResult(result, fallbackValue) {
    if (Array.isArray(fallbackValue)) {
        return Array.isArray(result) ? cloneNumberArray(result) : cloneNumberArray(fallbackValue);
    }
    const scalar = unwrapScalarValue(result);
    return Number.isFinite(scalar) ? scalar : (Number(fallbackValue) || 0);
}

function evaluateHostedExpressionValue(expression, frame, layer, value, animationData, currentCompLayers, currentPath = null) {
    if (_expressionCallDepth >= MAX_EXPRESSION_CALL_DEPTH) {
        return value;
    }
    _expressionCallDepth++;
    try {
        const result = getExpressionFunction(expression)(
            buildContext({
                expression,
                frame,
                layer,
                value: clonePropertyValue(value),
                animationData,
                playbackMeta: { fps: Number(animationData?.fr) || DEFAULT_FPS },
                currentPath: currentPath ?? null,
                currentCompLayers,
            }),
        );
        _expressionCallDepth--;
        return result;
    } catch (error) {
        _expressionCallDepth--;
        console.warn('[MoonLottie] expression evaluation failed', error);
        return value;
    }
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
        const fallbackEvaluatorPrelude = `
const {
  value,
  time,
    comp,
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
`;
        expressionFunctionCache.set(
            expression,
            new Function(
                'context',
                `
${fallbackEvaluatorPrelude}
${expression}
return typeof $bm_rt === 'undefined' ? value : $bm_rt;
`,
            ),
        );
    }
    return expressionFunctionCache.get(expression);
}

function createEffectAccessor(layer, animationData, frame, compLayers = null, activeExpression = null) {
    return (effectName) => {
        const effect = layer?.ef?.find((item) => item?.nm === effectName || item?.mn === effectName) ?? null;
        return (paramName) => {
            const param = effect?.ef?.find((item) => item?.mn === paramName || item?.nm === paramName) ?? null;
            if (!param) return 0;
            if (param.v) {
                const baseValue = sampleKeyframedProperty(param.v, frame);
                const expression = typeof param.v.x === 'string' ? param.v.x : null;
                const value = (expression && expression !== activeExpression)
                    ? coerceExpressionResult(
                        evaluateHostedExpressionValue(expression, frame, layer, baseValue, animationData, compLayers),
                        baseValue,
                    )
                    : baseValue;
                if (param.mn === 'ADBE Layer Control-0001') {
                    const layerIndex = Number(value) || 0;
                    const targetLayer = findLayerInComp(compLayers, layerIndex) ?? findLayerByIndex(animationData, layerIndex);
                    return targetLayer ? createLayerProxy(targetLayer, animationData, frame, compLayers, activeExpression) : {};
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

function findLayerParent(layer, animationData, compLayers = null) {
    if (!layer?.parent) return null;
    const parentInComp = findLayerInComp(compLayers, Number(layer.parent));
    if (parentInComp) {
        return parentInComp;
    }
    return animationData?.layers?.find((candidate) => Number(candidate?.ind) === Number(layer.parent)) ?? null;
}

function evaluateLayerMatrix(layer, animationData, frame, compLayers = null, activeExpression = null, evaluateExpressions = true) {
    const transform = layer?.ks ?? {};

    // Helper: evaluate a transform property's expression (if any) to get the
    // final value.  Skips the expression when it matches activeExpression to
    // prevent direct self-recursion (e.g. the bounce expr reading its own position).
    const resolveTransformProp = (prop, rawValue) => {
        if (!prop) return rawValue;
        const expr = typeof prop.x === 'string' ? prop.x : null;
        if (!evaluateExpressions || !expr || expr === activeExpression) return rawValue;
        const result = evaluateHostedExpressionValue(expr, frame, layer, rawValue, animationData, compLayers);
        return coerceExpressionResult(result, rawValue);
    };

    const rawPosition = getTransformPosition(transform, frame);
    const rawAnchor   = getTransformAnchor(transform, frame);
    const rawScale    = getTransformScale(transform, frame);
    const rawRotation = getTransformRotation(transform, frame);

    // Use split-position property if present, otherwise the combined p property.
    const positionProp = transform.p?.s === true ? null : transform.p;
    const position = cloneNumberArray(resolveTransformProp(positionProp, rawPosition));
    const anchor   = cloneNumberArray(resolveTransformProp(transform.a, rawAnchor));
    const scale    = cloneNumberArray(resolveTransformProp(transform.s, rawScale));
    const rotRaw   = resolveTransformProp(transform.r ?? transform.rz, rawRotation);
    const rotation = typeof rotRaw === 'number' ? rotRaw : unwrapScalarValue(rotRaw);

    let matrix = createTranslationMatrix(position[0] ?? 0, position[1] ?? 0);
    matrix = multiplyMatrices(matrix, createRotationMatrix(rotation));
    matrix = multiplyMatrices(matrix, createScaleMatrix((scale[0] ?? 100) / 100, (scale[1] ?? 100) / 100));
    matrix = multiplyMatrices(matrix, createTranslationMatrix(-(anchor[0] ?? 0), -(anchor[1] ?? 0)));

    const parent = findLayerParent(layer, animationData, compLayers);
    return parent
        ? multiplyMatrices(evaluateLayerMatrix(parent, animationData, frame, compLayers, activeExpression, evaluateExpressions), matrix)
        : matrix;
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

const DEFAULT_CURVE_SEGMENTS = 150;

function createExpressionShapePath(pathValue) {
    const { vertices, inTangents, outTangents, closed } = createBezierSegments(pathValue);
    return {
        v: vertices,
        i: vertices.map((point, index) => [
            (point[0] ?? 0) + (inTangents[index]?.[0] ?? 0),
            (point[1] ?? 0) + (inTangents[index]?.[1] ?? 0),
        ]),
        o: vertices.map((point, index) => [
            (point[0] ?? 0) + (outTangents[index]?.[0] ?? 0),
            (point[1] ?? 0) + (outTangents[index]?.[1] ?? 0),
        ]),
        c: closed,
        _length: vertices.length,
    };
}

function getBezierLength(pt1, pt2, pt3, pt4) {
    let addedLength = 0;
    const percents = [];
    const lengths = [];
    const point = [];
    const lastPoint = [];
    const len = pt3.length;

    for (let segmentIndex = 0; segmentIndex < DEFAULT_CURVE_SEGMENTS; segmentIndex++) {
        const perc = segmentIndex / (DEFAULT_CURVE_SEGMENTS - 1);
        let pointDistance = 0;
        for (let coordIndex = 0; coordIndex < len; coordIndex++) {
            const coord =
                (1 - perc) ** 3 * pt1[coordIndex]
                + 3 * (1 - perc) ** 2 * perc * pt3[coordIndex]
                + 3 * (1 - perc) * perc ** 2 * pt4[coordIndex]
                + perc ** 3 * pt2[coordIndex];
            point[coordIndex] = coord;
            if (lastPoint[coordIndex] != null) {
                pointDistance += (point[coordIndex] - lastPoint[coordIndex]) ** 2;
            }
            lastPoint[coordIndex] = point[coordIndex];
        }
        if (pointDistance) {
            pointDistance = Math.sqrt(pointDistance);
            addedLength += pointDistance;
        }
        percents[segmentIndex] = perc;
        lengths[segmentIndex] = addedLength;
    }

    return { addedLength, percents, lengths };
}

function getSegmentsLength(shapePath) {
    const lengths = [];
    let totalLength = 0;
    for (let index = 0; index < shapePath._length - 1; index++) {
        lengths[index] = getBezierLength(
            shapePath.v[index],
            shapePath.v[index + 1],
            shapePath.o[index],
            shapePath.i[index + 1],
        );
        totalLength += lengths[index].addedLength;
    }
    if (shapePath.c && shapePath._length > 0) {
        const lastIndex = shapePath._length - 1;
        lengths[lastIndex] = getBezierLength(
            shapePath.v[lastIndex],
            shapePath.v[0],
            shapePath.o[lastIndex],
            shapePath.i[0],
        );
        totalLength += lengths[lastIndex].addedLength;
    }
    return { lengths, totalLength };
}

function getDistancePerc(perc, bezierData) {
    const { percents, lengths } = bezierData;
    const len = percents.length;
    let initPos = Math.floor((len - 1) * perc);
    const lengthPos = perc * bezierData.addedLength;
    let lerpPerc = 0;

    if (initPos === len - 1 || initPos === 0 || lengthPos === lengths[initPos]) {
        return percents[initPos];
    }

    const dir = lengths[initPos] > lengthPos ? -1 : 1;
    let searching = true;
    while (searching) {
        if (lengths[initPos] <= lengthPos && lengths[initPos + 1] > lengthPos) {
            lerpPerc = (lengthPos - lengths[initPos]) / (lengths[initPos + 1] - lengths[initPos]);
            searching = false;
        } else {
            initPos += dir;
        }
        if (initPos < 0 || initPos >= len - 1) {
            if (initPos === len - 1) {
                return percents[initPos];
            }
            searching = false;
        }
    }

    return percents[initPos] + (percents[initPos + 1] - percents[initPos]) * lerpPerc;
}

function getPointInSegment(pt1, pt2, pt3, pt4, percent, bezierData) {
    const t = getDistancePerc(percent, bezierData);
    const u = 1 - t;
    const x = Math.round((
        u ** 3 * pt1[0]
        + (t * u ** 2 + u * t * u + u ** 2 * t) * pt3[0]
        + (t ** 2 * u + u * t ** 2 + t * u * t) * pt4[0]
        + t ** 3 * pt2[0]
    ) * 1000) / 1000;
    const y = Math.round((
        u ** 3 * pt1[1]
        + (t * u ** 2 + u * t * u + u ** 2 * t) * pt3[1]
        + (t ** 2 * u + u * t ** 2 + t * u * t) * pt4[1]
        + t ** 3 * pt2[1]
    ) * 1000) / 1000;
    return [x, y];
}

function pointOnPath(shapePath, progress, cachedSegmentsLength = null) {
    if (!shapePath || shapePath._length === 0) {
        return [0, 0];
    }
    const clampedProgress = Math.min(Math.max(Number(progress) || 0, 0), 1);
    const segmentsLength = cachedSegmentsLength ?? getSegmentsLength(shapePath);
    const lengthPos = segmentsLength.totalLength * clampedProgress;
    let accumulatedLength = 0;

    for (let index = 0; index < segmentsLength.lengths.length; index++) {
        const segmentLength = segmentsLength.lengths[index];
        if (!segmentLength) {
            continue;
        }
        if (accumulatedLength + segmentLength.addedLength > lengthPos) {
            const endIndex = (shapePath.c && index === segmentsLength.lengths.length - 1) ? 0 : index + 1;
            const segmentPerc = (lengthPos - accumulatedLength) / segmentLength.addedLength;
            return getPointInSegment(
                shapePath.v[index],
                shapePath.v[endIndex],
                shapePath.o[index],
                shapePath.i[endIndex],
                segmentPerc,
                segmentLength,
            );
        }
        accumulatedLength += segmentLength.addedLength;
    }

    return shapePath.c
        ? [shapePath.v[0][0], shapePath.v[0][1]]
        : [shapePath.v[shapePath._length - 1][0], shapePath.v[shapePath._length - 1][1]];
}

function vectorOnPath(shapePath, progress, vectorType, cachedSegmentsLength = null) {
    let normalizedProgress = progress;
    // Match lottie-web's exact endpoint handling.
    if (normalizedProgress == 1) {
        normalizedProgress = shapePath.c;
    } else if (normalizedProgress == 0) {
        normalizedProgress = 0.999;
    }
    const pt1 = pointOnPath(shapePath, normalizedProgress, cachedSegmentsLength);
    const pt2 = pointOnPath(shapePath, normalizedProgress + 0.001, cachedSegmentsLength);
    const xLength = pt2[0] - pt1[0];
    const yLength = pt2[1] - pt1[1];
    const magnitude = Math.sqrt(xLength ** 2 + yLength ** 2);
    if (magnitude === 0) {
        return [0, 0];
    }
    return vectorType === 'tangent'
        ? [xLength / magnitude, yLength / magnitude]
        : [-yLength / magnitude, xLength / magnitude];
}

function samplePathAtProgress(pathValue, progress) {
    const shapePath = createExpressionShapePath(pathValue);
    return {
        point: pointOnPath(shapePath, progress),
        tangent: vectorOnPath(shapePath, progress, 'tangent'),
    };
}

function createPathProxy(pathValue, lengthSourcePathValue = null) {
    const {
        vertices,
        inTangents: inTangentPoints,
        outTangents: outTangentPoints,
        closed,
    } = createBezierSegments(pathValue);
    const shapePath = createExpressionShapePath(pathValue);
    const lengthSourceShapePath = lengthSourcePathValue ? createExpressionShapePath(lengthSourcePathValue) : shapePath;
    const segmentsLength = getSegmentsLength(lengthSourceShapePath);
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
        pointOnPath: (progress) => cloneNumberArray(pointOnPath(shapePath, progress, segmentsLength)),
        tangentOnPath: (progress) => cloneNumberArray(vectorOnPath(shapePath, progress, 'tangent', segmentsLength)),
    };
    proxyTarget.path = proxyTarget;
    return proxyTarget;
}

function createTransformProxy(layer, animationData, frame, compLayers = null, activeExpression = null) {
    const transform = layer?.ks ?? {};
    const resolveValue = (prop, fallbackValue) => {
        const expression = typeof prop?.x === 'string' ? prop.x : null;
        if (!expression || expression === activeExpression) {
            return clonePropertyValue(fallbackValue);
        }
        return coerceExpressionResult(
            evaluateHostedExpressionValue(expression, frame, layer, fallbackValue, animationData, compLayers),
            fallbackValue,
        );
    };
    return {
        anchorPoint: resolveValue(transform.a, getTransformAnchor(transform, frame)),
        position: resolveValue(transform.p, getTransformPosition(transform, frame)),
        scale: resolveValue(transform.s, getTransformScale(transform, frame)),
        rotation: resolveValue(transform.r ?? transform.rz, getTransformRotation(transform, frame)),
        opacity: resolveValue(transform.o, Number(sampleKeyframedProperty(transform.o, frame)) || 0),
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

function resolveShapeSelector(target, selector, frame, animationData = null, compLayers = null, parentLayer = null, activeExpression = null) {
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
        if (!target.ks) return null;
        const rawPath = sampleKeyframedProperty(target.ks, frame);
        // Evaluate the shape path expression so callers (e.g. light-position
        // expressions) see the expression-modified wire path rather than the
        // static base path.
        const pathExpr = typeof target.ks.x === 'string' ? target.ks.x : null;
        if (pathExpr && pathExpr !== activeExpression && parentLayer && animationData) {
            try {
                const { vertices, inTangents, outTangents, closed } = createBezierSegments(rawPath);
                const currentPath = { vertices, inTangents, outTangents, closed };
                const result = evaluateHostedExpressionValue(pathExpr, frame, parentLayer, rawPath, animationData, compLayers, currentPath);
                if (result && Array.isArray(result.vertices) && Array.isArray(result.inTangents) && Array.isArray(result.outTangents)) {
                    return createPathProxy(result, rawPath);
                }
            } catch (_) {}
        }
        return createPathProxy(rawPath);
    }
    return null;
}

function resolveShapePathForProp(ksProperty, frame, animationData, compLayers, parentLayer, activeExpression) {
    const rawPath = sampleKeyframedProperty(ksProperty, frame);
    const pathExpr = typeof ksProperty.x === 'string' ? ksProperty.x : null;
    if (pathExpr && pathExpr !== activeExpression && parentLayer && animationData) {
        try {
            // Extract a normalised path geometry (vertices/inTangents/outTangents/closed)
            // from the raw JSON path so buildContext can populate thisProperty.points() etc.
            const { vertices, inTangents, outTangents, closed } = createBezierSegments(rawPath);
            const currentPath = { vertices, inTangents, outTangents, closed };
            const result = evaluateHostedExpressionValue(pathExpr, frame, parentLayer, rawPath, animationData, compLayers, currentPath);
            if (result && Array.isArray(result.vertices) && Array.isArray(result.inTangents) && Array.isArray(result.outTangents)) {
                return createPathProxy(result, rawPath);
            }
        } catch (_) {}
    }
    return createPathProxy(rawPath);
}

function createShapeProxy(target, frame, animationData = null, compLayers = null, parentLayer = null, activeExpression = null) {
    const callable = function (selector) {
        const next = resolveShapeSelector(target, selector, frame, animationData, compLayers, parentLayer, activeExpression);
        return next ? createShapeProxy(next, frame, animationData, compLayers, parentLayer, activeExpression) : {};
    };

    return new Proxy(callable, {
        apply(_fn, _thisArg, args) {
            return callable(args[0]);
        },
        get(_fn, prop) {
            if (prop === 'path') {
                if (target?.ks) {
                    return resolveShapePathForProp(target.ks, frame, animationData, compLayers, parentLayer, activeExpression);
                }
                return undefined;
            }
            if (prop === 'points' || prop === 'inTangents' || prop === 'outTangents' || prop === 'isClosed' || prop === 'pointOnPath' || prop === 'tangentOnPath' || prop === 'vertices' || prop === 'closed') {
                const pathProxy = target?.ks
                    ? resolveShapePathForProp(target.ks, frame, animationData, compLayers, parentLayer, activeExpression)
                    : target;
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

function createLayerProxy(layer, animationData, frame, compLayers = null, activeExpression = null) {
    const callable = function (selector) {
        const next = resolveShapeSelector(layer, selector, frame, animationData, compLayers, layer, activeExpression);
        return next ? createShapeProxy(next, frame, animationData, compLayers, layer, activeExpression) : {};
    };

    return new Proxy(callable, {
        apply(_fn, _thisArg, args) {
            return callable(args[0]);
        },
        get(_fn, prop) {
            if (prop === 'effect') return createEffectAccessor(layer, animationData, frame, compLayers, activeExpression);
            if (prop === 'mask') return createMaskAccessor(layer, frame);
            if (prop === 'content') {
                return (name) => {
                    const match = findShapeByName(layer?.shapes ?? [], name);
                    return match ? createShapeProxy(match, frame, animationData, compLayers, layer, activeExpression) : {};
                };
            }
            if (prop === 'transform') return createTransformProxy(layer, animationData, frame, compLayers, activeExpression);
            if (prop === 'toComp') {
                // Use activeExpression so this layer's own transform expressions are
                // not re-entered when computing the matrix for toComp.
                return (point) => applyMatrixToPoint(evaluateLayerMatrix(layer, animationData, frame, compLayers, activeExpression), point);
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
        const deltaSeconds = -0.001;
        const frameCenter = (Number(timeSeconds) || 0) / safeDuration;
        const before = sampleKeyframedProperty(rawProperty, frameCenter);
        const after = sampleKeyframedProperty(rawProperty, (Number(timeSeconds) + deltaSeconds) / safeDuration);
        return binaryOp(after, before, (left, right) => (left - right) / deltaSeconds);
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
            return targetLayer ? createLayerProxy(targetLayer, animationData, frame, compLayers) : {};
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

function createThisProperty(rawProperty, rawPropertyContext, propertyHelpers, frame, frameDuration, layer, animationData, currentPath, compLayers = null, activeExpression = null) {
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

    // Use the current expression as activeExpression when computing the layer
    // matrix so the property's own position expression is not re-invoked.
    const layerMatrix = evaluateLayerMatrix(layer ?? {}, animationData, frame, compLayers, activeExpression, false);
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
    const rawPropertyContext = resolvePropertyContextByExpression(layer, expression, frame, value);
    const rawProperty = rawPropertyContext?.property ?? null;
    const propertyHelpers = createPropertyHelpers(rawProperty, frame, frameDuration);
    const currentLayerProxy = createLayerProxy(layer ?? {}, animationData, frame, currentCompLayers, expression);
    // Pass the current expression as activeExpression so the layer's own transform
    // expressions are not re-entered while computing the matrix / inverse.
    const currentLayerMatrix = evaluateLayerMatrix(layer ?? {}, animationData, frame, currentCompLayers, expression, false);
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
        expression,
    );

    const createCompProxy = (compRef) => {
        const assetComp = findCompAsset(animationData, compRef);
        const compLayers = Array.isArray(assetComp?.layers)
            ? assetComp.layers
            : (Array.isArray(currentCompLayers) ? currentCompLayers : animationData?.layers ?? []);
        return {
            name: assetComp?.nm ?? String(compRef ?? ''),
            width: Number(assetComp?.w) || Number(animationData?.w) || 0,
            height: Number(assetComp?.h) || Number(animationData?.h) || 0,
            frameDuration,
            layer: (layerRef) => {
                const matchedLayer = findLayerInComp(compLayers, layerRef)
                    ?? findLayerByIndex(animationData, layerRef);
                return matchedLayer ? createLayerProxy(matchedLayer, animationData, frame, compLayers, expression) : {};
            },
        };
    };

    return {
        value: clonePropertyValue(value),
        time: frame * frameDuration,
        comp: (compRef) => createCompProxy(compRef),
        thisComp: {
            frameDuration,
            width: Number(animationData?.w) || 0,
            height: Number(animationData?.h) || 0,
            layer: (layerRef) => {
                const matchedLayer = findLayerInComp(currentCompLayers, layerRef)
                    ?? findLayerByIndex(animationData, layerRef);
                return matchedLayer ? createLayerProxy(matchedLayer, animationData, frame, currentCompLayers, expression) : {};
            },
        },
        thisLayer: currentLayerProxy,
        thisProperty,
        effect: createEffectAccessor(layer, animationData, frame, currentCompLayers, expression),
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
        evaluateDouble(expression, frame, layerIndex, compIdOrLegacyValue, maybeValue) {
            const animationData = getAnimationData();
            const compId = maybeValue === undefined ? '' : String(compIdOrLegacyValue ?? '');
            const value = maybeValue === undefined ? compIdOrLegacyValue : maybeValue;
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression, compId);
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
                        currentCompLayers:
                            layerContext?.layers
                            ?? findLayerCollectionForCompId(animationData, compId)
                            ?? animationData?.layers
                            ?? [],
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

        evaluateVec(expression, frame, layerIndex, compIdOrLegacyValue, maybeValue) {
            const animationData = getAnimationData();
            const compId = maybeValue === undefined ? '' : String(compIdOrLegacyValue ?? '');
            const value = maybeValue === undefined ? compIdOrLegacyValue : maybeValue;
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression, compId);
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
                        currentCompLayers:
                            layerContext?.layers
                            ?? findLayerCollectionForCompId(animationData, compId)
                            ?? animationData?.layers
                            ?? [],
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

        evaluatePath(expression, frame, layerIndex, compIdOrLegacyValue, maybeValue) {
            const animationData = getAnimationData();
            const compId = maybeValue === undefined ? '' : String(compIdOrLegacyValue ?? '');
            const pathValue = maybeValue === undefined ? compIdOrLegacyValue : maybeValue;
            const layerContext = findLayerContextByIndex(animationData, layerIndex, expression, compId);
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
                        currentCompLayers:
                            layerContext?.layers
                            ?? findLayerCollectionForCompId(animationData, compId)
                            ?? animationData?.layers
                            ?? [],
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
        evaluate_double: (expression, frame, layerIndex, compId, value) =>
            resolveHost().evaluateDouble(expression, frame, layerIndex, compId, value),
        evaluate_vec: (expression, frame, layerIndex, compId, value) =>
            serializeNumberArray(parseNumberArray(resolveHost().evaluateVec(expression, frame, layerIndex, compId, parseNumberArray(value)))),
        evaluate_path: (expression, frame, layerIndex, compId, value) =>
            serializePath(resolveHost().evaluatePath(expression, frame, layerIndex, compId, parsePath(value))),
    };
}
