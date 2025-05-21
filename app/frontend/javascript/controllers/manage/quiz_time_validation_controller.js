import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "title", "titleError",
    "course", "courseError",
    "timeLimit", "timeLimitError",
    "startTime", "startTimeError",
    "endTime", "endTimeError"
  ]

  connect() {
    const now = new Date()

    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const hours = String(now.getHours()).padStart(2, '0')
    const minutes = String(now.getMinutes()).padStart(2, '0')

    // Định dạng chuỗi datetime-local cho các trường input
    const nowString = `${year}-${month}-${day}T${hours}:${minutes}`

    if (this.hasStartTimeTarget) {
      this.startTimeTarget.min = nowString
      this.startTimeTarget.addEventListener('change', this.updateEndTimeMin.bind(this))
    }

    if (this.hasEndTimeTarget) {
      this.endTimeTarget.min = nowString
    }
  }

  updateEndTimeMin() {
    if (this.startTimeTarget.value && this.hasEndTimeTarget) {
      this.endTimeTarget.min = this.startTimeTarget.value
    }
  }

  validateTitle() {
    const title = this.titleTarget.value.trim()
    this.titleErrorTarget.textContent = ""
    this.titleErrorTarget.classList.add("hidden")

    if (!title) {
      alert("Vui lòng nhập tiêu đề bài kiểm tra")
      return false
    }
    return true
  }

  validateCourse() {
    const course = this.courseTarget.value
    this.courseErrorTarget.textContent = ""
    this.courseErrorTarget.classList.add("hidden")

    if (!course) {
      alert("Vui lòng chọn khóa học")
      return false
    }
    return true
  }

  validateTime() {
    const timeLimit = parseInt(this.timeLimitTarget.value)
    const startTime = new Date(this.startTimeTarget.value)
    const endTime = new Date(this.endTimeTarget.value)
    const now = new Date()

    const allowedPastTime = new Date(now)
    allowedPastTime.setMinutes(allowedPastTime.getMinutes() - 5)

    let isValid = true

    if (!timeLimit || isNaN(timeLimit) || timeLimit <= 0) {
      alert("Vui lòng nhập thời gian làm bài hợp lệ")
      isValid = false
      return isValid
    }

    if (!this.startTimeTarget.value || !this.endTimeTarget.value) {
      alert("Vui lòng chọn đủ thời gian bắt đầu và kết thúc")
      isValid = false
      return isValid
    }

    if (startTime < allowedPastTime) {
      alert("Thời gian bắt đầu không thể ở quá khứ (cho phép sớm hơn hiện tại tối đa 5 phút)")
      isValid = false
      return isValid
    }

    if (startTime >= endTime) {
      alert("Thời gian bắt đầu phải trước thời gian kết thúc")
      isValid = false
      return isValid
    }

    const totalMinutes = Math.floor((endTime - startTime) / (1000 * 60))
    if (timeLimit > totalMinutes) {
      alert(`Thời gian làm bài (${timeLimit} phút) không được lớn hơn khoảng thời gian giữa bắt đầu và kết thúc (${totalMinutes} phút)`)
      isValid = false
      return isValid
    }

    return isValid
  }

  validateBeforeSubmit(event) {
    const isTitleValid = this.validateTitle()
    const isCourseValid = this.validateCourse()
    const isTimeValid = this.validateTime()

    if (!isTitleValid || !isCourseValid || !isTimeValid) {
      event.preventDefault()
      event.stopPropagation()
    }
  }
}
