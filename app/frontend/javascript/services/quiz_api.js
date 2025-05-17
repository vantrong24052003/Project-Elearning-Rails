import { ApiService } from './api_service';

export class QuizApi {
  static async checkQuizStatus(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_statuses`);
  }

  static async generateQuestions(title, description, numQuestions, difficulty) {
    try {
      return await ApiService.post('/manage/quizzes.json', {
        title,
        description,
        num_questions: numQuestions,
        difficulty: difficulty || 'medium'
      });
    } catch (error) {
      console.error('API Error - generateQuestions:', error.message);
      throw error;
    }
  }

  static async logAction(courseId, quizId, attemptId, actionType, extraData = {}) {
    return ApiService.put(
      `/dashboard/courses/${courseId}/quiz_statuses/${attemptId}`,
      {
        quiz_id: quizId,
        action_type: actionType,
        timestamp: new Date().toISOString(),
        client_ip: extraData.client_ip,
        details: extraData.details || null
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
    let clientIp = "0.0.0.0";
    try {
      const ipData = await this.getIpAddress();
      if (ipData && ipData.ip) {
        clientIp = ipData.ip;
      }
    } catch (error) {
      console.error("Error getting IP for saveAttemptState:", error);
    }

    return ApiService.put(
      `/dashboard/courses/${courseId}/quiz_statuses/${attemptId}`,
      {
        quiz_id: quizId,
        client_ip: clientIp,
        state_data: {
          current_question: data.current_question,
          elapsed_time: data.elapsed_time,
          answers: data.answers
        }
      }
    );
  }

  static async getInProgressAttempts(courseId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quiz_statuses`);
  }

  static async getAttemptState(courseId, quizId, attemptId) {
    return ApiService.get(`/dashboard/courses/${courseId}/quizzes/${quizId}/quiz_attempts/${attemptId}`);
  }

  static async getIpAddress() {
    try {
      const response = await fetch('https://api.ipify.org?format=json', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
        mode: 'cors',
        cache: 'no-cache',
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error("Error fetching IP address:", error);
      return { ip: "0.0.0.0" };
    }
  }

  static async getLocalIpAddress(courseId) {
    try {
      return ApiService.get(`/dashboard/courses/${courseId}/quiz_statuses/get_ip`);
    } catch (error) {
      console.error("Error fetching local IP address:", error);
      return { ip: "0.0.0.0" };
    }
  }
}
