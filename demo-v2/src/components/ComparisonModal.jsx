import React, { useState, useEffect, useRef } from 'react';
import { X, Play, Pause, RotateCcw, Monitor, Zap } from 'lucide-react';
import MoonLottiePlayer from './MoonLottiePlayer';
import OfficialPlayer from './OfficialPlayer';

const ComparisonModal = ({ isOpen, onClose, animationData, sampleLabel }) => {
    const [currentTime, setCurrentTime] = useState(0);
    const [isPlaying, setIsPlaying] = useState(true);
    const [background, setBackground] = useState('dark'); // dark, light, grid
    const requestRef = useRef();
    const startTimeRef = useRef(Date.now());

    const fr = animationData?.fr || 60;
    const ip = animationData?.ip || 0;
    const op = animationData?.op || 100;
    const totalFrames = op - ip;
    const duration = (totalFrames / fr) * 1000;

    // 同步时钟逻辑
    useEffect(() => {
        if (!isOpen || !animationData) return;

        const animate = () => {
            if (isPlaying) {
              const now = Date.now();
              const elapsed = (now - startTimeRef.current) % duration;
              const currentFrame = ip + (elapsed / 1000 * fr);
              setCurrentTime(currentFrame);
            }
            requestRef.current = requestAnimationFrame(animate);
        };

        requestRef.current = requestAnimationFrame(animate);
        return () => cancelAnimationFrame(requestRef.current);
    }, [isOpen, isPlaying, duration, ip, fr, animationData]);

    if (!isOpen) return null;

    const bgClasses = {
        dark: 'bg-[#1d1d1f]',
        light: 'bg-white',
        grid: 'bg-[#f5f5f7] bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]'
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
            <div className="bg-white border border-[#e5e5e7] w-full max-w-6xl max-h-[90vh] rounded-xl overflow-hidden flex flex-col shadow-2xl">
                
                {/* Header */}
                <div className="p-4 border-b border-[#e5e5e7] flex items-center justify-between bg-white">
                    <div>
                        <h2 className="text-lg font-semibold text-[#1d1d1f] flex items-center gap-2">
                            <Monitor className="w-5 h-5 text-[#007aff]" />
                            Render Comparison
                        </h2>
                        <p className="text-[#86868b] text-xs mt-0.5">
                            {sampleLabel} • {fr} FPS • {totalFrames} Frames
                        </p>
                    </div>
                    <button 
                        onClick={onClose}
                        className="p-2 hover:bg-[#f5f5f7] rounded-full text-[#86868b] transition"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Main Viewport */}
                <div className="flex-1 flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-[#e5e5e7] overflow-hidden">
                    
                    {/* Left: MoonLottie (WASM) */}
                    <div className="flex-1 flex flex-col overflow-hidden">
                        <div className="p-2.5 bg-[#007aff]/5 border-b border-[#007aff]/10 flex items-center justify-between">
                            <span className="text-[10px] font-semibold text-[#007aff] uppercase flex items-center gap-1">
                                <Zap className="w-3 h-3 fill-current" /> MoonLottie (WASM-GC)
                            </span>
                            <span className="text-[10px] bg-[#007aff]/10 px-1.5 py-0.5 rounded text-[#007aff]">EXPERIMENTAL</span>
                        </div>
                        <div className={`flex-1 flex items-center justify-center p-8 ${bgClasses[background]}`}>
                            <MoonLottiePlayer 
                                animationData={animationData}
                                width={500}
                                height={400}
                                currentFrameControlled={currentTime}
                                autoPlay={false}
                            />
                        </div>
                    </div>

                    {/* Right: Official (JS) */}
                    <div className="flex-1 flex flex-col overflow-hidden">
                        <div className="p-2.5 bg-[#f5f5f7] border-b border-[#e5e5e7] flex items-center justify-between">
                            <span className="text-[10px] font-semibold text-[#86868b] uppercase">
                                Official Lottie-Web (JS)
                            </span>
                            <span className="text-[10px] bg-[#e5e5e7] px-1.5 py-0.5 rounded text-[#86868b]">STABLE</span>
                        </div>
                        <div className={`flex-1 flex items-center justify-center p-8 ${bgClasses[background]}`}>
                            <OfficialPlayer 
                                animationData={animationData}
                                width={500}
                                height={400}
                                currentFrame={currentTime}
                            />
                        </div>
                    </div>
                </div>

                {/* Footer Controls */}
                <div className="p-6 bg-white border-t border-[#e5e5e7]">
                    <div className="flex flex-col gap-4">
                        {/* Timeline */}
                        <div className="flex items-center gap-4">
                            <span className="text-[10px] font-mono text-[#86868b] w-12">{currentTime.toFixed(0)} F</span>
                            <input 
                                type="range" 
                                min={ip} 
                                max={op} 
                                step={0.1}
                                value={currentTime}
                                onChange={(e) => {
                                    setIsPlaying(false);
                                    setCurrentTime(parseFloat(e.target.value));
                                }}
                                className="flex-1 h-1 bg-[#e5e5e7] rounded-lg appearance-none cursor-pointer accent-[#007aff]"
                            />
                            <span className="text-[10px] font-mono text-[#86868b] w-12">{op.toFixed(0)} F</span>
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <button 
                                    onClick={() => setIsPlaying(!isPlaying)}
                                    className="p-2.5 bg-[#007aff] hover:bg-[#0070e0] text-white rounded-lg transition shadow-sm"
                                >
                                    {isPlaying ? <Pause size={18} /> : <Play size={18} />}
                                </button>
                                <button 
                                    onClick={() => {
                                        startTimeRef.current = Date.now();
                                        setCurrentTime(ip);
                                    }}
                                    className="p-2.5 bg-[#f5f5f7] hover:bg-[#e5e5e7] text-[#1d1d1f] rounded-lg transition border border-[#e5e5e7]"
                                >
                                    <RotateCcw size={18} />
                                </button>
                            </div>

                            <div className="flex bg-slate-800 p-1 rounded-xl">
                                {['dark', 'light', 'grid'].map(b => (
                                    <button
                                        key={b}
                                        onClick={() => setBackground(b)}
                                        className={`px-4 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition ${
                                            background === b ? 'bg-slate-700 text-white shadow-sm' : 'text-slate-500 hover:text-slate-300'
                                        }`}
                                    >
                                        {b}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ComparisonModal;