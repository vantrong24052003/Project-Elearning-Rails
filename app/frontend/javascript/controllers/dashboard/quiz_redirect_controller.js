import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    mode: String
  }

  connect() {
    // Lấy quiz ID từ URL
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    if (!quizId) return;
    
    // Lấy tham số URL
    const urlParams = new URLSearchParams(window.location.search);
    const forceRetake = urlParams.get('force') === 'true';
    
    // Nếu đang làm lại bài (có force=true), không cần kiểm tra
    if (forceRetake) return;
    
    // Kiểm tra xem đã nộp bài chưa
    this.checkIfAlreadySubmitted(quizId);
  }
  
  // Kiểm tra nếu bài kiểm tra này đã được nộp
  checkIfAlreadySubmitted(quizId) {
    // Kiểm tra xem bài này đã được nộp chưa
    const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';
    
    if (isSubmitted) {
      this.redirectToQuizList('Bài làm của bạn đã được nộp. Vui lòng sử dụng nút "Làm lại bài" nếu muốn làm lại.');
      return true;
    }
    
    return false;
  }
  
  // Chuyển hướng về trang danh sách bài kiểm tra
  redirectToQuizList(message) {
    if (message) {
      alert(message);
    }
    
    // Lấy đường dẫn trở về trang danh sách bài kiểm tra
    const currentPath = window.location.pathname;
    const redirectPath = currentPath.replace(/\/quizzes\/[^\/]+/, '/quizzes');
    
    // Chuyển hướng
    window.location.href = redirectPath;
  }
  
  // Sự kiện khi người dùng nhấn nút Back
  handleBackButton(event) {
    event.preventDefault();
    
    // Lấy quiz ID từ URL
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    if (!quizId) return;
    
    // Kiểm tra đã nộp bài chưa
    const isSubmitted = localStorage.getItem(`quiz_${quizId}_submitted`) === 'true';
    
    if (isSubmitted) {
      this.redirectToQuizList();
    } else if (confirm('Bạn có chắc muốn quay lại? Tiến trình làm bài của bạn sẽ được lưu lại.')) {
      this.redirectToQuizList();
    } else {
      // Nếu không muốn quay lại, push lại history
      history.pushState(null, null, location.href);
    }
  }
} 
