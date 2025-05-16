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
    // Kiểm tra các target có tồn tại không
    console.log("courseSelect target found:", this.hasCourseSelectTarget)
    console.log("chapterSelect target found:", this.hasChapterSelectTarget)
    console.log("lessonSelect target found:", this.hasLessonSelectTarget)
    console.log("videoSelect target found:", this.hasVideoSelectTarget)
  }

  // Phương thức load các chương khi chọn khóa học
  loadChapters() {
    console.log("loadChapters called")
    console.log("courseSelect element:", this.courseSelectTarget)

    let courseId = this.courseSelectTarget.value
    if (!courseId) {
      const formElement = document.querySelector('form[data-manage--course-content-select-target="form"]')
      if (formElement) {
        const courseSelect = formElement.querySelector('select[name="quiz[course_id]"]')
        if (courseSelect) {
          courseId = courseSelect.value
          console.log("Found courseId from form:", courseId)
        }
      }
    }

    if (!courseId) {
      console.log("No courseId found")
      this.resetSelect(this.chapterSelectTarget)
      this.resetSelect(this.lessonSelectTarget)
      this.resetSelect(this.videoSelectTarget)
      this.hideVideoPreview()
      return
    }

    console.log("Loading chapters for course:", courseId)
    this.resetSelect(this.chapterSelectTarget, 'Đang tải...')
    this.resetSelect(this.lessonSelectTarget)
    this.resetSelect(this.videoSelectTarget)
    this.hideVideoPreview()

    CourseContentApi.getCourseChapters(courseId)
      .then(chapters => {
        console.log("Chapters loaded:", chapters)
        this.populateSelect(this.chapterSelectTarget, chapters, 'Chọn chương')
      })
      .catch(error => {
        console.error('Error loading chapters:', error)
        this.resetSelect(this.chapterSelectTarget, 'Lỗi khi tải dữ liệu')
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

    console.log("Loading lessons for chapter:", chapterId)
    this.resetSelect(this.lessonSelectTarget, 'Đang tải...')
    this.resetSelect(this.videoSelectTarget)
    this.hideVideoPreview()

    CourseContentApi.getChapterLessons(chapterId)
      .then(lessons => {
        console.log("Lessons loaded:", lessons)
        this.populateSelect(this.lessonSelectTarget, lessons, 'Chọn bài học')
      })
      .catch(error => {
        console.error('Error loading lessons:', error)
        this.resetSelect(this.lessonSelectTarget, 'Lỗi khi tải dữ liệu')
      })
  }

  loadVideos() {
    const lessonId = this.lessonSelectTarget.value
    if (!lessonId) {
      this.resetSelect(this.videoSelectTarget)
      this.hideVideoPreview()
      return
    }

    console.log("Loading videos for lesson:", lessonId)
    this.resetSelect(this.videoSelectTarget, 'Đang tải...')
    this.hideVideoPreview()

    CourseContentApi.getLessonVideos(lessonId)
      .then(videos => {
        console.log("Videos loaded:", videos)
        this.populateSelect(this.videoSelectTarget, videos, 'Chọn video')
      })
      .catch(error => {
        console.error('Error loading videos:', error)
        this.resetSelect(this.videoSelectTarget, 'Lỗi khi tải dữ liệu')
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
    placeholder.textContent = placeholderText || selectElement.getAttribute('data-placeholder') || 'Chọn một giá trị'
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

  getYoutubeVideoId(url) {
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/
    const match = url.match(regExp)
    return (match && match[2].length === 11) ? match[2] : null
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
      .catch(error => {
        console.error('Error extracting transcript from video:', error)
        this.showToast('Không thể lấy nội dung từ video', 'error')
      })
  }

  formatVideoContent(video) {
    let content = `📚 Video: ${video.title || 'Không có tiêu đề'}\n\n`

    if (video.transcription) {
      content += `📝 Nội dung:\n${video.transcription}`
    } else {
      content += '❗ Không có nội dung phiên âm sẵn cho video này. Vui lòng nhập mô tả thủ công.'
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

  generateQuestions(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)
    const courseId = formData.get('quiz[course_id]')
    const numQuestions = formData.get('num_questions') || 5
    const difficulty = formData.get('difficulty') || 'medium'
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
      this.showToast('Đang lấy dữ liệu phiên âm từ video...', 'success')

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty)
        .then(questions => {
          this.questions = questions
          this.displayQuestionsAndAnalysis()
          this.showToast(`Đã tạo ${questions.length} câu hỏi từ phiên âm video thành công!`, 'success')
        })
        .catch(error => {
          console.error('Lỗi khi tạo câu hỏi từ video:', error)
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

  createQuestionsFromVideo(videoId, numQuestions, difficulty) {
    return new Promise((resolve, reject) => {
      CourseContentApi.getVideoDetails(videoId)
        .then(video => {
          const title = video.title || 'Video không có tiêu đề'
          const transcription = video.transcription

          if (!transcription || transcription === "Chưa có phiên âm cho video này.") {
            this.showToast('Không có phiên âm cho video này.', 'error')
            return []
          }


          QuizApi.generateQuestions(title, transcription, numQuestions, difficulty)
            .then(questions => {
              console.log('Câu hỏi từ AI:', questions)
              if (!questions || !Array.isArray(questions) || questions.length === 0) {
                throw new Error('Không nhận được câu hỏi hợp lệ từ AI')
              }
              this.showToast('Đã tạo câu hỏi thành công từ phiên âm!', 'success')
              resolve(questions)
            })
            .catch(error => {
              console.error('Lỗi khi gọi API tạo câu hỏi:', error.message)
              this.showToast(`Lỗi: ${error.message}`, 'error')
              reject(error)
            })
        })
        .catch(error => {
          console.error('Lỗi khi lấy thông tin video:', error)
          reject(error)
        })
    })
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
        difficultySelect.value = question.difficulty
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

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty).then(questions => {
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

  regenerateQuestions() {
    this.isGenerating = true
    this.loadingTarget.classList.remove("hidden")
    this.questionsContainerTarget.classList.add("hidden")

    const videoId = this.hasVideoSelectTarget ? this.videoSelectTarget.value : null
    const numQuestions = this.questions.length || 5
    const difficulty = document.querySelector('select[name="difficulty"]')?.value || 'medium'

    if (videoId) {

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty).then(questions => {
        this.questions = questions
        this.renderQuestions()
        this.loadingTarget.classList.add("hidden")
        this.questionsContainerTarget.classList.remove("hidden")
        this.isGenerating = false
        this.showToast(`Đã tạo lại ${questions.length} câu hỏi từ phiên âm video thành công!`, 'success')
      }).catch(error => {
        console.error('Lỗi khi tạo lại câu hỏi từ video:', error)
        return []
      })
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
        difficulty
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

    // Submit form
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

    questionItems.forEach(item => {
      const questionId = item.getAttribute('data-question-id')
      const content = item.querySelector('.question-content').value
      const explanation = item.querySelector('.explanation')?.value || ''
      const difficulty = item.querySelector('.question-difficulty').value

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
        difficulty
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
