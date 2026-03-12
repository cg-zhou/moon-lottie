import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Search, Filter, Tag, Info, LayoutGrid, Eye } from 'lucide-react';
import MoonLottiePlayer from './components/MoonLottiePlayer';
import ComparisonModal from './components/ComparisonModal';

const App = () => {
  const [samples, setSamples] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [activeTag, setActiveTag] = useState('all');
  const [activeSource, setActiveSource] = useState('all');
  const [loading, setLoading] = useState(true);
  
  // Modal State
  const [selectedSample, setSelectedSample] = useState(null);
  const [selectedAnimationData, setSelectedAnimationData] = useState(null);

  // 加载 sample_index.json
  useEffect(() => {
    fetch('/sample_index.json')
      .then(res => res.json())
      .then(data => {
        setSamples(data);
        setLoading(false);
      });
  }, []);

  const handleInspect = async (sample) => {
    setSelectedSample(sample);
    try {
      const response = await fetch(`/samples/${sample.file}`);
      const data = await response.json();
      setSelectedAnimationData(data);
    } catch (err) {
      console.error("Failed to load sample for inspector:", err);
    }
  };

  // 所有可用标签
  const allTags = useMemo(() => {
    const tags = new Set(['all']);
    samples.forEach(s => s.tags?.forEach(t => tags.add(t)));
    return Array.from(tags);
  }, [samples]);

  // 搜索和过滤逻辑
  const filteredSamples = useMemo(() => {
    return samples.filter(s => {
      const matchSearch = s.label.toLowerCase().includes(searchTerm.toLowerCase());
      const matchTag = activeTag === 'all' || s.tags?.includes(activeTag);
      const matchSource = activeSource === 'all' || s.source === activeSource;
      return matchSearch && matchTag && matchSource;
    }).slice(0, 100); 
  }, [searchTerm, activeTag, activeSource, samples]);

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-200">
      {/* Header Area */}
      <div className="bg-slate-900/50 border-b border-slate-800/80 sticky top-0 z-10 backdrop-blur-md">
        <div className="max-w-7xl mx-auto p-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h1 className="text-3xl font-black bg-gradient-to-r from-blue-400 to-indigo-500 bg-clip-text text-transparent italic flex items-center gap-3">
                <LayoutGrid className="w-8 h-8 text-blue-500" />
                MOON-LOTTIE 2.0
              </h1>
              <p className="text-slate-500 text-sm mt-1 font-medium">
                WASM-powered Lottie rendering engine • {samples.length} animations
              </p>
            </div>

            <div className="flex items-center gap-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 w-4 h-4" />
                <input 
                  type="text" 
                  placeholder="Search..." 
                  className="bg-slate-950/50 border border-slate-700/50 rounded-lg py-1.5 pl-9 pr-4 text-sm focus:ring-1 focus:ring-blue-500 focus:outline-none w-48 lg:w-64"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
            </div>
          </div>

          <div className="flex flex-wrap gap-2 mt-6">
            {allTags.map(tag => (
              <button
                key={tag}
                onClick={() => setActiveTag(tag)}
                className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider transition duration-200 ${
                  activeTag === tag 
                    ? 'bg-blue-600/20 text-blue-400 border border-blue-500/50 shadow-[0_0_15px_rgba(37,99,235,0.2)]' 
                    : 'bg-slate-800/40 text-slate-500 border border-slate-700/30 hover:bg-slate-700/50'
                }`}
              >
                #{tag}
              </button>
            ))}
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto p-6 pb-24">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-40 gap-4">
            <div className="w-10 h-10 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
            <p className="text-slate-500 font-medium">Initializing WASM Playground...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredSamples.map((sample) => (
              <LottieCard 
                key={sample.file} 
                sample={sample} 
                onInspect={() => handleInspect(sample)}
              />
            ))}
          </div>
        )}
      </main>

      {/* Comparison Inspector Modal */}
      {selectedSample && selectedAnimationData && (
        <ComparisonModal 
          isOpen={!!selectedSample}
          onClose={() => {
            setSelectedSample(null);
            setSelectedAnimationData(null);
          }}
          sampleLabel={selectedSample.label}
          animationData={selectedAnimationData}
        />
      )}
    </div>
  );
};

const LottieCard = ({ sample, onInspect }) => {
  const [animationData, setAnimationData] = useState(null);
  const [isIntersecting, setIsIntersecting] = useState(false);
  const cardRef = useRef(null);

  // 1. 基础可见性监听 (Lazy Loading + Viewport Auto-play)
  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      setIsIntersecting(entry.isIntersecting);
    }, { threshold: 0.1 });

    if (cardRef.current) observer.observe(cardRef.current);
    return () => observer.disconnect();
  }, []);

  // 2. 加载数据
  useEffect(() => {
    if (isIntersecting && !animationData) {
      fetch(`/samples/${sample.file}`)
        .then(res => res.json())
        .then(data => setAnimationData(data))
        .catch(err => console.error("Failed to load animation:", sample.file));
    }
  }, [isIntersecting, animationData, sample.file]);

  return (
    <div 
      ref={cardRef}
      className={`group bg-slate-800/30 rounded-2xl border transition-all duration-300 overflow-hidden flex flex-col ${
        isIntersecting ? 'border-slate-800/80' : 'border-slate-800/20'
      } hover:border-blue-500/50 hover:shadow-xl hover:shadow-blue-500/10`}
    >
      <div className="aspect-[4/3] flex items-center justify-center bg-slate-900/40 relative">
        {animationData ? (
          <>
            <MoonLottiePlayer 
              animationData={animationData} 
              width={400} 
              height={300}
              autoPlay={true}
              isPaused={!isIntersecting} 
              className="w-full h-full"
            />
            {/* Hover Actions */}
            <div className="absolute inset-0 bg-slate-900/0 group-hover:bg-slate-950/40 transition-all duration-300 flex items-center justify-center">
               <button 
                onClick={onInspect}
                className="opacity-0 group-hover:opacity-100 scale-90 group-hover:scale-100 transition-all bg-white text-slate-900 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest flex items-center gap-2 shadow-2xl hover:bg-blue-50"
               >
                 <Eye size={14} /> Compare
               </button>
            </div>
          </>
        ) : (
          <div className="w-10 h-10 border-2 border-slate-700 border-t-slate-500 rounded-full animate-spin" />
        )}
      </div>
      
      <div className="p-4 flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-slate-300 truncate text-sm flex-1">{sample.label}</h3>
          <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700/50 text-slate-500 uppercase font-mono">
            {sample.source}
          </span>
        </div>
        
        <div className="flex flex-wrap gap-1">
          {sample.tags?.map(tag => (
            <span key={tag} className="text-[10px] text-blue-400 bg-blue-400/10 px-1.5 py-0.5 rounded border border-blue-400/20">
              {tag}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

export default App;