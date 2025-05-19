import { Controller } from "@hotwired/stimulus"
import { VideoApi } from "../../services/video_api"

export default class extends Controller {
  static targets = [
    "resultContainer", "loadingContainer", "errorContainer", "errorMessage",
    "coverage", "structure", "length", "language",
    "remove", "add", "restructure", "notes"
  ]

  connect() {
    console.log("Video analysis controller connected")
  }

  analyzeVideoContent() {
    this.showLoading()
    
    const videoId = this.element.dataset.videoId
    
    if (!videoId) {
      this.handleError("Không tìm thấy ID video")
      return
    }
    
    VideoApi.analyzeVideoContent(videoId)
      .then(data => {
        this.displayResults(data)
        this.hideLoading()
        this.showResults()
      })
      .catch(error => {
        this.handleError(error.message)
      })
  }
  
  displayResults(data) {
    const analysis = data.analysis || {}
    const recommendations = data.recommendations || {}
    
    // Hiển thị phân tích
    if (this.hasCoverageTarget) {
      this.coverageTarget.textContent = analysis.coverage || "Không có dữ liệu"
    }
    
    if (this.hasStructureTarget) {
      this.structureTarget.textContent = analysis.structure || "Không có dữ liệu"
    }
    
    if (this.hasLengthTarget) {
      this.lengthTarget.textContent = analysis.length || "Không có dữ liệu"
    }
    
    if (this.hasLanguageTarget) {
      this.languageTarget.textContent = analysis.language || "Không có dữ liệu"
    }
    
    // Hiển thị đề xuất
    if (this.hasRemoveTarget) {
      this.removeTarget.innerHTML = ""
      if (recommendations.remove && recommendations.remove.length > 0) {
        recommendations.remove.forEach(item => {
          const li = document.createElement("li")
          li.textContent = item
          this.removeTarget.appendChild(li)
        })
      } else {
        const li = document.createElement("li")
        li.textContent = "Không có đề xuất"
        this.removeTarget.appendChild(li)
      }
    }
    
    if (this.hasAddTarget) {
      this.addTarget.innerHTML = ""
      if (recommendations.add && recommendations.add.length > 0) {
        recommendations.add.forEach(item => {
          const li = document.createElement("li")
          li.textContent = item
          this.addTarget.appendChild(li)
        })
      } else {
        const li = document.createElement("li")
        li.textContent = "Không có đề xuất"
        this.addTarget.appendChild(li)
      }
    }
    
    if (this.hasRestructureTarget) {
      this.restructureTarget.innerHTML = ""
      if (recommendations.restructure && recommendations.restructure.length > 0) {
        recommendations.restructure.forEach(item => {
          const li = document.createElement("li")
          li.textContent = item
          this.restructureTarget.appendChild(li)
        })
      } else {
        const li = document.createElement("li")
        li.textContent = "Không có đề xuất"
        this.restructureTarget.appendChild(li)
      }
    }
    
    if (this.hasNotesTarget) {
      this.notesTarget.textContent = recommendations.notes || "Không có ghi chú bổ sung"
    }
  }
  
  showLoading() {
    if (this.hasLoadingContainerTarget) {
      this.loadingContainerTarget.classList.remove("hidden")
    }
    
    if (this.hasResultContainerTarget) {
      this.resultContainerTarget.classList.add("hidden")
    }
    
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.add("hidden")
    }
  }
  
  hideLoading() {
    if (this.hasLoadingContainerTarget) {
      this.loadingContainerTarget.classList.add("hidden")
    }
  }
  
  showResults() {
    if (this.hasResultContainerTarget) {
      this.resultContainerTarget.classList.remove("hidden")
    }
  }
  
  handleError(message) {
    this.hideLoading()
    
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.classList.remove("hidden")
    }
    
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
    }
  }
}
