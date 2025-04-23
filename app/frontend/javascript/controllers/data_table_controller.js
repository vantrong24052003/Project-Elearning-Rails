import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "mainCheckbox", "bulkActionsPanel", "selectedCount", "tableRow"]

  connect() {
    // Khởi tạo trạng thái ban đầu
    this.updateBulkActionsVisibility()
  }

  toggleAll(event) {
    const isChecked = event.target.checked

    // Chọn/bỏ chọn tất cả
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })

    // Cập nhật UI
    this.updateBulkActionsVisibility()
  }

  toggleOne(event) {
    event.stopPropagation() // Ngăn chặn sự kiện click lan ra ngoài

    // Đếm số checkbox được chọn
    const checkedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length
    const totalCheckboxes = this.checkboxTargets.length

    // Cập nhật trạng thái checkbox chính
    if (this.hasMainCheckboxTarget) {
      this.mainCheckboxTarget.checked = checkedCount === totalCheckboxes
      this.mainCheckboxTarget.indeterminate = checkedCount > 0 && checkedCount < totalCheckboxes
    }

    // Cập nhật UI
    this.updateBulkActionsVisibility()
  }

  updateBulkActionsVisibility() {
    const checkedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length

    // Cập nhật số lượng mục đã chọn
    this.selectedCountTargets.forEach(el => {
      el.textContent = checkedCount
    })

    // Hiển thị/ẩn panel hành động hàng loạt
    if (checkedCount > 0) {
      this.bulkActionsPanelTarget.classList.remove("hidden")
    } else {
      this.bulkActionsPanelTarget.classList.add("hidden")
    }
  }

  showDetails(event) {
    // Không hiển thị chi tiết nếu click vào checkbox hoặc nút action
    if (event.target.type === "checkbox" ||
        event.target.closest('[type="checkbox"]') ||
        event.target.closest('.action-btn') ||
        event.target.closest('.row-actions')) {
      return
    }

    const row = event.currentTarget
    const data = JSON.parse(row.dataset.item || "{}")

    // Hiển thị modal với dữ liệu
    this.showModal(data)
  }

  showModal(data) {
    const modal = document.getElementById("detailModal")
    const modalTitle = document.getElementById("modalTitle")
    const modalContent = document.getElementById("modalContent")

    // Cập nhật nội dung modal
    modalTitle.textContent = data.title || "Chi tiết"

    let contentHTML = ""

    // Thêm hình ảnh nếu có
    if (data.thumbnail_path) {
      contentHTML += `<div class="mb-4"><img src="${data.thumbnail_path}" alt="${data.title}" class="w-full h-48 object-cover rounded-lg"></div>`
    }

    // Thông tin chi tiết
    contentHTML += `
      <div>
        <h4 class="text-lg font-medium text-white">${data.title}</h4>
        <p class="text-gray-300 my-2">${data.description || 'Không có mô tả'}</p>
        
        <div class="grid grid-cols-2 gap-4 mt-4">
          <div>
            <p class="text-sm text-gray-400">Giá</p>
            <p class="text-white">${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(data.price || 0)}</p>
          </div>
          <div>
            <p class="text-sm text-gray-400">Trạng thái</p>
            <p class="text-white">${data.status === 'published' ? 'Đã xuất bản' : 'Bản nháp'}</p>
          </div>
          <div>
            <p class="text-sm text-gray-400">Ngôn ngữ</p>
            <p class="text-white">${data.language === 'vi' ? 'Tiếng Việt' : 'Tiếng Anh'}</p>
          </div>
          <div>
            <p class="text-sm text-gray-400">Giảng viên</p>
            <p class="text-white">${data.instructor_name || 'Không có thông tin'}</p>
          </div>
        </div>
        
        <div class="flex justify-end mt-4 space-x-2">
          <a href="/manage/courses/${data.id}/edit" class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm" data-turbo-frame="modal">Chỉnh sửa</a>
          <a href="/manage/courses/${data.id}" class="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white rounded text-sm">Xem chi tiết</a>
        </div>
      </div>
    `

    modalContent.innerHTML = contentHTML
    modal.classList.remove("hidden")
  }

  closeModal() {
    document.getElementById("detailModal").classList.add("hidden")
  }

  bulkDelete() {
    const selectedIds = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)

    if (selectedIds.length === 0) return

    if (confirm(`Bạn có chắc chắn muốn xóa ${selectedIds.length} mục đã chọn không?`)) {
      const token = document.querySelector('meta[name="csrf-token"]').content

      fetch('/manage/courses/bulk_delete', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        },
        body: JSON.stringify({ course_ids: selectedIds })
      })
      .then(response => {
        if (response.ok) {
          window.location.reload()
        } else {
          alert('Đã xảy ra lỗi khi xóa.')
        }
      })
    }
  }

  bulkPublish() {
    this.processAction('/manage/courses/bulk_publish', 'xuất bản')
  }

  bulkDraft() {
    this.processAction('/manage/courses/bulk_draft', 'chuyển thành bản nháp')
  }

  processAction(url, actionText) {
    const selectedIds = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)

    if (selectedIds.length === 0) return

    if (confirm(`Bạn có chắc chắn muốn ${actionText} ${selectedIds.length} mục đã chọn không?`)) {
      const token = document.querySelector('meta[name="csrf-token"]').content

      fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        },
        body: JSON.stringify({ course_ids: selectedIds })
      })
      .then(response => {
        if (response.ok) {
          window.location.reload()
        } else {
          alert(`Đã xảy ra lỗi khi ${actionText}.`)
        }
      })
    }
  }

  deleteSingle(event) {
    event.preventDefault()
    event.stopPropagation()

    const id = event.currentTarget.dataset.id
    if (!id) return

    if (confirm("Bạn có chắc chắn muốn xóa mục này không?")) {
      const token = document.querySelector('meta[name="csrf-token"]').content

      fetch(`/manage/courses/${id}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': token
        }
      })
      .then(response => {
        if (response.ok) {
          window.location.reload()
        } else {
          alert('Đã xảy ra lỗi khi xóa.')
        }
      })
    }
  }

  publishSingle(event) {
    event.preventDefault()
    event.stopPropagation()

    const id = event.currentTarget.dataset.id
    if (!id) return

    this.processSingleAction(id, '/manage/courses/publish', 'xuất bản')
  }

  draftSingle(event) {
    event.preventDefault()
    event.stopPropagation()

    const id = event.currentTarget.dataset.id
    if (!id) return

    this.processSingleAction(id, '/manage/courses/draft', 'chuyển thành bản nháp')
  }

  processSingleAction(id, urlPath, actionText) {
    if (confirm(`Bạn có chắc chắn muốn ${actionText} mục này không?`)) {
      const token = document.querySelector('meta[name="csrf-token"]').content

      fetch(`${urlPath}/${id}`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': token
        }
      })
      .then(response => {
        if (response.ok) {
          window.location.reload()
        } else {
          alert(`Đã xảy ra lỗi khi ${actionText}.`)
        }
      })
    }
  }

  changeLimit(event) {
    const limit = event.currentTarget.value
    const url = new URL(window.location)
    url.searchParams.set('per_page', limit)
    url.searchParams.set('page', 1)
    Turbo.visit(url)
  }
}
