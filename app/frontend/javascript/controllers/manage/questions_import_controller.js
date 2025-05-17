import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["importForm"]

  connect() {
    console.log('Questions import controller connected')
  }

  toggleImportForm() {
    this.importFormTarget.classList.toggle('hidden')
  }

  exportToExcel(event) {
    event.preventDefault()

    const searchInput = document.querySelector('[data-manage--questions-target="searchInput"]')
    const courseSelect = document.querySelector('[data-manage--questions-target="courseSelect"]')
    const difficultySelect = document.querySelector('[data-manage--questions-target="difficultySelect"]')
    const topicSelect = document.querySelector('[data-manage--questions-target="topicSelect"]')
    const learningGoalSelect = document.querySelector('[data-manage--questions-target="learningGoalSelect"]')
    const statusSelect = document.querySelector('[data-manage--questions-target="statusSelect"]')

    const url = new URL('/manage/questions_export.xlsx', window.location.origin)

    if (searchInput && searchInput.value) {
      url.searchParams.append('search', searchInput.value)
    }

    if (courseSelect && courseSelect.value) {
      url.searchParams.append('course_id', courseSelect.value)
    }

    if (difficultySelect && difficultySelect.value) {
      url.searchParams.append('difficulty', difficultySelect.value)
    }

    if (topicSelect && topicSelect.value) {
      url.searchParams.append('topic', topicSelect.value)
    }

    if (learningGoalSelect && learningGoalSelect.value) {
      url.searchParams.append('learning_goal', learningGoalSelect.value)
    }

    if (statusSelect && statusSelect.value) {
      url.searchParams.append('status', statusSelect.value)
    }

    window.location.href = url.toString()
  }
}
