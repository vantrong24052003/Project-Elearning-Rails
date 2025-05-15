import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"

export default class extends Controller {
  static values = {
    start: Boolean,
    hasIp: Boolean,
    attemptId: String,
    quizId: String,
    courseId: String
  }

  connect() {
    if (ipAddress && this.attemptIdValue) {
      const ipAddress = this.detectIp();
      this.logIpInfo(ipAddress);
    } else if (this.startValue && !this.hasIpValue) {
      this.detectIp();
    }
  }

  async detectIp() {
    try {
      const response  = QuizApi.getAttemptInfo()
      const data = await response.json()
      console.log("IP Address:", data.ip);

      return data.ip
    } catch (error) {
      console.error("Lỗi khi lấy IP:", error);
      return '::1'
    }
  }

  async logIpInfo(ipAddress) {
    if (!this.attemptIdValue || !this.courseIdValue || !this.quizIdValue) {
      console.error("Thiếu thông tin attempt_id, course_id hoặc quiz_id");
      return;
    }

    try {
      await QuizApi.logAction(
        this.courseIdValue,
        this.quizIdValue,
        this.attemptIdValue,
        'start_quiz',
        {
          client_ip: ipAddress,
          device_info: navigator.userAgent,
        }
      );
      console.log("Đã log IP thành công!");
    } catch (error) {
      console.error("Lỗi khi log IP và device info:", error);
    }
  }
}
