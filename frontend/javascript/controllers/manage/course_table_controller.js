import { Controller } from "@hotwired/stimulus"

/**
 * Controller xử lý bảng khóa học và các thao tác hàng loạt
 */
export default class extends Controller {
  static targets = [
    "selectAll", 
    "checkbox", 
    "bulkActions", 
    "selectedCount",
    "bulkPublishForm", 
    "bulkDraftForm", 
    "bulkDeleteForm", 
    "bulkPublishContainer", 
    "bulkDraftContainer", 
    "bulkDeleteContainer"
  ]

  connect() {
    // Cập nhật trạng thái ban đầu khi kết nối controller
    this.updateSelectionStatus()
  }

  // Chọn/bỏ chọn tất cả các khóa học
  toggleAll() {
    const isChecked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => checkbox.checked = isChecked)
    this.updateSelectionStatus()
  }

  // Xử lý khi chọn/bỏ chọn một khóa học
  toggleOne() {
    this.updateSelectAllCheckbox()
    this.updateSelectionStatus()
  }

  // Cập nhật trạng thái checkbox "Chọn tất cả"
  updateSelectAllCheckbox() {
    if (!this.hasSelectAllTarget) return

    const totalCheckboxes = this.checkboxTargets.length
    const checkedCount = this.selectedCheckboxes().length
    
    this.selectAllTarget.checked = checkedCount === totalCheckboxes && totalCheckboxes > 0
    this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < totalCheckboxes
  }

  // Cập nhật hiển thị khu vực thao tác hàng loạt và số lượng đã chọn
  updateSelectionStatus() {
    if (!this.hasBulkActionsTarget || !this.hasSelectedCountTarget) return
    
    const selectedCount = this.selectedCheckboxes().length
    this.selectedCountTarget.textContent = selectedCount
    
    if (selectedCount > 0) {
      this.bulkActionsTarget.classList.remove('hidden')
    } else {
      this.bulkActionsTarget.classList.add('hidden')
    }
  }

  // Lấy danh sách các khóa học đã chọn
  selectedCheckboxes() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked)
  }

  // Lấy các ID của khóa học đã chọn
  getSelectedIds() {
    return this.selectedCheckboxes().map(checkbox => checkbox.value)
  }

  // Thao tác xuất bản hàng loạt
  bulkPublish() {
    this.processBulkAction(
      this.bulkPublishFormTarget, 
      this.bulkPublishContainerTarget, 
      "Are you sure you want to publish the selected courses?"
    )
  }

  // Thao tác chuyển thành bản nháp hàng loạt
  bulkDraft() {
    this.processBulkAction(
      this.bulkDraftFormTarget, 
      this.bulkDraftContainerTarget, 
      "Are you sure you want to change the selected courses to draft?"
    )
  }

  // Thao tác xóa hàng loạt
  bulkDelete() {
    this.processBulkAction(
      this.bulkDeleteFormTarget, 
      this.bulkDeleteContainerTarget, 
      "Are you sure you want to delete the selected courses? This action cannot be undone."
    )
  }

  // Xử lý thao tác hàng loạt chung
  processBulkAction(form, container, confirmMessage) {
    if (!confirm(confirmMessage)) return

    const selectedIds = this.getSelectedIds()
    if (selectedIds.length === 0) return

    // Xóa tất cả input hiện có
    container.innerHTML = ''
    
    // Tạo input hidden mới cho mỗi ID
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'course_ids[]'
      input.value = id
      container.appendChild(input)
    })
    
    // Gửi form
    form.submit()
  }
}
