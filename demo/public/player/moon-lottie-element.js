import { createBrowserPlayer } from './browser-player.js';

function normalizeSpeed(value) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
        return 1;
    }

    return Math.min(4, Math.max(0.1, Math.round(parsed * 10) / 10));
}

export class MoonLottieElement extends HTMLElement {
    static get observedAttributes() {
        return ['src', 'autoplay', 'loop', 'speed', 'direction', 'background'];
    }

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
        this._speed = normalizeSpeed(this.getAttribute('speed') || '1');
        this._direction = Number(this.getAttribute('direction')) < 0 ? -1 : 1;
        this._autoplay = this.getAttribute('autoplay') !== 'false';
        this._loop = this.getAttribute('loop') !== 'false';
        this._background = this.getAttribute('background') || 'transparent';
        this._player = null;
        this._readyPromise = Promise.resolve(null);
        this._listenerCleanups = [];
        this._mounted = false;

        this._shadow.innerHTML = `
            <style>
                :host {
                    display: block;
                    min-width: 0;
                    min-height: 0;
                }

                .mount {
                    width: 100%;
                    height: 100%;
                    min-height: 120px;
                }
            </style>
            <div class="mount"></div>
        `;

        this._mount = this._shadow.querySelector('.mount');
    }

    _createPlayer() {
        this._player = createBrowserPlayer({
            container: this._mount,
            path: this.getAttribute('src') || null,
            autoplay: this._autoplay,
            loop: this._loop,
            speed: this._speed,
            direction: this._direction,
            background: this._background,
        });
        this._readyPromise = this._player.whenReady();
        this._bindPlayerEvents();
    }

    _destroyPlayer() {
        this._listenerCleanups.forEach((cleanup) => cleanup?.());
        this._listenerCleanups = [];
        this._player?.destroy();
        this._player = null;
        this._readyPromise = Promise.resolve(null);
    }

    connectedCallback() {
        if (this._mounted) {
            return;
        }

        this._mounted = true;
        this._createPlayer();
    }

    disconnectedCallback() {
        this._destroyPlayer();
        this._mounted = false;
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue) {
            return;
        }

        if (name === 'src' && this._mounted && newValue) {
            this.loadAnimation({ path: newValue, name: newValue });
        }

        if (name === 'autoplay') {
            this._autoplay = newValue !== 'false';
        }

        if (name === 'loop') {
            this._loop = newValue !== 'false';
            this._player?.setLoop(this._loop);
        }

        if (name === 'speed') {
            this._speed = normalizeSpeed(newValue || '1');
            this._player?.setSpeed(this._speed);
        }

        if (name === 'direction') {
            this._direction = Number(newValue) < 0 ? -1 : 1;
            this._player?.setDirection(this._direction);
        }

        if (name === 'background') {
            this._background = newValue || 'transparent';
            this._player?.setBackground(this._background);
        }
    }

    _bindPlayerEvents() {
        if (!this._player) {
            return;
        }

        this._listenerCleanups = ['load', 'error', 'runtimechange', 'enterframe', 'enterFrame', 'play', 'pause', 'complete', 'loopComplete', 'destroy'].map((type) => {
            return this._player.addEventListener(type, (detail) => {
                this.dispatchEvent(new CustomEvent(type, { detail }));
            });
        });
    }

    whenReady() {
        return this._readyPromise;
    }

    load(source) {
        if (typeof source === 'string') {
            return this.loadAnimation({ path: source, name: source });
        }
        return this.loadAnimation(source);
    }

    loadAnimation(options = {}) {
        if (!this._player && this.isConnected) {
            this._mounted = true;
            this._createPlayer();
        }

        if (!this._player) {
            return Promise.reject(new Error('MoonLottieElement is not connected'));
        }

        const normalized = {
            ...options,
            autoplay: options.autoplay ?? this._autoplay,
            loop: options.loop ?? this._loop,
            speed: options.speed ?? this._speed,
            direction: options.direction ?? this._direction,
            background: options.background ?? this._background,
        };

        return this._player.loadAnimation(normalized);
    }

    play() {
        this._player?.play();
    }

    pause() {
        this._player?.pause();
    }

    stop() {
        this._player?.stop();
    }

    setSpeed(speed) {
        this._speed = normalizeSpeed(speed);
        this.setAttribute('speed', String(this._speed));
    }

    setDirection(direction) {
        this._direction = Number(direction) < 0 ? -1 : 1;
        this.setAttribute('direction', String(this._direction));
    }

    setLoop(loop) {
        this._loop = Boolean(loop);
        this.setAttribute('loop', String(this._loop));
    }

    setBackground(background) {
        this._background = background || 'transparent';
        this.setAttribute('background', this._background);
    }

    goToAndStop(value, isFrame = false) {
        this._player?.goToAndStop(value, isFrame);
    }

    goToAndPlay(value, isFrame = false) {
        this._player?.goToAndPlay(value, isFrame);
    }

    playSegments(segments, forceFlag = false) {
        return this._player?.playSegments(segments, forceFlag) ?? [];
    }

    setSubframe(value) {
        return this._player?.setSubframe(value);
    }

    resize() {
        this._player?.resize();
    }

    getCurrentFrame() {
        return this._player?.getCurrentFrame() ?? 0;
    }

    getDuration(inFrames = false) {
        return this._player?.getDuration(inFrames) ?? 0;
    }

    getSubframe() {
        return this._player?.getSubframe() ?? true;
    }

    getPlayer() {
        return this._player;
    }

    destroy() {
        this._destroyPlayer();
        this._mounted = false;
    }
}

export function defineMoonLottieElement(tagName = 'moon-lottie') {
    if (!customElements.get(tagName)) {
        customElements.define(tagName, MoonLottieElement);
    }

    return customElements.get(tagName);
}