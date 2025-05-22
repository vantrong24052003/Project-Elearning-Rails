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

    if (!title) {
      alert("Please enter a title for the quiz")
      return false
    }
    return true
  }

  validateCourse() {
    const course = this.courseTarget.value

    if (!course) {
      alert("Please select a course")
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
      alert("Please enter a valid time limit")
      isValid = false
      return isValid
    }

    if (!this.startTimeTarget.value || !this.endTimeTarget.value) {
      alert("Please select both start and end times")
      isValid = false
      return isValid
    }

    if (startTime < allowedPastTime) {
      alert("Start time cannot be in the past (allowed to be up to 5 minutes before current time)")
      isValid = false
      return isValid
    }

    if (startTime >= endTime) {
      alert("Start time must be before end time")
      isValid = false
      return isValid
    }

    const totalMinutes = Math.floor((endTime - startTime) / (1000 * 60))
    if (timeLimit > totalMinutes) {
      alert(`Time limit (${timeLimit} minutes) cannot be greater than the time period between start and end times (${totalMinutes} minutes)`)
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
