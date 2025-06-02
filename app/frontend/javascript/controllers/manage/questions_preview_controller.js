import { Controller } from "@hotwired/stimulus"
import { Modal } from "tw-elements";
import { QuestionsApi } from "../../services/questions_api";
import { Toast } from "../../services/toast_service";
export default class extends Controller {
  static targets = [
    "courseSelect", "fileInput", "previewContainer", "normalForm",
    "questionsList", "errorContainer", "errorMessage",
    "questionRowTemplate", "emptyStateTemplate", "editModalTemplate"
  ]

  connect() {
    this.questions = [];
    this.editingQuestionIndex = null;
    this.selectedCourseId = null;
    this.modal = null;
  }

  importQuestions(event) {
    event.preventDefault();

    if (!this.fileInputTarget.files || this.fileInputTarget.files.length === 0) {
      Toast.error("Vui lòng chọn file để import");
      return;
    }

    if (!this.courseSelectTarget.value) {
      alert("Vui lòng chọn khóa học trước khi import");
      return;
    }

    const file = this.fileInputTarget.files[0];
    const validExtensions = ['.xlsx', '.xls', '.csv'];
    const fileExtension = '.' + file.name.split('.').pop().toLowerCase();

    if (!validExtensions.includes(fileExtension)) {
      Toast.error("Định dạng file không hỗ trợ. Vui lòng sử dụng Excel (.xlsx, .xls) hoặc CSV (.csv)");
      return;
    }

    this.selectedCourseId = this.courseSelectTarget.value;

    QuestionsApi.previewImport(file, this.selectedCourseId)
      .then(data => {
        if (data.error) {
         Toast.error(data.error);
          return;
        }

        this.questions = data.questions || [];

        if (data.validation_errors && data.validation_errors.length > 0) {
          const errorMessage = `Có ${data.validation_errors.length} lỗi trong file:
            ${data.validation_errors.map(e => e.message).join('; ')}`;
          Toast.warning(errorMessage);
          this.showError(errorMessage);
        } else {
          this.hideError();
        }

        if (this.questions.length === 0) {
          Toast.warning("Không tìm thấy câu hỏi nào trong file Excel");
          return;
        }

        this.renderQuestions();
        this.showPreview();
        Toast.success(`Đã tìm thấy ${this.questions.length} câu hỏi từ file Excel`);
      })
      .catch(error => {
        console.error('Error importing questions:', error);
        Toast.error("Đã xảy ra lỗi khi đọc file. Vui lòng thử lại.");
      });
  }

  renderQuestions() {
    const tbody = this.questionsListTarget;
    tbody.innerHTML = '';

    if (this.questions.length === 0) {
      const emptyRow = this.emptyStateTemplateTarget.content.cloneNode(true);
      tbody.appendChild(emptyRow);
      return;
    }

    this.questions.forEach((question, index) => {
      const row = this.questionRowTemplateTarget.content.cloneNode(true);

      row.querySelector('.question-index').textContent = index + 1;
      row.querySelector('.question-content').textContent = this.truncateText(question.content, 50);
      row.querySelector('.question-option-0').textContent = this.truncateText(question.options["0"], 20);
      row.querySelector('.question-option-1').textContent = this.truncateText(question.options["1"], 20);
      row.querySelector('.question-option-2').textContent = this.truncateText(question.options["2"], 20);
      row.querySelector('.question-option-3').textContent = this.truncateText(question.options["3"], 20);

      const correctOption = parseInt(question.correct_option);
      row.querySelector('.question-correct-option').textContent = ['A', 'B', 'C', 'D'][correctOption];
      row.querySelector('.question-difficulty').textContent = this.formatDifficulty(question.difficulty);
      row.querySelector('.question-topic').textContent = this.formatTopic(question.topic);
      row.querySelector('.question-learning-goal').textContent = this.formatLearningGoal(question.learning_goal);

      const editButton = row.querySelector('.edit-question');
      editButton.setAttribute('data-index', index);
      editButton.addEventListener('click', () => this.openEditModal(index));

      const deleteButton = row.querySelector('.delete-question');
      deleteButton.setAttribute('data-index', index);
      deleteButton.addEventListener('click', () => this.deleteQuestion(index));

      tbody.appendChild(row);
    });
  }

  openEditModal(index) {
    const question = this.questions[index];
    this.editingQuestionIndex = index;

    const modalContainer = document.createElement('div');
    modalContainer.classList.add('modal', 'modal-open');
    modalContainer.id = 'edit-question-modal';

    const modalContent = this.editModalTemplateTarget.content.cloneNode(true);

    const form = modalContent.querySelector('.edit-question-form');
    form.querySelector('[name="content"]').value = question.content;
    form.querySelector('[name="options_0"]').value = question.options["0"];
    form.querySelector('[name="options_1"]').value = question.options["1"];
    form.querySelector('[name="options_2"]').value = question.options["2"];
    form.querySelector('[name="options_3"]').value = question.options["3"];
    form.querySelector('[name="correct_option"]').value = question.correct_option;
    form.querySelector('[name="difficulty"]').value = question.difficulty || 'medium';

    if (form.querySelector('[name="topic"]')) {
      form.querySelector('[name="topic"]').value = question.topic || '';
    }

    if (form.querySelector('[name="explanation"]')) {
      form.querySelector('[name="explanation"]').value = question.explanation || '';
    }

    form.addEventListener('submit', (e) => {
      e.preventDefault();
      this.saveQuestionEdit(form);
    });

    modalContent.querySelector('.cancel-edit').addEventListener('click', () => {
      document.getElementById('edit-question-modal').remove();
      this.editingQuestionIndex = null;
    });

    modalContainer.appendChild(modalContent);
    document.body.appendChild(modalContainer);
    this.modal = new Modal(document.getElementById('edit-question-modal'));
  }

  saveQuestionEdit(form) {
    const updatedQuestion = {
      ...this.questions[this.editingQuestionIndex],
      content: form.querySelector('[name="content"]').value,
      options: {
        "0": form.querySelector('[name="options_0"]').value,
        "1": form.querySelector('[name="options_1"]').value,
        "2": form.querySelector('[name="options_2"]').value,
        "3": form.querySelector('[name="options_3"]').value
      },
      correct_option: form.querySelector('[name="correct_option"]').value,
      difficulty: form.querySelector('[name="difficulty"]').value,
      topic: form.querySelector('[name="topic"]').value,
      learning_goal: form.querySelector('[name="learning_goal"]').value,
      explanation: form.querySelector('[name="explanation"]').value || 'Không có giải thích'
    };

    this.questions[this.editingQuestionIndex] = updatedQuestion;

    this.renderQuestions();

    document.getElementById('edit-question-modal').remove();
    this.editingQuestionIndex = null;

    Toast.success("Câu hỏi đã được cập nhật");
  }

  deleteQuestion(index) {
    if (!confirm('Bạn có chắc chắn muốn xóa câu hỏi này?')) {
      return;
    }

    this.questions.splice(index, 1);
    this.renderQuestions();
    Toast.success("Đã xóa câu hỏi");
  }

  addNewQuestion() {
    const newQuestion = {
      content: 'Nội dung câu hỏi mới',
      options: {
        "0": 'Đáp án A',
        "1": 'Đáp án B',
        "2": 'Đáp án C',
        "3": 'Đáp án D'
      },
      correct_option: 0,
      explanation: 'Giải thích đáp án',
      difficulty: 'medium',
      topic: 'other',
      learning_goal: 'other',
      course_id: this.selectedCourseId,
      status: 'active'
    };

    this.questions.push(newQuestion);
    this.renderQuestions();

    this.openEditModal(this.questions.length - 1);
  }

  saveAllQuestions() {
    if (this.questions.length === 0) {
      Toast.error('Không có câu hỏi nào để lưu');
      return;
    }

    if (!confirm(`Bạn có chắc chắn muốn lưu ${this.questions.length} câu hỏi này vào hệ thống?`)) {
      return;
    }

    QuestionsApi.saveImportedQuestions(this.questions, this.selectedCourseId)
      .then(response => {
        window.location.href = '/manage/questions';
      })
      .catch(error => {
        console.error('Error saving questions:', error);
        Toast.error('Đã xảy ra lỗi khi lưu câu hỏi. Vui lòng thử lại.');
      });
  }

  cancelPreview() {
    this.hidePreview();
    this.questions = [];
  }

  showPreview() {
    this.previewContainerTarget.classList.remove('hidden');
    this.normalFormTarget.classList.add('hidden');
  }

  hidePreview() {
    this.previewContainerTarget.classList.add('hidden');
    this.normalFormTarget.classList.remove('hidden');
  }

  showError(message) {
    this.errorContainerTarget.classList.remove('hidden');
    this.errorMessageTarget.textContent = message;
  }

  hideError() {
    this.errorContainerTarget.classList.add('hidden');
    this.errorMessageTarget.textContent = '';
  }


  truncateText(text, maxLength) {
    if (!text) return '';
    return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
  }

  formatDifficulty(difficulty) {
    const difficultyMap = {
      'easy': 'Dễ',
      'medium': 'Trung bình',
      'hard': 'Khó'
    };
    return difficultyMap[difficulty] || difficulty;
  }

  formatTopic(topic) {
    const topicMap = {
      'math': 'Toán học',
      'physics': 'Vật lý',
      'chemistry': 'Hóa học',
      'biology': 'Sinh học',
      'history': 'Lịch sử',
      'geography': 'Địa lý',
      'literature': 'Văn học',
      'programming': 'Lập trình',
      'other': 'Khác'
    };
    return topicMap[topic] || topic;
  }

  formatLearningGoal(learning_goal) {
    const learningGoalMap = {
      'remember': 'Ghi nhớ',
      'understand': 'Hiểu',
      'apply': 'Áp dụng',
      'analyze': 'Phân tích',
      'create': 'Sáng tạo',
      'other': 'Khác'
    };
    return learningGoalMap[learning_goal] || learning_goal;
  }

  getToastBackgroundColor(type) {
    switch (type) {
      case "success": return "bg-green-500 text-white";
      case "error": return "bg-red-500 text-white";
      case "warning": return "bg-yellow-500 text-white";
      default: return "bg-blue-500 text-white";
    }
  }

  createQuiz(event) {
    event.preventDefault();

    if (this.questions.length === 0) {
      Toast.error("Không có câu hỏi nào để tạo bài kiểm tra");
      return;
    }

    const questionsCopy = this.questions.map((q, index) => ({
      ...q,
      id: q.id || `preview-${index}`,
      preview_id: `preview-${index}`
    }));

    sessionStorage.setItem('preview_questions_data', JSON.stringify(questionsCopy));
    window.location.href = '/manage/quizzes/new';
  }
}
