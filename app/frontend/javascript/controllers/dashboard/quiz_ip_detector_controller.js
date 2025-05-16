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
    if (this.startValue && !this.hasIpValue) {
      this.detectIp();
    } else if (this.attemptIdValue) {
      this.detectIp().then(ip => {
        if (ip) {
          this.logIpInfo(ip);
        }
      });
    }
  }

  async detectIp() {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      const clientIp = urlParams.get('client_ip');

      if (clientIp) {
        console.log("Using IP from URL:", clientIp);
        return clientIp;
      } else {
        try {
          const ipData = await QuizApi.getIpAddress();
          console.log("IP from API111111111:", ipData);
          return ipData.ip || "0.0.0.0";
        } catch (ipError) {
          console.error("Error getting IP from API:", ipError);
          return "0.0.0.0";
        }
      }
    } catch (error) {
      console.error("Lỗi khi lấy IP:", error);
      return "0.0.0.0";
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
