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

    function getState() {
        return {
            currentFrame,
            isPlaying,
            meta: getMeta(),
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

        onRenderFrame(currentFrame);
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

            const inPoint = meta?.inPoint || 0;
            const totalFrames = meta?.totalFrames || 0;
            const endFrame = inPoint + totalFrames;
            if (direction >= 0 && currentFrame >= endFrame) {
                if (loopEnabled) {
                    currentFrame = inPoint;
                    emitter.dispatchEvent('loopComplete', getState());
                } else {
                    currentFrame = endFrame;
                    isPlaying = false;
                    lastTimestamp = 0;
                    renderCurrentFrame();
                    notifyFrameChange();
                    notifyPlayStateChange();
                    return;
                }
            }

            if (direction < 0 && currentFrame <= inPoint) {
                if (loopEnabled) {
                    currentFrame = endFrame;
                    emitter.dispatchEvent('loopComplete', getState());
                } else {
                    currentFrame = inPoint;
                    isPlaying = false;
                    lastTimestamp = 0;
                    renderCurrentFrame();
                    notifyFrameChange();
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
        const meta = getMeta();
        const inPoint = meta?.inPoint || 0;
        const totalFrames = meta?.totalFrames || 0;
        const endFrame = inPoint + totalFrames;

        pause();
        const nextFrame = delta < 0
            ? Math.max(inPoint, currentFrame + delta)
            : Math.min(endFrame, currentFrame + delta);
        seek(nextFrame);
    }

    function stop() {
        const meta = getMeta();
        pause();
        seek(meta?.inPoint || 0, { render: false });
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
        stepFrame,
        render,
        destroy,
        getCurrentFrame: () => currentFrame,
        isPlaying: () => isPlaying,
        getDirection: () => getDirection(),
        getLoop: () => getLoop(),
        addEventListener: emitter.addEventListener,
        removeEventListener: emitter.removeEventListener,
    };
}