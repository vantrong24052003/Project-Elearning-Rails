import { ApiService } from './api_service';

export class QuizApi {
  static async checkQuizStatus(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_statuses`);
  }

  static async logAction(courseId, quizId, attemptId, actionType) {
    return ApiService.put(
      `/dashboard/courses/${courseId}/quiz_statuses/${attemptId}`,
      {
        quiz_id: quizId,
        action_type: actionType,
        timestamp: new Date().toISOString()
      }
    );
  }

  static async updateBehaviorCounts(courseId, quizId, attemptId, counts) {
    return ApiService.put(
      `/dashboard/courses/${courseId}/quiz_statuses/${attemptId}`,
      {
        quiz_id: quizId,
        behavior_counts: {
          tab_switch_count: counts.tabSwitchCount,
          copy_paste_count: counts.copyPasteCount,
          screenshot_count: counts.screenshotCount,
          right_click_count: counts.rightClickCount,
          devtools_open_count: counts.devtoolsOpenCount,
          other_unusual_actions: counts.otherUnusualCount
        }
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
    return ApiService.put(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}`,
      {
        quiz_attempt: {
          answers,
          time_spent: timeSpent
        }
      }
    );
  }

  static async saveAttemptState(courseId, quizId, attemptId, data) {
    return ApiService.put(
      `/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}`,
      {
        quiz_attempt: data
      }
    );
  }

  static async getInProgressAttempts(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_statuses`);
  }

  static async getAttemptState(courseId, quizId, attemptId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}`);
  }
}
