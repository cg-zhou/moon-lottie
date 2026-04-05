import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import MoonLottiePlayer from '@moon-lottie/react';

const assetBase = import.meta.env.BASE_URL;

const App = () => {
  const playerRef = useRef<any>(null);
  const [speed, setSpeed] = useState(1);
  const [loop, setLoop] = useState(true);
  const [direction, setDirection] = useState(1);
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    console.log('Player Ref:', playerRef.current);
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setFrame(playerRef.current?.getCurrentFrame?.() ?? 0);
    }, 150);

    return () => window.clearInterval(timer);
  }, []);

  const updateSpeed = (value: number) => {
    setSpeed(value);
    playerRef.current?.setSpeed(value);
  };

  const updateLoop = (value: boolean) => {
    setLoop(value);
    playerRef.current?.setLoop(value);
  };

  const updateDirection = (value: number) => {
    setDirection(value);
    playerRef.current?.setDirection(value);
  };

  const controlsStyle = {
    display: 'flex',
    flexWrap: 'wrap' as const,
    gap: '8px',
    marginTop: '12px',
    alignItems: 'center',
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h2>React Example</h2>
      <p style={{ marginBottom: '12px', color: '#666' }}>
        This is a <a href="https://www.npmjs.com/package/@moon-lottie/react" style={{ textDecoration: 'underline', color: '#111' }}>@moon-lottie/react</a> example of <a href="https://lottie.cg-zhou.top/" style={{ textDecoration: 'underline', color: '#111' }}>Moon Lottie</a>.
      </p>
      <div style={{ width: '300px', height: '200px', border: '1px solid #eee' }}>
        <MoonLottiePlayer
          ref={playerRef}
          src={`${assetBase}samples/1_1_Super_Mario.json`}
          autoplay
          loop={loop}
          speed={speed}
          style={{ width: '100%', height: '100%' }}
          wasmPath={`${assetBase}runtime/wasm/moon-lottie-runtime.wasm`}
          jsRuntimePath={`${assetBase}runtime/js/moon-lottie-runtime.js`}
        />
      </div>
      <div style={controlsStyle}>
        <button onClick={() => playerRef.current?.play()}>Play</button>
        <button onClick={() => playerRef.current?.pause()}>Pause</button>
        <button onClick={() => playerRef.current?.stepFrame(-1)}>Prev Frame</button>
        <button onClick={() => playerRef.current?.stepFrame(1)}>Next Frame</button>
        <button onClick={() => updateDirection(1)}>Forward</button>
        <button onClick={() => updateDirection(-1)}>Reverse</button>
        <label>
          Speed{' '}
          <select value={speed} onChange={(event) => updateSpeed(Number(event.target.value))}>
            <option value={0.5}>0.5x</option>
            <option value={1}>1x</option>
            <option value={1.5}>1.5x</option>
            <option value={2}>2x</option>
          </select>
        </label>
        <label>
          <input
            type="checkbox"
            checked={loop}
            onChange={(event) => updateLoop(event.target.checked)}
          />{' '}
          Loop
        </label>
      </div>
      <p style={{ marginTop: '12px', color: '#555' }}>
        Frame: {Math.round(frame)} | Speed: {speed}x | Direction: {direction > 0 ? 'forward' : 'reverse'} | Loop: {loop ? 'on' : 'off'}
      </p>
    </div>
  );
};

const container = document.getElementById('root');
if (container) {
  const root = createRoot(container);
  root.render(<App />);
}
