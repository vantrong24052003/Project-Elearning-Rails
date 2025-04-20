import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Initialize controller
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    // Don't hide if clicking inside the dropdown
    if (this.element.contains(event.target)) return

    // Otherwise hide the dropdown
    this.menuTarget.classList.add("hidden")
  }
}
