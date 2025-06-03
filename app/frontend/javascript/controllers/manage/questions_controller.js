import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchForm",
    "searchInput",
    "courseSelect",
    "difficultySelect",
    "topicSelect",
    "learningGoalSelect",
    "statusSelect",
    "createQuizBtn",
    "selectedQuestionsInput",
    "perPageSelect"
  ]

  connect() {
    console.log('Questions controller connected')
    this.selectedQuestions = []
  }

  search() {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.submitForm()
    }, 500)
  }

  clearSearch(event) {
    this.searchInputTarget.value = ''
    this.submitForm()
  }

  filterByCourse() {
    this.submitForm()
  }

  filterByDifficulty() {
    this.submitForm()
  }

  filterByTopic() {
    this.submitForm()
  }

  filterByLearningGoal() {
    this.submitForm()
  }

  filterByStatus() {
    this.submitForm()
  }

  changePerPage() {
    this.submitForm()
  }

  resetAllFilters() {
    this.searchInputTarget.value = ''
    this.courseSelectTarget.value = ''
    this.difficultySelectTarget.value = ''
    this.topicSelectTarget.value = ''
    this.learningGoalSelectTarget.value = ''
    this.statusSelectTarget.value = ''
    if (this.hasPerPageSelectTarget) this.perPageSelectTarget.value = '10'
    this.submitForm()
  }

  submitForm() {
    this.searchFormTarget.requestSubmit()
  }

  toggleQuestionSelection(event) {
    const checkbox = event.currentTarget
    const questionId = checkbox.dataset.questionId

    if (checkbox.checked) {
      if (!this.selectedQuestions.includes(questionId)) {
        this.selectedQuestions.push(questionId)
      }
    } else {
      this.selectedQuestions = this.selectedQuestions.filter(id => id !== questionId)
    }

    if (this.hasSelectedQuestionsInputTarget) {
      this.selectedQuestionsInputTarget.value = JSON.stringify(this.selectedQuestions)
    }

  }

  createQuiz(event) {
    event.preventDefault()

    if (this.selectedQuestions.length === 0) {
      alert('Vui lòng chọn ít nhất một câu hỏi để tạo bài kiểm tra')
      return
    }

    sessionStorage.setItem('selected_questions_data', JSON.stringify(this.selectedQuestions))
    window.location.href = '/manage/quizzes/new'
  }
}
