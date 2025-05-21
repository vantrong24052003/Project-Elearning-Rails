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
  }

  validateTitle() {
    const title = this.titleTarget.value.trim()
    this.titleErrorTarget.textContent = ""
    this.titleErrorTarget.classList.add("hidden")

    if (!title) {
      this.titleErrorTarget.textContent = "Vui lòng nhập tiêu đề bài kiểm tra"
      this.titleErrorTarget.classList.remove("hidden")
      return false
    }
    return true
  }

  validateCourse() {
    const course = this.courseTarget.value
    this.courseErrorTarget.textContent = ""
    this.courseErrorTarget.classList.add("hidden")

    if (!course) {
      this.courseErrorTarget.textContent = "Vui lòng chọn khóa học"
      this.courseErrorTarget.classList.remove("hidden")
      return false
    }
    return true
  }

  validateTime() {
    const timeLimit = parseInt(this.timeLimitTarget.value)
    const startTime = this.startTimeTarget.value
    const endTime = this.endTimeTarget.value

    this.timeLimitErrorTarget.textContent = ""
    this.timeLimitErrorTarget.classList.add("hidden")
    this.startTimeErrorTarget.textContent = ""
    this.startTimeErrorTarget.classList.add("hidden")
    this.endTimeErrorTarget.textContent = ""
    this.endTimeErrorTarget.classList.add("hidden")

    let isValid = true

    // Validate time limit bắt buộc
    if (!timeLimit) {
      this.timeLimitErrorTarget.textContent = "Vui lòng nhập thời gian làm bài"
      this.timeLimitErrorTarget.classList.remove("hidden")
      isValid = false
    }

    // Validate khoảng thời gian
    if (startTime && endTime) {
      const start = new Date(startTime)
      const end = new Date(endTime)

      if (start >= end) {
        this.startTimeErrorTarget.textContent = "Thời gian bắt đầu phải trước thời gian kết thúc"
        this.startTimeErrorTarget.classList.remove("hidden")
        isValid = false
      }

      const totalMinutes = (end - start) / (1000 * 60)
      if (timeLimit > totalMinutes) {
        this.timeLimitErrorTarget.textContent = `Thời gian làm bài không được lớn hơn ${Math.floor(totalMinutes)} phút`
        this.timeLimitErrorTarget.classList.remove("hidden")
        isValid = false
      }
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
