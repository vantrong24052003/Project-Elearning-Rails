import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateContinueButtons();
    this.updateStartButtons();
    
    // Cập nhật định kỳ để hiển thị đúng trạng thái nút làm bài
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
        // Bài làm đã nộp, chuyển thành "Làm lại bài"
        button.querySelector('span').textContent = 'Làm lại bài';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          // Xóa tất cả query params hiện tại và thêm force=true
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?force=true`);
        }
      } else if (quizState) {
        // Có tiến trình đang làm, giữ là "Tiếp tục làm"
        button.querySelector('span').textContent = 'Tiếp tục làm';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          // Xóa tất cả query params hiện tại và thêm continue=true
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?continue=true`);
        }
      } else {
        // Không có tiến trình, chuyển thành "Làm lại bài"
        button.querySelector('span').textContent = 'Làm lại bài';
        const currentHref = button.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          button.setAttribute('href', `${baseUrl}?force=true`);
        }
      }
    });
    
    // Cập nhật nút "Bắt đầu làm bài" nếu có tiến trình lưu
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
          // Xóa tất cả query params hiện tại và thêm continue=true
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
        // Nếu có tiến trình dở dang, đổi thành "Tiếp tục làm bài"
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
        // Nếu không có tiến trình, đảm bảo có tham số start=true
        const currentHref = link.getAttribute('href');
        if (currentHref) {
          const baseUrl = currentHref.split('?')[0];
          link.setAttribute('href', `${baseUrl}?start=true`);
        }
      }
    });
  }
}
