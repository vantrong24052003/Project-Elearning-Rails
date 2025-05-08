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
    // Lấy quiz ID từ URL
    const quizIdMatch = location.pathname.match(/\/quizzes\/([^\/]+)/);
    const quizId = quizIdMatch ? quizIdMatch[1] : null;
    this.quizId = quizId;
    this.storageKey = quizId ? `quiz_timer_${quizId}` : null;
    
    // Các biến trạng thái
    this.isPaused = false;
    this.isSubmitted = false;
    
    // Lắng nghe sự kiện turbo:before-render
    document.addEventListener('turbo:before-render', this.checkClearStorage.bind(this));
    
    // Lắng nghe sự kiện pageshow
    window.addEventListener('pageshow', this.handlePageShow.bind(this));
    
    // Lấy tham số URL
    const urlParams = new URLSearchParams(window.location.search);
    const forceRetake = urlParams.get('force') === 'true';
    const continueParam = urlParams.get('continue') === 'true';

    if (quizId) {
      if (forceRetake) {
        // Nếu làm lại bài (force=true), xóa trạng thái đã nộp và trạng thái làm bài
        localStorage.removeItem(`quiz_${quizId}_submitted`);
        localStorage.removeItem(`${quizId}_remaining_time`);
        this.clearState();
        this.setupNewQuiz();
      } else if (continueParam) {
        // Nếu tiếp tục làm (continue=true), kiểm tra thời gian còn lại
        const remainingTime = parseInt(localStorage.getItem(`${quizId}_remaining_time`), 10);
        if (remainingTime && !isNaN(remainingTime)) {
          // Nếu có thời gian còn lại, sử dụng nó
          this.remainingSeconds = remainingTime;
          this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
          this.initialElapsedTime = this.initialTimeLimit - this.remainingSeconds;
          this.elapsedTime = this.initialElapsedTime;
        } else {
          // Nếu không có thời gian còn lại, kiểm tra trạng thái đã lưu
          const savedState = this.loadState();
          if (!savedState) {
            // Nếu không có trạng thái lưu, bắt đầu làm mới
            this.setupNewQuiz();
          }
        }
      } else {
        // Trường hợp bình thường, kiểm tra còn thời gian
        const remainingTime = parseInt(localStorage.getItem(`${quizId}_remaining_time`), 10);
        if (remainingTime && !isNaN(remainingTime)) {
          // Nếu có thời gian còn lại, sử dụng nó
          this.remainingSeconds = remainingTime;
          this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
          this.initialElapsedTime = this.initialTimeLimit - this.remainingSeconds;
          this.elapsedTime = this.initialElapsedTime;
        } else {
          // Kiểm tra trạng thái lưu
          const savedState = this.loadState();
          if (!savedState) {
            // Không có trạng thái, bắt đầu làm mới
            this.setupNewQuiz();
          }
        }
      }
    }

    // Thiết lập nút tạm dừng
    this.setupPauseButton();
    
    // Tải trạng thái và cập nhật UI
    this.loadStateAndUpdateUI();
    
    // Thiết lập các trình nghe sự kiện
    this.setupFormListeners();
  }

  // Xử lý khi trang được hiển thị lại (ví dụ: sau khi quay lại từ trang khác)
  handlePageShow(event) {
    if (event.persisted || document.hidden === false) {
      // Cập nhật UI khi quay lại trang
      this.loadStateAndUpdateUI();
    }
  }

  // Xóa các timer đang chạy
  disconnect() {
    this.clearTimers();
    document.removeEventListener('turbo:before-render', this.checkClearStorage.bind(this));
    window.removeEventListener('pageshow', this.handlePageShow.bind(this));
    
    // Lưu trạng thái trước khi rời khỏi
    if (!this.isSubmitted) {
      this.saveState();
    }
  }

  // Thiết lập quiz mới
  setupNewQuiz() {
    this.initialElapsedTime = 0;
    this.elapsedTime = 0;
    this.startTime = new Date().getTime();
    this.isPaused = false;
    this.isSubmitted = false;
    this.initialTimeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
    this.remainingSeconds = this.initialTimeLimit;

    // Lưu thời gian còn lại vào localStorage
    localStorage.setItem(`${this.quizId}_remaining_time`, this.remainingSeconds);
  }

  // Bắt đầu đếm thời gian
  startTimer() {
    // Xóa các timers hiện tại nếu có
    this.clearTimers();
    
    // Đảm bảo startTime được thiết lập
    if (!this.startTime) {
      this.startTime = new Date().getTime();
    }

    // Lưu thời gian còn lại vào localStorage mỗi 2 giây
    this.saveInterval = setInterval(() => {
      if (!this.isPaused && !this.isSubmitted) {
        const currentTime = new Date().getTime();
        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);
        const totalElapsedTime = this.initialElapsedTime + elapsedSeconds;
        const remainingSeconds = Math.max(0, this.initialTimeLimit - totalElapsedTime);
        
        localStorage.setItem(`${this.quizId}_remaining_time`, remainingSeconds);
      }
    }, 2000);

    // Cập nhật đồng hồ đếm ngược mỗi giây
    this.interval = setInterval(() => {
      if (!this.isPaused && !this.isSubmitted) {
        // Tính toán thời gian đã trôi qua
        const currentTime = new Date().getTime();
        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);

        this.elapsedTime = this.initialElapsedTime + elapsedSeconds;
        this.remainingSeconds = Math.max(0, this.initialTimeLimit - this.elapsedTime);

        // Lưu trạng thái định kỳ
        if (this.elapsedTime % 10 === 0) {
          this.saveState();
        }

        // Cập nhật hiển thị
        this.updateDisplay();

        // Tự động nộp bài khi hết thời gian
        if (this.remainingSeconds <= 0) {
          this.clearTimers();
          alert('Đã hết thời gian làm bài. Bài làm của bạn sẽ được nộp tự động.');
          this.autoSubmit();
        }
      }
    }, 1000);
    
    // Cập nhật hiển thị ban đầu
    this.updateDisplay();
  }

  // Xóa các timer đang chạy
  clearTimers() {
    if (this.interval) {
      clearInterval(this.interval);
    }
    if (this.saveInterval) {
      clearInterval(this.saveInterval);
    }
  }

  // Cập nhật hiển thị đồng hồ đếm ngược
  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

    // Cập nhật thời gian đã trôi qua cho form
    this.timeSpentTarget.value = this.elapsedTime;

    // Cảnh báo khi gần hết thời gian
    if (this.remainingSeconds <= 60) {
      this.displayTarget.classList.add('text-red-500');
      this.displayTarget.classList.add('animate-pulse');
    } else {
      this.displayTarget.classList.remove('text-red-500');
      this.displayTarget.classList.remove('animate-pulse');
    }

    // Hiển thị trạng thái tạm dừng
    if (this.isPaused) {
      this.displayTarget.classList.add('text-yellow-500');
    } else {
      this.displayTarget.classList.remove('text-yellow-500');
    }
  }

  // Theo dõi sự thay đổi trong form
  setupFormListeners() {
    // Lắng nghe sự kiện beforeunload để cảnh báo khi rời trang
    window.addEventListener('beforeunload', (e) => {
      if (!this.isSubmitted) {
        this.saveState();
        const message = 'Bạn có chắc muốn rời khỏi? Tiến trình làm bài sẽ được lưu lại.';
        e.returnValue = message;
        return message;
      }
    });
  }

  // Cập nhật số câu hỏi đã trả lời
  updateAnsweredQuestions() {
    const radioGroups = this.formTarget.querySelectorAll('input[type="radio"]:checked');
    this.progressTarget.textContent = radioGroups.length;
    
    // Cập nhật thanh tiến độ
    const progressPercent = (radioGroups.length / this.totalQuestionsValue) * 100;
    this.progressBarTarget.style.width = `${progressPercent}%`;
  }

  // Nộp bài
  submitForm() {
    if (this.isSubmitted) {
      alert('Bài làm của bạn đã được nộp.');
      return;
    }

    // Tính toán thời gian đã trôi qua chính xác
    let totalElapsedTime = this.initialElapsedTime;
    if (!this.isPaused) {
      const currentTime = new Date().getTime();
      const additionalSeconds = Math.floor((currentTime - this.startTime) / 1000);
      totalElapsedTime += additionalSeconds;
    }

    this.timeSpentTarget.value = totalElapsedTime;

    // Đếm số câu hỏi đã trả lời
    const answeredQuestions = parseInt(this.progressTarget.textContent, 10);

    const confirmSubmit = () => {
      // Đánh dấu là đã nộp bài
      this.isSubmitted = true;
      localStorage.setItem(`quiz_${this.quizId}_submitted`, 'true');
      localStorage.removeItem(`${this.quizId}_remaining_time`);
      
      if (this.modeValue === 'exam') {
        localStorage.setItem(`quiz_${this.quizId}_submit_time`, new Date().getTime().toString());
      }
      
      // Xóa trạng thái làm bài
      this.clearState();
      
      // Hiển thị thông báo
      const submitNotification = document.createElement('div');
      submitNotification.className = 'fixed top-0 left-0 w-full bg-green-600 text-white text-center py-2 z-50';
      submitNotification.textContent = 'Đang nộp bài...';
      document.body.appendChild(submitNotification);
      
      // Nộp form sau một chút delay
      setTimeout(() => {
        this.formTarget.submit();
      }, 500);
    };

    // Kiểm tra và xác nhận nộp bài
    if (answeredQuestions < this.totalQuestionsValue) {
      if (this.modeValue === 'exam') {
        // Nếu là bài thi, cảnh báo khi chưa làm hết
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn có chắc muốn nộp bài?`)) {
          confirmSubmit();
        }
      } else {
        // Nếu là bài kiểm tra thông thường
        if (confirm(`Bạn chỉ mới trả lời ${answeredQuestions}/${this.totalQuestionsValue} câu hỏi. Bạn vẫn muốn nộp bài?`)) {
          confirmSubmit();
        }
      }
    } else {
      // Đã trả lời đủ số câu hỏi
      confirmSubmit();
    }
  }

  // Tự động nộp bài khi hết thời gian
  autoSubmit() {
    if (this.isSubmitted) {
      return;
    }

    // Đã hết thời gian, thời gian đã trôi qua = toàn bộ thời gian
    let totalElapsedTime = this.initialTimeLimit;
    this.timeSpentTarget.value = totalElapsedTime;

    // Đánh dấu là đã nộp bài
    this.isSubmitted = true;
    localStorage.setItem(`quiz_${this.quizId}_submitted`, 'true');
    localStorage.removeItem(`${this.quizId}_remaining_time`);
    
    if (this.modeValue === 'exam') {
      localStorage.setItem(`quiz_${this.quizId}_submit_time`, new Date().getTime().toString());
    }
    
    // Xóa trạng thái làm bài
    this.clearState();
    
    // Hiển thị thông báo
    const submitNotification = document.createElement('div');
    submitNotification.className = 'fixed top-0 left-0 w-full bg-red-600 text-white text-center py-2 z-50';
    submitNotification.textContent = 'Đã hết thời gian làm bài. Đang nộp bài...';
    document.body.appendChild(submitNotification);
    
    // Nộp form sau một chút delay
    setTimeout(() => {
      this.formTarget.submit();
    }, 1000);
  }

  // Tạm dừng/tiếp tục làm bài
  togglePause() {
    if (this.modeValue !== 'exam') {
      const currentTime = new Date().getTime();

      if (!this.isPaused) {
        // Tạm dừng làm bài
        this.isPaused = true;

        // Lưu thời gian đã trôi qua
        const elapsedSeconds = Math.floor((currentTime - this.startTime) / 1000);
        this.initialElapsedTime += elapsedSeconds;

        // Lưu thời điểm bắt đầu tạm dừng
        this.lastPauseTime = currentTime;

        // Cập nhật UI
        this.pauseBtnTarget.classList.add('hidden');
        this.resumeBtnTarget.classList.remove('hidden');
        this.displayTarget.classList.add('text-yellow-500');
      } else {
        // Tiếp tục làm bài
        this.isPaused = false;

        // Tính thời gian đã tạm dừng
        if (this.lastPauseTime) {
          const pauseDuration = Math.floor((currentTime - this.lastPauseTime) / 1000);
          this.totalPausedTime = (this.totalPausedTime || 0) + pauseDuration;
        }

        // Đặt lại thời điểm bắt đầu
        this.startTime = currentTime;
        this.lastPauseTime = null;

        // Cập nhật UI
        this.pauseBtnTarget.classList.remove('hidden');
        this.resumeBtnTarget.classList.add('hidden');
        this.displayTarget.classList.remove('text-yellow-500');
      }

      // Lưu trạng thái
      this.saveState();
    }
  }

  // Huỷ bài làm
  cancel(event) {
    if (!confirm('Bạn có chắc muốn hủy bài làm? Các câu trả lời sẽ không được lưu lại.')) {
      event.preventDefault();
    } else {
      this.clearState();
    }
  }

  // Lưu trạng thái
  saveState() {
    if (!this.storageKey) return;

    try {
      // Thu thập đáp án đã chọn
      const answers = {};
      this.formTarget.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
        const questionId = radio.name.match(/\[(\w+)\]/)[1];
        answers[questionId] = radio.value;
      });

      // Tính toán thời gian đã trôi qua
      let totalElapsedTime = this.initialElapsedTime;
      if (!this.isPaused) {
        const currentTime = new Date().getTime();
        const additionalSeconds = Math.floor((currentTime - this.startTime) / 1000);
        totalElapsedTime += additionalSeconds;
      }

      // Tạo đối tượng trạng thái
      const state = {
        elapsedTime: totalElapsedTime,
        startTime: this.startTime,
        lastPauseTime: this.lastPauseTime,
        totalPausedTime: this.totalPausedTime || 0,
        answers: answers,
        isPaused: this.isPaused,
        timestamp: new Date().getTime()
      };

      // Lưu vào localStorage
      localStorage.setItem(this.storageKey, JSON.stringify(state));
      
      // Cập nhật số câu đã trả lời
      this.updateAnsweredQuestions();
    } catch (error) {
      console.error('Lỗi khi lưu trạng thái:', error);
    }
  }

  // Tải trạng thái từ localStorage
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

  // Xóa trạng thái
  clearState() {
    if (this.storageKey) {
      localStorage.removeItem(this.storageKey);
    }
  }

  // Xử lý trạng thái đã lưu và cập nhật UI
  loadStateAndUpdateUI() {
    const timeLimit = parseInt(this.displayTarget.dataset.timeLimit, 10) * 60;
    this.initialTimeLimit = timeLimit;
    
    // Thử khôi phục từ thời gian còn lại trước
    const remainingTime = parseInt(localStorage.getItem(`${this.quizId}_remaining_time`), 10);
    if (remainingTime && !isNaN(remainingTime) && remainingTime > 0) {
      this.remainingSeconds = remainingTime;
      this.initialElapsedTime = timeLimit - remainingTime;
      this.elapsedTime = this.initialElapsedTime;
    } else {
      // Thử khôi phục từ trạng thái đã lưu
      const savedState = this.loadState();
      if (savedState) {
        this.isPaused = savedState.isPaused || false;
        this.initialElapsedTime = savedState.elapsedTime || 0;
        this.elapsedTime = this.initialElapsedTime;
        this.remainingSeconds = Math.max(0, timeLimit - this.elapsedTime);
        
        // Cập nhật UI tạm dừng nếu cần
        if (this.isPaused && this.modeValue !== 'exam') {
          this.updatePauseButtonUI();
        }
      } else {
        // Không có trạng thái nào, thiết lập mới
        this.initialTimeLimit = timeLimit;
        this.remainingSeconds = timeLimit;
        this.initialElapsedTime = 0;
        this.elapsedTime = 0;
        this.isPaused = false;
      }
    }

    // Đặt thời điểm bắt đầu mới
    this.startTime = new Date().getTime();
    
    // Khởi động timer
    this.startTimer();
    
    // Khôi phục đáp án đã chọn
    this.loadSavedAnswers();
    
    // Cập nhật số câu đã trả lời
    this.updateAnsweredQuestions();

    // Lưu thời gian còn lại vào localStorage
    localStorage.setItem(`${this.quizId}_remaining_time`, this.remainingSeconds);
  }

  // Khôi phục đáp án đã lưu
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

  // Thiết lập nút tạm dừng
  setupPauseButton() {
    if (this.modeValue !== 'exam') {
      this.pauseBtnTarget.classList.remove('hidden');
      this.resumeBtnTarget.classList.add('hidden');
    } else {
      this.pauseBtnTarget.classList.add('hidden');
      this.resumeBtnTarget.classList.add('hidden');
    }
  }

  // Cập nhật UI nút tạm dừng
  updatePauseButtonUI() {
    this.pauseBtnTarget.classList.add('hidden');
    this.resumeBtnTarget.classList.remove('hidden');
    this.displayTarget.classList.add('text-yellow-500');
  }

  // Kiểm tra xóa storage từ response header
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
