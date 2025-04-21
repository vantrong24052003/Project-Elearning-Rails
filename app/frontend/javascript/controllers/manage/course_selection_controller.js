import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]
  
  connect() {
    this.updateSelectedCount()
  }
  
  toggle() {
    this.updateSelectedCount()
  }
  
  toggleAll(event) {
    const checked = event.currentTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateSelectedCount()
  }
  
  updateSelectedCount() {
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length
    
    const event = new CustomEvent('course-selection:change', {
      detail: { count: selectedCount }
    })
    document.dispatchEvent(event)
  }
}
