import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["importForm", "normalForm", "importButtonText"]

  connect() {
    console.log('Questions import controller connected')
  }

  toggleForms() {
    this.importFormTarget.classList.toggle('hidden')
    this.normalFormTarget.classList.toggle('hidden')

    if (this.importFormTarget.classList.contains('hidden')) {
      this.importButtonTextTarget.textContent = "Import từ Excel"
    } else {
      this.importButtonTextTarget.textContent = "Tạo câu hỏi thủ công"
    }
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
