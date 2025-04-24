import { Controller } from "@hotwired/stimulus"

// Controller xử lý các thao tác trên bảng dữ liệu
export default class extends Controller {
  static targets = [
    "mainCheckbox",
    "checkbox",
    "bulkActionsPanel",
    "selectedCount"
  ]

  connect() {
    // Cập nhật trạng thái khi controller kết nối
    if (this.hasCheckboxTarget) {
      this.updateBulkActions()
    }
  }

  // Chọn/bỏ chọn tất cả các hàng
  toggleAll() {
    const isChecked = this.mainCheckboxTarget.checked
    this.checkboxTargets.forEach(checkbox => checkbox.checked = isChecked)
    this.updateBulkActions()
  }

  // Xử lý khi một checkbox được chọn/bỏ chọn
  toggleOne() {
    this.updateMainCheckbox()
    this.updateBulkActions()
  }

  // Cập nhật trạng thái checkbox chính
  updateMainCheckbox() {
    if (!this.hasMainCheckboxTarget) return

    const totalCheckboxes = this.checkboxTargets.length
    const checkedBoxes = this.getSelectedCheckboxes().length

    this.mainCheckboxTarget.checked = checkedBoxes === totalCheckboxes && totalCheckboxes > 0
    this.mainCheckboxTarget.indeterminate = checkedBoxes > 0 && checkedBoxes < totalCheckboxes
  }

  // Cập nhật hiển thị panel thao tác hàng loạt
  updateBulkActions() {
    if (!this.hasBulkActionsPanelTarget || !this.hasSelectedCountTarget) return

    const selectedCount = this.getSelectedCheckboxes().length
    this.selectedCountTarget.textContent = selectedCount

    if (selectedCount > 0) {
      this.bulkActionsPanelTarget.classList.remove('hidden')
    } else {
      this.bulkActionsPanelTarget.classList.add('hidden')
    }
  }

  // Lấy các checkbox đã được chọn
  getSelectedCheckboxes() {
    return this.checkboxTargets.filter(checkbox => checkbox.checked)
  }

  // Lấy ID của các mục đã chọn
  getSelectedIds() {
    return this.getSelectedCheckboxes().map(checkbox => checkbox.value)
  }

  // Thay đổi số lượng bản ghi mỗi trang
  changeLimit(event) {
    const url = new URL(window.location.href)
    url.searchParams.set('per_page', event.target.value)
    url.searchParams.set('page', 1) // Reset về trang đầu tiên khi thay đổi số lượng bản ghi
    Turbo.visit(url.toString())
  }

  // Xóa nhiều mục
  bulkDelete() {
    if (!confirm("Bạn có chắc chắn muốn xóa các mục đã chọn không?")) return
    this.submitBulkAction("bulk_delete")
  }

  // Xuất bản nhiều mục
  bulkPublish() {
    if (!confirm("Bạn có chắc chắn muốn xuất bản các mục đã chọn không?")) return
    this.submitBulkAction("bulk_publish")
  }

  // Chuyển về bản nháp nhiều mục
  bulkDraft() {
    if (!confirm("Bạn có chắc chắn muốn chuyển các mục đã chọn thành bản nháp không?")) return
    this.submitBulkAction("bulk_draft")
  }

  // Xử lý việc gửi form cho các thao tác hàng loạt
  submitBulkAction(action) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = `${window.location.pathname}/${action}`

    // Thêm CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken.content
      form.appendChild(csrfInput)
    }

    // Thêm ID của các mục đã chọn
    this.getSelectedIds().forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "course_ids[]"
      input.value = id
      form.appendChild(input)
    })

    // Thêm form vào DOM và gửi
    document.body.appendChild(form)
    form.submit()
  }

  // Mở modal chi tiết
  openModal(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute('href')

    fetch(url)
      .then(response => response.text())
      .then(html => {
        document.getElementById('modalContent').innerHTML = html
        document.getElementById('detailModal').classList.remove('hidden')
      })
  }

  // Đóng modal chi tiết
  closeModal() {
    document.getElementById('detailModal').classList.add('hidden')
  }
}
