export function createOfficialPlayerController(options = {}) {
    const {
        container,
        getLottie = () => window.lottie,
        defaultRenderer = 'svg',
    } = options;

    let officialPlayer = null;
    let renderer = defaultRenderer === 'canvas' ? 'canvas' : 'svg';

    function destroy() {
        if (officialPlayer) {
            officialPlayer.destroy();
            officialPlayer = null;
        }

        if (container) {
            container.innerHTML = '';
        }
    }

    function load(animationData) {
        const lottie = getLottie();
        if (!lottie || typeof lottie.loadAnimation !== 'function') {
            return null;
        }

        destroy();

        try {
            officialPlayer = lottie.loadAnimation({
                container,
                renderer,
                loop: false,
                autoplay: false,
                animationData,
                rendererSettings: {
                    preserveAspectRatio: 'xMidYMid meet',
                    clearCanvas: true,
                },
            });
            return officialPlayer;
        } catch (error) {
            console.warn('Official renderer init failed:', error);
            officialPlayer = null;
            return null;
        }
    }

    function seek(frame) {
        if (officialPlayer) {
            officialPlayer.goToAndStop(frame, true);
        }
    }

    return {
        load,
        seek,
        destroy,
        setRenderer: (value) => {
            renderer = value === 'canvas' ? 'canvas' : 'svg';
        },
        getRenderer: () => renderer,
        getPlayer: () => officialPlayer,
    };
}
