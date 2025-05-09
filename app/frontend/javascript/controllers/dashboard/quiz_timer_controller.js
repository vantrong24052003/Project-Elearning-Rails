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
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;

    document.addEventListener('turbo:before-render', this.checkClearStorage.bind(this));

    if (quizId) {
      const urlParams = new URLSearchParams(window.location.search);
      const forceRetake = urlParams.get('force') === 'true';

      if (!forceRetake) {
        const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';
        if (isSubmitted) {
          alert('Bài làm của bạn đã được nộp. Bạn không thể làm lại bằng cách quay lại trang.');
          window.location.href = window.location.pathname.replace(/\/quizzes\/[^\/]+/, '/quizzes');
          return;
        }
      } else {
        localStorage.removeItem(`quiz_${quizId}_submitted`);
      }

      if (this.modeValue === 'exam') {
        const lastSubmitTime = localStorage.getItem(`quiz_${quizId}_submit_time`);
        if (lastSubmitTime && (new Date().getTime() - parseInt(lastSubmitTime) < 3600000)) { // 1 giờ
          window.location.href = window.location.pathname.replace(/\/quizzes\/[^\/]+/, '/quizzes');
          return;
        }
      }
    }

    if (window.quizSubmitted) {
      this.isSubmitted = true;
      alert('Bài làm của bạn đã được nộp. Bạn không thể làm lại.');
      window.location.href = document.referrer || '/';
      return;
    }

    this.flaggedQuestions = new Set()
    this.isPaused = false
    this.storageKey = `quiz_${location.pathname.split('/').pop()}`

    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('force') === 'true') {
      sessionStorage.removeItem(this.storageKey);
    }

    const savedState = this.loadState()
    if (savedState) {
      this.currentQuestionValue = savedState.currentQuestion || 0
      this.elapsedTime = savedState.elapsedTime || 0

      if (savedState.flaggedQuestions) {
        this.flaggedQuestions = new Set(savedState.flaggedQuestions)
      }

      const timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10)
      this.remainingSeconds = Math.max(0, timeLimit * 60 - this.elapsedTime)
    } else {
      this.remainingSeconds = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60
      this.elapsedTime = 0
    }

    this.isSubmitted = false
    this.startTimer()
    this.loadSavedAnswers()
    this.updateAnsweredQuestions()
    this.setupFormListeners()
    this.showQuestion(this.currentQuestionValue)
    this.updateNavigation()
    this.updateDisplay()

    history.pushState(null, null, location.href)
    window.addEventListener('popstate', this.handleBackButton.bind(this))
  }

  disconnect() {
    this.clearTimers()
    window.removeEventListener('popstate', this.handleBackButton.bind(this))
    document.removeEventListener('turbo:before-render', this.checkClearStorage.bind(this));
    window.quizSubmitted = this.isSubmitted;
  }

  clearTimers() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  startTimer() {
    this.interval = setInterval(() => {
      if (!this.isPaused) {
        this.remainingSeconds -= 1
        this.elapsedTime += 1

        if (this.elapsedTime % 10 === 0) {
          this.saveState()
        }

        this.updateDisplay()

        if (this.remainingSeconds <= 0) {
          this.clearTimers()
          alert('Đã hết thời gian làm bài. Bài làm của bạn sẽ được nộp tự động.')
          this.autoSubmit()
        }
      }
    }, 1000)
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`

    this.timeSpentTarget.value = this.elapsedTime

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
        this.saveState()
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
        this.saveState()
        const message = 'Bạn có chắc muốn rời khỏi? Tiến trình làm bài sẽ được lưu lại.'
        e.returnValue = message
        return message
      }
    })
  }

  loadSavedAnswers() {
    const savedState = this.loadState()
    if (savedState && savedState.answers) {
      Object.entries(savedState.answers).forEach(([questionId, optionValue]) => {
        const radioInput = this.formTarget.querySelector(`input[name="answers[${questionId}]"][value="${optionValue}"]`)
        if (radioInput) {
          radioInput.checked = true
        }
      })
    }
  }

  updateAnsweredQuestions() {
    const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked')
    this.progressTarget.textContent = radioGroups.length
    this.updateNavigation()
  }

  submitForm() {
    if (this.isSubmitted) {
      alert('Bài làm của bạn đã được nộp.');
      return;
    }

    this.timeSpentTarget.value = this.elapsedTime

    const answeredQuestions = parseInt(this.progressTarget.textContent, 10)

    if (answeredQuestions < this.totalQuestionsValue) {
      if (this.modeValue === 'exam') {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
          this.isSubmitted = true
          localStorage.setItem(`${this.storageKey}_submitted`, 'true');
          localStorage.setItem(`${this.storageKey}_submit_time`, new Date().getTime().toString());
          this.clearState()
          window.quizSubmitted = true;
          this.formTarget.submit()
        }
      } else {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
          this.isSubmitted = true
          localStorage.setItem(`${this.storageKey}_submitted`, 'true');
          this.clearState()
          window.quizSubmitted = true;
          this.formTarget.submit()
        }
      }
    } else {
      this.isSubmitted = true
      localStorage.setItem(`${this.storageKey}_submitted`, 'true');
      if (this.modeValue === 'exam') {
        localStorage.setItem(`${this.storageKey}_submit_time`, new Date().getTime().toString());
      }
      this.clearState()
      window.quizSubmitted = true;
      this.formTarget.submit()
    }
  }

  autoSubmit() {
    if (this.isSubmitted) {
      return;
    }

    this.timeSpentTarget.value = this.elapsedTime
    this.isSubmitted = true
    localStorage.setItem(`${this.storageKey}_submitted`, 'true');
    if (this.modeValue === 'exam') {
      localStorage.setItem(`${this.storageKey}_submit_time`, new Date().getTime().toString());
    }
    this.clearState()
    window.quizSubmitted = true;
    this.formTarget.submit()
  }

  cancel(event) {
    if (!confirm('Bạn có chắc muốn hủy bài làm? Các câu trả lời sẽ không được lưu lại.')) {
      event.preventDefault()
    } else {
      this.clearState()
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

      this.saveState()
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
    this.saveState()
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

    this.saveState()
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

  saveState() {
    const answers = {}
    this.formTarget.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
      const questionId = radio.name.match(/\[(\w+)\]/)[1]
      answers[questionId] = radio.value
    })

    const state = {
      currentQuestion: this.currentQuestionValue,
      elapsedTime: this.elapsedTime,
      flaggedQuestions: Array.from(this.flaggedQuestions),
      answers: answers,
      isPaused: this.isPaused
    }

    sessionStorage.setItem(this.storageKey, JSON.stringify(state))
  }

  loadState() {
    const savedData = sessionStorage.getItem(this.storageKey)
    return savedData ? JSON.parse(savedData) : null
  }

  clearState() {
    sessionStorage.removeItem(this.storageKey)
  }

  handleBackButton(e) {
    history.pushState(null, null, location.href)

    if (!this.isSubmitted) {
      alert('Vui lòng hoàn thành hoặc hủy bài làm trước khi rời khỏi trang.')
    } else {
      window.location.href = window.location.pathname.replace(/\/quizzes\/[^\/]+/, '/quizzes');
    }
  }

  checkClearStorage(event) {
    const clearKey = event.detail.fetchResponse.header('X-Clear-Quiz-Storage');
    if (clearKey) {
      sessionStorage.removeItem(clearKey);

      localStorage.setItem(`${clearKey}_submitted`, 'true');

      const isExam = event.detail.fetchResponse.header('X-Quiz-Is-Exam');
      if (isExam === 'true') {
        localStorage.setItem(`${clearKey}_submit_time`, new Date().getTime().toString());
      }
    }
  }
}
