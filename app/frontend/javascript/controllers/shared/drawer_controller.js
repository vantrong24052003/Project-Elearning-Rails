import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.applyStoredState()
    window.addEventListener('resize', this.handleResize.bind(this))
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize.bind(this))
  }

  applyStoredState() {
    if (window.innerWidth >= 1024) {
      const storedState = localStorage.getItem('drawer-state')
      this.toggleTarget.checked = storedState !== 'closed'
    } else {
      this.toggleTarget.checked = false
    }
  }

  handleResize() {
    if (window.innerWidth >= 1024) {
      const storedState = localStorage.getItem('drawer-state')
      this.toggleTarget.checked = storedState !== 'closed'
    } else {
      this.toggleTarget.checked = false
    }
  }

  toggleDrawer(event) {
    event.preventDefault()
    this.toggleTarget.checked = !this.toggleTarget.checked

    if (window.innerWidth >= 1024) {
      localStorage.setItem('drawer-state', this.toggleTarget.checked ? 'open' : 'closed')
    }
  }
}
