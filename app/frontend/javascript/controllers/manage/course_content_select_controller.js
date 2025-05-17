import { Controller } from '@hotwired/stimulus'
import { CourseContentApi } from '../../services/course_content_api'
import { QuizApi } from '../../services/quiz_api'

export default class extends Controller {
  static targets = [
    "form", "courseSelect", "loading", "questionsContainer", "questionTemplate", "questionsData",
    "controls", "analysis", "analysisLoading", "conceptCount", "coverageBar",
    "coverageText", "suggestions", "videoSelect", "chapterSelect", "lessonSelect", "videoPreview", "videoTitle", "videoDetailLink"
  ]

  connect() {
    console.log("CourseContentSelect controller connected")
    this.questions = []
    this.isGenerating = false
  }

  loadChapters() {
    let courseId = this.courseSelectTarget.value
    if (!courseId) {
      const formElement = document.querySelector('form[data-manage--course-content-select-target="form"]')
      if (formElement) {
        const courseSelect = formElement.querySelector('select[name="quiz[course_id]"]')
        if (courseSelect) {
          courseId = courseSelect.value
        }
      }
    }

    if (!courseId) {
      this.resetSelect(this.chapterSelectTarget)
      this.resetSelect(this.lessonSelectTarget)
      this.resetSelect(this.videoSelectTarget)
      this.hideVideoPreview()
      return
    }

    this.resetSelect(this.chapterSelectTarget, 'Đang tải...')
    this.resetSelect(this.lessonSelectTarget)
    this.resetSelect(this.videoSelectTarget)
    this.hideVideoPreview()

    CourseContentApi.getCourseChapters(courseId)
      .then(chapters => {
        this.populateSelect(this.chapterSelectTarget, chapters, 'Chọn chương')
      })
  }

  loadLessons() {
    const chapterId = this.chapterSelectTarget.value
    if (!chapterId) {
      this.resetSelect(this.lessonSelectTarget)
      this.resetSelect(this.videoSelectTarget)
      this.hideVideoPreview()
      return
    }

    this.resetSelect(this.lessonSelectTarget, 'Đang tải...')
    this.resetSelect(this.videoSelectTarget)
    this.hideVideoPreview()

    CourseContentApi.getChapterLessons(chapterId)
      .then(lessons => {
        this.populateSelect(this.lessonSelectTarget, lessons, 'Chọn bài học')
      })
  }

  loadVideos() {
    const lessonId = this.lessonSelectTarget.value
    if (!lessonId) {
      this.resetSelect(this.videoSelectTarget)
      this.hideVideoPreview()
      return
    }

    this.resetSelect(this.videoSelectTarget, 'Đang tải...')
    this.hideVideoPreview()

    CourseContentApi.getLessonVideos(lessonId)
      .then(videos => {
        this.populateSelect(this.videoSelectTarget, videos, 'Chọn video')
      })
  }

  showVideoPreview() {
    const videoId = this.videoSelectTarget.value
    if (!videoId) {
      this.hideVideoPreview()
      return
    }

    CourseContentApi.getVideoDetails(videoId)
      .then(video => {
        this.videoPreviewTarget.classList.remove('hidden')

        if (this.hasVideoDetailLinkTarget) {
          this.videoDetailLinkTarget.href = `/manage/videos/${videoId}`
          this.videoDetailLinkTarget.addEventListener('click', (e) => {
            if (!videoId) {
              e.preventDefault()
              this.showToast('Không thể xem chi tiết video này', 'error')
            }
          })
        }
      })
      .catch(error => {
        console.error('Error loading video details:', error)
        this.hideVideoPreview()
      })
  }

  resetSelect(selectElement, placeholderText = null) {
    if (!selectElement) return

    selectElement.innerHTML = ''
    const placeholder = document.createElement('option')
    placeholder.value = ''
    placeholder.textContent = "Chọn giá trị"
    placeholder.selected = true
    placeholder.disabled = true
    selectElement.appendChild(placeholder)
  }

  populateSelect(selectElement, items, placeholderText) {
    if (!selectElement) return

    this.resetSelect(selectElement, placeholderText)

    items.forEach(item => {
      const option = document.createElement('option')
      option.value = item.id
      option.textContent = item.title || item.name
      selectElement.appendChild(option)
    })
  }

  hideVideoPreview() {
    if (this.hasVideoPreviewTarget) {
      this.videoPreviewTarget.classList.add('hidden')
    }
  }

  extractVideoContent(event) {
    event.preventDefault()

    const videoId = this.videoSelectTarget.value
    if (!videoId) {
      this.showToast('Vui lòng chọn video trước', 'error')
      return
    }

    CourseContentApi.getVideoDetails(videoId)
      .then(video => {
        const userDescriptionField = document.querySelector('textarea[name="user_description"]')
        if (userDescriptionField) {
          const formattedContent = this.formatVideoContent(video)
          userDescriptionField.value = formattedContent
          this.showToast('Nội dung video đã được thêm vào mô tả')
        }
      })
  }

  formatVideoContent(video) {
    let content = `Video: ${video.title || 'Không có tiêu đề'}\n\n`

    if (video.transcription) {
      content += `Nội dung:\n${video.transcription}`
    } else {
      content += 'Không có nội dung phiên âm sẵn cho video này. Vui lòng nhập mô tả thủ công.'
    }

    return content
  }

  showToast(message, type = 'success') {
    const toast = document.createElement('div')
    toast.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-lg ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    } text-white shadow-lg transform transition-transform duration-300 ease-in-out`
    toast.textContent = message
    document.body.appendChild(toast)

    setTimeout(() => {
      toast.classList.add('opacity-0')
      setTimeout(() => {
        document.body.removeChild(toast)
      }, 300)
    }, 3000)
  }

  createQuestionsFromVideo(videoId, numQuestions, difficulty, topic, learningGoal) {
    return new Promise((resolve, reject) => {
      CourseContentApi.getVideoDetails(videoId)
        .then(video => {
          const title = video.title || 'Video không có tiêu đề'

          const userDescriptionField = document.querySelector('textarea[name="user_description"]')
          const description = userDescriptionField && userDescriptionField.value.trim()
            ? userDescriptionField.value
            : ''

          if (!description) {
            this.showToast('Không có nội dung mô tả. Vui lòng nhập mô tả.', 'error')
            this.isGenerating = false
            this.loadingTarget.classList.add("hidden")
            reject(new Error('Không có nội dung mô tả'))
            return
          }

          QuizApi.generateQuestions(title, description, numQuestions, difficulty, topic, learningGoal)
            .then(questions => {
              if (questions && questions.error) {
                this.showToast(`Lỗi: ${questions.error}`, 'error')
                this.isGenerating = false
                this.loadingTarget.classList.add("hidden")
                reject(new Error(questions.error))
                return
              }

              if (!questions || !Array.isArray(questions) || questions.length === 0) {
                this.showToast('Không thể tạo câu hỏi từ nội dung này. Vui lòng thử lại.', 'error')
                this.isGenerating = false
                this.loadingTarget.classList.add("hidden")
                reject(new Error('Không nhận được câu hỏi hợp lệ từ AI'))
                return
              }
              this.showToast('Đã tạo câu hỏi thành công!', 'success')
              resolve(questions)
            })
            .catch(error => {
              this.showToast(`Lỗi khi tạo câu hỏi: ${error.message}`, 'error')
              this.isGenerating = false
              this.loadingTarget.classList.add("hidden")
              reject(error)
            })
        })
        .catch(error => {
          this.showToast(`Lỗi khi lấy thông tin video: ${error.message}`, 'error')
          this.isGenerating = false
          this.loadingTarget.classList.add("hidden")
          reject(error)
        })
    })
  }

  generateQuestions(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const courseId = formData.get('quiz[course_id]')
    const numQuestions = formData.get('num_questions') || 5
    const difficulty = formData.get('difficulty') || 'medium'
    const topic = formData.get('topic')
    const learningGoal = formData.get('learning_goal')
    const videoId = this.hasVideoSelectTarget ? this.videoSelectTarget.value : null


    if (!courseId) {
      alert('Vui lòng chọn khóa học')
      return
    }

    if (this.isGenerating) return
    this.isGenerating = true

    this.loadingTarget.classList.remove("hidden")
    this.questionsContainerTarget.classList.add("hidden")
    this.controlsTarget.classList.add("hidden")

    if (videoId) {
      this.showToast('Đang xử lý...', 'success')

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty, topic, learningGoal)
        .then(questions => {
          this.questions = questions
          this.displayQuestionsAndAnalysis()
          this.showToast(`Đã tạo ${questions.length} câu hỏi thành công!`, 'success')
          this.isGenerating = false
        })
        .catch(error => {
          this.showToast(`Lỗi khi tạo câu hỏi: ${error.message}`, 'error')
          this.isGenerating = false
          this.loadingTarget.classList.add("hidden")
          this.questionsContainerTarget.classList.remove("hidden")
          this.controlsTarget.classList.remove("hidden")
        })
    }
  }

  displayQuestionsAndAnalysis() {
    this.analysisLoadingTarget.classList.add("hidden")
    this.analysisTarget.classList.remove("hidden")

    const conceptCount = Math.floor(Math.random() * 8) + 5
    this.conceptCountTarget.textContent = conceptCount

    const coverage = Math.floor(Math.random() * 30) + 70
    this.coverageBarTarget.style.width = `${coverage}%`
    this.coverageTextTarget.textContent = `${coverage}%`

    const suggestions = [
      'Bổ sung thêm ví dụ thực tế để làm rõ khái niệm',
      'Cân nhắc thêm các câu hỏi về ứng dụng thực tiễn',
      'Tăng độ phủ của các khái niệm nâng cao'
    ]

    this.suggestionsTarget.innerHTML = suggestions.map(s => `<li>${s}</li>`).join('')

    this.renderQuestions()

    this.loadingTarget.classList.add("hidden")
    this.questionsContainerTarget.classList.remove("hidden")
    this.controlsTarget.classList.remove("hidden")
    this.isGenerating = false
  }

  renderQuestions() {
    const container = this.questionsContainerTarget
    container.innerHTML = ''

    this.questions.forEach((question, index) => {
      const template = this.questionTemplateTarget.content.cloneNode(true)
      const item = template.querySelector('.question-item')

      item.dataset.index = index
      item.querySelector('.question-number').textContent = (index + 1)
      item.querySelector('.question-content').value = question.content

      const difficultySelect = item.querySelector('.question-difficulty')
      if (difficultySelect) {
        difficultySelect.value = question.difficulty || 'medium'
      }

      const topicSelect = item.querySelector('.question-topic')
      if (topicSelect && question.topic) {
        topicSelect.value = question.topic
      }

      const learningGoalSelect = item.querySelector('.question-learning-goal')
      if (learningGoalSelect && question.learning_goal) {
        learningGoalSelect.value = question.learning_goal
      }

      const optionsContainer = item.querySelector('.options-container')
      if (optionsContainer) {
        optionsContainer.innerHTML = ''

        let optionsArray = [];

        if (question.options && typeof question.options === 'object' && !Array.isArray(question.options)) {
          optionsArray = Object.keys(question.options)
            .sort()
            .map(key => question.options[key]);
        }
        else if (Array.isArray(question.options)) {
          optionsArray = question.options;
        }

        optionsArray.forEach((option, optionIndex) => {
          const optionItem = document.createElement('div')
          optionItem.className = 'option-item flex items-start gap-2'
          optionItem.innerHTML = `
            <div class="flex items-center h-5 mt-1">
              <input type="radio" name="correct-option-${index+1}" value="${optionIndex}" class="option-radio h-4 w-4 text-blue-600 border-gray-300 dark:border-gray-700" ${optionIndex === question.correct_option ? 'checked' : ''}>
            </div>
            <div class="flex-1">
              <textarea class="option-text w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-600 focus:border-blue-500 dark:focus:border-blue-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white" rows="1">${option}</textarea>
            </div>
          `
          optionsContainer.appendChild(optionItem)
        })
      }

      const explanation = item.querySelector('.explanation')
      if (explanation) {
        explanation.value = question.explanation
      }

      const regenerateBtn = item.querySelector('.regenerate-btn')
      if (regenerateBtn) {
        regenerateBtn.addEventListener('click', () => this.regenerateQuestion(index))
      }

      container.appendChild(item)
    })
  }

  regenerateQuestion(index) {
    const videoId = this.hasVideoSelectTarget ? this.videoSelectTarget.value : null

    if (videoId) {
      const numQuestions = 1
      const difficulty = document.querySelector('select[name="difficulty"]')?.value || 'medium'
      const topic = document.querySelector('select[name="topic"]')?.value
      const learningGoal = document.querySelector('select[name="learning_goal"]')?.value

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty, topic, learningGoal).then(questions => {
        if (questions && questions.length > 0) {
          this.questions[index] = questions[0]
          this.updateQuestionItem(index, questions[0])
          this.showToast(`Đã tạo lại câu hỏi #${index + 1} thành công!`, 'success')
        }
      }).catch(error => {
        console.error('Lỗi khi tạo lại câu hỏi từ video:', error)
      })
    }
  }

  updateQuestionItem(index, newQuestion) {
    const item = this.questionsContainerTarget.querySelector(`[data-index="${index}"]`)
    if (item) {
      item.querySelector('.question-content').value = newQuestion.content
      item.querySelector('.explanation').value = newQuestion.explanation

      const difficultySelect = item.querySelector('.question-difficulty')
      if (difficultySelect && newQuestion.difficulty) {
        difficultySelect.value = newQuestion.difficulty
      }

      const topicSelect = item.querySelector('.question-topic')
      if (topicSelect && newQuestion.topic) {
        topicSelect.value = newQuestion.topic
      }

      const learningGoalSelect = item.querySelector('.question-learning-goal')
      if (learningGoalSelect && newQuestion.learning_goal) {
        learningGoalSelect.value = newQuestion.learning_goal
      }

      const optionsContainer = item.querySelector('.options-container')
      if (optionsContainer) {
        optionsContainer.innerHTML = ''

        let optionsArray = [];

        if (newQuestion.options && typeof newQuestion.options === 'object' && !Array.isArray(newQuestion.options)) {
          optionsArray = Object.keys(newQuestion.options)
            .sort()
            .map(key => newQuestion.options[key]);
        }
        else if (Array.isArray(newQuestion.options)) {
          optionsArray = newQuestion.options;
        }

        optionsArray.forEach((option, optionIndex) => {
          const optionItem = document.createElement('div')
          optionItem.className = 'option-item flex items-start gap-2'
          optionItem.innerHTML = `
            <div class="flex items-center h-5 mt-1">
              <input type="radio" name="correct-option-${index+1}" value="${optionIndex}" class="option-radio h-4 w-4 text-blue-600 border-gray-300 dark:border-gray-700" ${optionIndex === newQuestion.correct_option ? 'checked' : ''}>
            </div>
            <div class="flex-1">
              <textarea class="option-text w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-600 focus:border-blue-500 dark:focus:border-blue-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white" rows="1">${option}</textarea>
            </div>
          `
          optionsContainer.appendChild(optionItem)
        })
      }
    }
  }

  saveQuiz() {
    if (this.questions.length === 0) {
      alert('Không có câu hỏi nào để lưu')
      return
    }

    const form = this.formTarget
    const title = form.querySelector('input[name="quiz[title]"]').value
    const courseId = form.querySelector('select[name="quiz[course_id]"]').value

    if (!title || !courseId) {
      alert('Vui lòng điền đầy đủ thông tin bài kiểm tra')
      return
    }

    const questionsData = []
    const questionItems = this.questionsContainerTarget.querySelectorAll('.question-item')


    questionItems.forEach((item, index) => {
      const content = item.querySelector('.question-content').value
      const explanation = item.querySelector('.explanation').value
      const difficulty = item.querySelector('.question-difficulty').value
      const topic = item.querySelector('.question-topic').value
      const learningGoal = item.querySelector('.question-learning-goal').value


      const optionElements = item.querySelectorAll('.option-text')

      const options = {}
      optionElements.forEach((el, idx) => {
        options[idx.toString()] = el.value
      })

      let correctOption = 0
      const radioButtons = item.querySelectorAll('.option-radio')
      radioButtons.forEach((radio, radioIndex) => {
        if (radio.checked) {
          correctOption = radioIndex
        }
      })

      questionsData.push({
        content,
        options,
        correct_option: correctOption,
        explanation,
        difficulty,
        topic,
        learning_goal: learningGoal
      })
    })

    const questionsDataField = form.querySelector('input[name="questions_data"]')
    questionsDataField.value = JSON.stringify(questionsData)

    let sourceTypeField = form.querySelector('input[name="source_type"]')
    if (!sourceTypeField) {
      sourceTypeField = document.createElement('input')
      sourceTypeField.type = 'hidden'
      sourceTypeField.name = 'source_type'
      form.appendChild(sourceTypeField)
    }
    sourceTypeField.value = 'ai_generated'

    this.loadingTarget.classList.remove("hidden")
    this.questionsContainerTarget.classList.add("hidden")
    this.controlsTarget.classList.add("hidden")

    form.submit()
  }

  toggleEditMode(event) {
    event.preventDefault()

    const editModeToggle = event.currentTarget
    const isEditMode = editModeToggle.classList.contains('editing')

    if (isEditMode) {
      this.collectQuestionsData()
      this.formTarget.submit()
    } else {
      const viewElements = document.querySelectorAll('.view-only')
      const editElements = document.querySelectorAll('.edit-only')

      viewElements.forEach(el => el.classList.add('hidden'))
      editElements.forEach(el => el.classList.remove('hidden'))

      if (this.hasControlsTarget) {
        this.controlsTarget.classList.remove('hidden')
      }

      editModeToggle.classList.add('editing')
      editModeToggle.querySelector('.edit-text').classList.add('hidden')
      editModeToggle.querySelector('.save-text').classList.remove('hidden')
    }
  }

  collectQuestionsData() {
    const questionsData = []
    const questionItems = this.questionsContainerTarget.querySelectorAll('.question-item')

    const formTopic = document.querySelector('select[name="topic"]')?.value
    const formLearningGoal = document.querySelector('select[name="learning_goal"]')?.value

    questionItems.forEach(item => {
      const questionId = item.getAttribute('data-question-id')
      const content = item.querySelector('.question-content').value
      const explanation = item.querySelector('.explanation')?.value || ''
      const difficulty = item.querySelector('.question-difficulty').value

      let topic = item.querySelector('.question-topic')?.value || 'other'

      if (formTopic && (!topic || topic === 'other')) {
        topic = formTopic
      }

      let learningGoal = item.querySelector('.question-learning-goal')?.value || 'other'
      if (formLearningGoal && (!learningGoal || learningGoal === 'other')) {
        learningGoal = formLearningGoal
      }

      const optionElements = item.querySelectorAll('.option-text')
      const options = {}
      optionElements.forEach((el, idx) => {
        options[idx.toString()] = el.value
      })

      let correctOption = 0
      const radioButtons = item.querySelectorAll('.option-radio')
      radioButtons.forEach((radio, idx) => {
        if (radio.checked) {
          correctOption = idx
        }
      })

      questionsData.push({
        id: questionId,
        content,
        options,
        correct_option: correctOption,
        explanation,
        difficulty,
        topic,
        learning_goal: learningGoal
      })
    })

    this.questionsDataTarget.value = JSON.stringify(questionsData)
    return questionsData
  }

  deleteQuestion(event) {
    event.preventDefault()

    const button = event.currentTarget
    const questionId = button.getAttribute('data-question-id')

    if (confirm('Bạn có chắc chắn muốn xóa câu hỏi này không?')) {
      document.getElementById('delete_question_id').value = questionId
      this.formTarget.submit()
    }
  }
}
