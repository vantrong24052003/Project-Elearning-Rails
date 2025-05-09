import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateContinueButtons();
    this.updateStartButtons();

    this.updateInterval = setInterval(() => {
      this.updateContinueButtons();
      this.updateStartButtons();
    }, 2000);
  }

  disconnect() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
    }
  }

  updateContinueButtons() {
    const continueButtons = document.querySelectorAll('.quiz-continue-btn');

    continueButtons.forEach(button => {
      const quizId = button.dataset.quizId;
      if (!quizId) return;

      const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';
      const quizState = localStorage.getItem(`quiz_state_${quizId}`);

      if (isSubmitted) {
        button.querySelector('span').textContent = 'Làm lại bài';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?force=true`);
        }
      } else if (quizState) {
        button.querySelector('span').textContent = 'Tiếp tục làm';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?continue=true`);
        }
      } else {
        button.querySelector('span').textContent = 'Làm lại bài';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?force=true`);
        }
      }
    });

    const startButtons = document.querySelectorAll('.quiz-action-text');
    startButtons.forEach(textElement => {
      if (!textElement) return;

      const link = textElement.closest('a');
      if (!link) return;

      const quizId = link.dataset.quizId;
      if (!quizId) return;

      const storageKey = `quiz_state_${quizId}`;
      const savedData = localStorage.getItem(storageKey);

      if (savedData) {
        textElement.textContent = 'Tiếp tục làm bài';
        const currentHref = link.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          link.setAttribute('href', `${baseUrl}?continue=true`);
        }
      }
    });
  }

  updateStartButtons() {
    const startButtons = document.querySelectorAll('.quiz-start-btn');

    startButtons.forEach(link => {
      const quizId = link.dataset.quizId;
      if (!quizId) return;

      const storageKey = `quiz_state_${quizId}`;
      const savedData = localStorage.getItem(storageKey);

      if (savedData) {
        const textElement = link.querySelector('.quiz-action-text');
        if (textElement) {
          textElement.textContent = 'Tiếp tục làm bài';
        }

        const currentHref = link.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          link.setAttribute('href', `${baseUrl}?continue=true`);
        }
      } else {
        const currentHref = link.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          link.setAttribute('href', `${baseUrl}?start=true`);
        }
      }
    });
  }
}
