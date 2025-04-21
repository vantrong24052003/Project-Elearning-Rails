import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Bulk action controller connected")
  }

  publish(event) {
    event.preventDefault()
    const url = this.element.dataset.url || this.element.getAttribute("href")
    this._submitBulkAction(url, 'post')
  }

  draft(event) {
    event.preventDefault()
    const url = this.element.dataset.url || this.element.getAttribute("href")
    this._submitBulkAction(url, 'post')
  }

  delete(event) {
    event.preventDefault()
    const url = this.element.dataset.url || this.element.getAttribute("href")
    const confirmMsg = this.element.dataset.confirm || "Bạn có chắc chắn muốn xóa các khóa học đã chọn không?"
    
    if (confirm(confirmMsg)) {
      this._submitBulkAction(url, 'delete')
    }
  }

  _submitBulkAction(url, method) {
    // Find the course selection controller
    const courseSelectionController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="dashboard--course-selection"]'),
      'dashboard--course-selection'
    )

    if (!courseSelectionController) {
      console.error('Could not find course selection controller')
      return
    }

    // Get selected course IDs
    const selectedIds = courseSelectionController.getSelectedIds()
    if (selectedIds.length === 0) {
      alert('Vui lòng chọn ít nhất một khóa học')
      return
    }

    // Create and submit a form with Turbo
    const form = document.createElement('form')
    form.method = 'post'
    form.action = url
    form.style.display = 'none'
    form.dataset.turbo = true

    // Add method override for DELETE
    if (method === 'delete') {
      const methodInput = document.createElement('input')
      methodInput.type = 'hidden'
      methodInput.name = '_method'
      methodInput.value = 'delete'
      form.appendChild(methodInput)
    }

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add course IDs
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'course_ids[]'
      input.value = id
      form.appendChild(input)
    })

    // Submit the form
    document.body.appendChild(form)
    form.requestSubmit()
  }
}
