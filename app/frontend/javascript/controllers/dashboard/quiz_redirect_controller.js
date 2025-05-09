import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    mode: String
  }

  connect() {
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    if (!quizId) return;

    const urlParams = new URLSearchParams(window.location.search);
    const forceRetake = urlParams.get('force') === 'true';

    if (forceRetake) return;

    this.checkIfAlreadySubmitted(quizId);
  }

  checkIfAlreadySubmitted(quizId) {
    const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';

    if (isSubmitted) {
      this.redirectToQuizList('Bài làm của bạn đã được nộp. Vui lòng sử dụng nút "Làm lại bài" nếu muốn làm lại.');
      return true;
    }

    return false;
  }

  redirectToQuizList(message) {
    if (message) {
      alert(message);
    }

    const currentPath = window.location.pathname;
    const redirectPath = currentPath.replace(/\/quizzes\/[^\/]+/, '/quizzes');

    window.location.href = redirectPath;
  }

  handleBackButton(event) {
    event.preventDefault();

    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    if (!quizId) return;

    const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';

    if (isSubmitted) {
      this.redirectToQuizList();
    } else if (confirm('Bạn có chắc muốn quay lại? Tiến trình làm bài của bạn sẽ được lưu lại.')) {
      this.redirectToQuizList();
    } else {
      history.pushState(null, null, location.href);
    }
  }
}
