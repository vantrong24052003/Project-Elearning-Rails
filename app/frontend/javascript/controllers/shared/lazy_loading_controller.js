import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["screen", "progressCircle", "progressText"]

  connect() {
    if (document.readyState === 'complete') {
      this.hidePreloader()
      return
    }

    this.showPreloader()
    this.setupProgressAnimation()
    this.handlePageLoad()
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
    if (this.pageLoadHandler) window.removeEventListener('load', this.pageLoadHandler)
  }

  showPreloader() {
    this.screenTarget.style.display = 'flex'
    this.screenTarget.classList.remove('opacity-0')
  }

  hidePreloader() {
    this.screenTarget.classList.add('opacity-0')
    this.screenTarget.style.transition = 'opacity 0.5s ease'
    setTimeout(() => this.screenTarget.style.display = 'none', 500)
  }

  setupProgressAnimation() {
    this.progress = 0
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
      setTimeout(() => this.hidePreloader(), 300)
      if (this.interval) clearInterval(this.interval)
    }
    window.addEventListener('load', this.pageLoadHandler)
  }
}
