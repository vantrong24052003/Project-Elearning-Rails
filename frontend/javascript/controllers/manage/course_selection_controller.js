import { Controller } from "@hotwired/stimulus"

// Controller xử lý việc chọn khóa học và hiển thị bulk actions
export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    // Kết nối với bulk actions controller
    this.bulkActionsButton = document.getElementById('bulkActions')
    this.selectedCountElement = document.getElementById('selectedCount')
    this.updateUI()
  }

  updateSelection() {
    this.updateUI()
  }

  updateUI() {
    if (!this.bulkActionsButton) return

    const selectedCount = this.selectedCheckboxes().length

    // Cập nhật số lượng đã chọn
    if (this.selectedCountElement) {
      this.selectedCountElement.textContent = selectedCount.toString()
    }

    // Hiển thị/ẩn nút bulk actions
    this.bulkActionsButton.classList.toggle('hidden', selectedCount === 0)
  }

  selectedCheckboxes() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked)
  }

  getSelectedIds() {
    return this.selectedCheckboxes().map(checkbox => checkbox.value)
  }
}
