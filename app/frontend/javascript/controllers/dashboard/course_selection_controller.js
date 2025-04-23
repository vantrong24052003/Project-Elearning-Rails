import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]
  static values = { selectedIds: Array }

  connect() {
    console.log("Course selection controller connected");
    this.updateSelectedCount();
  }

  toggleAll(event) {
    const isChecked = event.currentTarget.checked;

    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked;
      this._updateSelectedId(checkbox.value, isChecked);
    });

    this.updateSelectedCount();
  }

  toggle(event) {
    const checkbox = event.target;
    this._updateSelectedId(checkbox.value, checkbox.checked);
    this.updateSelectedCount();
  }

  _updateSelectedId(id, isSelected) {
    if (isSelected) {
      if (!this.selectedIdsValue.includes(id)) {
        this.selectedIdsValue = [...this.selectedIdsValue, id];
      }
    } else {
      this.selectedIdsValue = this.selectedIdsValue.filter(selectedId => selectedId !== id);
    }
  }

  updateSelectedCount() {
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length;

    // Dispatch a custom event to notify other components
    const event = new CustomEvent('dashboard--course-selection:change', {
      detail: { count: selectedCount },
      bubbles: true
    });

    this.element.dispatchEvent(event);
  }

  getSelectedIds() {
    return this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value);
  }
}
