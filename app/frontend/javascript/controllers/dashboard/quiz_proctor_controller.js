import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"
import { Toast } from "../../services/toast_service"

export default class extends Controller {
  static values = {
    mode: String,
    courseId: String,
    quizId: String,
    attemptId: String
  }

  connect() {
    console.log("Quiz proctor controller connected")
    this.cheatingBehaviors = {};
    this.warningShown = false;
    this.eventHandlers = {};
    this.tabSwitchCount = 0;
    this.copyPasteCount = 0;
    this.screenshotCount = 0;
    this.rightClickCount = 0;
    this.devtoolsOpenCount = 0;
    this.otherUnusualCount = 0;
    this.lastDevToolsDetection = 0;
    this.lastVisibilityChangeTime = 0;
    this.lastScreenshotTime = 0;

    const hasAttemptId = this.attemptIdValue && this.attemptIdValue.trim() !== '';
    if (!hasAttemptId) {
      console.log("Chưa có attempt ID, không theo dõi hành vi");
      return;
    }

    this.setupEventListeners();
    this.setupGlobalScreenshotDetection();
  }

  disconnect() {
    this.removeEventListeners();

    if (this.devtoolsCheckInterval) {
      clearInterval(this.devtoolsCheckInterval);
    }

    if (this.syncInterval) {
      clearInterval(this.syncInterval);
    }

    if (this.clipboardMonitorInterval) {
      clearInterval(this.clipboardMonitorInterval);
    }

    this.syncBehaviorCounts();
  }

  removeEventListeners() {
    Object.entries(this.eventHandlers).forEach(([type, handler]) => {
      const [target, eventName] = type.split(':');
      if (target === 'document') {
        document.removeEventListener(eventName, handler);
      } else if (target === 'window') {
        window.removeEventListener(eventName, handler);
      }
    });

    this.eventHandlers = {};
  }

  setupEventListeners() {
    if (!this.attemptIdValue || this.attemptIdValue.trim() === '') {
      console.log("Không thiết lập theo dõi hành vi vì chưa có attempt ID");
      return;
    }

    this.eventHandlers = {
      'document:visibilitychange': this.handleVisibilityChange.bind(this),
      'window:blur': this.handleWindowBlur.bind(this),
      'window:focus': this.handleWindowFocus.bind(this),
      'document:copy': this.handleCopy.bind(this),
      'document:paste': this.handlePaste.bind(this),
      'document:cut': this.handleCut.bind(this),
      'document:keydown': this.handleAllKeyDown.bind(this),
      'document:keyup': this.handleAllKeyUp.bind(this),
      'document:contextmenu': this.handleRightClick.bind(this),
      'document:dragstart': this.handleDragStart.bind(this),
      'document:drop': this.handleDrop.bind(this),
      'document:mousedown': this.handleMouseDown.bind(this),
      'document:printscreen': this.handleScreenshot.bind(this),
    };

    document.addEventListener("visibilitychange", this.eventHandlers['document:visibilitychange']);
    window.addEventListener("blur", this.eventHandlers['window:blur']);
    window.addEventListener("focus", this.eventHandlers['window:focus']);
    document.addEventListener("copy", this.eventHandlers['document:copy']);
    document.addEventListener("paste", this.eventHandlers['document:paste']);
    document.addEventListener("cut", this.eventHandlers['document:cut']);
    document.addEventListener("keydown", this.eventHandlers['document:keydown']);
    document.addEventListener("keyup", this.eventHandlers['document:keyup']);
    document.addEventListener("contextmenu", this.eventHandlers['document:contextmenu']);
    document.addEventListener("dragstart", this.eventHandlers['document:dragstart']);
    document.addEventListener("drop", this.eventHandlers['document:drop']);
    document.addEventListener("mousedown", this.eventHandlers['document:mousedown']);

    if (this.modeValue === 'exam') {
      this.initialWindowWidth = window.innerWidth;
      this.initialWindowHeight = window.innerHeight;
      this.eventHandlers['window:resize'] = this.handleWindowResize.bind(this);
      window.addEventListener("resize", this.eventHandlers['window:resize']);

      window.addEventListener("beforeprint", () => {
        console.log("Print attempt detected");
        this.screenshotCount++;
        this.logAction("screenshot");
        this.showCheatingAlert("In màn hình", "không được phép khi làm bài thi");
      });

      this.devtoolsCheckInterval = setInterval(() => {
        this.checkDevTools();
      }, 1000);

      const style = document.createElement('style');
      style.id = 'quiz-proctor-style';
      style.innerHTML = `
        .question-container * {
          -webkit-user-select: none;
          -moz-user-select: none;
          -ms-user-select: none;
          user-select: none;
        }
      `;
      document.head.appendChild(style);

      this.syncInterval = setInterval(() => {
        this.syncBehaviorCounts();
      }, 30000);
    }

    if ('onbeforeprint' in window) {
      window.addEventListener('beforeprint', () => {
        this.screenshotCount++
        this.logAction("screenshot")
        this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi")
      })
    }
  }

  setupGlobalScreenshotDetection() {
    if (this.modeValue !== 'exam') return;

    this.clipboardMonitorInterval = setInterval(() => {
      if (navigator.clipboard && navigator.clipboard.read) {
        navigator.clipboard.read()
          .then(clipboardItems => {
            for (const item of clipboardItems) {
              if (item.types && (item.types.includes('image/png') || item.types.includes('image/jpeg'))) {
                console.log("Image in clipboard detected, likely screenshot");
                const now = Date.now();
                if (now - this.lastScreenshotTime < 3000) {
                  return;
                }
                this.lastScreenshotTime = now;
                this.screenshotCount++;
                this.logAction("screenshot");
                this.showCheatingAlert("Chụp màn hình phát hiện qua clipboard", "không được phép khi làm bài thi");
              }
            }
          })
          .catch(err => {
            console.log("Clipboard access error:", err);
          });
      }
    }, 10000);
  }

  checkDevTools() {
    if (!this.initialWindowWidth || !this.initialWindowHeight) return;

    const now = Date.now();
    if (now - this.lastDevToolsDetection < 3000) {
      return;
    }

    const widthThreshold = Math.abs(window.innerWidth - this.initialWindowWidth) > 50;
    const heightThreshold = Math.abs(window.innerHeight - this.initialWindowHeight) > 50;

    let isDevToolsOpen = false;
    try {
      console.profile();
      console.profileEnd();

      if (console.clear) {
        console.clear();
      }

      if (console.profileEnd.toString().indexOf('native code') === -1) {
        isDevToolsOpen = true;
      }

      const element = document.createElement('div');
      Object.defineProperty(element, 'id', {
        get: function() {
          isDevToolsOpen = true;
          return 'detection';
        }
      });
      console.log(element);
      console.clear();

    } catch (e) {
      isDevToolsOpen = true;
    }

    if (widthThreshold || heightThreshold || isDevToolsOpen) {
      this.lastDevToolsDetection = now;
      this.devtoolsOpenCount++;
      console.log("DevTools mở lần thứ:", this.devtoolsOpenCount);
      this.logAction("devtools_open");
      this.showCheatingAlert("Công cụ nhà phát triển (DevTools)", "không được phép sử dụng khi làm bài thi!");
    }
  }

  handleScreenshot(e) {
    if (
      e.key === "PrintScreen" ||
      e.code === "PrintScreen" ||
      ((e.ctrlKey || e.metaKey) && e.key === "PrintScreen") ||
      (e.metaKey && e.shiftKey && e.key === "5") ||
      (e.metaKey && e.shiftKey && e.key === "4") ||
      (e.metaKey && e.shiftKey && e.key === "3") ||
      (e.key === "s" && e.shiftKey && e.metaKey) ||
      (e.key === "S" && e.shiftKey && e.metaKey) ||
      (e.key === "s" && e.shiftKey && e.ctrlKey) ||
      (e.key === "S" && e.shiftKey && e.ctrlKey) ||
      (e.key === "s" && e.shiftKey && e.getModifierState("Meta")) ||
      (e.key === "S" && e.shiftKey && e.getModifierState("Meta")) ||
      (e.shiftKey && e.key === "s")
    ) {
      const now = Date.now()
      if (now - this.lastScreenshotTime < 1000) {
        return false
      }
      this.lastScreenshotTime = now
      this.screenshotCount++
      this.logAction("screenshot")
      this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi")
      e.preventDefault()
      return false
    }
  }

  handleRightClick(e)  {
    console.log("Right click detected");
    this.rightClickCount++;
    this.logAction("right_click");
    this.showCheatingAlert("Click chuột phải", "không được phép khi làm bài!");
    e.preventDefault();
    return false;
  }

  handleCopy(e) {
    this.copyPasteCount++
    this.logAction("copy")
    this.showCheatingAlert("Sao chép (copy)", "không được phép khi làm bài thi")
    e.preventDefault()
    return false
  }

  handlePaste(e) {
    this.copyPasteCount++
    this.logAction("paste")
    this.showCheatingAlert("Dán (paste)", "không được phép khi làm bài thi")
    e.preventDefault()
    return false
  }

  handleCut(e) {
    this.copyPasteCount++
    this.logAction("cut")
    this.showCheatingAlert("Cắt (cut)", "không được phép khi làm bài thi")
    e.preventDefault()
    return false
  }

  handleVisibilityChange() {
    const now = Date.now()

    if (document.hidden) {
      this.tabSwitchCount++
      this.logAction("tab_switch")
      this.tabSwitchTime = new Date()
      this.lastVisibilityChangeTime = now
    } else if (this.tabSwitchTime) {
      const timeAway = new Date() - this.tabSwitchTime

      const visibilityDuration = now - this.lastVisibilityChangeTime
      if (this.lastVisibilityChangeTime && visibilityDuration < 300) {
        const screenshotTime = Date.now()
        if (screenshotTime - this.lastScreenshotTime < 3000) {
          this.tabSwitchTime = null
          return
        }
        this.lastScreenshotTime = screenshotTime
        this.screenshotCount++
        this.logAction("screenshot")
        this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi")
      } else if (timeAway > 2000) {
        this.showCheatingAlert("Chuyển tab", `trong ${Math.round(timeAway/1000)} giây`)
      }

      this.tabSwitchTime = null
    }
  }

  handleWindowBlur() {
    this.tabSwitchCount++
    this.logAction("window_blur")
    this.windowBlurTime = new Date()
  }

  handleWindowFocus() {
    if (this.windowBlurTime) {
      const timeAway = new Date() - this.windowBlurTime
      if (timeAway > 2000) {
        this.showCheatingAlert("Rời khỏi trang", `trong ${Math.round(timeAway/1000)} giây`)
      }
      this.windowBlurTime = null
    }
  }

  handleAllKeyDown(e) {
    if (
      e.key === "PrintScreen" ||
      e.code === "PrintScreen" ||
      ((e.ctrlKey || e.metaKey) && e.key === "PrintScreen") ||
      (e.metaKey && e.shiftKey && e.key === "5") ||
      (e.metaKey && e.shiftKey && e.key === "4") ||
      (e.metaKey && e.shiftKey && e.key === "3") ||
      (e.key === "s" && e.shiftKey && e.metaKey) ||
      (e.key === "S" && e.shiftKey && e.metaKey) ||
      (e.key === "s" && e.shiftKey && e.ctrlKey) ||
      (e.key === "S" && e.shiftKey && e.ctrlKey) ||
      (e.key === "s" && e.shiftKey) ||
      (e.key === "S" && e.shiftKey) ||
      (e.code === "KeyS" && e.shiftKey) ||
      (e.key === "PrtScn") ||
      (e.code === "NumpadAdd" && e.ctrlKey) ||
      (e.shiftKey && e.key === "Snapshot") ||
      (e.code === "Snapshot")
    ) {
      const now = Date.now()
      if (now - this.lastScreenshotTime < 3000) {
        return false
      }
      this.lastScreenshotTime = now
      this.screenshotCount++
      this.logAction("screenshot")
      this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi")
      e.preventDefault()
      return false
    }

    if (this.modeValue === 'exam' && e.key === 'F12') {
      e.preventDefault();

      const now = Date.now();
      if (now - this.lastDevToolsDetection < 3000) {
        return false;
      }

      this.lastDevToolsDetection = now;
      this.devtoolsOpenCount++;
      console.log("DevTools mở bằng F12 lần thứ:", this.devtoolsOpenCount);
      this.logAction("devtools_key");
      this.showCheatingAlert("Phím F12", "không được phép khi làm bài thi");
      return false;
    }

    if ((e.ctrlKey || e.metaKey) && (e.key === "c" || e.key === "v" || e.key === "x")) {
      console.log("Copy/Paste/Cut shortcut detected");
      const action = e.key === "c" ? "copy" : (e.key === "v" ? "paste" : "cut");
      this.logAction(action);
      this.showCheatingAlert(`Phím tắt ${action === "copy" ? "sao chép" : (action === "paste" ? "dán" : "cắt")}`, "không được phép khi làm bài thi");
      e.preventDefault();
      return false;
    }

    if (e.altKey && e.key === "Tab") {
      this.logAction("tab_switch");
      e.preventDefault();
      return false;
    }
  }

  handleAllKeyUp(e) {
    if (e.key === "PrintScreen" || e.code === "PrintScreen") {
      const now = Date.now()
      if (now - this.lastScreenshotTime < 1000) {
        return false
      }
      this.lastScreenshotTime = now
      this.screenshotCount++
      this.logAction("screenshot")
      this.showCheatingAlert("Chụp màn hình (PrtSc)", "không được phép khi làm bài thi")
      e.preventDefault()
      return false
    }
  }

  showCheatingAlert(action, message, duration = 3000) {
    if (this.modeValue !== 'exam') return;

    let type = "warning";

    if (action === "Nộp bài tự động") {
      type = "error";
      duration = 10000;
    }
    else if (action === "Cảnh báo") {
      type = "error";
      duration = 5000;
    }

    Toast.show(`<span class="font-medium">${action}:</span> ${message}`, type, duration);
  }

  async logAction(actionType, details = {}) {
    const courseId = this.courseIdValue
    const quizId = this.quizIdValue
    const attemptId = this.attemptIdValue

    try {
      let clientIp = ''
      try {
        const ipResponse = await fetch('https://api.ipify.org/?format=json')
        const ipData = await ipResponse.json()
        clientIp = ipData.ip
      } catch (error) {
        console.error("Lỗi khi lấy IP từ ipify:", error)
      }

      QuizApi.logAction(courseId, quizId, attemptId, actionType, {
        client_ip: clientIp,
        details: details
      })
    } catch (error) {
      console.error("Lỗi khi ghi log:", error)
    }
  }

  handleDragStart(e) {
    if (this.modeValue === 'exam') {
      e.preventDefault();
      this.otherUnusualCount++;
      this.logAction("drag_attempt");
      this.showCheatingAlert("Kéo thả", "không được phép khi làm bài thi");
      return false;
    }
  }

  handleDrop(e) {
    if (this.modeValue === 'exam') {
      e.preventDefault();
      this.otherUnusualCount++;
      this.logAction("drop_attempt");
      return false;
    }
  }

  handleMouseDown(e) {
    if (this.modeValue === 'exam' && e.button === 2) {
      e.preventDefault();
      return false;
    }
  }

  handleWindowResize(e) {
    if (this.modeValue !== 'exam') return;

    const widthChanged = Math.abs(window.innerWidth - this.initialWindowWidth) > 100;
    const heightChanged = Math.abs(window.innerHeight - this.initialWindowHeight) > 100;

    if (widthChanged || heightChanged) {
      this.otherUnusualCount++;
      this.logAction("window_resize");
      this.showCheatingAlert("Thay đổi kích thước cửa sổ", "có thể dẫn đến nghi ngờ gian lận");
    }
  }

  notifyAutoSubmit() {
    Toast.error("Hệ thống đã phát hiện các hành vi vi phạm quy định thi, bài thi đang được nộp tự động", 30000);
  }

  syncBehaviorCounts() {
    if (!this.courseIdValue || !this.quizIdValue || !this.attemptIdValue) {
      return;
    }

    QuizApi.updateBehaviorCounts(
      this.courseIdValue,
      this.quizIdValue,
      this.attemptIdValue,
      {
        tabSwitchCount: this.tabSwitchCount,
        copyPasteCount: this.copyPasteCount,
        screenshotCount: this.screenshotCount,
        rightClickCount: this.rightClickCount,
        devtoolsOpenCount: this.devtoolsOpenCount,
        otherUnusualCount: this.otherUnusualCount
      }
    ).then(() => {
      console.log("Đã đồng bộ số liệu hành vi");
    }).catch(error => {
      console.error("Lỗi khi đồng bộ số liệu hành vi:", error);
    });
  }
}
