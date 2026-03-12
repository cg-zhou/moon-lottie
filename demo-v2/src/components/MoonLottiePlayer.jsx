import React, { useEffect, useRef, useState } from 'react';
import { createWasmImportObject } from '../wasm-renderer';
import { createExpressionModule } from '../expression_host';

const wasmModuleCache = new Map();

async function getCompiledWasmModule(wasmUrl) {
    if (!wasmModuleCache.has(wasmUrl)) {
        const modulePromise = (async () => {
            const response = await fetch(wasmUrl);
            const buffer = await response.arrayBuffer();
            return WebAssembly.compile(buffer, { builtins: ['js-string'] });
        })().catch((error) => {
            wasmModuleCache.delete(wasmUrl);
            throw error;
        });

        wasmModuleCache.set(wasmUrl, modulePromise);
    }

    return wasmModuleCache.get(wasmUrl);
}

const MoonLottiePlayer = ({ 
    animationData, 
    wasmUrl = '/renderer.wasm', 
    autoPlay = true,
    width = 300,
    height = 300,
    className = "",
    isPaused = false,
    currentFrameControlled = null // 受控模式：外部直接传入帧号
}) => {
    const canvasRef = useRef(null);
    const playerRef = useRef({
        instance: null,
        playerHandle: undefined,
    });
    const playbackRef = useRef({
        autoPlay,
        isPaused,
        currentFrameControlled,
    });
    const viewportRef = useRef({
        scale: 1,
        offsetX: 0,
        offsetY: 0,
        dpr: 1,
    });
    const animationFrameIdRef = useRef(null);
    const [error, setError] = useState(null);

    useEffect(() => {
        playbackRef.current = {
            autoPlay,
            isPaused,
            currentFrameControlled,
        };
    }, [autoPlay, isPaused, currentFrameControlled]);

    useEffect(() => {
        let isMounted = true;
        let resizeHandler = null;
        
        async function initWasm() {
            if (!animationData || !canvasRef.current) return;

            try {
                const fr = animationData.fr || 60;
                const ip = animationData.ip || 0;
                const op = animationData.op || 100;
                const totalFrames = op - ip;

                const ctx = canvasRef.current.getContext('2d');
                
                // 动态调整 Canvas 位图大小以匹配容器，并考虑 DPR
                const updateCanvasSize = () => {
                    if (!canvasRef.current) return;
                    const dpr = window.devicePixelRatio || 1;
                    const rect = canvasRef.current.parentElement.getBoundingClientRect();
                    canvasRef.current.width = rect.width * dpr;
                    canvasRef.current.height = rect.height * dpr;
                };
                
                updateCanvasSize();
                resizeHandler = updateCanvasSize;
                window.addEventListener('resize', resizeHandler);

                const jsonStr = JSON.stringify(animationData);
                
                const expressionModule = createExpressionModule({
                    getAnimationData: () => animationData,
                    getPlaybackMeta: () => ({
                        frameRate: fr,
                        currentFrame: 0, 
                    }),
                });

                const importObject = createWasmImportObject(
                    ctx, 
                    () => "#000000", 
                    () => jsonStr, 
                    [], 
                    expressionModule,
                    () => viewportRef.current
                );

                const compiledModule = await getCompiledWasmModule(wasmUrl);
                const instance = await WebAssembly.instantiate(compiledModule, importObject);

                if (!isMounted) return;

                playerRef.current.instance = instance;
                
                if (instance.exports._start) {
                    instance.exports._start();
                }

                if (instance.exports.create_player_from_js) {
                    playerRef.current.playerHandle = instance.exports.create_player_from_js();
                }
                
                const startTime = performance.now();
                
                const renderFrame = (timestamp) => {
                    if (!isMounted || !canvasRef.current) {
                        return;
                    }

                    const playback = playbackRef.current;
                    const frameToRender = playback.currentFrameControlled !== null 
                        ? playback.currentFrameControlled 
                        : (() => {
                            if (playback.isPaused || !playback.autoPlay) return null;
                            const elapsed = timestamp - startTime;
                            const durationInMs = (totalFrames / fr) * 1000;
                            const timeInMs = elapsed % (durationInMs || 1000);
                            return ip + (timeInMs / 1000 * fr);
                        })();

                    if (frameToRender !== null && instance.exports.update_player && playerRef.current.playerHandle !== undefined) {
                        const parentRect = canvasRef.current.parentElement?.getBoundingClientRect();
                        const canvasWidth = canvasRef.current.width;
                        const canvasHeight = canvasRef.current.height;
                        const animWidth = (animationData.w || 500);
                        const animHeight = (animationData.h || 500);
                        const viewportWidth = parentRect?.width || (canvasWidth / (window.devicePixelRatio || 1));
                        const viewportHeight = parentRect?.height || (canvasHeight / (window.devicePixelRatio || 1));
                        const dpr = window.devicePixelRatio || 1;
                        const scale = Math.min(viewportWidth / animWidth, viewportHeight / animHeight);
                        const offsetX = (viewportWidth - animWidth * scale) / 2;
                        const offsetY = (viewportHeight - animHeight * scale) / 2;
                        const frameNumber = Number(frameToRender) || 0;

                        viewportRef.current = {
                            scale,
                            offsetX,
                            offsetY,
                            dpr,
                        };
                        
                        ctx.save();
                        ctx.setTransform(1, 0, 0, 1, 0, 0);
                        ctx.clearRect(0, 0, canvasWidth, canvasHeight);
                        instance.exports.update_player(playerRef.current.playerHandle, frameNumber);
                        ctx.restore();
                    }
                    
                    animationFrameIdRef.current = requestAnimationFrame(renderFrame);
                };

                animationFrameIdRef.current = requestAnimationFrame(renderFrame);

            } catch (err) {
                console.error("WASM Load Error:", err);
                setError(err.message);
            }
        }

        initWasm();

        return () => {
            isMounted = false;
            if (resizeHandler) {
                window.removeEventListener('resize', resizeHandler);
            }
            if (animationFrameIdRef.current) {
                cancelAnimationFrame(animationFrameIdRef.current);
                animationFrameIdRef.current = null;
            }
            if (playerRef.current.instance?.exports.destroy_player && playerRef.current.playerHandle !== undefined) {
                playerRef.current.instance.exports.destroy_player(playerRef.current.playerHandle);
            }
            playerRef.current = {
                instance: null,
                playerHandle: undefined,
            };
        };
    }, [animationData, wasmUrl]);

    if (error) return <div className="text-red-500 text-xs p-2 border border-red-500">Error: {error}</div>;

    return (
        <div className={`relative flex items-center justify-center overflow-hidden rounded-lg bg-black/5 ${className}`} style={{ width: '100%', height: '100%' }}>
            <canvas 
                ref={canvasRef} 
                style={{ 
                    width: '100%', 
                    height: '100%', 
                    objectFit: 'contain',
                    imageRendering: 'pixelated' // 保持清晰度
                }}
            />
        </div>
    );
};

export default MoonLottiePlayer;