import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Prevent scrolling on the body
    document.body.classList.add("overflow-hidden")

    // Add event listener for ESC key
    document.addEventListener("keydown", this.handleKeydown)

    // Focus trap
    this.setupFocusTrap()

    // Click outside to close
    this.element.addEventListener("click", this.handleOutsideClick)
  }

  disconnect() {
    // Re-enable scrolling on the body
    document.body.classList.remove("overflow-hidden")

    // Remove event listeners
    document.removeEventListener("keydown", this.handleKeydown)
    this.element.removeEventListener("click", this.handleOutsideClick)
  }

  handleKeydown = (event) => {
    if (event.key === "Escape") {
      this.close()
    }
  }

  handleOutsideClick = (event) => {
    if (event.target === this.element) {
      this.close()
    }
  }

  close() {
    this.element.classList.add("animate-fade-out")

    setTimeout(() => {
      this.element.remove()
    }, 150)
  }

  setupFocusTrap() {
    setTimeout(() => {
      const focusableElements = this.element.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      if (focusableElements.length) {
        focusableElements[0].focus()
      }
    }, 100)
  }
}
