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
    // Lấy quiz ID từ URL
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    this.quizId = quizIdMatch ? quizIdMatch[1] : null;
    this.storageKey = this.quizId ? `quiz_flag_${this.quizId}` : null;
    
    // Khởi tạo danh sách câu hỏi đã đánh dấu
    this.flaggedQuestions = new Set();
    
    // Tải trạng thái đánh dấu từ storage
    this.loadFlaggedState();
    
    // Cập nhật hiển thị đánh dấu ban đầu
    this.updateNavigation();
    this.updateFlagButton();
  }
  
  disconnect() {
    this.saveFlaggedState();
  }
  
  // Xử lý đánh dấu câu hỏi hiện tại
  flagCurrentQuestion() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;

    if (this.flaggedQuestions.has(questionId)) {
      // Bỏ đánh dấu
      this.flaggedQuestions.delete(questionId);
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    } else {
      // Đánh dấu
      this.flaggedQuestions.add(questionId);
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    }

    this.updateNavigation();
    this.saveFlaggedState();
  }
  
  // Chuyển đến câu hỏi được chọn
  goToQuestion(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.showQuestion(index);
  }
  
  // Đi đến câu hỏi trước
  prevQuestion() {
    if (this.currentQuestionValue > 0) {
      this.showQuestion(this.currentQuestionValue - 1);
    }
  }
  
  // Đi đến câu hỏi tiếp theo
  nextQuestion() {
    if (this.currentQuestionValue < this.questionContainerTargets.length - 1) {
      this.showQuestion(this.currentQuestionValue + 1);
    }
  }
  
  // Hiển thị câu hỏi theo index
  showQuestion(index) {
    // Ẩn tất cả các câu hỏi
    this.questionContainerTargets.forEach(container => {
      container.classList.add('hidden');
    });

    // Đảm bảo index hợp lệ
    if (index < 0) {
      index = 0;
    } else if (index >= this.questionContainerTargets.length) {
      index = this.questionContainerTargets.length - 1;
    }

    // Cập nhật câu hỏi hiện tại
    this.currentQuestionValue = index;
    const currentQuestion = this.getCurrentQuestion();
    currentQuestion.classList.remove('hidden');

    // Cập nhật số hiển thị
    this.currentQuestionDisplayTarget.textContent = (index + 1);

    // Cập nhật nút đánh dấu
    this.updateFlagButton();
    
    // Cập nhật navigation
    this.updateNavigation();
    
    // Lưu trạng thái
    this.saveFlaggedState();
    
    // Gửi event để quiz_timer_controller biết câu hỏi đã thay đổi
    this.dispatch('questionChanged', { detail: { index: index } });
  }
  
  // Lấy câu hỏi hiện tại
  getCurrentQuestion() {
    return this.questionContainerTargets[this.currentQuestionValue];
  }
  
  // Cập nhật trạng thái nút đánh dấu dựa trên câu hỏi hiện tại
  updateFlagButton() {
    const currentQuestion = this.getCurrentQuestion();
    const questionId = currentQuestion.dataset.questionId;
    
    if (this.flaggedQuestions.has(questionId)) {
      // Câu hỏi đã được đánh dấu
      this.flagBtnTarget.classList.remove('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.classList.add('bg-yellow-500', 'text-white');
      this.flagBtnTarget.querySelector('span').textContent = 'Bỏ đánh dấu';
    } else {
      // Câu hỏi chưa được đánh dấu
      this.flagBtnTarget.classList.remove('bg-yellow-500', 'text-white');
      this.flagBtnTarget.classList.add('bg-gray-200', 'text-gray-700');
      this.flagBtnTarget.querySelector('span').textContent = 'Đánh dấu';
    }
  }
  
  // Cập nhật hiển thị các nút điều hướng câu hỏi
  updateNavigation() {
    this.questionNavItemTargets.forEach((item, index) => {
      const questionId = item.dataset.questionId;
      
      // Kiểm tra câu hỏi đã được trả lời chưa (bằng cách kiểm tra class của item)
      const isAnswered = item.classList.contains('bg-green-500');
      
      // Kiểm tra câu hỏi đã được đánh dấu chưa
      const isFlagged = this.flaggedQuestions.has(questionId);
      
      // Cập nhật hiển thị
      if (isFlagged) {
        item.classList.remove('bg-gray-500', 'bg-green-500');
        item.classList.add('bg-yellow-500');
      } else if (!isAnswered) {
        item.classList.remove('bg-yellow-500', 'bg-green-500');
        item.classList.add('bg-gray-500');
      }
      
      // Đánh dấu câu hỏi hiện tại
      if (index === this.currentQuestionValue) {
        item.classList.add('ring-2', 'ring-white');
      } else {
        item.classList.remove('ring-2', 'ring-white');
      }
    });
  }
  
  // Lưu trạng thái đánh dấu vào localStorage
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
  
  // Tải trạng thái đánh dấu từ localStorage
  loadFlaggedState() {
    if (!this.storageKey) return;
    
    try {
      const savedData = localStorage.getItem(this.storageKey);
      if (!savedData) return;
      
      const state = JSON.parse(savedData);
      
      // Khôi phục câu hỏi hiện tại
      if (state.currentQuestion !== undefined) {
        this.currentQuestionValue = state.currentQuestion;
      }
      
      // Khôi phục danh sách câu hỏi đã đánh dấu
      if (state.flaggedQuestions && Array.isArray(state.flaggedQuestions)) {
        this.flaggedQuestions = new Set(state.flaggedQuestions);
      }
    } catch (error) {
      console.error('Lỗi khi tải trạng thái đánh dấu:', error);
    }
  }
  
  // Xóa trạng thái đánh dấu
  clearFlaggedState() {
    if (this.storageKey) {
      localStorage.removeItem(this.storageKey);
    }
  }
} 
