import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"

export default class extends Controller {
  static targets = [
    "display", "form", "timeSpent", "progress", "submitBtn", "cancelBtn",
    "pauseBtn", "resumeBtn", "questionContainer", "questionNav", "flagBtn",
    "questionNavItem", "questionCount", "currentQuestionDisplay", "timer",
    "progressBar"
  ]

  static values = {
    mode: String,
    totalQuestions: Number,
    currentQuestion: { type: Number, default: 0 },
    courseId: String,
    quizId: String,
    attemptId: String
  }

  connect() {
    console.log("Quiz timer controller connected")

    const hasAttemptId = this.attemptIdValue && this.attemptIdValue.trim() !== '';
    if (!hasAttemptId) {
      console.log("Chưa có attempt ID, đang ở chế độ xem trước bài làm");
      return;
    }

    document.addEventListener('turbo:before-render', this.handleTurboBeforeRender.bind(this));
    document.addEventListener('quiz:auto-submit', this.autoSubmit.bind(this));

    const urlParams = new URLSearchParams(window.location.search);
    const startingNewQuiz = urlParams.get('start') === 'true';
    const forceRetake = urlParams.get('force') === 'true';

    if (this.modeValue === 'exam') {
      this.checkQuizStatus();
    } else {
      this.initializeQuizTimer();
    }
  }

  async checkQuizStatus() {
    try {
      const courseId = this.courseIdValue;
      const quizId = this.quizIdValue;

      if (!courseId || !quizId) {
        console.error("Thiếu courseId hoặc quizId");
        return;
      }

      const quizAttempts = await QuizApi.checkQuizStatus(courseId);

      const isSubmitted = quizAttempts.some(attempt =>
        attempt.quiz_id === quizId && attempt.completed_at !== null
      );

      if (isSubmitted) {
        this.isSubmitted = true;
        alert('Bài làm của bạn đã được nộp. Bạn không thể làm lại.');
        window.location.href = document.referrer || '/';
        return;
      }

      this.initializeQuizTimer();
    } catch (error) {
      console.error("Lỗi khi kiểm tra trạng thái bài thi:", error);
      this.initializeQuizTimer();
    }
  }

  async initializeQuizTimer() {
    this.flaggedQuestions = new Set();
    this.isPaused = false;
    this.isSubmitted = false;

    // Phòng trường hợp không load được questions
    if (!this.hasQuestionContainerTarget) {
      console.error("Không tìm thấy container câu hỏi");
      return;
    }

    const questions = this.questionContainerTarget.querySelectorAll('.question');
    if (questions.length === 0) {
      console.error("Không có câu hỏi nào trong container");
      return;
    }

    // Time limit từ HTML
    if (this.hasDisplayTarget && this.displayTarget.dataset.timeLimit) {
      this.timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
      this.remainingSeconds = this.timeLimit;
      this.elapsedTime = 0;
    } else {
      console.error("Không tìm thấy thông tin time limit");
      this.timeLimit = 3600; // Default 60 phút
      this.remainingSeconds = 3600;
      this.elapsedTime = 0;
    }

    try {
      // Tải trạng thái từ database
      if (this.courseIdValue && this.quizIdValue && this.attemptIdValue) {
        const state = await QuizApi.getAttemptState(
          this.courseIdValue,
          this.quizIdValue,
          this.attemptIdValue
        );

        if (state) {
          if (state.current_question !== undefined) {
            this.currentQuestionValue = state.current_question;
          }

          if (state.elapsed_time !== undefined) {
            this.elapsedTime = state.elapsed_time;
            this.remainingSeconds = Math.max(0, this.timeLimit - this.elapsedTime);
          }

          if (state.answers) {
            this.applyStoredAnswers(state.answers);
          }

          if (state.flagged_questions) {
            this.flaggedQuestions = new Set(state.flagged_questions);
          }
        }
      }
    } catch (error) {
      console.error("Lỗi khi tải trạng thái bài làm:", error);
    }

    this.startTime = new Date(new Date() - this.elapsedTime * 1000);
    this.startTimer();
    this.showQuestion(this.currentQuestionValue);
    this.setupFormListeners();
    this.updateAnsweredQuestions();
    this.updateNavigation();
    this.updateDisplay();

    history.pushState(null, null, location.href);
    window.addEventListener('popstate', this.handleBackButton.bind(this));

    // Lưu trạng thái ban đầu
    this.saveStateDebounced = this.debounce(this.saveState.bind(this), 1000);
  }

  disconnect() {
    this.clearTimers();
    window.removeEventListener('popstate', this.handleBackButton.bind(this));
    document.removeEventListener('turbo:before-render', this.handleTurboBeforeRender.bind(this));
    document.removeEventListener('quiz:auto-submit', this.autoSubmit.bind(this));
    window.quizSubmitted = this.isSubmitted;
  }

  clearTimers() {
    if (this.interval) {
      clearInterval(this.interval);
    }

    if (this.saveStateTimeout) {
      clearTimeout(this.saveStateTimeout);
    }
  }

  startTimer() {
    this.clearTimers();

    if (!this.startTime) {
      this.startTime = new Date().getTime();
    }

    this.saveInterval = setInterval(() => {
      if (!this.isPaused && !this.isSubmitted) {
        const currentTime = new Date().getTime();
        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);
        const totalElapsedTime = this.initialElapsedTime + elapsedSeconds;
        const remainingSeconds = Math.max(0, this.initialTimeLimit - totalElapsedTime);

        localStorage.setItem(`${this.quizId}_remaining_time`, remainingSeconds);
      }
    }, 2000);

    this.interval = setInterval(() => {
      if (!this.isPaused) {
        const now = new Date();
        const elapsed = Math.floor((now - this.startTime) / 1000);
        this.remainingSeconds = Math.max(0, this.timeLimit - elapsed);
        this.elapsedTime = elapsed;

        this.updateDisplay();

        if (this.remainingSeconds <= 0) {
          this.clearTimers();
          alert('Đã hết thời gian làm bài. Bài làm của bạn sẽ được nộp tự động.');
          this.autoSubmit();
        }
      }
    }, 1000);
  }

  updateDisplay() {
    if (!this.hasDisplayTarget) return;

    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

    if (this.hasTimeSpentTarget) {
      this.timeSpentTarget.value = this.elapsedTime;
    }

    if (this.hasProgressBarTarget && this.hasTotalQuestionsValue) {
      const answeredQuestions = this.getAnsweredQuestions().length;
      const progressPercent = (answeredQuestions / this.totalQuestionsValue) * 100;
      this.progressBarTarget.style.width = `${progressPercent}%`;
    }

    if (this.remainingSeconds <= 60) {
      this.displayTarget.classList.add('text-red-500');
      this.displayTarget.classList.add('animate-pulse');
    }
  }

  setupFormListeners() {
    if (!this.hasFormTarget) return;

    const radioButtons = this.formTarget.querySelectorAll('input[type="radio"]');
    radioButtons.forEach(radio => {
      radio.addEventListener('change', (e) => {
        this.updateAnsweredQuestions();
        this.saveStateDebounced();

        const questionIdMatch = e.target.name.match(/\[(\w+)\]/);
        if (questionIdMatch && questionIdMatch[1]) {
          const questionId = questionIdMatch[1];
          const navItem = this.findNavItemByQuestionId(questionId);
          if (navItem) {
            navItem.classList.remove('bg-gray-500', 'bg-yellow-500');
            navItem.classList.add('bg-green-500');
          }
        }
      });
    });

    window.addEventListener('beforeunload', (e) => {
      if (!this.isSubmitted) {
        const message = 'Bạn có chắc muốn rời khỏi? Tiến trình làm bài sẽ được lưu lại.';
        e.returnValue = message;
        return message;
      }
    });
  }

  findNavItemByQuestionId(questionId) {
    if (!this.hasQuestionNavItemTarget) return null;

    return this.questionNavItemTargets.find(item => item.dataset.questionId === questionId);
  }

  updateAnsweredQuestions() {
    if (!this.hasFormTarget || !this.hasProgressTarget) return;

    const radioGroups = this.getAnsweredQuestions();
    this.progressTarget.textContent = radioGroups.length;
    this.updateNavigation();
  }

  getAnsweredQuestions() {
    if (!this.hasFormTarget) return [];
    return this.formTarget.querySelectorAll('input[type="radio"]:checked');
  }

  applyStoredAnswers(answers) {
    if (!this.hasFormTarget) return;

    Object.entries(answers).forEach(([questionId, optionIndex]) => {
      const radioInput = this.formTarget.querySelector(`input[name="answers[${questionId}]"][value="${optionIndex}"]`);
      if (radioInput) {
        radioInput.checked = true;
      }
    });
  }

  submitForm() {
    if (this.isSubmitted) {
      alert('Bài làm của bạn đã được nộp.');
      return;
    }

    if (!this.hasFormTarget || !this.hasTimeSpentTarget || !this.hasTotalQuestionsValue) return;

    this.timeSpentTarget.value = this.elapsedTime;

    const answeredQuestions = parseInt(this.progressTarget.textContent, 10);

    if (answeredQuestions < this.totalQuestionsValue) {
      if (this.modeValue === 'exam') {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
          this.isSubmitted = true;
          window.quizSubmitted = true;
          this.formTarget.submit();
        }
      } else {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
          this.isSubmitted = true;
          window.quizSubmitted = true;
          this.formTarget.submit();
        }
      }
    } else {
      this.isSubmitted = true;
      window.quizSubmitted = true;
      this.formTarget.submit();
    }
  }

  autoSubmit(event) {
    if (this.isSubmitted) return;

    const reason = event && event.detail ? event.detail.reason : 'Hết thời gian làm bài';
    console.log(`Nộp bài tự động: ${reason}`);

    if (!this.hasFormTarget || !this.hasTimeSpentTarget) {
      console.error("Không tìm thấy form hoặc trường time_spent");
      return;
    }

    this.timeSpentTarget.value = this.elapsedTime;
    this.isSubmitted = true;
    window.quizSubmitted = true;

    this.formTarget.submit();
  }

  cancel(event) {
    event.preventDefault();
    if (confirm('Bạn có chắc muốn hủy bài làm này? Tiến trình sẽ không được lưu lại.')) {
      window.location.href = document.referrer || '/';
    }
  }

  togglePause() {
    if (!this.hasPauseBtnTarget || !this.hasResumeBtnTarget || !this.hasDisplayTarget) return;

    this.isPaused = !this.isPaused;

    if (this.isPaused) {
      this.pauseBtnTarget.classList.add('hidden');
      this.resumeBtnTarget.classList.remove('hidden');
      this.displayTarget.classList.add('opacity-50');
    } else {
      this.pauseBtnTarget.classList.remove('hidden');
      this.resumeBtnTarget.classList.add('hidden');
      this.displayTarget.classList.remove('opacity-50');
      this.startTime = new Date(new Date() - this.elapsedTime * 1000);
    }
  }

  flagCurrentQuestion() {
    if (!this.hasQuestionContainerTarget || !this.hasFlagBtnTarget) return;

    const questionIndex = this.currentQuestionValue;
    const questions = this.questionContainerTarget.querySelectorAll('.question');

    if (questionIndex < 0 || questionIndex >= questions.length) {
      console.error("Chỉ số câu hỏi không hợp lệ:", questionIndex);
      return;
    }

    const currentQuestion = questions[questionIndex];
    if (!currentQuestion || !currentQuestion.dataset.questionId) {
      console.error("Không tìm thấy question-id cho câu hỏi hiện tại");
      return;
    }

    const questionId = currentQuestion.dataset.questionId;
    const navItem = this.findNavItemByQuestionId(questionId);

    if (this.flaggedQuestions.has(questionId)) {
      this.flaggedQuestions.delete(questionId);
      this.flagBtnTarget.classList.remove('bg-yellow-500');
      this.flagBtnTarget.classList.add('bg-gray-500');
      if (navItem) {
        navItem.classList.remove('bg-yellow-500');
      }
    } else {
      this.flaggedQuestions.add(questionId);
      this.flagBtnTarget.classList.remove('bg-gray-500');
      this.flagBtnTarget.classList.add('bg-yellow-500');
      if (navItem) {
        navItem.classList.add('bg-yellow-500');
      }
    }

    this.saveStateDebounced();
  }

  getCurrentQuestion() {
    return this.currentQuestionValue;
  }

  showQuestion(index) {
    if (!this.hasQuestionContainerTarget) {
      console.error("Không tìm thấy container câu hỏi");
      return;
    }

    const questions = this.questionContainerTarget.querySelectorAll('.question');
    if (questions.length === 0) {
      console.error("Không có câu hỏi nào trong container");
      return;
    }

    if (index < 0 || index >= questions.length) {
      console.error("Chỉ số câu hỏi không hợp lệ:", index);
      return;
    }

    questions.forEach((q, i) => {
      q.classList.toggle('hidden', i !== index);
    });

    this.currentQuestionValue = index;

    if (this.hasCurrentQuestionDisplayTarget) {
      this.currentQuestionDisplayTarget.textContent = index + 1;
    }

    const currentQuestion = questions[index];
    if (!currentQuestion || !currentQuestion.dataset.questionId) {
      console.error("Không tìm thấy question-id cho câu hỏi hiện tại");
      return;
    }

    const questionId = currentQuestion.dataset.questionId;

    if (this.hasFlagBtnTarget) {
      this.flagBtnTarget.classList.toggle('bg-yellow-500', this.flaggedQuestions.has(questionId));
      this.flagBtnTarget.classList.toggle('bg-gray-500', !this.flaggedQuestions.has(questionId));
    }

    this.updateNavigation();
    this.saveStateDebounced();
  }

  nextQuestion() {
    if (!this.hasQuestionContainerTarget) return;

    const questions = this.questionContainerTarget.querySelectorAll('.question');
    if (this.currentQuestionValue < questions.length - 1) {
      this.showQuestion(this.currentQuestionValue + 1);
    }
  }

  prevQuestion() {
    if (this.currentQuestionValue > 0) {
      this.showQuestion(this.currentQuestionValue - 1);
    }
  }

  goToQuestion(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.showQuestion(index);
  }

  updateNavigation() {
    if (!this.hasQuestionNavItemTarget || !this.hasFormTarget) return;

    const answeredMap = {};

    const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked');
    radioGroups.forEach(radio => {
      const name = radio.getAttribute('name');
      const questionIdMatch = name.match(/\[(\w+)\]/);
      if (questionIdMatch && questionIdMatch[1]) {
        const questionId = questionIdMatch[1];
        answeredMap[questionId] = true;
      }
    });

    this.questionNavItemTargets.forEach((item, index) => {
      if (!item.dataset.questionId) return;

      const questionId = item.dataset.questionId;

      item.classList.remove('bg-green-500', 'bg-gray-500', 'bg-yellow-500');

      if (answeredMap[questionId]) {
        item.classList.add('bg-green-500');
      } else if (this.flaggedQuestions.has(questionId)) {
        item.classList.add('bg-yellow-500');
      } else {
        item.classList.add('bg-gray-500');
      }

      if (index === this.currentQuestionValue) {
        item.classList.add('ring-2', 'ring-blue-500');
      } else {
        item.classList.remove('ring-2', 'ring-blue-500');
      }
    });
  }

  async saveState() {
    if (!this.courseIdValue || !this.quizIdValue || !this.attemptIdValue || this.isSubmitted) {
      return;
    }

    try {
      const answers = {};
      const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked');
      radioGroups.forEach(radio => {
        const name = radio.getAttribute('name');
        const questionIdMatch = name.match(/\[(\w+)\]/);
        if (questionIdMatch && questionIdMatch[1]) {
          const questionId = questionIdMatch[1];
          answers[questionId] = radio.value;
        }
      });

      const state = {
        current_question: this.currentQuestionValue,
        elapsed_time: this.elapsedTime,
        answers,
        flagged_questions: Array.from(this.flaggedQuestions)
      };

      await QuizApi.saveAttemptState(
        this.courseIdValue,
        this.quizIdValue,
        this.attemptIdValue,
        state
      );
    } catch (error) {
      console.error("Lỗi khi lưu trạng thái bài làm:", error);
    }
  }

  handleBackButton(e) {
    e.preventDefault();
    history.pushState(null, null, location.href);

    if (!this.isSubmitted && confirm('Bạn có chắc muốn rời khỏi trang này? Tiến trình làm bài sẽ được lưu lại.')) {
      window.removeEventListener('popstate', this.handleBackButton);
      this.saveState();
      history.back();
    }
  }

  updatePauseButtonUI() {
    this.pauseBtnTarget.classList.add('hidden');
    this.resumeBtnTarget.classList.remove('hidden');
    this.displayTarget.classList.add('text-yellow-500');
  }

  handleTurboBeforeRender(event) {
    const currentUrl = window.location.pathname;
    if (!currentUrl.includes('/quiz_attempts/') && !currentUrl.includes('/results')) {
      this.saveState();
    }
  }

  // Hàm debounce để tránh lưu quá nhiều
  debounce(func, wait) {
    return (...args) => {
      if (this.saveStateTimeout) {
        clearTimeout(this.saveStateTimeout);
      }
      this.saveStateTimeout = setTimeout(() => {
        func.apply(this, args);
      }, wait);
    };
  }
}
