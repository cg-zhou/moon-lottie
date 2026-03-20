export function createOfficialPlayerController(options = {}) {
    const {
        container,
        getLottie = () => window.lottie,
    } = options;

    let officialPlayer = null;

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
                renderer: 'svg',
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
        getPlayer: () => officialPlayer,
    };
}