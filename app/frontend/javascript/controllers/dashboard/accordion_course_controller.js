import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "trigger"]

  connect() {
    this.element.querySelectorAll('[data-dashboard--accordion-course-target="trigger"]').forEach((trigger, index) => {
      if (!trigger.dataset.accordionId) {
        trigger.dataset.accordionId = `accordion_${index}`
      }
    })

    this.restoreState()
  }

  toggle(event) {
    event.preventDefault()

    const trigger = event.currentTarget
    const accordionId = trigger.dataset.accordionId

    const content = this.element.querySelector(`[data-accordion-id="${accordionId}"][data-dashboard--accordion-course-target="content"]`)
    const icon = this.element.querySelector(`[data-accordion-id="${accordionId}"][data-dashboard--accordion-course-target="icon"]`)

    if (!content || !icon) return

    const isVisible = !content.classList.contains('hidden')
    content.classList.toggle('hidden')

    if (isVisible) {
      icon.style.transform = 'rotate(0deg)'
    } else {
      icon.style.transform = 'rotate(180deg)'
    }

    this.saveState(accordionId, !content.classList.contains('hidden'))
  }

  saveState(accordionId, isOpen) {
    const path = window.location.pathname
    const key = `accordion_course_${path}_${accordionId}`
    localStorage.setItem(key, JSON.stringify(isOpen))
  }

  restoreState() {
    const path = window.location.pathname

    this.element.querySelectorAll('[data-dashboard--accordion-course-target="trigger"]').forEach(trigger => {
      const accordionId = trigger.dataset.accordionId
      if (!accordionId) return

      const key = `accordion_course_${path}_${accordionId}`
      const savedState = localStorage.getItem(key)

      if (savedState) {
        const state = JSON.parse(savedState)
        const content = this.element.querySelector(`[data-accordion-id="${accordionId}"][data-dashboard--accordion-course-target="content"]`)
        const icon = this.element.querySelector(`[data-accordion-id="${accordionId}"][data-dashboard--accordion-course-target="icon"]`)

        if (content && icon && state) {
          content.classList.remove('hidden')
          icon.style.transform = 'rotate(180deg)'
        }
      }
    })
  }
}
