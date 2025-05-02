import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkInProgressQuizzes();
  }

  checkInProgressQuizzes() {
    const quizLinks = document.querySelectorAll('a[data-quiz-id]');

    quizLinks.forEach(link => {
      const quizId = link.dataset.quizId;
      const storageKey = `quiz_${quizId}`;
      const quizType = link.dataset.quizType || '';

      const isSubmitted = localStorage.getItem(`${storageKey}_submitted`) === 'true';

      const savedData = sessionStorage.getItem(storageKey);

      const textElement = link.querySelector('.quiz-action-text');
      if (!textElement) return;

      if (isSubmitted) {
        if (quizType !== 'exam') {
          textElement.textContent = 'Làm lại bài';

          const currentHref = link.getAttribute('href');
          if (currentHref && !currentHref.includes('force=true')) {
            link.setAttribute('href', `${currentHref}?force=true`);
          }
        }
      } else if (savedData) {
        textElement.textContent = 'Tiếp tục làm bài';
        const currentHref = link.getAttribute('href');
        if (currentHref && currentHref.includes('force=true')) {
          link.setAttribute('href', currentHref.replace('?force=true', ''));
        }
      }
    });
  }
}
