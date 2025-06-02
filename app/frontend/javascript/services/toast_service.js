export const Toast = {
  success(message, duration = 2000) {
    this.show(message, 'success', duration);
  },

  error(message, duration = 2000) {
    this.show(message, 'error', duration);
  },

  warning(message, duration = 2000) {
    this.show(message, 'warning', duration);
  },

  show(message, type = 'success', duration = 2000) {
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
