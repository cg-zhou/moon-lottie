import { cloneAnimationData, createRuntimeAnimationData, loadAnimationSourceFromUrl, loadRemoteAnimationSource, preloadAssets, readFileAnimationSource } from './animation-source.js';
import { createPlaybackController } from './playback-controller.js';
import { createRuntimeManager } from './runtime-manager.js';

export function createPlayer(options = {}) {
    const {
        loadWasmRuntime,
        loadJsRuntime,
        officialPlayerController,
        viewportPresenter,
        getAnimationPlaybackMeta,
        animationUsesExpressions,
        setStatusMessage = () => {},
        setExpressionHost = () => {},
        setRuntimeAnimationJson = () => {},
        setFullAnimationJson = () => {},
        setImageAssets = () => {},
        getSpeed = () => 1,
        getDirection = () => 1,
        getLoop = () => true,
        getCompareEnabled = () => true,
        renderFrame = () => {},
        createNativePlayer = () => null,
        onRuntimeChanged = () => {},
        onStateChange = () => {},
        onFrameChange = () => {},
        onPlayStateChange = () => {},
    } = options;

    const state = {
        currentFileName: '',
        currentFileSize: 0,
        currentAnimationData: null,
        currentAnimationMeta: null,
        currentExpressionAnimationData: null,
        currentExpressionMeta: null,
        nativePlayer: null,
    };

    function getState() {
        return {
            currentFileName: state.currentFileName,
            currentFileSize: state.currentFileSize,
            currentAnimationData: state.currentAnimationData,
            currentAnimationMeta: state.currentAnimationMeta,
            currentExpressionAnimationData: state.currentExpressionAnimationData,
            currentExpressionMeta: state.currentExpressionMeta,
            nativePlayer: state.nativePlayer,
            runtime: runtimeManager.getRuntime(),
            backend: runtimeManager.getBackend(),
            preference: runtimeManager.getPreference(),
            isPlaying: playbackController.isPlaying(),
            currentFrame: playbackController.getCurrentFrame(),
        };
    }

    function notifyStateChange() {
        onStateChange(getState());
    }

    function applyAnimationMetadata() {
        if (!state.currentAnimationMeta) {
            return;
        }

        viewportPresenter.applyAnimationMetadata(state.currentAnimationMeta, {
            currentFileName: state.currentFileName,
            currentFileSize: state.currentFileSize,
        });
    }

    function syncOfficialPlayer() {
        if (!getCompareEnabled() || !state.currentAnimationData) {
            officialPlayerController.destroy();
            return null;
        }

        return officialPlayerController.load(state.currentAnimationData);
    }

    const runtimeManager = createRuntimeManager({
        loadWasmRuntime,
        loadJsRuntime,
        onRuntimeChanged: (detail) => {
            onRuntimeChanged(detail);
            notifyStateChange();
        },
    });

    const playbackController = createPlaybackController({
        getMeta: () => state.currentAnimationMeta,
        getSpeed,
        getDirection,
        getLoop,
        canRender: () => Boolean(state.nativePlayer && runtimeManager.getRuntime()),
        onRenderFrame: (frame) => {
            renderFrame(frame, getState());
            officialPlayerController.seek(frame);
        },
        onFrameChange: (detail) => {
            onFrameChange({ ...detail, state: getState() });
        },
        onPlayStateChange: (detail) => {
            onPlayStateChange({ ...detail, state: getState() });
        },
    });

    async function initialize() {
        await runtimeManager.initialize();
        notifyStateChange();
        return getState();
    }

    async function switchRuntime(preference) {
        await runtimeManager.switchRuntime(preference);
        if (state.currentAnimationData) {
            await restartCurrentAnimation();
        }
        notifyStateChange();
        return getState();
    }

    async function loadFromText(jsonText, context = {}) {
        let animationData;
        try {
            animationData = JSON.parse(jsonText);
        } catch {
            throw new Error('无效的 JSON 文件');
        }

        const runtime = runtimeManager.getRuntime();
        if (!runtime) {
            throw new Error('运行时尚未初始化');
        }

        state.currentFileName = context.filename || state.currentFileName;
        state.currentFileSize = context.size ?? state.currentFileSize;
        state.currentAnimationData = animationData;
        state.currentAnimationMeta = getAnimationPlaybackMeta(animationData);
        state.currentExpressionAnimationData = cloneAnimationData(animationData);
        state.currentExpressionMeta = getAnimationPlaybackMeta(state.currentExpressionAnimationData);

        setStatusMessage('初始化渲染引擎...');
        playbackController.stop();
        officialPlayerController.destroy();
        state.nativePlayer = null;

        const imageAssets = await preloadAssets(animationData, { onStatusMessage: setStatusMessage });
        setImageAssets(imageAssets);

        const runtimeAnimationData = createRuntimeAnimationData(animationData);
        setRuntimeAnimationJson(JSON.stringify(runtimeAnimationData));
        // Provide the full (non-stripped) animation JSON for renderers that
        // need embedded image data (e.g. the SVG renderer which embeds base64
        // images directly in the <image> elements rather than using a canvas
        // image asset index).
        setFullAnimationJson(JSON.stringify(animationData));

        state.nativePlayer = createNativePlayer(runtime, getState());
        if (!state.nativePlayer) {
            throw new Error('动画解析失败');
        }

        syncOfficialPlayer();
        setExpressionHost(null);
        applyAnimationMetadata();
        playbackController.start({
            initialFrame: state.currentAnimationMeta.inPoint,
            autoplay: true,
        });

        if (animationUsesExpressions(animationData)) {
            setStatusMessage('检测到 expressions，moon-lottie 将通过内置 JS 表达式宿主执行表达式');
        } else {
            const backendLabel = runtimeManager.getBackend() === 'wasm' ? 'Wasm' : 'JS';
            setStatusMessage(`正在播放 (${backendLabel}): ${animationData.nm || '未命名动画'}`);
        }

        notifyStateChange();
        return getState();
    }

    async function loadRemoteAnimation(filename) {
        const source = await loadRemoteAnimationSource(filename);
        return loadFromText(source.text, {
            filename: source.filename,
            size: source.size,
        });
    }

    async function loadFromUrl(url, options = {}) {
        const source = await loadAnimationSourceFromUrl(url, options);
        return loadFromText(source.text, {
            filename: source.filename,
            size: source.size,
        });
    }

    async function loadFile(file) {
        const source = await readFileAnimationSource(file);
        return loadFromText(source.text, {
            filename: source.filename,
            size: source.size,
        });
    }

    async function restartCurrentAnimation() {
        if (!state.currentAnimationData) {
            return getState();
        }

        return loadFromText(JSON.stringify(state.currentAnimationData), {
            filename: state.currentFileName,
            size: state.currentFileSize,
        });
    }

    function refreshCompare() {
        syncOfficialPlayer();
        playbackController.render();
        notifyStateChange();
        return getState();
    }

    function scheduleViewportRefresh() {
        viewportPresenter.scheduleViewportRefresh(() => ({
            currentFileName: state.currentFileName,
            currentFileSize: state.currentFileSize,
        }));
    }

    function destroy() {
        playbackController.destroy();
        officialPlayerController.destroy();
        state.nativePlayer = null;
        state.currentAnimationData = null;
        state.currentAnimationMeta = null;
        state.currentExpressionAnimationData = null;
        state.currentExpressionMeta = null;
        setImageAssets([]);
        setRuntimeAnimationJson('');
        notifyStateChange();
    }

    return {
        initialize,
        switchRuntime,
        loadFromText,
        loadFromUrl,
        loadRemoteAnimation,
        loadFile,
        restartCurrentAnimation,
        refreshCompare,
        scheduleViewportRefresh,
        render: () => playbackController.render(),
        seek: (frame) => playbackController.seek(frame),
        stop: () => playbackController.stop(),
        toggle: () => playbackController.toggle(),
        play: () => playbackController.play(),
        pause: () => playbackController.pause(),
        playSegments: (segments, forceFlag = false) => playbackController.playSegments(segments, forceFlag),
        setSubframe: (value) => playbackController.setSubframe(value),
        stepFrame: (delta) => playbackController.stepFrame(delta),
        isPlaying: () => playbackController.isPlaying(),
        getCurrentFrame: () => playbackController.getCurrentFrame(),
        getSubframe: () => playbackController.getSubframe(),
        getRuntime: () => runtimeManager.getRuntime(),
        getBackend: () => runtimeManager.getBackend(),
        getPreference: () => runtimeManager.getPreference(),
        describePreference: (preference) => runtimeManager.describePreference(preference),
        getState,
        getNativePlayer: () => state.nativePlayer,
        addEventListener: (type, listener) => playbackController.addEventListener(type, listener),
        removeEventListener: (type, listener) => playbackController.removeEventListener(type, listener),
        destroy,
    };
}