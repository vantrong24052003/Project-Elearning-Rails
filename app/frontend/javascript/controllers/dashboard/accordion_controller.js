import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content", "icon"]

  toggle(event) {
    // Ngăn chặn event bubbling
    event.preventDefault()

    // Toggle content
    this.contentTarget.classList.toggle("hidden")

    // Rotate icon
    this.iconTarget.classList.toggle("rotate-180")
  }
}
