import { createEventEmitter } from './event-emitter.js';

export function createPlaybackController(options = {}) {
    const {
        requestAnimationFrameFn = window.requestAnimationFrame.bind(window),
        cancelAnimationFrameFn = window.cancelAnimationFrame.bind(window),
        getMeta = () => null,
        getSpeed = () => 1,
        getDirection = () => 1,
        getLoop = () => true,
        canRender = () => true,
        onRenderFrame = () => {},
        onFrameChange = () => {},
        onPlayStateChange = () => {},
    } = options;

    const emitter = createEventEmitter();
    let currentFrame = 0;
    let isPlaying = true;
    let lastTimestamp = 0;
    let requestId = null;
    let useSubframes = true;
    let activeSegment = null;
    let queuedSegments = [];

    function normalizeSegment(segment) {
        if (!Array.isArray(segment) || segment.length < 2) {
            return null;
        }

        const start = Number(segment[0]);
        const end = Number(segment[1]);
        if (!Number.isFinite(start) || !Number.isFinite(end)) {
            return null;
        }

        return start <= end ? [start, end] : [end, start];
    }

    function normalizeSegments(segments) {
        if (!Array.isArray(segments)) {
            return [];
        }

        if (segments.length >= 2 && !Array.isArray(segments[0])) {
            const single = normalizeSegment(segments);
            return single ? [single] : [];
        }

        return segments.map(normalizeSegment).filter(Boolean);
    }

    function getPlaybackBounds() {
        const meta = getMeta();
        const inPoint = meta?.inPoint || 0;
        const totalFrames = meta?.totalFrames || 0;
        const endFrame = inPoint + totalFrames;

        if (activeSegment) {
            return {
                startFrame: activeSegment[0],
                endFrame: activeSegment[1],
            };
        }

        return {
            startFrame: inPoint,
            endFrame,
        };
    }

    function getRenderableFrame() {
        return useSubframes ? currentFrame : Math.round(currentFrame);
    }

    function getState() {
        return {
            currentFrame,
            isPlaying,
            meta: getMeta(),
            useSubframes,
            activeSegment,
        };
    }

    function notifyFrameChange() {
        const detail = getState();
        onFrameChange(detail);
        emitter.dispatchEvent('enterFrame', detail);
    }

    function notifyPlayStateChange() {
        const detail = getState();
        onPlayStateChange(detail);
        emitter.dispatchEvent(isPlaying ? 'play' : 'pause', detail);
    }

    function renderCurrentFrame() {
        if (!canRender()) {
            return;
        }

        onRenderFrame(getRenderableFrame());
    }

    function advanceToNextSegment() {
        if (queuedSegments.length === 0) {
            activeSegment = null;
            return false;
        }

        activeSegment = queuedSegments.shift() || null;
        const direction = getDirection() >= 0 ? 1 : -1;
        currentFrame = direction >= 0 ? activeSegment[0] : activeSegment[1];
        renderCurrentFrame();
        notifyFrameChange();
        return true;
    }

    function cancelLoop() {
        if (requestId !== null) {
            cancelAnimationFrameFn(requestId);
            requestId = null;
        }
    }

    function scheduleLoop() {
        if (requestId !== null) {
            return;
        }

        requestId = requestAnimationFrameFn(loop);
    }

    function loop(timestamp) {
        requestId = null;

        if (!canRender()) {
            return;
        }

        if (isPlaying) {
            if (!lastTimestamp) {
                lastTimestamp = timestamp;
            }

            const deltaTime = (timestamp - lastTimestamp) / 1000;
            lastTimestamp = timestamp;

            const meta = getMeta();
            const fps = meta?.fps || 0;
            const speed = getSpeed();
            const direction = getDirection() >= 0 ? 1 : -1;
            const loopEnabled = getLoop();
            const frameDelta = deltaTime * fps * speed * direction;
            currentFrame += frameDelta;

            const { startFrame, endFrame } = getPlaybackBounds();
            if (direction >= 0 && currentFrame >= endFrame) {
                if (advanceToNextSegment()) {
                    scheduleLoop();
                    return;
                }
                if (loopEnabled) {
                    currentFrame = startFrame;
                    emitter.dispatchEvent('loopComplete', getState());
                } else {
                    currentFrame = endFrame;
                    isPlaying = false;
                    lastTimestamp = 0;
                    renderCurrentFrame();
                    notifyFrameChange();
                    emitter.dispatchEvent('complete', getState());
                    notifyPlayStateChange();
                    return;
                }
            }

            if (direction < 0 && currentFrame <= startFrame) {
                if (advanceToNextSegment()) {
                    scheduleLoop();
                    return;
                }
                if (loopEnabled) {
                    currentFrame = endFrame;
                    emitter.dispatchEvent('loopComplete', getState());
                } else {
                    currentFrame = startFrame;
                    isPlaying = false;
                    lastTimestamp = 0;
                    renderCurrentFrame();
                    notifyFrameChange();
                    emitter.dispatchEvent('complete', getState());
                    notifyPlayStateChange();
                    return;
                }
            }

            renderCurrentFrame();
            notifyFrameChange();
        } else {
            lastTimestamp = 0;
        }

        scheduleLoop();
    }

    function start({ initialFrame = 0, autoplay = true } = {}) {
        cancelLoop();
        activeSegment = null;
        queuedSegments = [];
        currentFrame = initialFrame;
        isPlaying = autoplay;
        lastTimestamp = autoplay ? performance.now() : 0;
        renderCurrentFrame();
        notifyPlayStateChange();
        notifyFrameChange();
        scheduleLoop();
    }

    function play() {
        if (isPlaying) {
            return;
        }

        isPlaying = true;
        lastTimestamp = performance.now();
        notifyPlayStateChange();
        scheduleLoop();
    }

    function pause() {
        if (!isPlaying) {
            return;
        }

        isPlaying = false;
        lastTimestamp = 0;
        notifyPlayStateChange();
    }

    function toggle() {
        if (isPlaying) {
            pause();
        } else {
            play();
        }
    }

    function seek(frame, { render = true } = {}) {
        currentFrame = frame;
        lastTimestamp = 0;
        if (render) {
            renderCurrentFrame();
        }
        notifyFrameChange();
    }

    function stepFrame(delta) {
        const { startFrame, endFrame } = getPlaybackBounds();

        pause();
        const nextFrame = delta < 0
            ? Math.max(startFrame, currentFrame + delta)
            : Math.min(endFrame, currentFrame + delta);
        seek(nextFrame);
    }

    function stop() {
        const meta = getMeta();
        pause();
        activeSegment = null;
        queuedSegments = [];
        seek(meta?.inPoint || 0, { render: false });
    }

    function playSegments(segments, forceFlag = false) {
        const normalized = normalizeSegments(segments);
        if (normalized.length === 0) {
            return [];
        }

        if (forceFlag) {
            queuedSegments = normalized.slice(1);
            activeSegment = normalized[0];
        } else if (activeSegment || queuedSegments.length > 0) {
            queuedSegments = [...queuedSegments, ...normalized];
            if (!activeSegment) {
                activeSegment = queuedSegments.shift() || null;
            }
        } else {
            queuedSegments = normalized.slice(1);
            activeSegment = normalized[0];
        }

        const direction = getDirection() >= 0 ? 1 : -1;
        currentFrame = direction >= 0 ? activeSegment[0] : activeSegment[1];
        isPlaying = true;
        lastTimestamp = performance.now();
        renderCurrentFrame();
        notifyFrameChange();
        notifyPlayStateChange();
        scheduleLoop();
        return [activeSegment, ...queuedSegments];
    }

    function setSubframe(value) {
        useSubframes = value !== false;
        renderCurrentFrame();
        notifyFrameChange();
        return useSubframes;
    }

    function render() {
        renderCurrentFrame();
        notifyFrameChange();
    }

    function destroy() {
        cancelLoop();
        emitter.clear();
    }

    return {
        start,
        play,
        pause,
        toggle,
        stop,
        seek,
        playSegments,
        setSubframe,
        stepFrame,
        render,
        destroy,
        getCurrentFrame: () => currentFrame,
        isPlaying: () => isPlaying,
        getDirection: () => getDirection(),
        getLoop: () => getLoop(),
        getSubframe: () => useSubframes,
        addEventListener: emitter.addEventListener,
        removeEventListener: emitter.removeEventListener,
    };
}