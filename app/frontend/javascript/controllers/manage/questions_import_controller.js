import { Controller } from "@hotwired/stimulus"
import { QuestionsApi } from "../../services/questions_api";

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

    const filters = {}

    if (searchInput && searchInput.value) {
      filters.search = searchInput.value
    }

    if (courseSelect && courseSelect.value) {
      filters.course_id = courseSelect.value
    }

    if (difficultySelect && difficultySelect.value) {
      filters.difficulty = difficultySelect.value
    }

    if (topicSelect && topicSelect.value) {
      filters.topic = topicSelect.value
    }

    if (learningGoalSelect && learningGoalSelect.value) {
      filters.learning_goal = learningGoalSelect.value
    }

    if (statusSelect && statusSelect.value) {
      filters.status = statusSelect.value
    }

    try {
      QuestionsApi.exportQuestions(filters)
      console.log('Đang tải xuống file Excel...')
    } catch (error) {
      console.error('Error exporting questions:', error)
      alert('Đã xảy ra lỗi khi xuất file Excel. Vui lòng thử lại.')
    }
  }
}
