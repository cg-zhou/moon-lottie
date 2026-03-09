export function moonStringJS(moonStr) {
    if (typeof moonStr === 'string') return moonStr;
    if (moonStr === null || moonStr === undefined) return "";

    const primitive = typeof moonStr.valueOf === 'function' ? moonStr.valueOf() : moonStr;
    if (typeof primitive === 'string') return primitive;

    if (typeof moonStr.toString === 'function') {
        const stringified = moonStr.toString();
        if (typeof stringified === 'string' && stringified !== '[object Object]') {
            return stringified;
        }
    }

    const len = typeof moonStr.length === 'function' ? moonStr.length() : moonStr.length;
    if (typeof len !== 'number') return "";

    let res = "";
    for (let i = 0; i < len; i++) {
        const code = typeof moonStr.get === 'function' ? moonStr.get(i) : moonStr[i];
        if (typeof code !== 'number') return "";
        res += String.fromCharCode(code);
    }
    return res;
}

function warnInvalidWasmString(message) {
    if (typeof console === 'object' && typeof console.warn === 'function') {
        console.warn(`[moon-lottie] ${message}`);
    }
}

export function readWasmString(length, getCharCodeAt) {
    if (typeof length !== 'number' || length < 0) {
        warnInvalidWasmString(`invalid exported string length: ${length}`);
        return "";
    }

    let res = "";
    for (let i = 0; i < length; i++) {
        const code = getCharCodeAt(i);
        if (typeof code !== 'number' || code < 0) {
            warnInvalidWasmString(`invalid exported string char code at ${i}: ${code}`);
            return "";
        }
        res += String.fromCharCode(code);
    }
    return res;
}
