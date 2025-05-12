import { ApiService } from './api_service';

export class QuizApi {
  static async checkQuizStatus(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_attempts/in_progress`);
  }

  static async logAction(courseId, quizId, attemptId, actionType) {
    return ApiService.post(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}/log_action`,
      {
        action_type: actionType,
        timestamp: new Date().toISOString()
      }
    );
  }

  static async updateBehaviorCounts(courseId, quizId, attemptId, counts) {
    return ApiService.post(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}/update_behavior_counts`,
      {
        tab_switch_count: counts.tabSwitchCount,
        copy_paste_count: counts.copyPasteCount,
        screenshot_count: counts.screenshotCount,
        right_click_count: counts.rightClickCount,
        devtools_open_count: counts.devtoolsOpenCount,
        other_unusual_actions: counts.otherUnusualCount
      }
    );
  }

  static async getQuestions(courseId, quizId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}/questions`);
  }

  static async getQuizInfo(courseId, quizId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}`);
  }

  static async getAttemptInfo(courseId, quizId, attemptId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}`);
  }

  static async createAttempt(courseId, quizId) {
    return ApiService.post(`/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts`);
  }

  static async submitAttempt(courseId, quizId, attemptId, answers, timeSpent) {
    return ApiService.post(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}/submit`,
      {
        answers,
        time_spent: timeSpent
      }
    );
  }

  static async saveAttemptState(courseId, quizId, attemptId, data) {
    return ApiService.put(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}/save_state`,
      data
    );
  }

  static async getInProgressAttempts(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_attempts/in_progress`);
  }

  static async getAttemptState(courseId, quizId, attemptId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}/state`);
  }
}
