import { Controller } from "@hotwired/stimulus"

let globalAudio = null;

export default class extends Controller {
  static targets = ["audio", "toggleButton", "mutedIcon", "playingIcon"]

  connect() {
    console.log("Audio player controller connected")

    if (!globalAudio) {
      globalAudio = new Audio(this.audioTarget.src);
      globalAudio.loop = true;
      globalAudio.muted = localStorage.getItem("musicEnabled") !== "true";

      if (localStorage.getItem("musicEnabled") === "true") {
        this.tryPlayAudio();
      }
    }

    this.updateUI();

    document.addEventListener('turbo:before-cache', this.beforeCache.bind(this));
    document.addEventListener('turbo:load', this.updateUI.bind(this));

    this.setupInteractionListeners();
  }

  disconnect() {
  }

  beforeCache() {
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.classList.remove('animate-pulse');
    }
  }

  setupInteractionListeners() {
    const enableAudio = () => {
      if (localStorage.getItem("musicEnabled") === "true" && globalAudio) {
        globalAudio.play().catch(e => console.log("Audio still couldn't play:", e));
      }
    };

    document.addEventListener('click', enableAudio, { once: true });
    document.addEventListener('keydown', enableAudio, { once: true });
    document.addEventListener('touchstart', enableAudio, { once: true });
  }

  updateUI() {
    if (!globalAudio) return;

    if (globalAudio.muted) {
      if (this.hasMutedIconTarget) this.mutedIconTarget.classList.remove("hidden");
      if (this.hasPlayingIconTarget) this.playingIconTarget.classList.add("hidden");
      if (this.hasToggleButtonTarget) this.toggleButtonTarget.classList.remove("animate-pulse");
    } else {
      if (this.hasMutedIconTarget) this.mutedIconTarget.classList.add("hidden");
      if (this.hasPlayingIconTarget) this.playingIconTarget.classList.remove("hidden");
      if (this.hasToggleButtonTarget) this.toggleButtonTarget.classList.add("animate-pulse");
    }
  }

  toggleMusic(event) {
    if (!globalAudio) {
      globalAudio = new Audio(this.audioTarget.src);
      globalAudio.loop = true;
    }

    if (globalAudio.muted) {
      this.unmute();
    } else {
      this.mute();
    }
  }

  unmute() {
    if (globalAudio) {
      globalAudio.muted = false;
      this.tryPlayAudio();
      localStorage.setItem("musicEnabled", "true");
    }

    if (this.hasMutedIconTarget) this.mutedIconTarget.classList.add("hidden");
    if (this.hasPlayingIconTarget) this.playingIconTarget.classList.remove("hidden");
    if (this.hasToggleButtonTarget) this.toggleButtonTarget.classList.add("animate-pulse");
  }

  mute() {
    if (globalAudio) {
      globalAudio.muted = true;
      localStorage.setItem("musicEnabled", "false");
    }

    if (this.hasMutedIconTarget) this.mutedIconTarget.classList.remove("hidden");
    if (this.hasPlayingIconTarget) this.playingIconTarget.classList.add("hidden");
    if (this.hasToggleButtonTarget) this.toggleButtonTarget.classList.remove("animate-pulse");
  }

  tryPlayAudio() {
    if (!globalAudio) return;

    const playPromise = globalAudio.play();
    if (playPromise !== undefined) {
      playPromise.catch(error => {
        console.error("Audio play failed:", error);
        if (error.name === "NotAllowedError") {
          console.log("Audio autoplay prevented. User interaction required.");
        }
      });
    }
  }
}
