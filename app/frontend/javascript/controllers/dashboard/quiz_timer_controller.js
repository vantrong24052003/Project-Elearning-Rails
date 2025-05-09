import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "display", "form", "timeSpent", "progress", "submitBtn",
    "pauseBtn", "resumeBtn", "progressBar"
  ]

  static values = {
    mode: String,
    totalQuestions: Number
  }

  connect() {
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    this.quizId = quizId;
    this.storageKey = quizId ? `quiz_timer_${quizId}` : null;

    this.isPaused = false;
    this.isSubmitted = false;

    document.addEventListener('turbo:before-render', this.checkClearStorage.bind(this));

    window.addEventListener('pageshow', this.handlePageShow.bind(this));

    const urlParams = new URLSearchParams(window.location.search);
    const forceRetake = urlParams.get('force') === 'true';
    const continueParam = urlParams.get('continue') === 'true';

    if (quizId) {
      if (forceRetake) {
        localStorage.removeItem(`quiz_${quizId}_submitted`);
        localStorage.removeItem(`${quizId}_remaining_time`);
        this.clearState();
        this.setupNewQuiz();
      } else if (continueParam) {
        const remainingTime = parseInt(localStorage.getItem(`${quizId}_remaining_time`), 10);
        if (remainingTime && !isNaN(remainingTime)) {
          this.remainingSeconds = remainingTime;
          this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
          this.initialElapsedTime = this.initialTimeLimit - this.remainingSeconds;
          this.elapsedTime = this.initialElapsedTime;
        } else {
          const savedState = this.loadState();
          if (!savedState) {
            this.setupNewQuiz();
          }
        }
      } else {
        const remainingTime = parseInt(localStorage.getItem(`${quizId}_remaining_time`), 10);
        if (remainingTime && !isNaN(remainingTime)) {
          this.remainingSeconds = remainingTime;
          this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
          this.initialElapsedTime = this.initialTimeLimit - this.remainingSeconds;
          this.elapsedTime = this.initialElapsedTime;
        } else {
          const savedState = this.loadState();
          if (!savedState) {
            this.setupNewQuiz();
          }
        }
      }
    }

    this.setupPauseButton();

    this.loadStateAndUpdateUI();

    this.setupFormListeners();
  }

  handlePageShow(event) {
    if (event.persisted || document.hidden === false) {
      this.loadStateAndUpdateUI();
    }
  }

  disconnect() {
    this.clearTimers();
    document.removeEventListener('turbo:before-render', this.checkClearStorage.bind(this));
    window.removeEventListener('pageshow', this.handlePageShow.bind(this));

    if (!this.isSubmitted) {
      this.saveState();
    }
  }

  setupNewQuiz() {
    this.initialElapsedTime = 0;
    this.elapsedTime = 0;
    this.startTime = new Date().getTime();
    this.isPaused = false;
    this.isSubmitted = false;
    this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
    this.remainingSeconds = this.initialTimeLimit;

    localStorage.setItem(`${this.quizId}_remaining_time`, this.remainingSeconds);
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
      if (!this.isPaused && !this.isSubmitted) {
        const currentTime = new Date().getTime();
        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);

        this.elapsedTime = this.initialElapsedTime + elapsedSeconds;
        this.remainingSeconds = Math.max(0, this.initialTimeLimit - this.elapsedTime);

        if (this.elapsedTime % 10 === 0) {
          this.saveState();
        }

        this.updateDisplay();

        if (this.remainingSeconds <= 0) {
          this.clearTimers();
          alert('Đã hết thời gian làm bài. Bài làm của bạn sẽ được nộp tự động.');
          this.autoSubmit();
        }
      }
    }, 1000);

    this.updateDisplay();
  }

  clearTimers() {
    if (this.interval) {
      clearInterval(this.interval);
    }
    if (this.saveInterval) {
      clearInterval(this.saveInterval);
    }
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

    this.timeSpentTarget.value = this.elapsedTime;
    if (this.remainingSeconds <= 60) {
      this.displayTarget.classList.add('text-red-500');
      this.displayTarget.classList.add('animate-pulse');
    } else {
      this.displayTarget.classList.remove('text-red-500');
      this.displayTarget.classList.remove('animate-pulse');
    }

    if (this.isPaused) {
      this.displayTarget.classList.add('text-yellow-500');
    } else {
      this.displayTarget.classList.remove('text-yellow-500');
    }
  }

  setupFormListeners() {
    window.addEventListener('beforeunload', (e) => {
      if (!this.isSubmitted) {
        this.saveState();
        const message = 'Bạn có chắc muốn rời khỏi? Tiến trình làm bài sẽ được lưu lại.';
        e.returnValue = message;
        return message;
      }
    });
  }

  updateAnsweredQuestions() {
    const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked');
    this.progressTarget.textContent = radioGroups.length;

    const progressPercent = (radioGroups.length / this.totalQuestionsValue) * 100;
    this.progressBarTarget.style.width = `${progressPercent}%`;
  }

  submitForm() {
    if (this.isSubmitted) {
      alert('Bài làm của bạn đã được nộp.');
      return;
    }

    let totalElapsedTime = this.initialElapsedTime;
    if (!this.isPaused) {
      const currentTime = new Date().getTime();
      const additionalSeconds = Math.floor((currentTime - this.startTime) / 1000);
      totalElapsedTime += additionalSeconds;
    }

    this.timeSpentTarget.value = totalElapsedTime;

    const answeredQuestions = parseInt(this.progressTarget.textContent, 10);

    const confirmSubmit = () => {
      this.isSubmitted = true;
      localStorage.setItem(`quiz_${this.quizId}_submitted`, 'true');
      localStorage.removeItem(`${this.quizId}_remaining_time`);

      if (this.modeValue === 'exam') {
        localStorage.setItem(`quiz_${this.quizId}_submit_time`, new Date().getTime().toString());
      }

      this.clearState();

      const submitNotification = document.createElement('div');
      submitNotification.className = 'fixed top-0 left-0 w-full bg-green-600 text-white text-center py-2 z-50';
      submitNotification.textContent = 'Đang nộp bài...';
      document.body.appendChild(submitNotification);

      setTimeout(() => {
        this.formTarget.submit();
      }, 500);
    };

    if (answeredQuestions < this.totalQuestionsValue) {
      if (this.modeValue === 'exam') {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
          confirmSubmit();
        }
      } else {
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
          confirmSubmit();
        }
      }
    } else {
      confirmSubmit();
    }
  }

  autoSubmit() {
    if (this.isSubmitted) {
      return;
    }

    let totalElapsedTime = this.initialTimeLimit;
    this.timeSpentTarget.value = totalElapsedTime;

    this.isSubmitted = true;
    localStorage.setItem(`quiz_${this.quizId}_submitted`, 'true');
    localStorage.removeItem(`${this.quizId}_remaining_time`);

    if (this.modeValue === 'exam') {
      localStorage.setItem(`quiz_${this.quizId}_submit_time`, new Date().getTime().toString());
    }

    this.clearState();

    const submitNotification = document.createElement('div');
    submitNotification.className = 'fixed top-0 left-0 w-full bg-red-600 text-white text-center py-2 z-50';
    submitNotification.textContent = 'Đã hết thời gian làm bài. Đang nộp bài...';
    document.body.appendChild(submitNotification);

    setTimeout(() => {
      this.formTarget.submit();
    }, 1000);
  }

  togglePause() {
    if (this.modeValue !== 'exam') {
      const currentTime = new Date().getTime();

      if (!this.isPaused) {
        this.isPaused = true;

        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);
        this.initialElapsedTime += elapsedSeconds;

        this.lastPauseTime = currentTime;

        this.pauseBtnTarget.classList.add('hidden');
        this.resumeBtnTarget.classList.remove('hidden');
        this.displayTarget.classList.add('text-yellow-500');
      } else {
        this.isPaused = false;

        if (this.lastPauseTime) {
          const pauseDuration = Math.floor((currentTime - this.lastPauseTime) / 1000);
          this.totalPausedTime = (this.totalPausedTime || 0) + pauseDuration;
        }

        this.startTime = currentTime;
        this.lastPauseTime = null;

        this.pauseBtnTarget.classList.remove('hidden');
        this.resumeBtnTarget.classList.add('hidden');
        this.displayTarget.classList.remove('text-yellow-500');
      }

      this.saveState();
    }
  }

  cancel(event) {
    if (!confirm('Bạn có chắc muốn hủy bài làm? Các câu trả lời sẽ không được lưu lại.')) {
      event.preventDefault();
    } else {
      this.clearState();
    }
  }

  saveState() {
    if (!this.storageKey) return;

    try {
      const answers = {};
      this.formTarget.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
        const questionId = radio.name.match(/\[(\w+)\]/)[1];
        answers[questionId] = radio.value;
      });

      let totalElapsedTime = this.initialElapsedTime;
      if (!this.isPaused) {
        const currentTime = new Date().getTime();
        const additionalSeconds = Math.floor((currentTime - this.startTime) / 1000);
        totalElapsedTime += additionalSeconds;
      }

      const state = {
        elapsedTime: totalElapsedTime,
        startTime: this.startTime,
        lastPauseTime: this.lastPauseTime,
        totalPausedTime: this.totalPausedTime || 0,
        answers: answers,
        isPaused: this.isPaused,
        timestamp: new Date().getTime()
      };

      localStorage.setItem(this.storageKey, JSON.stringify(state));

      this.updateAnsweredQuestions();
    } catch (error) {
      console.error('Lỗi khi lưu trạng thái:', error);
    }
  }

  loadState() {
    if (!this.storageKey) return null;

    try {
      const savedData = localStorage.getItem(this.storageKey);
      if (!savedData) return null;

      return JSON.parse(savedData);
    } catch (error) {
      console.error('Lỗi khi tải trạng thái:', error);
      return null;
    }
  }

  clearState() {
    if (this.storageKey) {
      localStorage.removeItem(this.storageKey);
    }
  }

  loadStateAndUpdateUI() {
    const timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
    this.initialTimeLimit = timeLimit;

    const remainingTime = parseInt(localStorage.getItem(`${this.quizId}_remaining_time`), 10);
    if (remainingTime && !isNaN(remainingTime) && remainingTime > 0) {
      this.remainingSeconds = remainingTime;
      this.initialElapsedTime = timeLimit - remainingTime;
      this.elapsedTime = this.initialElapsedTime;
    } else {
      const savedState = this.loadState();
      if (savedState) {
        this.isPaused = savedState.isPaused || false;
        this.initialElapsedTime = savedState.elapsedTime || 0;
        this.elapsedTime = this.initialElapsedTime;
        this.remainingSeconds = Math.max(0, timeLimit - this.elapsedTime);

        if (this.isPaused && this.modeValue !== 'exam') {
          this.updatePauseButtonUI();
        }
      } else {
        this.initialTimeLimit = timeLimit;
        this.remainingSeconds = timeLimit;
        this.initialElapsedTime = 0;
        this.elapsedTime = 0;
        this.isPaused = false;
      }
    }

    this.startTime = new Date().getTime();

    this.startTimer();

    this.loadSavedAnswers();

    this.updateAnsweredQuestions();

    localStorage.setItem(`${this.quizId}_remaining_time`, this.remainingSeconds);
  }

  loadSavedAnswers() {
    const savedState = this.loadState();
    if (!savedState || !savedState.answers) return;

    Object.entries(savedState.answers).forEach(([questionId, optionValue]) => {
      const radioInput = this.formTarget.querySelector(`input[name="answers[${questionId}]"][value="${optionValue}"]`);
      if (radioInput) {
        radioInput.checked = true;
      }
    });
  }

  setupPauseButton() {
    if (this.modeValue !== 'exam') {
      this.pauseBtnTarget.classList.remove('hidden');
      this.resumeBtnTarget.classList.add('hidden');
    } else {
      this.pauseBtnTarget.classList.add('hidden');
      this.resumeBtnTarget.classList.add('hidden');
    }
  }

  updatePauseButtonUI() {
    this.pauseBtnTarget.classList.add('hidden');
    this.resumeBtnTarget.classList.remove('hidden');
    this.displayTarget.classList.add('text-yellow-500');
  }

  checkClearStorage(event) {
    const clearKey = event.detail.fetchResponse.header('X-Clear-Quiz-Storage');
    if (clearKey) {
      localStorage.setItem(`${clearKey}_submitted`, 'true');

      const isExam = event.detail.fetchResponse.header('X-Quiz-Is-Exam');
      if (isExam === 'true') {
        localStorage.setItem(`${clearKey}_submit_time`, new Date().getTime().toString());
      }
    }
  }
}
