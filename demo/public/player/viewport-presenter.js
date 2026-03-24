function readDevicePixelRatio() {
    return window.devicePixelRatio || 1;
}

function parsePixelValue(value) {
    const parsed = Number.parseFloat(value || '0');
    return Number.isFinite(parsed) ? parsed : 0;
}

function getWrapperChromeHeight(wrapper) {
    if (!wrapper) {
        return 0;
    }
    const head = wrapper.querySelector('.playground-canvas-head');
    const wrapperStyle = window.getComputedStyle(wrapper);
    const gap = parsePixelValue(wrapperStyle.rowGap || wrapperStyle.gap);
    return Math.ceil((head?.offsetHeight || 0) + gap);
}

function fitStage(maxWidth, maxHeight, aspectRatio) {
    if (maxWidth <= 0 || maxHeight <= 0 || aspectRatio <= 0) {
        return { width: 0, height: 0, area: 0 };
    }

    const width = Math.min(maxWidth, maxHeight * aspectRatio);
    const height = width / aspectRatio;

    return {
        width,
        height,
        area: width * height,
    };
}

function applyWrapperLayout(wrapper, stage, width, height) {
    if (!wrapper || !stage) {
        return;
    }

    const chromeHeight = getWrapperChromeHeight(wrapper);
    wrapper.style.flex = '0 0 auto';
    wrapper.style.width = `${Math.max(0, width)}px`;
    wrapper.style.height = `${Math.max(0, chromeHeight + height)}px`;
    stage.style.width = `${Math.max(0, width)}px`;
    stage.style.height = `${Math.max(0, height)}px`;
}

function fitStageWithinSlot(slotWidth, slotHeight, chromeHeight, aspectRatio) {
    return fitStage(slotWidth, Math.max(0, slotHeight - chromeHeight), aspectRatio);
}

function evaluateViewportLayout({
    direction,
    availableWidth,
    availableHeight,
    gap,
    chromeHeight,
    aspectRatio,
}) {
    const slotWidth = direction === 'row'
        ? Math.max(0, (availableWidth - gap) / 2)
        : availableWidth;
    const slotHeight = direction === 'column'
        ? Math.max(0, (availableHeight - gap) / 2)
        : availableHeight;

    return {
        direction,
        stageSize: fitStageWithinSlot(slotWidth, slotHeight, chromeHeight, aspectRatio),
    };
}

function resetWrapperLayout(wrapper, stage) {
    if (!wrapper || !stage) {
        return;
    }

    wrapper.style.flex = '';
    wrapper.style.width = '';
    wrapper.style.height = '';
    stage.style.width = '';
    stage.style.height = '';
}

export function createViewportPresenter(options = {}) {
    const {
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
        getCompareEnabled = () => true,
        requestRender = () => {},
        updateCurrentFileLabel = () => {},
        infoElements = {},
    } = options;

    let lastMetadata = null;
    let pendingCanvasResizeFrame = null;

    function layoutViewport(meta) {
        const animWidth = meta?.width || canvas.width || 1;
        const animHeight = meta?.height || canvas.height || 1;
        const aspectRatio = animWidth / animHeight;
        const viewportStyle = window.getComputedStyle(viewport);
        const horizontalPadding = parsePixelValue(viewportStyle.paddingLeft) + parsePixelValue(viewportStyle.paddingRight);
        const verticalPadding = parsePixelValue(viewportStyle.paddingTop) + parsePixelValue(viewportStyle.paddingBottom);
        const gap = parsePixelValue(viewportStyle.columnGap || viewportStyle.gap);
        const availableWidth = Math.max(0, viewport.clientWidth - horizontalPadding);
        const availableHeight = Math.max(0, viewport.clientHeight - verticalPadding);
        const compareActive = getCompareEnabled();
        const wasmChrome = getWrapperChromeHeight(wasmWrapper);
        const officialChrome = compareActive ? getWrapperChromeHeight(officialWrapper) : 0;
        const chromeHeight = Math.max(wasmChrome, officialChrome);

        let layout = {
            direction: 'row',
            stageSize: fitStageWithinSlot(availableWidth, availableHeight, wasmChrome, aspectRatio),
        };

        if (compareActive) {
            const rowLayout = evaluateViewportLayout({
                direction: 'row',
                availableWidth,
                availableHeight,
                gap,
                chromeHeight,
                aspectRatio,
            });
            const columnLayout = evaluateViewportLayout({
                direction: 'column',
                availableWidth,
                availableHeight,
                gap,
                chromeHeight,
                aspectRatio,
            });

            layout = columnLayout.stageSize.area > rowLayout.stageSize.area ? columnLayout : rowLayout;
        }

        viewport.style.flexDirection = layout.direction;
        viewport.dataset.layout = layout.direction;
        viewport.dataset.compare = compareActive ? 'true' : 'false';

        applyWrapperLayout(wasmWrapper, wasmStage, layout.stageSize.width, layout.stageSize.height);
        canvas.style.width = `${Math.max(0, layout.stageSize.width)}px`;
        canvas.style.height = `${Math.max(0, layout.stageSize.height)}px`;

        if (compareActive) {
            applyWrapperLayout(officialWrapper, officialStage, layout.stageSize.width, layout.stageSize.height);
            if (officialContainer) {
                officialContainer.style.width = `${Math.max(0, layout.stageSize.width)}px`;
                officialContainer.style.height = `${Math.max(0, layout.stageSize.height)}px`;
            }
        } else {
            resetWrapperLayout(officialWrapper, officialStage);
            if (officialContainer) {
                officialContainer.style.width = '';
                officialContainer.style.height = '';
            }
        }

        return layout.stageSize;
    }

    function updateViewportTransform(meta) {
        const animWidth = meta?.width || canvas.width || 100;
        const animHeight = meta?.height || canvas.height || 100;
        const stageSize = layoutViewport(meta);
        const dpr = readDevicePixelRatio();
        const viewportWidth = stageSize.width > 0 ? stageSize.width : animWidth;
        const viewportHeight = stageSize.height > 0 ? stageSize.height : animHeight;
        const scale = Math.min(viewportWidth / animWidth, viewportHeight / animHeight) || 1;

        viewportTransform.scale = scale;
        viewportTransform.offsetX = (viewportWidth - animWidth * scale) / 2;
        viewportTransform.offsetY = (viewportHeight - animHeight * scale) / 2;
        viewportTransform.dpr = dpr;

        return {
            width: viewportWidth,
            height: viewportHeight,
            dpr,
        };
    }

    function applyAnimationMetadata(meta, context = {}) {
        const {
            currentFileName = '',
            currentFileSize = 0,
        } = context;

        lastMetadata = meta;
        const { width, height, fps, totalFrames, inPoint, aspectRatio, version } = meta;

        wasmStage.style.aspectRatio = aspectRatio;
        if (officialStage) officialStage.style.aspectRatio = aspectRatio;
        if (officialContainer) officialContainer.style.aspectRatio = aspectRatio;

        const viewportSize = updateViewportTransform(meta);
        resizeCanvasForDpr(canvas, viewportSize.width, viewportSize.height, viewportSize.dpr);

        if (infoElements.filename) infoElements.filename.innerText = currentFileName || '未知';
        if (infoElements.filesize) infoElements.filesize.innerText = (currentFileSize / 1024).toFixed(2) + ' KB';
        if (infoElements.size) infoElements.size.innerText = `${width} x ${height}`;
        if (infoElements.fps) infoElements.fps.innerText = `${fps.toFixed(2)} fps`;
        if (infoElements.totalFrames) infoElements.totalFrames.innerText = Math.floor(totalFrames);
        if (infoElements.duration) infoElements.duration.innerText = fps > 0 ? `${(totalFrames / fps).toFixed(2)}s` : '-';
        if (infoElements.version) infoElements.version.innerText = version;
        updateCurrentFileLabel();

        if (seekBar) {
            seekBar.min = inPoint;
            seekBar.max = inPoint + totalFrames;
            seekBar.value = inPoint;
        }
    }

    function scheduleViewportRefresh(contextFactory = () => ({})) {
        if (!lastMetadata || pendingCanvasResizeFrame !== null) {
            return;
        }

        pendingCanvasResizeFrame = requestAnimationFrame(() => {
            pendingCanvasResizeFrame = null;
            if (!lastMetadata) {
                return;
            }
            applyAnimationMetadata(lastMetadata, contextFactory());
            requestRender();
        });
    }

    return {
        applyAnimationMetadata,
        scheduleViewportRefresh,
        getLastMetadata: () => lastMetadata,
    };
}