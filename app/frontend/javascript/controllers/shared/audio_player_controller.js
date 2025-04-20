import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "toggleButton"]

  connect() {
    this.isMusicOn = localStorage.getItem("isMusicOn") === "true" || false
    this.currentTime = parseFloat(localStorage.getItem("currentTime") || "0")

    if (this.hasAudioTarget) {
      this.audioTarget.currentTime = this.currentTime

      document.addEventListener('click', this.enableAudio, { once: true })

      this.updatePlayback()

      this.audioTarget.addEventListener('timeupdate', this.handleTimeUpdate)
    }

    this.updateButtonIcon()

    window.addEventListener('storage', this.handleStorageChange)
  }

  disconnect() {
    document.removeEventListener('click', this.enableAudio)
    window.removeEventListener('storage', this.handleStorageChange)

    if (this.hasAudioTarget) {
      this.audioTarget.removeEventListener('timeupdate', this.handleTimeUpdate)
    }
  }

  toggleMusic() {
    this.isMusicOn = !this.isMusicOn
    localStorage.setItem("isMusicOn", this.isMusicOn)
    this.updatePlayback()
    this.updateButtonIcon()
  }

  updatePlayback() {
    if (!this.hasAudioTarget) return

    if (this.isMusicOn) {
      this.audioTarget.play().catch(error => console.error('Autoplay blocked:', error))
    } else {
      this.audioTarget.pause()
    }
  }

  updateButtonIcon() {
    if (!this.hasToggleButtonTarget) return

    this.toggleButtonTarget.innerHTML = this.isMusicOn ?
      `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M15.536 8.464a5 5 0 010 7.072M17.07 6.93a8 8 0 010 10.14M9 18l3-3-3-3v6z M6 18h2v-6H6v6z" />
      </svg>` :
      `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M9 18l3-3-3-3v6z M6 18h2v-6H6v6z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2" />
      </svg>`;
  }

  handleStorageChange = (event) => {
    if (event.key === 'isMusicOn') {
      this.isMusicOn = event.newValue === 'true'
      this.updatePlayback()
      this.updateButtonIcon()
    }
  }

  enableAudio = () => {
    if (this.hasAudioTarget) {
      this.audioTarget.muted = false
    }
  }

  handleTimeUpdate = () => {
    if (this.hasAudioTarget) {
      const currentTime = this.audioTarget.currentTime
      localStorage.setItem("currentTime", currentTime.toString())
    }
  }
}
