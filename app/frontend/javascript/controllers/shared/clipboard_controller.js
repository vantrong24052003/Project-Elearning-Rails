import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy(event) {
    event.preventDefault()
    const text = this.sourceTarget.textContent
    navigator.clipboard.writeText(text)

    const originalHTML = this.buttonTarget.innerHTML
    this.buttonTarget.innerHTML = `
      <svg class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
    `

    setTimeout(() => {
      this.buttonTarget.innerHTML = originalHTML
    }, 2000)
  }
}
