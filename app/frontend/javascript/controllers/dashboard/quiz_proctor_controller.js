import { Controller } from "@hotwired/stimulus"
import { QuizApi } from "../../services/quiz_api"

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

    const hasAttemptId = this.attemptIdValue && this.attemptIdValue.trim() !== '';
    if (!hasAttemptId) {
      console.log("Chưa có attempt ID, không theo dõi hành vi");
      return;
    }

    this.createToasterContainer();
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
      'document:mousedown': this.handleMouseDown.bind(this)
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
      console.log("Screenshot key combination detected:", e.key, e.code);
      this.screenshotCount++;
      this.logAction("screenshot");
      this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi");
      e.preventDefault();
      return false;
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
    console.log("Copy detected");
    this.copyPasteCount++;
    this.logAction("copy");
    this.showCheatingAlert("Sao chép (copy)", "không được phép khi làm bài thi");
    e.preventDefault();
    return false;
  }

  handlePaste(e) {
    console.log("Paste detected");
    this.copyPasteCount++;
    this.logAction("paste");
    this.showCheatingAlert("Dán (paste)", "không được phép khi làm bài thi");
    e.preventDefault();
    return false;
  }

  handleCut(e) {
    console.log("Cut detected");
    this.copyPasteCount++;
    this.logAction("cut");
    this.showCheatingAlert("Cắt (cut)", "không được phép khi làm bài thi");
    e.preventDefault();
    return false;
  }

  handleVisibilityChange() {
    console.log("Visibility changed:", document.hidden);
    const now = Date.now();
    
    if (document.hidden) {
      this.tabSwitchCount++;
      this.logAction("tab_switch");
      this.tabSwitchTime = new Date();
      this.lastVisibilityChangeTime = now;
      
    } else if (this.tabSwitchTime) {
      const timeAway = new Date() - this.tabSwitchTime;
      
      const visibilityDuration = now - this.lastVisibilityChangeTime;
      if (this.lastVisibilityChangeTime && visibilityDuration < 300) {
        console.log("Quick visibility change detected, possible screenshot, duration:", visibilityDuration);
        this.screenshotCount++;
        this.logAction("screenshot");
        this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi");
      } else if (timeAway > 2000) {
        this.showCheatingAlert("Chuyển tab", `trong ${Math.round(timeAway/1000)} giây`);
      }
      
      this.tabSwitchTime = null;
    }
  }

  handleWindowBlur() {
    console.log("Window blur detected");
    this.tabSwitchCount++;
    this.logAction("window_blur");
    this.windowBlurTime = new Date();
  }

  handleWindowFocus() {
    console.log("Window focus detected");
    if (this.windowBlurTime) {
      const timeAway = new Date() - this.windowBlurTime;
      if (timeAway > 2000) {
        this.showCheatingAlert("Rời khỏi trang", `trong ${Math.round(timeAway/1000)} giây`);
      }
      this.windowBlurTime = null;
    }
  }

  handleAllKeyDown(e) {
    console.log("Key pressed:", e.key, e.code, e.ctrlKey, e.altKey, e.shiftKey, e.metaKey);
    
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
      console.log("Screenshot key combination detected:", e.key, e.code);
      this.screenshotCount++;
      this.logAction("screenshot");
      this.showCheatingAlert("Chụp màn hình", "không được phép khi làm bài thi");
      e.preventDefault();
      return false;
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
    console.log("Key released:", e.key, e.code);
    
    if (e.key === "PrintScreen" || e.code === "PrintScreen") {
      console.log("PrintScreen key released");
      this.screenshotCount++;
      this.logAction("screenshot");
      this.showCheatingAlert("Chụp màn hình (PrtSc)", "không được phép khi làm bài thi");
      e.preventDefault();
      return false;
    }
  }

  createToasterContainer() {
    if (document.getElementById('quiz-cheating-toaster-container')) {
      return;
    }

    const toasterContainer = document.createElement('div');
    toasterContainer.id = 'quiz-cheating-toaster-container';
    toasterContainer.className = 'fixed top-4 right-4 z-50 flex flex-col gap-2 items-end max-w-xs';
    document.body.appendChild(toasterContainer);

    const style = document.createElement('style');
    style.id = 'quiz-toaster-style';
    style.textContent = `
      .toast-enter {
        opacity: 0;
        transform: translateX(20px);
      }
      .toast-enter-active {
        opacity: 1;
        transform: translateX(0);
        transition: opacity 300ms, transform 300ms;
      }
      .toast-exit {
        opacity: 1;
      }
      .toast-exit-active {
        opacity: 0;
        transform: translateX(20px);
        transition: opacity 300ms, transform 300ms;
      }
    `;
    document.head.appendChild(style);
  }

  showCheatingAlert(action, message, duration = 3000) {
    if (this.modeValue !== 'exam') return;

    const toasterContainer = document.getElementById('quiz-cheating-toaster-container');
    if (!toasterContainer) return;

    let bgColor = 'bg-orange-500';
    let icon = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
    </svg>`;

    if (action === "Nộp bài tự động") {
      bgColor = 'bg-red-600';
      duration = 10000;
      icon = `<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
      </svg>`;
    }
    else if (action === "Cảnh báo") {
      bgColor = 'bg-red-500';
      duration = 5000;
    }
    else if (action === "Lưu ý") {
      bgColor = 'bg-yellow-500';
    }

    const toaster = document.createElement('div');
    toaster.className = `${bgColor} text-white p-3 rounded-lg shadow-lg toast-enter max-w-xs mb-2`;
    toaster.innerHTML = `
      <div class="flex items-center">
        ${icon}
        <span class="font-medium text-sm">${action}</span>
      </div>
      <p class="text-sm mt-1">${message}</p>
    `;

    toasterContainer.appendChild(toaster);

    setTimeout(() => {
      toaster.classList.remove('toast-enter');
      toaster.classList.add('toast-enter-active');
    }, 10);

    setTimeout(() => {
      toaster.classList.remove('toast-enter-active');
      toaster.classList.add('toast-exit');
      setTimeout(() => {
        toaster.classList.add('toast-exit-active');
        setTimeout(() => {
          if (toaster.parentNode) {
            toaster.parentNode.removeChild(toaster);
          }
        }, 300);
      }, 10);
    }, duration);
  }

  async logAction(actionType) {
    try {
      if (!this.courseIdValue || !this.quizIdValue || !this.attemptIdValue) {
        return;
      }

      if (!this.cheatingBehaviors) {
        this.cheatingBehaviors = {};
      }

      this.cheatingBehaviors[actionType] = (this.cheatingBehaviors[actionType] || 0) + 1;

      const totalCheatingCount =
        this.rightClickCount +
        this.devtoolsOpenCount * 2 +
        this.screenshotCount * 2 +
        this.copyPasteCount +
        Math.floor(this.tabSwitchCount / 2);

      console.log("Tổng số hành vi gian lận:", totalCheatingCount);
      console.log("DevTools mở:", this.devtoolsOpenCount, "lần");
      console.log("Screenshot:", this.screenshotCount, "lần");

      if (this.modeValue === 'exam') {
        if (this.devtoolsOpenCount >= 5) {
          this.showCheatingAlert("Nộp bài tự động", "Do phát hiện mở DevTools nhiều lần, bài thi của bạn sẽ bị nộp tự động");
          this.syncBehaviorCounts();
          this.notifyAutoSubmit();

          setTimeout(() => {
            const event = new CustomEvent('quiz:auto-submit', {
              detail: { reason: 'Phát hiện mở DevTools nhiều lần' }
            });
            document.dispatchEvent(event);
          }, 3000);

          return;
        }

        if (totalCheatingCount >= 15 && !this.warningShown) {
          this.warningShown = true;
          this.showCheatingAlert("Cảnh báo", "Hệ thống đã phát hiện nhiều hành vi bất thường. Tiếp tục có thể dẫn đến việc tự động nộp bài!");
        }
        else if (totalCheatingCount >= 25) {
          this.showCheatingAlert("Nộp bài tự động", "Do phát hiện nhiều hành vi gian lận, bài thi của bạn sẽ bị nộp tự động");
          this.syncBehaviorCounts();

          this.notifyAutoSubmit();

          setTimeout(() => {
            const event = new CustomEvent('quiz:auto-submit', {
              detail: { reason: 'Phát hiện hành vi gian lận' }
            });
            document.dispatchEvent(event);
          }, 3000);

          return;
        }
      }

      await QuizApi.logAction(
        this.courseIdValue,
        this.quizIdValue,
        this.attemptIdValue,
        actionType
      );
    } catch (error) {
      console.error("Lỗi khi ghi nhận hành động:", error);
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
    const toasterContainer = document.getElementById('quiz-cheating-toaster-container');
    if (toasterContainer) {
      toasterContainer.innerHTML = '';
      const finalToast = document.createElement('div');
      finalToast.className = 'bg-red-600 text-white p-4 rounded-lg shadow-lg toast-enter max-w-sm mb-2 text-center fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-50';
      finalToast.innerHTML = `
        <div class="flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 flex-shrink-0" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
          <span class="font-bold text-base">ĐANG NỘP BÀI TỰ ĐỘNG</span>
        </div>
        <p class="mt-2">Hệ thống đã phát hiện các hành vi vi phạm quy định thi.</p>
      `;

      toasterContainer.appendChild(finalToast);
    }
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
