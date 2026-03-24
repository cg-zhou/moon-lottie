export function createEventEmitter() {
    const listeners = new Map();

    return {
        addEventListener(type, listener) {
            if (typeof listener !== 'function') {
                return () => {};
            }

            const bucket = listeners.get(type) || new Set();
            bucket.add(listener);
            listeners.set(type, bucket);

            return () => {
                bucket.delete(listener);
                if (bucket.size === 0) {
                    listeners.delete(type);
                }
            };
        },

        removeEventListener(type, listener) {
            const bucket = listeners.get(type);
            if (!bucket) {
                return;
            }

            bucket.delete(listener);
            if (bucket.size === 0) {
                listeners.delete(type);
            }
        },

        dispatchEvent(type, detail) {
            const bucket = listeners.get(type);
            if (!bucket) {
                return;
            }

            [...bucket].forEach((listener) => {
                listener(detail);
            });
        },

        clear() {
            listeners.clear();
        },
    };
}