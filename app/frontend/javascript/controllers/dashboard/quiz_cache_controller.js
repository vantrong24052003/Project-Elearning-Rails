import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    isSubmitted: { type: Boolean, default: false }
  }

  connect() {
    console.log("Quiz cache controller connected")
    this.setupCachePrevention()
    this.setupBackButtonHandling()
  }

  setupCachePrevention() {
    window.addEventListener('pageshow', (event) => {
      if (event.persisted) {
        window.location.reload()
      }
    })
  }

  setupBackButtonHandling() {
    if (window.history && window.history.pushState) {
      window.history.pushState(null, null, window.location.href)
      window.addEventListener('popstate', this.handleBackButton.bind(this))
    }
  }

  handleBackButton(event) {
    event.preventDefault()
    window.history.pushState(null, null, window.location.href)
    if (confirm('Bạn có chắc muốn rời khỏi trang làm bài? Tiến trình làm bài sẽ được lưu lại.')) {
      window.location.href = document.referrer || '/'
    }
  }

  disconnect() {
    window.removeEventListener('popstate', this.handleBackButton.bind(this))
  }
}
