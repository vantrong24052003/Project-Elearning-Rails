import { Controller } from "@hotwired/stimulus"

// Controller xử lý các hành động hàng loạt trên khóa học
export default class extends Controller {
  static targets = ["publishForm", "draftForm", "deleteForm", "counter"]
  
  publish() {
    if (confirm("Are you sure you want to publish all selected courses?")) {
      this.processAction('publishForm', 'course_ids_publish_container')
    }
  }
  
  draft() {
    if (confirm("Are you sure you want to change all selected courses to draft?")) {
      this.processAction('draftForm', 'course_ids_draft_container')
    }
  }
  
  delete() {
    if (confirm("Are you sure you want to delete all selected courses? This action cannot be undone.")) {
      this.processAction('deleteForm', 'course_ids_delete_container')
    }
  }
  
  processAction(formTarget, containerId) {
    const selectedIds = this.getSelectedIds()
    if (!selectedIds.length) return
    
    // Tạo các input hidden và thêm vào form
    const container = document.getElementById(containerId)
    container.innerHTML = ''
    
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'course_ids[]'
      input.value = id
      container.appendChild(input)
    })
    
    // Submit form
    this[`${formTarget}Target`].submit()
  }
  
  getSelectedIds() {
    return Array.from(document.querySelectorAll('input.course-checkbox:checked')).map(cb => cb.value)
  }
}
