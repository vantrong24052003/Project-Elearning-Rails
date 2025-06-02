import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer"]

  connect() {
    this.duration = 60 * 60
    this.updateTimer()
    this.timer = setInterval(() => this.updateTimer(), 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  updateTimer() {
    if (this.duration <= 0) {
      clearInterval(this.timer)
      return
    }

    const minutes = Math.floor(this.duration / 60)
    const seconds = this.duration % 60

    this.timerTarget.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
    this.duration--
  }
}
