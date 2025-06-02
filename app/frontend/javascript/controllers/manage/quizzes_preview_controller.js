import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "container", "count", "list", "data", "courseSelect"
  ]

  connect() {
    this.loadQuestionsFromSessionStorage()
  }

  loadQuestionsFromSessionStorage() {
    const previewQuestionsData = sessionStorage.getItem('preview_questions_data');
    const selectedQuestionsData = sessionStorage.getItem('selected_questions_data');

    if (previewQuestionsData) {
      this.loadPreviewQuestions(previewQuestionsData);
      sessionStorage.removeItem('preview_questions_data');
    } else if (selectedQuestionsData) {
      this.loadSelectedQuestions(selectedQuestionsData);
      sessionStorage.removeItem('selected_questions_data');
    }
  }

  loadPreviewQuestions(previewQuestionsData) {
    try {
      const previewQuestions = JSON.parse(previewQuestionsData);

      if (previewQuestions.length > 0) {
        this.containerTarget.classList.remove('hidden');
        this.countTarget.textContent = previewQuestions.length;
        this.dataTarget.value = previewQuestionsData;
        this.renderQuestions(previewQuestions);

        if (previewQuestions[0]?.course_id) {
          this.setCourseValue(previewQuestions[0].course_id);
        }
      }
    } catch (error) {
      console.error('Error parsing preview questions:', error);
    }
  }

  loadSelectedQuestions(selectedQuestionsData) {
    try {
      const questionIds = JSON.parse(selectedQuestionsData);

      if (questionIds.length > 0) {
        this.fetchQuestionDetails(questionIds);
      }
    } catch (error) {
      console.error('Error parsing selected questions:', error);
    }
  }

  fetchQuestionDetails(questionIds) {
    fetch(`/manage/questions?ids=${questionIds.join(',')}&format=json`)
      .then(response => response.json())
      .then(data => {
        if (data.questions && data.questions.length > 0) {
          this.containerTarget.classList.remove('hidden');
          this.countTarget.textContent = data.questions.length;
          this.dataTarget.value = JSON.stringify(data.questions);
          this.renderQuestions(data.questions);

          if (data.questions[0]?.course_id) {
            this.setCourseValue(data.questions[0].course_id);
          }
        }
      })
      .catch(error => {
        console.error('Error fetching question details:', error);
      });
  }

  renderQuestions(questions) {
    this.listTarget.innerHTML = ''

    questions.forEach((question, index) => {
      const difficultyClass = this.getDifficultyClass(question.difficulty)

      const questionElement = document.createElement('div')
      questionElement.className = 'border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-gray-50 dark:bg-gray-800'
      questionElement.innerHTML = `
        <div class="flex justify-between items-start mb-2">
          <span class="text-sm font-medium text-gray-900 dark:text-white">Câu hỏi ${index + 1}</span>
          <div class="flex gap-1">
            <span class="badge ${difficultyClass}">${question.difficulty}</span>
            <span class="badge badge-primary">${question.topic}</span>
          </div>
        </div>
        <p class="text-gray-800 dark:text-gray-200 text-sm mb-2">${question.content}</p>
        <div class="text-xs text-gray-500 dark:text-gray-400">
          <p>Đáp án đúng: ${question.options[question.correct_option]}</p>
        </div>
      `

      this.listTarget.appendChild(questionElement)
    })
  }

  getDifficultyClass(difficulty) {
    return difficulty === 'easy' ? 'badge-success' :
           (difficulty === 'medium' ? 'badge-warning' : 'badge-error')
  }

  setCourseValue(courseId) {
    if (this.hasCourseSelectTarget && this.courseSelectTarget) {
      this.courseSelectTarget.value = courseId
    }
  }

  submitForm() {
    // Không cần xóa URL params nữa
  }
}
