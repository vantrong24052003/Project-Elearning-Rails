import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["screen", "progressCircle", "progressText"]

  connect() {
    this.progress = 0
    this.setupProgressAnimation()
    this.handlePageLoad()
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
    window.removeEventListener('load', this.pageLoadHandler)
  }

  setupProgressAnimation() {
    this.interval = setInterval(() => {
      if (this.progress >= 90) return
      this.progress += Math.random() * 8
      this.updateProgress(Math.min(this.progress, 90))
    }, 100)
  }

  updateProgress(value) {
    this.progress = value
    this.progressTextTarget.innerText = `${Math.round(this.progress)}%`
    this.progressCircleTarget.setAttribute('stroke-dashoffset', 282.74 - (282.74 * this.progress / 100))
  }

  handlePageLoad() {
    this.pageLoadHandler = () => {
      this.updateProgress(100)

      setTimeout(() => {
        this.screenTarget.classList.add('opacity-0')
        this.screenTarget.style.transition = 'opacity 0.5s ease'

        setTimeout(() => {
          this.screenTarget.style.display = 'none'
        }, 500)
      }, 500)

      clearInterval(this.interval)
    }

    if (document.readyState === 'complete') {
      this.pageLoadHandler()
    } else {
      window.addEventListener('load', this.pageLoadHandler)
    }
  }
}
