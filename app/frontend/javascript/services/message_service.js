import toastr from "toastr"

export const MessageService = {
  types: {
    SUCCESS: 'success',
    ERROR: 'error',
    WARNING: 'warning',
    INFO: 'info'
  },

  defaultDuration: 5000,

  success(message, duration = this.defaultDuration) {
    toastr.success(message, '', { timeOut: duration })
  },

  error(message, duration = this.defaultDuration) {
    toastr.error(message, '', { timeOut: duration })
  },

  warning(message, duration = this.defaultDuration) {
    toastr.warning(message, '', { timeOut: duration })
  },

  info(message, duration = this.defaultDuration) {
    toastr.info(message, '', { timeOut: duration })
  },

  show(message, type = this.types.SUCCESS, duration = this.defaultDuration) {
    switch (type) {
      case this.types.SUCCESS:
        this.success(message, duration)
        break
      case this.types.ERROR:
        this.error(message, duration)
        break
      case this.types.WARNING:
        this.warning(message, duration)
        break
      case this.types.INFO:
        this.info(message, duration)
        break
      default:
        this.success(message, duration)
    }
  },

  clearAll() {
    toastr.clear()
  },

  forceClear() {
    toastr.clear()
    toastr.remove()
  }
}

export default MessageService
