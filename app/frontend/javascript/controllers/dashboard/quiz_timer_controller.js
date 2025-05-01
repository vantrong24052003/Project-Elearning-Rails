import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "display", "form", "timeSpent", "progress", "submitBtn", "cancelBtn",
    "pauseBtn", "resumeBtn", "questionContainer", "questionNav", "flagBtn",
    "questionNavItem", "questionCount", "currentQuestionDisplay"
  ]

  static values = {
    mode: String,
    totalQuestions: Number,
    currentQuestion: { type: Number, default: 0 }
  }

  connect() {
    this.flaggedQuestions = new Set()
    this.isPaused = false
    this.initializeTimer()
    this.updateAnsweredQuestions()
    this.setupFormListeners()
    this.showQuestion(0)
    this.updateNavigation()
  }

  disconnect() {
    this.clearTimers()
  }

  clearTimers() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  initializeTimer() {
    const timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10)
    this.remainingSeconds = timeLimit * 60
    this.startTime = new Date().getTime()
    this.elapsedTime = 0

    this.interval = setInterval(() => {
      if (!this.isPaused) {
        this.remainingSeconds -= 1
        this.elapsedTime += 1
        this.updateDisplay()
        if (this.remainingSeconds <= 0 && this.modeValue === 'exam') {
          this.clearTimers()
          this.submitForm()
        }
      }
    }, 1000)

    this.updateDisplay()
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
    if (this.remainingSeconds <= 60) {
      this.displayTarget.classList.add('text-red-500')
      this.displayTarget.classList.add('animate-pulse')
    }
  }

  setupFormListeners() {
    const radioButtons = this.formTarget.querySelectorAll('input[type="radio"]')
    radioButtons.forEach(radio => {
      radio.addEventListener('change', (e) => {
        this.updateAnsweredQuestions()
        const questionId = e.target.name.match(/\[(\w+)\]/)[1]
        const navItem = this.questionNavItemTargets.find(item => item.dataset.questionId === questionId)
        if (navItem) {
          navItem.classList.remove('bg-gray-500', 'bg-yellow-500')
          navItem.classList.add('bg-green-500')
        }
      })
    })

    window.addEventListener('beforeunload', (e) => {
      if (!this.isSubmitted) {
        const message = 'Bạn có chắc muốn rời khỏi? Tiến trình làm bài sẽ không được lưu lại.'
        e.returnValue = message
        return message
      }
    })
  }

  updateAnsweredQuestions() {
    const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked')
    this.progressTarget.textContent = radioGroups.length
    this.updateNavigation()
  }

  submitForm() {
    this.timeSpentTarget.value = this.elapsedTime

    const answeredQuestions = parseInt(this.progressTarget.textContent, 10)

    if (answeredQuestions < this.totalQuestionsValue) {
      if (this.modeValue === 'exam') {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
          this.isSubmitted = true
          this.formTarget.submit()
        }
      } else {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
          this.isSubmitted = true
          this.formTarget.submit()
        }
      }
    } else {
      this.isSubmitted = true
      this.formTarget.submit()
    }
  }

  cancel(event) {
    if (!confirm('Bạn có chắc muốn hủy bài làm? Các câu trả lời sẽ không được lưu lại.')) {
      event.preventDefault()
    }
  }

  togglePause() {
    if (this.modeValue !== 'exam') {
      this.isPaused = !this.isPaused

      if (this.isPaused) {
        this.pauseBtnTarget.classList.add('hidden')
        this.resumeBtnTarget.classList.remove('hidden')
        this.displayTarget.classList.add('text-yellow-500')
      } else {
        this.pauseBtnTarget.classList.remove('hidden')
        this.resumeBtnTarget.classList.add('hidden')
        this.displayTarget.classList.remove('text-yellow-500')
      }
    }
  }

  flagCurrentQuestion() {
    const currentQuestion = this.getCurrentQuestion()
    const questionId = currentQuestion.dataset.questionId

    if (this.flaggedQuestions.has(questionId)) {
      this.flaggedQuestions.delete(questionId)
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white')
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700')
    } else {
      this.flaggedQuestions.add(questionId)
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700')
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white')
    }

    this.updateNavigation()
  }

  getCurrentQuestion() {
    return this.questionContainerTargets[this.currentQuestionValue]
  }

  showQuestion(index) {
    this.questionContainerTargets.forEach(container => {
      container.classList.add('hidden')
    })

    this.currentQuestionValue = index
    const currentQuestion = this.getCurrentQuestion()
    currentQuestion.classList.remove('hidden')

    this.currentQuestionDisplayTarget.textContent = (index + 1)

    const questionId = currentQuestion.dataset.questionId
    if (this.flaggedQuestions.has(questionId)) {
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700')
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white')
    } else {
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white')
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700')
    }
  }

  nextQuestion() {
    if (this.currentQuestionValue < this.questionContainerTargets.length - 1) {
      this.showQuestion(this.currentQuestionValue + 1)
    }
  }

  prevQuestion() {
    if (this.currentQuestionValue > 0) {
      this.showQuestion(this.currentQuestionValue - 1)
    }
  }

  goToQuestion(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.showQuestion(index)
  }

  updateNavigation() {
    this.questionNavItemTargets.forEach((item, index) => {
      const questionId = item.dataset.questionId

      const isAnswered = !!this.formTarget.querySelector(`input[name="answers[${questionId}]"]:checked`)

      const isFlagged = this.flaggedQuestions.has(questionId)

      item.classList.remove('bg-gray-500', 'bg-green-500', 'bg-yellow-500')

      if (isFlagged) {
        item.classList.add('bg-yellow-500')
      } else if (isAnswered) {
        item.classList.add('bg-green-500')
      } else {
        item.classList.add('bg-gray-500')
      }

      if (index === this.currentQuestionValue) {
        item.classList.add('ring-2', 'ring-white')
      } else {
        item.classList.remove('ring-2', 'ring-white')
      }
    })
  }
}
