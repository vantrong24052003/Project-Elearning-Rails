import { Controller } from "@hotwired/stimulus"

// Stimulus controller để xử lý việc gửi form tức thì khi thay đổi các trường
export default class extends Controller {
  // Định nghĩa các targets để tương tác với các phần tử DOM
  static targets = ["form"]
  
  // Định nghĩa các giá trị có thể cấu hình
  static values = {
    debounceDelay: { type: Number, default: 500 }
  }

  // Kết nối controller với DOM
  connect() {
    // Log để debug
    console.log("InstantSubmit controller connected")
    
    // Lấy form từ phần tử gốc nếu không có form target
    if (!this.hasFormTarget) {
      this.formTarget = this.element.tagName === "FORM" 
        ? this.element 
        : this.element.querySelector("form")
    }
  }

  // Gửi form sau khi debounce (cho ô tìm kiếm)
  debouncedSubmit() {
    // Hủy timeout hiện tại nếu có
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Thiết lập timeout mới
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.debounceDelayValue)
  }

  // Gửi form ngay lập tức (cho select boxes)
  submitForm() {
    // Log để debug
    console.log("Submitting form...")
    
    // Gửi form với Turbo
    if (this.formTarget) {
      // Lấy turbo_frame từ data attribute của form
      const turboFrame = this.formTarget.dataset.turboFrame
      console.log("Target turbo frame:", turboFrame)
      
      // Submit form
      this.formTarget.requestSubmit()
    }
  }

  // Reset tất cả các trường trong form
  reset(event) {
    event.preventDefault()
    
    // Log để debug
    console.log("Resetting form...")
    
    // Reset tất cả input fields
    const inputs = this.formTarget.querySelectorAll('input:not([type="hidden"]), select')
    inputs.forEach(input => {
      if (input.tagName === "SELECT") {
        input.selectedIndex = 0
      } else {
        input.value = ""
      }
    })
    
    // Submit form sau khi reset
    this.submitForm()
  }
}
