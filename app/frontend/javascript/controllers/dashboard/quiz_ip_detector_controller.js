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
    console.log("Quiz IP Detector connected");

    // Lấy IP từ URL nếu có
    const urlParams = new URLSearchParams(window.location.search);
    const ipAddress = urlParams.get('client_ip');

    if (ipAddress && this.attemptIdValue) {
      console.log("Đã có IP và attempt_id, log IP vào attempt");
      this.logIpInfo(ipAddress);
    } else if (this.startValue && !this.hasIpValue) {
      console.log("Bắt đầu lấy IP...");
      this.detectIp();
    }
  }

  async detectIp() {
    try {
      console.log("Đang gọi API lấy IP...");
      const response = await fetch('https://api.ipify.org/?format=json');
      const data = await response.json();
      const ipAddress = data.ip;
      console.log("Đã lấy được IP:", ipAddress);

      // Thêm IP vào URL
      const currentUrl = new URL(window.location.href);
      currentUrl.searchParams.set('client_ip', ipAddress);
      window.location.href = currentUrl.toString();
    } catch (error) {
      console.error("Lỗi khi lấy IP:", error);

      // Nếu không lấy được IP, vẫn thêm tham số client_ip=unknown vào URL
      const currentUrl = new URL(window.location.href);
      currentUrl.searchParams.set('client_ip', 'unknown');
      window.location.href = currentUrl.toString();
    }
  }

  async logIpInfo(ipAddress) {
    if (!this.attemptIdValue || !this.courseIdValue || !this.quizIdValue) {
      console.error("Thiếu thông tin attempt_id, course_id hoặc quiz_id");
      return;
    }

    try {
      console.log(`Đang log IP ${ipAddress} vào log_actions cho attempt_id ${this.attemptIdValue}`);
      await QuizApi.logAction(
        this.courseIdValue,
        this.quizIdValue,
        this.attemptIdValue,
        'start_quiz',
        {
          client_ip: ipAddress,
          device_info: navigator.userAgent,
          details: {
            timestamp: new Date().toISOString()
          }
        }
      );
      console.log("Đã log IP thành công!");
    } catch (error) {
      console.error("Lỗi khi log IP và device info:", error);
    }
  }
}
