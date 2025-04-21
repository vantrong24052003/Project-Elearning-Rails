import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  initialize() {
    this.debounceTimer = null
  }

  connect() {
    console.log("Course filter controller connected")
  }

  submit(event) {
    // Debounce the form submission to prevent multiple rapid submissions
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      // Use Turbo to submit the form and update only the courses list frame
      const formData = new FormData(this.element)
      const url = new URL(this.element.action)

      // Append form data to URL
      for (let [key, value] of formData.entries()) {
        if (value) url.searchParams.append(key, value)
      }

      // Use Turbo.visit to update only the courses list frame
      Turbo.visit(url.toString(), {
        frame: this.element.dataset.turboFrame,
        action: 'replace'
      })
    }, 300)
  }
}
