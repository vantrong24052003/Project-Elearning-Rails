import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "select"]

  connect() {
    console.log("Overview controller connected")
  }

  filter() {
    this.updateURL()
    this.submitForm()
  }

  updateURL() {
    if (!this.hasFormTarget) return

    const formData = new FormData(this.formTarget)
    const url = new URL(window.location.href)
    const params = url.searchParams

    Array.from(params.keys()).forEach(key => {
      if (key !== 'authenticity_token') {
        params.delete(key)
      }
    })

    for (const [key, value] of formData.entries()) {
      if (key !== 'authenticity_token') {
        params.set(key, value)
      }
    }

    window.history.pushState({}, '', url.toString())
  }

  submitForm() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }
}
