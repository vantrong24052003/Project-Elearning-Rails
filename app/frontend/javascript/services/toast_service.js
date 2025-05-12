export const Toast = {
  success(message, duration = 5000) {
    this.show(message, 'success', duration);
  },

  error(message, duration = 5000) {
    this.show(message, 'error', duration);
  },

  warning(message, duration = 5000) {
    this.show(message, 'warning', duration);
  },

  show(message, type = 'success', duration = 5000) {
    const event = new CustomEvent('toast:show', {
      detail: {
        message,
        type,
        duration
      }
    });

    document.dispatchEvent(event);
  }
};
