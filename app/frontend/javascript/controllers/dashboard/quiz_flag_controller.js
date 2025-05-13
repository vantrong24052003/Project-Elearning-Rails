import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "flagBtn", "questionContainer", "questionNav",
    "questionNavItem", "currentQuestionDisplay"
  ]

  static values = {
    totalQuestions: Number,
    currentQuestion: { type: Number, default: 0 }
  }

  connect() {
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    this.quizId = quizIdMatch ? quizIdMatch[1] : null;
    this.storageKey = this.quizId ? `quiz_flag_${this.quizId}` : null;

    this.flaggedQuestions = new Set();

    this.loadFlaggedState();

    this.updateNavigation();
    this.updateFlagButton();
  }

  disconnect() {
    this.saveFlaggedState();
  }

  flagCurrentQuestion() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;

    if (this.flaggedQuestions.has(questionId)) {
      this.flaggedQuestions.delete(questionId);
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    } else {
      this.flaggedQuestions.add(questionId);
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    }

    this.updateNavigation();
    this.saveFlaggedState();
  }

  goToQuestion(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.showQuestion(index);
  }

  prevQuestion() {
    if (this.currentQuestionValue > 0) {
      this.showQuestion(this.currentQuestionValue - 1);
    }
  }

  nextQuestion() {
    if (this.currentQuestionValue < this.questionContainerTargets.length - 1) {
      this.showQuestion(this.currentQuestionValue + 1);
    }
  }

  showQuestion(index) {
    this.questionContainerTargets.forEach(container => {
      container.classList.add('hidden');
    });

    if (index < 0) {
      index = 0;
    } else if (index >= this.questionContainerTargets.length) {
      index = this.questionContainerTargets.length - 1;
    }

    this.currentQuestionValue = index;
    const currentQuestion = this.getCurrentQuestion();
    currentQuestion.classList.remove('hidden');

    this.currentQuestionDisplayTarget.textContent = (index + 1);

    this.updateFlagButton();

    this.updateNavigation();

    this.saveFlaggedState();

    this.dispatch('questionChanged', { detail: { index: index } });
  }

  getCurrentQuestion() {
    return this.questionContainerTargets[this.currentQuestionValue];
  }

  updateFlagButton() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;

    if (this.flaggedQuestions.has(questionId)) {
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    } else {
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    }
  }

  updateNavigation() {
    this.questionNavItemTargets.forEach((item, index) => {
      const questionId = item.dataset.questionId;

      const isAnswered = item.classList.contains('bg-green-500');

      const isFlagged = this.flaggedQuestions.has(questionId);

      if (isFlagged) {
        item.classList.remove('bg-gray-500', 'bg-green-500');
        item.classList.add('bg-yellow-500');
      } else if (!isAnswered) {
        item.classList.remove('bg-yellow-500', 'bg-green-500');
        item.classList.add('bg-gray-500');
      }

      if (index === this.currentQuestionValue) {
        item.classList.add('ring-2', 'ring-white');
      } else {
        item.classList.remove('ring-2', 'ring-white');
      }
    });
  }

  saveFlaggedState() {
    if (!this.storageKey) return;

    try {
      const state = {
        currentQuestion: this.currentQuestionValue,
        flaggedQuestions: Array.from(this.flaggedQuestions),
        timestamp: new Date().getTime()
      };

      localStorage.setItem(this.storageKey, JSON.stringify(state));
    } catch (error) {
      console.error('Lỗi khi lưu trạng thái đánh dấu:', error);
    }
  }

  loadFlaggedState() {
    if (!this.storageKey) return;

    try {
      const savedData = localStorage.getItem(this.storageKey);
      if (!savedData) return;

      const state = JSON.parse(savedData);

      if (state.currentQuestion !== undefined) {
        this.currentQuestionValue = state.currentQuestion;
      }

      if (state.flaggedQuestions && Array.isArray(state.flaggedQuestions)) {
        this.flaggedQuestions = new Set(state.flaggedQuestions);
      }
    } catch (error) {
      console.error('Lỗi khi tải trạng thái đánh dấu:', error);
    }
  }

  clearFlaggedState() {
    if (this.storageKey) {
      localStorage.removeItem(this.storageKey);
    }
  }
}
