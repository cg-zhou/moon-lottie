import {
    animationUsesExpressions,
    getAnimationPlaybackMeta,
} from './render_mode.js';
import {
    setExpressionHost,
} from './expression_host.js';
import {
    resizeCanvasForDpr,
} from './canvas_dpr.js';
import {
    createCanvasRuntimeBridge,
    createOfficialPlayerController,
    createPlayer,
    createViewportPresenter,
    loadSampleIndex,
} from './player/index.js';

// MoonLottie UI 2.0 - 现代化播放驱动

const canvas = document.getElementById('lottie-canvas');
let ctx = canvas.getContext('2d');
const statusDot = document.getElementById('status-dot');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const seekBar = document.getElementById('seek-bar');
const fileInput = document.getElementById('file-input');
const viewport = document.getElementById('viewport');
const currentFileNameEl = document.getElementById('current-file-name');
const compareToggle = document.getElementById('compare-toggle');
const wasmWrapper = document.getElementById('wasm-wrapper');
const officialWrapper = document.getElementById('official-wrapper');
const wasmStage = wasmWrapper.querySelector('.canvas-stage');
const officialStage = officialWrapper.querySelector('.canvas-stage');
const officialContainer = document.getElementById('official-lottie-container');
const infoRuntimeEl = document.getElementById('info-runtime');
const openFileBtn = document.getElementById('open-file-btn');
const prevAnimationBtn = document.getElementById('prev-animation');
const nextAnimationBtn = document.getElementById('next-animation');
const prevFrameBtn = document.getElementById('prev-frame');
const nextFrameBtn = document.getElementById('next-frame');
const speedInput = document.getElementById('speed-input');
const speedButtons = Array.from(document.querySelectorAll('.speed-btn'));
const bgButtons = Array.from(document.querySelectorAll('.bg-btn'));
const runtimeButtons = Array.from(document.querySelectorAll('.runtime-btn'));
const playlistDrawer = document.getElementById('playlist-drawer');
const playlistBackdrop = document.getElementById('playlist-backdrop');
const playlistToggle = document.getElementById('playlist-toggle');
const playlistClose = document.getElementById('playlist-close');
const playlistSearch = document.getElementById('playlist-search');
const playlistList = document.getElementById('playlist-list');
const detailsPanel = document.getElementById('details-panel');
const detailsToggle = document.getElementById('details-toggle');
const detailsClose = document.getElementById('details-close');
const panelBackdrop = document.getElementById('panel-backdrop');
const dropOverlay = document.getElementById('drop-overlay');

let player = null;
let currentJsonStr = '';
let currentFileName = '';
let currentFileSize = 0;
let imageAssetsByIndex = [];
let compareEnabled = true;
let currentSpeed = 1;
let currentBackground = 'grid';
let currentAnimationData = null;
let currentAnimationMeta = null;
let currentExpressionAnimationData = null;
let currentExpressionMeta = null;
let sampleEntries = [];
let viewportResizeObserver = null;
const viewportTransform = {
    scale: 1,
    offsetX: 0,
    offsetY: 0,
    dpr: 1,
};

const officialPlayerController = createOfficialPlayerController({
    container: officialContainer,
});
const infoElements = {
    filename: document.getElementById('info-filename'),
    filesize: document.getElementById('info-filesize'),
    size: document.getElementById('info-size'),
    fps: document.getElementById('info-fps'),
    totalFrames: document.getElementById('info-total-frames'),
    duration: document.getElementById('info-duration'),
    version: document.getElementById('info-version'),
};

function getRuntimePreference() {
    return playerController.getPreference();
}

function describeRuntimePreference(preference) {
    return playerController.describePreference(preference);
}

function setStatusMessage(message) {
    console.log(`[Status] ${message}`);
}

function updateCurrentFileLabel() {
    currentFileNameEl.innerText = currentFileName || '选择一个样例或打开本地 JSON';
}

function updateRuntimeBadges() {
    const backend = playerController.getBackend();
    const actual = backend === 'uninitialized'
        ? '未初始化'
        : (backend === 'wasm' ? 'Wasm' : 'JS');
    infoRuntimeEl.innerText = actual;
    runtimeButtons.forEach((button) => {
        button.classList.toggle('is-active', button.dataset.runtime === playerController.getPreference());
    });
}

function applyBackgroundSelection() {
    viewport.classList.remove('bg-white', 'bg-black');
    if (currentBackground === 'white') {
        viewport.classList.add('bg-white');
    } else if (currentBackground === 'black') {
        viewport.classList.add('bg-black');
    }
    bgButtons.forEach((button) => {
        button.classList.toggle('is-active', button.dataset.bg === currentBackground);
    });
}

function updateCompareUI() {
    compareToggle.classList.toggle('is-active', compareEnabled);
    compareToggle.setAttribute('aria-pressed', compareEnabled ? 'true' : 'false');
    officialWrapper.style.display = compareEnabled ? 'flex' : 'none';
    scheduleViewportRefresh();
}

function syncPlayerState(state) {
    if (!state) {
        return;
    }

    currentFileName = state.currentFileName || '';
    currentFileSize = state.currentFileSize || 0;
    currentAnimationData = state.currentAnimationData || null;
    currentAnimationMeta = state.currentAnimationMeta || null;
    currentExpressionAnimationData = state.currentExpressionAnimationData || null;
    currentExpressionMeta = state.currentExpressionMeta || null;
    player = state.nativePlayer || null;
    updateCurrentFileLabel();
}

function normalizeSpeed(value) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
        return currentSpeed;
    }
    return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10));
}

function updateSpeedInput() {
    speedInput.value = currentSpeed.toFixed(1);
    speedButtons.forEach((btn) => {
        btn.classList.toggle('is-active', Math.abs(Number(btn.dataset.speed) - currentSpeed) < 0.01);
    });
}

function getCurrentSampleIndex() {
    return sampleEntries.findIndex((entry) => entry.file === currentFileName);
}

function stepAnimation(direction) {
    if (sampleEntries.length === 0) {
        return;
    }

    const currentIndex = getCurrentSampleIndex();
    const baseIndex = currentIndex >= 0 ? currentIndex : 0;
    const nextIndex = (baseIndex + direction + sampleEntries.length) % sampleEntries.length;
    const nextEntry = sampleEntries[nextIndex];
    localStorage.setItem('moon-lottie-last-anim', nextEntry.file);
    loadRemoteAnimation(nextEntry.file);
}

function openPlaylistDrawer() {
    document.body.classList.add('drawer-open');
    playlistDrawer.classList.add('is-open');
    playlistBackdrop.classList.add('is-open');
    playlistDrawer.setAttribute('aria-hidden', 'false');
}

function closePlaylistDrawer() {
    playlistDrawer.classList.remove('is-open');
    playlistBackdrop.classList.remove('is-open');
    playlistDrawer.setAttribute('aria-hidden', 'true');
    if (!detailsPanel.classList.contains('is-open')) {
        document.body.classList.remove('drawer-open');
    }
}

function openDetailsPanel() {
    document.body.classList.add('drawer-open');
    detailsPanel.classList.add('is-open');
    panelBackdrop.classList.add('is-open');
    detailsPanel.setAttribute('aria-hidden', 'false');
    detailsToggle.classList.add('is-active');
}

function closeDetailsPanel() {
    detailsPanel.classList.remove('is-open');
    panelBackdrop.classList.remove('is-open');
    detailsPanel.setAttribute('aria-hidden', 'true');
    detailsToggle.classList.remove('is-active');
    if (!playlistDrawer.classList.contains('is-open')) {
        document.body.classList.remove('drawer-open');
    }
}

function renderPlaylist() {
    const query = (playlistSearch.value || '').trim().toLowerCase();
    const filtered = sampleEntries.filter((entry) => {
        const searchText = `${entry.label} ${entry.file}`.toLowerCase();
        return !query || searchText.includes(query);
    });

    if (filtered.length === 0) {
        playlistList.innerHTML = '<div class="playlist-empty">没有匹配的样例。</div>';
        return;
    }

    playlistList.innerHTML = '';
    filtered.forEach((entry) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'playlist-item';
        if (entry.file === currentFileName) {
            button.classList.add('is-active');
        }
        button.innerHTML = `<span class="playlist-item__title">${entry.label}</span><span class="playlist-item__meta">${entry.file}</span>`;
        button.onclick = () => {
            localStorage.setItem('moon-lottie-last-anim', entry.file);
            closePlaylistDrawer();
            loadRemoteAnimation(entry.file);
        };
        playlistList.appendChild(button);
    });
}

async function restartCurrentAnimation() {
    if (!currentJsonStr && !currentAnimationData) {
        return;
    }
    const state = await playerController.restartCurrentAnimation();
    syncPlayerState(state);
}

async function switchRuntime(preference) {
    if (preference !== 'auto' && preference !== 'wasm' && preference !== 'js') {
        return;
    }
    if (playerController.getPreference() === preference && playerController.getRuntime()) {
        return;
    }

    updateRuntimeBadges();
    setStatusMessage(`切换运行时到 ${describeRuntimePreference(preference)}...`);

    try {
        const state = await playerController.switchRuntime(preference);
        syncPlayerState(state);
        updateRuntimeBadges();
        if (currentAnimationData) {
            renderPlaylist();
        } else {
            setStatusMessage(`已切换到 ${playerController.getBackend() === 'wasm' ? 'Wasm' : 'JS'} 后端`);
        }
    } catch (error) {
        statusDot.style.background = '#ff3b30';
        setStatusMessage(`运行时切换失败: ${error.message}`);
    }
}

const viewportPresenter = createViewportPresenter({
    viewport,
    canvas,
    wasmWrapper,
    officialWrapper,
    wasmStage,
    officialStage,
    officialContainer,
    seekBar,
    resizeCanvasForDpr,
    viewportTransform,
    getCompareEnabled: () => compareEnabled,
    requestRender: () => renderCurrentFrame(),
    updateCurrentFileLabel,
    infoElements,
});

function scheduleViewportRefresh() {
    playerController.scheduleViewportRefresh();
}

const runtimeBridge = createCanvasRuntimeBridge({
    canvas,
    viewportTransform,
    getRuntimeAnimationJson: () => currentJsonStr,
    getImageAssets: () => imageAssetsByIndex,
    getExpressionAnimationData: () => currentExpressionAnimationData,
    getExpressionMeta: () => currentExpressionMeta,
    getCanvasContext: () => ctx,
    jsRuntimePath: './runtime/js/moon-lottie-runtime.js',
});

async function init() {
    try {
        updateCurrentFileLabel();
        applyBackgroundSelection();
        updateCompareUI();
        updateSpeedInput();
        updateRuntimeBadges();
        setStatusMessage('初始化 MoonLottie 运行时...');
        const state = await playerController.initialize();
        syncPlayerState(state);
        console.log(`[MoonLottie] Runtime preference: ${describeRuntimePreference(getRuntimePreference())}`);

        statusDot.style.background = '#34c759';
        updateRuntimeBadges();
        setStatusMessage(playerController.getBackend() === 'wasm'
            ? `已就绪，请打开 Lottie JSON (${describeRuntimePreference(getRuntimePreference())})`
            : `已就绪，当前使用 JS 兼容后端 (${describeRuntimePreference(getRuntimePreference())})`);

        await initAnimList();
    } catch (err) {
        statusDot.style.background = '#ff3b30';
        setStatusMessage(`错误: ${err.message}`);
    }
}

function renderCurrentFrame() {
    const currentFrame = playerController.getCurrentFrame();
    const runtime = playerController.getRuntime();
    if (player && runtime) {
        runtimeBridge.renderFrame(runtime, player, currentFrame);
    }

    officialPlayerController.seek(currentFrame);
}

async function initAnimList() {
    try {
        sampleEntries = await loadSampleIndex();
        renderPlaylist();

        const lastSelected = localStorage.getItem('moon-lottie-last-anim');
        const hasLastInList = lastSelected && sampleEntries.some((entry) => entry.file === lastSelected);

        if (hasLastInList) {
            loadRemoteAnimation(lastSelected);
        } else if (sampleEntries.length > 0) {
            loadRemoteAnimation(sampleEntries[0].file);
        }
    } catch (e) {
        console.error('Failed to initialize animation list:', e);
        loadSample();
    }
}

function loadSample() {
    loadRemoteAnimation('1_1_Super_Mario.json');
}

function loadRemoteAnimation(filename) {
    playerController.loadRemoteAnimation(filename).then((state) => {
        syncPlayerState(state);
        renderPlaylist();
    }).catch((error) => {
        console.warn(`Failed to load ${filename}:`, error.message);
    });
}

function updateUI() {
    const inPoint = currentAnimationMeta?.inPoint || 0;
    const totalFrames = currentAnimationMeta?.totalFrames || 0;
    const currentFrame = playerController.getCurrentFrame();
    const relativeFrame = currentFrame - inPoint;
    frameInfoEl.innerText = `${Math.floor(relativeFrame)} / ${Math.floor(totalFrames)}`;
    seekBar.value = currentFrame;
}

function updatePlayPauseButton() {
    playPauseBtn.innerText = playerController.isPlaying() ? '‖' : '▶';
}

const playerController = createPlayer({
    loadWasmRuntime: runtimeBridge.loadWasmRuntime,
    loadJsRuntime: runtimeBridge.loadJsRuntime,
    officialPlayerController,
    viewportPresenter,
    getAnimationPlaybackMeta,
    animationUsesExpressions,
    setStatusMessage,
    setExpressionHost,
    setRuntimeAnimationJson: (value) => {
        currentJsonStr = value;
    },
    setImageAssets: (assets) => {
        imageAssetsByIndex = assets;
    },
    getSpeed: () => currentSpeed,
    getCompareEnabled: () => compareEnabled,
    renderFrame: () => {
        renderCurrentFrame();
    },
    createNativePlayer: (runtime) => runtime.create_player_from_js(),
    onRuntimeChanged: ({ runtime, backend }) => {
        window.moonLottie = runtime;
        window.moonLottieBackend = backend;
    },
    onStateChange: (state) => {
        syncPlayerState(state);
    },
    onFrameChange: () => {
        updateUI();
    },
    onPlayStateChange: () => {
        updatePlayPauseButton();
    },
});

function isEditableTarget(target) {
    return target instanceof HTMLInputElement
        || target instanceof HTMLTextAreaElement
        || target instanceof HTMLSelectElement
        || target?.isContentEditable;
}

seekBar.oninput = () => {
    if (!player) return;
    playerController.seek(parseFloat(seekBar.value));
};

playPauseBtn.onclick = () => {
    playerController.toggle();
};

prevFrameBtn.onclick = () => {
    if (!player || !currentAnimationMeta) return;
    playerController.stepFrame(-1);
};

nextFrameBtn.onclick = () => {
    if (!player || !currentAnimationMeta) return;
    playerController.stepFrame(1);
};

prevAnimationBtn.onclick = () => {
    stepAnimation(-1);
};

nextAnimationBtn.onclick = () => {
    stepAnimation(1);
};

window.addEventListener('keydown', (e) => {
    if (isEditableTarget(e.target)) {
        return;
    }

    if (e.code === 'Space') {
        playerController.toggle();
        e.preventDefault();
    } else if (e.code === 'Escape') {
        closePlaylistDrawer();
        closeDetailsPanel();
    } else if (e.code === 'ArrowLeft') {
        prevFrameBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowRight') {
        nextFrameBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowUp') {
        prevAnimationBtn.click();
        e.preventDefault();
    } else if (e.code === 'ArrowDown') {
        nextAnimationBtn.click();
        e.preventDefault();
    }
});

speedInput.onchange = () => {
    currentSpeed = normalizeSpeed(speedInput.value);
    updateSpeedInput();
};

speedInput.onblur = () => {
    currentSpeed = normalizeSpeed(speedInput.value);
    updateSpeedInput();
};

speedButtons.forEach((btn) => {
    btn.onclick = () => {
        currentSpeed = parseFloat(btn.dataset.speed);
        updateSpeedInput();
    };
});

bgButtons.forEach((btn) => {
    btn.onclick = () => {
        currentBackground = btn.dataset.bg || 'grid';
        applyBackgroundSelection();
    };
});

compareToggle.onclick = () => {
    compareEnabled = !compareEnabled;
    updateCompareUI();

    if (!currentAnimationData) return;

    syncPlayerState(playerController.refreshCompare());
};

runtimeButtons.forEach((button) => {
    button.onclick = () => {
        switchRuntime(button.dataset.runtime);
    };
});

playlistToggle.onclick = openPlaylistDrawer;
playlistClose.onclick = closePlaylistDrawer;
playlistBackdrop.onclick = closePlaylistDrawer;
playlistSearch.oninput = () => renderPlaylist();

detailsToggle.onclick = () => {
    if (detailsPanel.classList.contains('is-open')) {
        closeDetailsPanel();
    } else {
        openDetailsPanel();
    }
};
detailsClose.onclick = closeDetailsPanel;
panelBackdrop.onclick = closeDetailsPanel;

openFileBtn.onclick = () => fileInput.click();

window.addEventListener('resize', scheduleViewportRefresh);

if (typeof ResizeObserver === 'function') {
    viewportResizeObserver = new ResizeObserver(() => {
        scheduleViewportRefresh();
    });
    viewportResizeObserver.observe(viewport);
}

function initDeployTime() {
    const deployTimeEl = document.getElementById('deploy-time');
    if (deployTimeEl && deployTimeEl.dataset.utc) {
        const utcStr = deployTimeEl.dataset.utc;
        const date = new Date(utcStr);
        if (!isNaN(date.getTime())) {
            deployTimeEl.innerText = date.toLocaleString();
            deployTimeEl.title = `UTC: ${utcStr}`;
        }
    }
}

fileInput.onchange = (e) => {
    const file = e.target.files[0];
    if (file) handleFile(file);
    fileInput.value = '';
};

window.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropOverlay.classList.add('is-open');
    dropOverlay.setAttribute('aria-hidden', 'false');
});

window.addEventListener('dragleave', (e) => {
    if (e.clientX === 0 && e.clientY === 0) {
        dropOverlay.classList.remove('is-open');
        dropOverlay.setAttribute('aria-hidden', 'true');
    }
});

window.addEventListener('drop', (e) => {
    e.preventDefault();
    dropOverlay.classList.remove('is-open');
    dropOverlay.setAttribute('aria-hidden', 'true');
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
});

function handleFile(file) {
    playerController.loadFile(file).then((state) => {
        syncPlayerState(state);
        renderPlaylist();
        closePlaylistDrawer();
    }).catch(() => {
        alert('无效的 JSON 文件');
    });
}

init().then(() => {
    initDeployTime();
});
