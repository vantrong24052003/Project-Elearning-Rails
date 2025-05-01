import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]

  connect() {
    if (this.triggerTargets.length > 0 && this.contentTargets.length > 0) {
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

    this.triggerTargets.forEach(trigger => {
      trigger.dataset.active = "false";
      trigger.classList.remove("dark:bg-purple-600");
    });

    this.contentTargets.forEach(content => {
      content.classList.add("hidden");
    });

    event.currentTarget.dataset.active = "true";
    event.currentTarget.classList.add("dark:bg-purple-600");

    const selectedContent = this.contentTargets.find(
      content => content.dataset.tab === selectedTab
    );

    if (selectedContent) {
      selectedContent.classList.remove("hidden");
    }

    if (history.replaceState) {
      history.replaceState(null, null, `#${selectedTab}`);
    } else {
      location.hash = `#${selectedTab}`;
    }
  }
}
