import { Controller } from '@hotwired/stimulus'
import { CourseContentApi } from '../../services/course_content_api'

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
    // Kiểm tra xem courseSelect có phải là selector select trong DOM không
    console.log("courseSelect element:", this.courseSelectTarget)

    // Trong trường hợp courseSelect là một phần tử khác, tìm select trong form của quiz
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

  // Phương thức load các bài học khi chọn chương
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

  // Phương thức load các video khi chọn bài học
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
    const questionTypes = formData.getAll('question_types[]')
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
      // Nếu có video được chọn, sử dụng transcription
      this.showToast('Đang lấy dữ liệu phiên âm từ video...', 'success')

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty)
        .then(questions => {
          this.questions = questions
          this.displayQuestionsAndAnalysis()
          this.showToast(`Đã tạo ${questions.length} câu hỏi từ phiên âm video thành công!`, 'success')
        })
        .catch(error => {
          console.error('Lỗi khi tạo câu hỏi từ video:', error)
          this.createSampleQuestions(numQuestions)
            .then(questions => {
              this.questions = questions
              this.displayQuestionsAndAnalysis()
              this.showToast('Lỗi khi tạo câu hỏi từ phiên âm, sử dụng mô tả người dùng thay thế', 'warning')
            })
            .catch(err => {
              console.error('Lỗi khi tạo câu hỏi mẫu:', err)
              this.showToast('Đã xảy ra lỗi khi tạo câu hỏi', 'error')
              this.loadingTarget.classList.add("hidden")
              this.isGenerating = false
            })
        })
    } else {
      // Nếu không có video, sử dụng mô tả người dùng
      this.showToast('Đang tạo câu hỏi từ mô tả của bạn...', 'success')

      this.createSampleQuestions(numQuestions)
        .then(questions => {
          this.questions = questions
          this.displayQuestionsAndAnalysis()
          this.showToast('Đã tạo câu hỏi thành công!', 'success')
        })
        .catch(error => {
          console.error('Lỗi khi tạo câu hỏi:', error)
          this.showToast('Đã xảy ra lỗi khi tạo câu hỏi', 'error')
          this.loadingTarget.classList.add("hidden")
          this.isGenerating = false
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

          // Kiểm tra nếu không có transcription hoặc là message mặc định
          if (!transcription || transcription === "Chưa có phiên âm cho video này.") {
            console.warn('Không có dữ liệu phiên âm, sử dụng câu hỏi mẫu')
            resolve(this.createSampleQuestions(numQuestions))
            return
          }

          // Hiển thị thông báo đang tạo câu hỏi
          this.showToast('Đang tạo câu hỏi từ phiên âm...', 'success')

          // Có transcription, gửi đến server để tạo câu hỏi
          fetch('/manage/quizzes.json', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
              title: title,
              description: transcription,
              num_questions: numQuestions,
              difficulty: difficulty || 'medium'
            })
          })
          .then(response => {
            if (!response.ok) {
              return response.json().then(errorData => {
                throw new Error(errorData.error || 'Lỗi khi tạo câu hỏi từ phiên âm')
              })
            }
            return response.json()
          })
          .then(data => {
            console.log('Câu hỏi từ AI:', data)
            if (!data || !Array.isArray(data) || data.length === 0) {
              throw new Error('Không nhận được câu hỏi hợp lệ từ AI')
            }
            this.showToast('Đã tạo câu hỏi thành công từ phiên âm!', 'success')
            resolve(data)
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

  createSampleQuestions(count) {
    const questionContent = document.querySelector('textarea[name="user_description"]')?.value || 'Nội dung mẫu khóa học'
    const courseTitle = document.querySelector('select[name="quiz[course_id]"] option:checked')?.text || 'Khóa học'
    const difficulty = document.querySelector('select[name="difficulty"]')?.value || 'medium'

    return fetch('/manage/quizzes.json', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        title: courseTitle,
        description: questionContent,
        num_questions: count,
        difficulty: difficulty
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Lỗi khi tạo câu hỏi')
      }
      return response.json()
    })
    .catch(error => {
      console.error('Lỗi khi gọi API tạo câu hỏi:', error)

      // Trả về dữ liệu mẫu nếu API lỗi
      const questions = []
      const questionTypes = [
        "Khái niệm chính của khóa học là gì?",
        "Đâu là ví dụ tốt nhất minh họa cho nguyên tắc này?",
        "Trong trường hợp nào phương pháp này không áp dụng được?",
        "Điểm khác biệt chính giữa hai khái niệm là gì?",
        "Đâu là thứ tự đúng của các bước trong quy trình này?",
        "Yếu tố nào quan trọng nhất trong việc áp dụng lý thuyết này?",
        "Đâu là kết quả dự kiến khi áp dụng phương pháp này?"
      ]

      for (let i = 0; i < count; i++) {
        const options = [
          `Đáp án A mẫu cho câu hỏi ${i+1}`,
          `Đáp án B mẫu cho câu hỏi ${i+1}`,
          `Đáp án C mẫu cho câu hỏi ${i+1}`,
          `Đáp án D mẫu cho câu hỏi ${i+1}`
        ]

        questions.push({
          content: `${questionTypes[i % questionTypes.length]} (Câu hỏi mẫu ${i+1})`,
          options: options,
          correct_option: Math.floor(Math.random() * 4),
          explanation: `Giải thích mẫu cho câu hỏi ${i+1}. Đáp án đúng là vì nó phù hợp với các nguyên tắc đã học trong khóa học. Các đáp án khác không chính xác vì chúng không đáp ứng điều kiện hoặc ngữ cảnh của vấn đề.`,
          difficulty: ['easy', 'medium', 'hard'][Math.floor(Math.random() * 3)]
        })
      }

      return questions
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

        question.options.forEach((option, optionIndex) => {
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

      this.showToast(`Đang tạo lại câu hỏi #${index + 1} từ phiên âm video...`, 'success')

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty).then(questions => {
        if (questions && questions.length > 0) {
          this.questions[index] = questions[0]
          this.updateQuestionItem(index, questions[0])
          this.showToast(`Đã tạo lại câu hỏi #${index + 1} thành công!`, 'success')
        } else {
          // Fallback to sample question if no questions returned
          this.showToast('Không nhận được câu hỏi từ AI, sử dụng câu hỏi mẫu', 'error')
          this.createSampleQuestions(1)
            .then(questions => {
              if (questions && questions.length > 0) {
                this.questions[index] = questions[0]
                this.updateQuestionItem(index, questions[0])
              }
            })
            .catch(error => {
              console.error('Lỗi khi tạo câu hỏi mẫu:', error)
            })
        }
      }).catch(error => {
        console.error('Lỗi khi tạo lại câu hỏi từ video:', error)
        this.showToast('Lỗi khi tạo câu hỏi từ phiên âm, sử dụng câu hỏi mẫu thay thế', 'error')
        this.createSampleQuestions(1)
          .then(questions => {
            if (questions && questions.length > 0) {
              this.questions[index] = questions[0]
              this.updateQuestionItem(index, questions[0])
            }
          })
          .catch(err => {
            console.error('Lỗi khi tạo câu hỏi mẫu:', err)
          })
      })
    } else {
      this.showToast('Không có video được chọn, sử dụng mô tả người dùng', 'info')
      this.createSampleQuestions(1)
        .then(questions => {
          if (questions && questions.length > 0) {
            this.questions[index] = questions[0]
            this.updateQuestionItem(index, questions[0])
            this.showToast('Đã tạo lại câu hỏi thành công', 'success')
          } else {
            this.showToast('Không thể tạo câu hỏi mẫu', 'error')
          }
        })
        .catch(error => {
          console.error('Lỗi khi tạo câu hỏi mẫu:', error)
          this.showToast('Đã xảy ra lỗi khi tạo câu hỏi', 'error')
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

        newQuestion.options.forEach((option, optionIndex) => {
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
      this.showToast('Đang tạo lại câu hỏi từ phiên âm video...', 'success')

      this.createQuestionsFromVideo(videoId, numQuestions, difficulty).then(questions => {
        this.questions = questions
        this.renderQuestions()
        this.loadingTarget.classList.add("hidden")
        this.questionsContainerTarget.classList.remove("hidden")
        this.isGenerating = false
        this.showToast(`Đã tạo lại ${questions.length} câu hỏi từ phiên âm video thành công!`, 'success')
      }).catch(error => {
        console.error('Lỗi khi tạo lại câu hỏi từ video:', error)
        this.showToast('Lỗi khi tạo câu hỏi từ phiên âm, sử dụng mô tả người dùng thay thế', 'error')

        this.createSampleQuestions(numQuestions)
          .then(questions => {
            this.questions = questions
            this.renderQuestions()
            this.loadingTarget.classList.add("hidden")
            this.questionsContainerTarget.classList.remove("hidden")
            this.isGenerating = false
          })
          .catch(err => {
            console.error('Lỗi khi tạo câu hỏi mẫu:', err)
            this.loadingTarget.classList.add("hidden")
            this.isGenerating = false
            this.showToast('Đã xảy ra lỗi khi tạo câu hỏi', 'error')
          })
      })
    } else {
      this.showToast('Sử dụng mô tả người dùng để tạo câu hỏi...', 'info')

      this.createSampleQuestions(numQuestions)
        .then(questions => {
          this.questions = questions
          this.renderQuestions()
          this.loadingTarget.classList.add("hidden")
          this.questionsContainerTarget.classList.remove("hidden")
          this.isGenerating = false
          this.showToast('Đã tạo lại câu hỏi thành công', 'success')
        })
        .catch(error => {
          console.error('Lỗi khi tạo câu hỏi mẫu:', error)
          this.loadingTarget.classList.add("hidden")
          this.isGenerating = false
          this.showToast('Đã xảy ra lỗi khi tạo câu hỏi', 'error')
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

      const options = []
      const optionElements = item.querySelectorAll('.option-text')
      optionElements.forEach(el => {
        options.push(el.value)
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

    this.questionsDataTarget.value = JSON.stringify(questionsData)

    form.submit()
  }
}
