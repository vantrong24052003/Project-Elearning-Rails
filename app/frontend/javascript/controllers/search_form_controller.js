import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  connect() {
    this.formTarget.addEventListener("input", this.debounce(this.submit.bind(this), 500))
  }
  
  submit() {
    this.formTarget.requestSubmit()
  }
  
  debounce(func, wait) {
    let timeout
    return function(...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }
}
