import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progressBar", "progressText"]
  static values = {
    uploadId: String,
    status: String,
    progress: Number
  }

  connect() {
    if (this.statusValue === 'processing') {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.checkProgress()
    this.pollingId = setInterval(() => {
      this.checkProgress()
    }, 3000)
  }

  stopPolling() {
    if (this.pollingId) {
      clearInterval(this.pollingId)
      this.pollingId = null
    }
  }

  checkProgress() {
    fetch(`/manage/uploads/${this.uploadIdValue}/progress`)
      .then(response => response.json())
      .then(data => {
        this.progressValue = data.progress

        if (data.status !== 'processing') {
          this.stopPolling()

          if (data.status === 'success') {
            window.location.reload()
          }
        }
      })
      .catch(error => {
        console.error("Error checking progress:", error)
      })
  }
}
