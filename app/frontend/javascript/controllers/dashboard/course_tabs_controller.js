import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    if (this.tabTargets.length > 0 && this.panelTargets.length > 0) {
      this.activateTab(0);
    }
  }

  switch(event) {
    const clickedTab = event.currentTarget;
    const tabIndex = this.tabTargets.indexOf(clickedTab);

    if (tabIndex > -1) {
      this.activateTab(tabIndex);
    }
  }

  activateTab(tabIndex) {
    this.tabTargets.forEach((tab, index) => {
      tab.classList.remove('border-purple-500', 'text-purple-500');
      tab.classList.add('border-transparent', 'text-gray-300');

      if (index < this.panelTargets.length) {
        this.panelTargets[index].classList.add('hidden');
      }
    });

    if (tabIndex < this.tabTargets.length) {
      this.tabTargets[tabIndex].classList.remove('border-transparent', 'text-gray-300');
      this.tabTargets[tabIndex].classList.add('border-purple-500', 'text-purple-500');

      if (tabIndex < this.panelTargets.length) {
        this.panelTargets[tabIndex].classList.remove('hidden');
      }
    }
  }
}
