import { ApiService } from './api_service';

export class QuestionsApi {
  static async getQuestions(courseId, filters = {}) {
    let url = '/manage/questions.json';
    const params = new URLSearchParams();

    if (courseId) params.append('course_id', courseId);
    if (filters.search) params.append('search', filters.search);
    if (filters.difficulty) params.append('difficulty', filters.difficulty);
    if (filters.topic) params.append('topic', filters.topic);
    if (filters.learning_goal) params.append('learning_goal', filters.learning_goal);
    if (filters.status) params.append('status', filters.status);

    if (params.toString()) {
      url += `?${params.toString()}`;
    }

    return ApiService.get(url);
  }

  static async getQuestion(questionId) {
    return ApiService.get(`/manage/questions/${questionId}.json`);
  }

  static async createQuestion(question) {
    return ApiService.post('/manage/questions.json', { question });
  }

  static async updateQuestion(questionId, question) {
    return ApiService.put(`/manage/questions/${questionId}.json`, { question });
  }

  static async deleteQuestion(questionId) {
    return ApiService.delete(`/manage/questions/${questionId}.json`);
  }

  static async previewImport(file, courseId) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('course_id', courseId);

    return ApiService.post('/manage/questions.json', formData, {
      headers: {
        'Accept': 'application/json'
      }
    });
  }

  static async saveImportedQuestions(questions, courseId) {
    return ApiService.post('/manage/questions.json', {
      preview_questions: JSON.stringify(questions),
      selected_course_id: courseId
    }, {
      headers: {
        'Accept': 'application/json'
      }
    });
  }

  static async exportQuestions(filters = {}) {
    let url = '/manage/questions_export.xlsx';
    const params = new URLSearchParams();

    if (filters.search) params.append('search', filters.search);
    if (filters.course_id) params.append('course_id', filters.course_id);
    if (filters.difficulty) params.append('difficulty', filters.difficulty);
    if (filters.topic) params.append('topic', filters.topic);
    if (filters.learning_goal) params.append('learning_goal', filters.learning_goal);
    if (filters.status) params.append('status', filters.status);

    if (params.toString()) {
      url += `?${params.toString()}`;
    }

    window.location.href = url;

    return Promise.resolve(true);
  }
}
