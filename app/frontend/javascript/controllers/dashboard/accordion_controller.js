import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.restoreState()
  }

  toggle(event) {
    event.preventDefault()

    const isVisible = !this.contentTarget.classList.contains('hidden')

    this.contentTarget.classList.toggle('hidden')

    if (isVisible) {
      this.iconTarget.style.transform = 'rotate(0deg)'
    } else {
      this.iconTarget.style.transform = 'rotate(180deg)'
    }

    this.saveState()
  }

  saveState() {
    const path = window.location.pathname
    const elementId = this.element.dataset.chapterId || this.element.dataset.lessonId
    const key = `accordion_${path}_${elementId}`
    const state = !this.contentTarget.classList.contains('hidden')
    localStorage.setItem(key, JSON.stringify(state))
  }

  restoreState() {
    const path = window.location.pathname
    const elementId = this.element.dataset.chapterId || this.element.dataset.lessonId
    const key = `accordion_${path}_${elementId}`
    const savedState = localStorage.getItem(key)

    if (savedState) {
      const state = JSON.parse(savedState)
      if (state) {
        this.contentTarget.classList.remove('hidden')
        this.iconTarget.style.transform = 'rotate(180deg)'
      }
    }
  }
}
