import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "icon", "button"];

  toggle(event) {
    const index = event.currentTarget.dataset.index;
    const content = this.contentTargets[index];
    const icon = this.iconTargets[index];
    const button = this.buttonTargets[index];

    content.classList.toggle("hidden");

    if (content.classList.contains("hidden")) {
      icon.classList.remove("rotate-180");
      button.setAttribute("aria-expanded", "false");
    } else {
      icon.classList.add("rotate-180");
      button.setAttribute("aria-expanded", "true");
    }
  }
}
