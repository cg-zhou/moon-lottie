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
        dark: 'bg-[#0f172a]',
        light: 'bg-white',
        grid: 'bg-[#1e293b] bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]'
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm">
            <div className="bg-slate-900 border border-slate-700 w-full max-w-6xl max-h-[90vh] rounded-3xl overflow-hidden flex flex-col shadow-2xl">
                
                {/* Header */}
                <div className="p-6 border-b border-slate-800 flex items-center justify-between bg-slate-900/50">
                    <div>
                        <h2 className="text-xl font-bold text-white flex items-center gap-2">
                            <Monitor className="w-5 h-5 text-blue-400" />
                            Render Comparison
                        </h2>
                        <p className="text-slate-400 text-sm mt-1 font-mono uppercase tracking-tighter">
                            {sampleLabel} • {fr} FPS • {totalFrames} Frames
                        </p>
                    </div>
                    <button 
                        onClick={onClose}
                        className="p-2 hover:bg-slate-800 rounded-full text-slate-400 transition"
                    >
                        <X className="w-6 h-6" />
                    </button>
                </div>

                {/* Main Viewport */}
                <div className="flex-1 flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-slate-800 overflow-hidden">
                    
                    {/* Left: MoonLottie (WASM) */}
                    <div className="flex-1 flex flex-col overflow-hidden">
                        <div className="p-3 bg-blue-600/10 border-b border-blue-500/20 flex items-center justify-between">
                            <span className="text-[10px] font-black text-blue-400 tracking-widest uppercase flex items-center gap-1">
                                <Zap className="w-3 h-3 fill-current" /> MoonLottie (WASM-GC)
                            </span>
                            <span className="text-[10px] bg-blue-500/20 px-2 py-0.5 rounded text-blue-300">EXPERIMENTAL</span>
                        </div>
                        <div className={`flex-1 flex items-center justify-center p-8 ${bgClasses[background]}`}>
                            <MoonLottiePlayer 
                                animationData={animationData}
                                width={500}
                                height={400}
                                currentFrameControlled={currentTime}
                                autoPlay={false}
                                className="drop-shadow-2xl"
                            />
                        </div>
                    </div>

                    {/* Right: Official (JS) */}
                    <div className="flex-1 flex flex-col overflow-hidden">
                        <div className="p-3 bg-slate-800 border-b border-slate-700 flex items-center justify-between">
                            <span className="text-[10px] font-black text-slate-400 tracking-widest uppercase">
                                Official Lottie-Web (JS)
                            </span>
                            <span className="text-[10px] bg-slate-700 px-2 py-0.5 rounded text-slate-400">STABLE</span>
                        </div>
                        <div className={`flex-1 flex items-center justify-center p-8 ${bgClasses[background]}`}>
                            <OfficialPlayer 
                                animationData={animationData}
                                width={500}
                                height={400}
                                currentFrame={currentTime}
                                className="drop-shadow-2xl"
                            />
                        </div>
                    </div>
                </div>

                {/* Footer Controls */}
                <div className="p-6 bg-slate-900 border-t border-slate-800">
                    <div className="flex flex-col gap-4">
                        {/* Timeline */}
                        <div className="flex items-center gap-4">
                            <span className="text-[10px] font-mono text-slate-500 w-12">{currentTime.toFixed(0)} F</span>
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
                                className="flex-1 h-1.5 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-blue-500"
                            />
                            <span className="text-[10px] font-mono text-slate-500 w-12">{op.toFixed(0)} F</span>
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <button 
                                    onClick={() => setIsPlaying(!isPlaying)}
                                    className="p-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl transition"
                                >
                                    {isPlaying ? <Pause size={20} /> : <Play size={20} />}
                                </button>
                                <button 
                                    onClick={() => {
                                        startTimeRef.current = Date.now();
                                        setCurrentTime(ip);
                                    }}
                                    className="p-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl transition"
                                >
                                    <RotateCcw size={20} />
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