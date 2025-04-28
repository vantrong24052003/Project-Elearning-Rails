import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]

  connect() {
    if (this.triggerTargets.length > 0 && this.contentTargets.length > 0) {
      // Kiểm tra URL hash để xác định tab nào nên được kích hoạt
      const hash = window.location.hash.substr(1);
      if (hash) {
        const trigger = this.triggerTargets.find(t => t.dataset.tab === hash);
        if (trigger) {
          this.select({ currentTarget: trigger });
        } else {
          this.select({ currentTarget: this.triggerTargets[0] });
        }
      } else {
        this.select({ currentTarget: this.triggerTargets[0] });
      }
    }
  }

  select(event) {
    const selectedTab = event.currentTarget.dataset.tab;
    
    // Bỏ active khỏi tất cả tabs
    this.triggerTargets.forEach(trigger => {
      trigger.dataset.active = "false";
      trigger.classList.remove("dark:bg-purple-600");
    });
    
    // Ẩn tất cả nội dung
    this.contentTargets.forEach(content => {
      content.classList.add("hidden");
    });
    
    // Hiển thị tab được chọn
    event.currentTarget.dataset.active = "true";
    event.currentTarget.classList.add("dark:bg-purple-600");
    
    const selectedContent = this.contentTargets.find(
      content => content.dataset.tab === selectedTab
    );
    
    if (selectedContent) {
      selectedContent.classList.remove("hidden");
    }
    
    // Cập nhật URL hash để giữ trạng thái tab khi refresh
    if (history.replaceState) {
      history.replaceState(null, null, `#${selectedTab}`);
    } else {
      location.hash = `#${selectedTab}`;
    }
  }
}
