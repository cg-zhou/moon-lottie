import React, { useEffect, useRef } from 'react';

const OfficialPlayer = ({ 
    animationData, 
    width = 400, 
    height = 300, 
    className = "",
    currentFrame = 0, // 受控模式：外部传入帧号
    isControlled = true // 是否由外部驱动
}) => {
    const containerRef = useRef(null);
    const animInstance = useRef(null);

    useEffect(() => {
        if (!animationData || !containerRef.current) return;

        // 动态加载 lottie-web (通过 public 目录下的 lottie.min.js)
        const initLottie = () => {
            if (!window.lottie) {
                console.error("Lottie-web not found in window. Ensure lottie.min.js is loaded in index.html");
                return;
            }

            // 清除旧实例
            if (animInstance.current) {
                animInstance.current.destroy();
            }

            animInstance.current = window.lottie.loadAnimation({
                container: containerRef.current,
                renderer: 'canvas', // 使用 canvas 对标 moon-lottie
                loop: false,
                autoplay: !isControlled,
                animationData: JSON.parse(JSON.stringify(animationData))
            });
        };

        if (window.lottie) {
            initLottie();
        } else {
            const script = document.createElement('script');
            script.src = '/lottie.min.js';
            script.onload = initLottie;
            document.head.appendChild(script);
        }

        return () => {
            if (animInstance.current) {
                animInstance.current.destroy();
            }
        };
    }, [animationData, isControlled]);

    // 同步帧
    useEffect(() => {
        if (animInstance.current && isControlled) {
            animInstance.current.goToAndStop(currentFrame, true);
        }
    }, [currentFrame, isControlled]);

    return (
        <div 
            ref={containerRef} 
            className={`official-player ${className}`} 
            style={{ width, height, overflow: 'hidden' }}
        />
    );
};

export default OfficialPlayer;