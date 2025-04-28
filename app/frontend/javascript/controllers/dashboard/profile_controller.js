import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["passwordField", "nameError", "genderError", "currentPasswordError", "newPasswordError", "confirmPasswordError"]

  connect() {
    console.log("Profile controller connected")
    this.showPassword = false
  }

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword
    this.passwordFieldTargets.forEach(field => {
      field.type = this.showPassword ? "text" : "password"
    })
  }

  validatePasswordMatch() {
    const newPassword = document.getElementById("new-password").value
    const confirmPassword = document.getElementById("confirm-password").value

    if (newPassword !== confirmPassword) {
      this.confirmPasswordErrorTarget.textContent = "Mật khẩu không khớp"
      this.confirmPasswordErrorTarget.classList.remove("hidden")
      return false
    } else {
      this.confirmPasswordErrorTarget.classList.add("hidden")
      return true
    }
  }

  // Hỗ trợ xử lý ID trong profile URL
  handleProfileRedirect(event) {
    // Nếu URL profile không có ID, bạn có thể chuyển hướng hoặc thêm ID vào đây
    const profileId = this.data.get("userId") || "current"
    const profileUrl = `/dashboard/profiles/${profileId}`

    // Xử lý chỉ khi không có ID trong URL hiện tại
    if (!window.location.pathname.match(/\/profiles\/\d+$/)) {
      // Có thể sử dụng để redirect nếu cần
      // window.location.href = profileUrl
      console.log("Profile route should include ID:", profileUrl)
    }
  }
}
