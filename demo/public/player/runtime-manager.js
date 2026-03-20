function normalizePreference(value) {
    if (value === 'auto' || value === 'wasm' || value === 'js') {
        return value;
    }

    return null;
}

export function createRuntimeManager(options = {}) {
    const {
        loadWasmRuntime,
        loadJsRuntime,
        onRuntimeChanged = () => {},
        storageKey = 'moon-lottie-runtime',
        queryKey = 'runtime',
    } = options;

    let runtime = null;
    let backend = 'uninitialized';
    let preference = 'auto';

    function readStoredPreference() {
        try {
            return window.localStorage.getItem(storageKey);
        } catch {
            return null;
        }
    }

    function writeStoredPreference(value) {
        try {
            window.localStorage.setItem(storageKey, value);
        } catch {
            // Ignore storage failures in restricted environments.
        }
    }

    function resolveInitialPreference() {
        const searchParams = new URLSearchParams(window.location.search);
        const runtimeParam = normalizePreference(searchParams.get(queryKey));
        if (runtimeParam) {
            writeStoredPreference(runtimeParam);
            return runtimeParam;
        }

        return normalizePreference(readStoredPreference()) || 'auto';
    }

    function describePreference(value) {
        if (value === 'js') return 'JS';
        if (value === 'wasm') return 'Wasm';
        return 'Auto';
    }

    function setActiveRuntime(nextRuntime, nextBackend) {
        runtime = nextRuntime;
        backend = nextBackend;
        onRuntimeChanged({ runtime, backend, preference });
        return runtime;
    }

    async function activate(preferenceToApply) {
        if (preferenceToApply === 'js') {
            return setActiveRuntime(await loadJsRuntime(), 'js');
        }

        if (preferenceToApply === 'wasm') {
            return setActiveRuntime(await loadWasmRuntime(), 'wasm');
        }

        try {
            return setActiveRuntime(await loadWasmRuntime(), 'wasm');
        } catch {
            return setActiveRuntime(await loadJsRuntime(), 'js');
        }
    }

    async function initialize() {
        preference = resolveInitialPreference();
        return activate(preference);
    }

    async function switchRuntime(nextPreference) {
        const normalized = normalizePreference(nextPreference);
        if (!normalized) {
            return runtime;
        }

        if (normalized === preference && runtime) {
            return runtime;
        }

        preference = normalized;
        writeStoredPreference(preference);
        return activate(preference);
    }

    return {
        initialize,
        switchRuntime,
        getRuntime: () => runtime,
        getBackend: () => backend,
        getPreference: () => preference,
        describePreference,
    };
}