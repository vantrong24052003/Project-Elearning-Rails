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
    this.flaggedQuestions = new Set();
    this.answeredQuestions = new Set();
    this.checkAnsweredQuestions();
    this.updateNavigation();
    this.updateFlagButton();
    document.addEventListener('change', this.handleAnswerChange.bind(this));
  }

  disconnect() {
    document.removeEventListener('change', this.handleAnswerChange.bind(this));
  }

  handleAnswerChange(event) {
    if (event.target.type === 'radio' && event.target.name.startsWith('answers')) {
      const currentQuestion = this.getCurrentQuestion();
      const questionId = currentQuestion.dataset.questionId;
      this.answeredQuestions.add(questionId);
      this.updateNavigation();
    }
  }

  checkAnsweredQuestions() {
    document.querySelectorAll('input[type="radio"]:checked').forEach(input => {
      if (input.name.startsWith('answers')) {
        const match = input.name.match(/answers\[(\d+)\]/);
        if (match && match[1]) {
          this.answeredQuestions.add(match[1]);
        }
      }
    });
  }

  flagCurrentQuestion() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;

    if (this.flaggedQuestions.has(questionId)) {
      this.flaggedQuestions.delete(questionId);
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700', 'dark:bg-gray-700', 'dark:text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    } else {
      this.flaggedQuestions.add(questionId);
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700', 'dark:bg-gray-700', 'dark:text-white');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    }

    this.updateNavigation();
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
    this.dispatch('questionChanged', { detail: { index: index } });
  }

  getCurrentQuestion() {
    return this.questionContainerTargets[this.currentQuestionValue];
  }

  updateFlagButton() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;

    if (this.flaggedQuestions.has(questionId)) {
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700', 'dark:bg-gray-700', 'dark:text-white');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    } else {
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700', 'dark:bg-gray-700', 'dark:text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    }
  }

  updateNavigation() {
    this.questionNavItemTargets.forEach((item) => {
      const questionId = item.dataset.questionId;

      item.classList.remove('bg-gray-500', 'bg-green-500', 'bg-yellow-500');

      if (this.flaggedQuestions.has(questionId)) {
        item.classList.add('bg-yellow-500');
      } else if (this.answeredQuestions.has(questionId)) {
        item.classList.add('bg-green-500');
      } else {
        item.classList.add('bg-gray-500');
      }

      if (parseInt(item.dataset.index) === this.currentQuestionValue) {
        item.classList.add('ring-2', 'ring-white');
      } else {
        item.classList.remove('ring-2', 'ring-white');
      }
    });
  }
}
