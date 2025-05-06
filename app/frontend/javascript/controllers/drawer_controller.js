import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.checkScreenSize()

    window.addEventListener('resize', this.checkScreenSize.bind(this))

    if (localStorage.getItem('drawer-state') === null) {
      localStorage.setItem('drawer-state', 'open')
    }

    this.applyDrawerState()
  }

  disconnect() {
    window.removeEventListener('resize', this.checkScreenSize.bind(this))
  }

  checkScreenSize() {
    if (window.innerWidth >= 1024) {
      if (localStorage.getItem('drawer-state') === 'open') {
        this.toggleTarget.checked = true
      } else {
        this.toggleTarget.checked = false
      }
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

  applyDrawerState() {
    if (window.innerWidth >= 1024) {
      const state = localStorage.getItem('drawer-state')
      this.toggleTarget.checked = state === 'open'
    }
  }
}
