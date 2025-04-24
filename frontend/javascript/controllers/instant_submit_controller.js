import { Controller } from "@hotwired/stimulus"

// Xử lý việc tự động gửi form khi có thay đổi các trường input
export default class extends Controller {
  static values = {
    debounceDelay: { type: Number, default: 500 }
  }

  // Gửi form ngay lập tức (sử dụng cho select boxes)
  submit() {
    this.element.requestSubmit();

    // Cập nhật URL để phản ánh trạng thái bộ lọc hiện tại
    const url = new URL(window.location);
    const formData = new FormData(this.element);

    for (const [key, value] of formData.entries()) {
      if (value) {
        url.searchParams.set(key, value);
      } else {
        url.searchParams.delete(key);
      }
    }

    history.pushState({}, "", url);
  }

  // Gửi form sau một khoảng thời gian (debouncing, sử dụng cho text search)
  debouncedSubmit() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.timeout = setTimeout(() => {
      this.submit();
    }, this.debounceDelayValue);
  }
}
