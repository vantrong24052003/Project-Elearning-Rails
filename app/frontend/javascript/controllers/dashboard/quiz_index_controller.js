import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"

export default class extends Controller {
  connect() {
    this.checkInProgressQuizzes();
  }

  async checkInProgressQuizzes() {
    const quizLinks = document.querySelectorAll('a[data-quiz-id]');
    const courseId = window.location.pathname.match(/\/courses\/([^\/]+)/)?.[1];

    if (!courseId) return;

    try {
      const inProgressAttempts = await QuizApi.checkQuizStatus(courseId);

      quizLinks.forEach(link => {
        const quizId = link.dataset.quizId;
        const quizType = link.dataset.quizType || '';
        const textElement = link.querySelector('.quiz-action-text');

        if (!textElement) return;

        const hasInProgressAttempt = inProgressAttempts.some(attempt =>
          attempt.quiz_id === quizId && attempt.completed_at === null
        );

        const currentHref = link.getAttribute('href');

        if (hasInProgressAttempt) {
          textElement.textContent = 'Tiếp tục làm bài';

          if (currentHref) {
            const url = new URL(currentHref, window.location.origin);
            url.searchParams.set('start', 'true');
            if (url.searchParams.has('force')) {
              url.searchParams.delete('force');
            }
            link.setAttribute('href', url.pathname + url.search);
          }
        } else if (quizType !== 'exam') {
          const hasCompletedAttempt = inProgressAttempts.some(attempt =>
            attempt.quiz_id === quizId && attempt.completed_at !== null
          );

          if (hasCompletedAttempt) {
            textElement.textContent = 'Làm lại bài';

            if (currentHref) {
              const url = new URL(currentHref, window.location.origin);
              url.searchParams.set('force', 'true');
              link.setAttribute('href', url.pathname + url.search);
            }
          }
        }
      });
    } catch (error) {
      console.error('Lỗi khi kiểm tra bài làm đang dở:', error);
    }
  }
}
