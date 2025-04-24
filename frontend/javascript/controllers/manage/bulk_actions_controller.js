import { Controller } from "@hotwired/stimulus"

// Controller xử lý các hành động hàng loạt
export default class extends Controller {
  static targets = ["button", "dropdown", "counter", "publishForm", "draftForm", "deleteForm"]
  
  toggleDropdown() {
    this.dropdownTarget.classList.toggle('hidden')
  }
  
  hideDropdown(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add('hidden')
    }
  }
  
  publish() {
    if (confirm("Are you sure you want to publish selected courses?")) {
      this.submitAction("publishForm")
    }
  }
  
  draft() {
    if (confirm("Are you sure you want to save selected courses as drafts?")) {
      this.submitAction("draftForm")
    }
  }
  
  delete() {
    if (confirm("Are you sure you want to delete selected courses? This action cannot be undone.")) {
      this.submitAction("deleteForm")
    }
  }
  
  submitAction(formTargetName) {
    const selectedIds = this.getSelectedIds()
    if (selectedIds.length === 0) return
    
    // Xóa các input cũ
    const container = this[`${formTargetName}Target`].querySelector('#bulk_course_ids_container')
    container.innerHTML = ''
    
    // Thêm các input mới cho mỗi id
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'course_ids[]'
      input.value = id
      container.appendChild(input)
    })
    
    // Submit form
    this[`${formTargetName}Target`].submit()
  }
  
  getSelectedIds() {
    return Array.from(document.querySelectorAll('.course-checkbox:checked')).map(cb => cb.value)
  }
}
