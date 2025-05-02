import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "display", "timeLimit", "timeSpent", "timeSpentInput", "submitButton"]

  connect() {
    this.startTime = new Date()
    this.elapsedTime = 0
    this.timeLimitInSeconds = parseInt(this.timeLimitTarget.value)
    this.remainingTime = this.timeLimitInSeconds

    this.timerInterval = setInterval(() => {
      this.updateTimer()
    }, 1000)
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  updateTimer() {
    this.elapsedTime = Math.floor((new Date() - this.startTime) / 1000)
    this.remainingTime = Math.max(0, this.timeLimitInSeconds - this.elapsedTime)

    const minutes = Math.floor(this.remainingTime / 60)
    const seconds = this.remainingTime % 60

    this.displayTarget.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    this.timeSpentInputTarget.value = this.elapsedTime

    if (this.remainingTime <= 0) {
      clearInterval(this.timerInterval)
      this.submitButtonTarget.click()
    }

    // Thêm màu cảnh báo khi thời gian còn ít
    if (this.remainingTime <= 60) {
      this.timerTarget.classList.add('bg-red-600')
      this.timerTarget.classList.remove('bg-purple-600')
    } else if (this.remainingTime <= 180) {
      this.timerTarget.classList.add('bg-yellow-600')
      this.timerTarget.classList.remove('bg-purple-600')
    }
  }

  submitForm() {
    this.timeSpentInputTarget.value = this.elapsedTime
    clearInterval(this.timerInterval)
  }
}
