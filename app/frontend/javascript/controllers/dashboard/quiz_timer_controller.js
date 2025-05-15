import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"

export default class extends Controller {
  static targets = [
    "display", "form", "timeSpent", "progress", "submitBtn", "cancelBtn",
    "pauseBtn", "resumeBtn", "questionContainer", "questionNav",
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
    this.isPaused = false;
    this.isSubmitted = false;

    if (!this.hasQuestionContainerTarget) {
      console.error("Không tìm thấy container câu hỏi");
      return;
    }

    const questions = this.questionContainerTarget.querySelectorAll('.question');
    if (questions.length === 0) {
      console.error("Không có câu hỏi nào trong container");
      return;
    }

    if (this.hasDisplayTarget && this.displayTarget.dataset.timeLimit) {
      this.timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
      this.remainingSeconds = this.timeLimit;
      this.elapsedTime = 0;
    } else {
      console.error("Không tìm thấy thông tin time limit");
      this.timeLimit = 3600;
      this.remainingSeconds = 3600;
      this.elapsedTime = 0;
    }

    try {
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
        }
      }
    } catch (error) {
      console.error("Lỗi khi tải trạng thái bài làm:", error);
    }

    this.startTime = new Date(new Date() - this.elapsedTime * 1000);
    this.startTimer();
    this.setupFormListeners();
    this.updateAnsweredQuestions();
    this.updateDisplay();

    history.pushState(null, null, location.href);
    window.addEventListener('popstate', this.handleBackButton.bind(this));

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

  updateAnsweredQuestions() {
    if (!this.hasFormTarget) return;

    const radioGroups = this.getAnsweredQuestions();

    if (this.hasProgressTarget) {
      this.progressTarget.textContent = radioGroups.length;
    }
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

    if (!this.hasFormTarget || !this.hasTimeSpentTarget) return;

    this.timeSpentTarget.value = this.elapsedTime;

    const answeredQuestions = this.getAnsweredQuestions().length;

    const submitTheForm = () => {
      this.isSubmitted = true;
      window.quizSubmitted = true;
      this.formTarget.submit();
    };

    const confirmAndSubmit = () => {
      if (answeredQuestions < this.totalQuestionsValue) {
        if (this.modeValue === 'exam') {
          if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
            this.getIpAndSubmit(submitTheForm);
          }
        } else {
          if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
            this.getIpAndSubmit(submitTheForm);
          }
        }
      } else {
        this.getIpAndSubmit(submitTheForm);
      }
    };

    confirmAndSubmit();
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

    this.getIpAndSubmit(() => {
      this.isSubmitted = true;
      window.quizSubmitted = true;
      this.formTarget.submit();
    });
  }

  async getIpAndSubmit(callback) {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      const clientIp = urlParams.get('client_ip');

      if (clientIp) {
        console.log("Sử dụng IP từ URL:", clientIp);
        const ipInput = document.createElement('input');
        ipInput.type = 'hidden';
        ipInput.name = 'client_ip_address';
        ipInput.value = clientIp;
        this.formTarget.appendChild(ipInput);
        callback();
      } else {
        const response = await fetch('https://api.ipify.org/?format=json');
        const data = await response.json();
        const ipInput = document.createElement('input');
        ipInput.type = 'hidden';
        ipInput.name = 'client_ip_address';
        ipInput.value = data.ip;
        this.formTarget.appendChild(ipInput);
        callback();
      }
    } catch (error) {
      console.error("Lỗi khi lấy địa chỉ IP:", error);
      callback();
    }
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
        answers
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
