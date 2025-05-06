import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "uploadUI", "fileList", "errorUI", "errorMessage", "uploadTemplate",
                    "noFilesMessage", "uploadMoreButton", "confirmButton", "successUI", "cancelButton"]

  connect() {
    console.log("Upload form controller kết nối")
    this.uploadXHRs = {}
    this.selectedFiles = []
    this.processingFiles = 0
    this.uploadsCompleted = 0

    if (this.hasConfirmButtonTarget) {
      this.confirmButtonTarget.disabled = false
    }
  }

  disconnect() {
    console.log("Upload form controller ngắt kết nối")
    this.abortAllUploads()
  }

  openFileDialog(event) {
    event.preventDefault()
    event.stopPropagation()

    this.fileInputTarget.click()
  }

  handleDragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50", "dark:bg-blue-900/10")
  }

  handleDragEnter(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50", "dark:bg-blue-900/10")
  }

  handleDragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50", "dark:bg-blue-900/10")
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()

    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50", "dark:bg-blue-900/10")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.processFiles(Array.from(files))
    }
  }

  handleFileChange(event) {
    event.stopPropagation()

    const files = this.fileInputTarget.files
    if (files.length > 0) {
      const fileArray = Array.from(files)
      this.processFiles(fileArray)

      this.fileInputTarget.value = ''
    }
  }

  processFiles(files) {
    const videoFiles = files.filter(file => this.isValidVideoFile(file))

    if (videoFiles.length === 0) {
      this.showError("Không có file video hợp lệ. Vui lòng chọn file video (MP4, MOV, AVI, MKV, WebM, FLV, WMV, 3GP, ...)")
      return
    }

    const oversizedFiles = videoFiles.filter(file => file.size > 2 * 1024 * 1024 * 1024) // > 2GB
    if (oversizedFiles.length > 0) {
      const fileNames = oversizedFiles.map(f => f.name).join(", ")
      this.showError(`Các file sau vượt quá kích thước tối đa 2GB: ${fileNames}`)
      return
    }

    this.selectedFiles = [...this.selectedFiles, ...videoFiles]

    this.uploadUITarget.classList.add("hidden")
    this.fileListTarget.classList.remove("hidden")
    this.noFilesMessageTarget.classList.add("hidden")
    this.uploadMoreButtonTarget.classList.remove("hidden")
    this.confirmButtonTarget.classList.remove("hidden")
    this.cancelButtonTarget.classList.remove("hidden")
    this.errorUITarget.classList.add("hidden")
    this.successUITarget.classList.add("hidden")

    this.updateFileList()
  }

  updateFileList() {
    const items = this.fileListTarget.querySelectorAll('.file-item')
    items.forEach(item => {
      if (!item.classList.contains('template')) {
        item.remove()
      }
    })

    this.selectedFiles.forEach((file, index) => {
      const template = this.uploadTemplateTarget.content.cloneNode(true)
      const item = template.querySelector('.file-item')

      const fileId = `file-${Date.now()}-${index}`
      item.dataset.fileIndex = index
      item.id = fileId

      item.querySelector('.file-name').textContent = file.name
      item.querySelector('.file-size').textContent = this.formatFileSize(file.size)

      const deleteButton = item.querySelector('.delete-file')
      deleteButton.addEventListener('click', (event) => this.removeFile(event, index))

      this.fileListTarget.appendChild(template)
    })
  }

  removeFile(event, index) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    this.selectedFiles = this.selectedFiles.filter((_, i) => i !== index)

    if (this.selectedFiles.length === 0) {
      this.resetUpload()
    } else {
      this.updateFileList()
    }
  }

  isValidVideoFile(file) {
    return file.type.startsWith('video/');
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'

    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  startUploads(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.selectedFiles.length === 0) return

    this.processingFiles = this.selectedFiles.length
    this.uploadsCompleted = 0

    this.confirmButtonTarget.disabled = true
    this.uploadMoreButtonTarget.disabled = true

    this.selectedFiles.forEach((file, index) => {
      this.uploadFile(file, index)
    })
  }

  uploadFile(file, index) {
    const fileItem = this.fileListTarget.querySelector(`[data-file-index="${index}"]`)
    if (!fileItem) return

    const progressBar = fileItem.querySelector('.progress-bar')
    const progressBarContainer = progressBar.parentElement
    const progressText = fileItem.querySelector('.progress-text')
    const status = fileItem.querySelector('.file-status')

    status.textContent = 'Đang tải lên...'
    status.className = 'file-status text-blue-500 dark:text-blue-400 text-xs'

    progressBarContainer.classList.remove('hidden')
    progressText.classList.remove('hidden')
    const deleteButton = fileItem.querySelector('.delete-file')
    if (deleteButton) deleteButton.classList.add('hidden')

    const cancelButton = document.createElement('button')
    cancelButton.className = 'cancel-button text-xs text-red-500 hover:text-red-700 dark:hover:text-red-400 underline'
    cancelButton.textContent = 'Hủy'
    cancelButton.addEventListener('click', () => this.cancelUpload(index))
    fileItem.querySelector('.file-actions').appendChild(cancelButton)

    const formData = new FormData()
    formData.append('upload[video]', file)

    const xhr = new XMLHttpRequest()
    this.uploadXHRs[index] = xhr

    xhr.upload.addEventListener('progress', (event) => {
      if (event.lengthComputable) {
        const percent = Math.round((event.loaded / event.total) * 100)
        progressBar.style.width = `${percent}%`
        progressText.textContent = `${percent}%`
      }
    })

    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          const response = JSON.parse(xhr.responseText)

          status.textContent = 'Đang xử lý...'
          status.className = 'file-status text-yellow-500 dark:text-yellow-400 text-xs'

          const cancelBtn = fileItem.querySelector('.cancel-button')
          if (cancelBtn) cancelBtn.remove()

          const viewBtn = document.createElement('a')
          viewBtn.href = `/manage/uploads/${response.upload_id}`
          viewBtn.className = 'text-xs text-blue-500 hover:text-blue-700 dark:hover:text-blue-400 underline'
          viewBtn.textContent = 'Xem chi tiết'
          fileItem.querySelector('.file-actions').appendChild(viewBtn)

          this.uploadsCompleted++

          this.monitorProcessing(response.upload_id, index)
        } catch (e) {
          console.error('Error parsing response:', e)
          this.showFileError(index, 'Lỗi khi xử lý phản hồi từ máy chủ')
          this.uploadsCompleted++
        }
      } else {
        let errorMsg = 'Lỗi khi tải lên video'

        try {
          const response = JSON.parse(xhr.responseText)
          if (response.errors && response.errors.length) {
            errorMsg = response.errors.join(', ')
          }
        } catch (e) {}

        this.showFileError(index, errorMsg)
        this.uploadsCompleted++
      }

      delete this.uploadXHRs[index]

      this.checkAllUploadsComplete()
    })

    xhr.addEventListener('error', () => {
      this.showFileError(index, 'Lỗi kết nối mạng')
      delete this.uploadXHRs[index]
      this.uploadsCompleted++
      this.checkAllUploadsComplete()
    })

    xhr.addEventListener('abort', () => {
      status.textContent = 'Đã hủy'
      status.className = 'file-status text-gray-500 dark:text-gray-400 text-xs'

      const cancelBtn = fileItem.querySelector('.cancel-button')
      if (cancelBtn) cancelBtn.remove()

      progressBar.style.width = '0%'
      progressText.textContent = '0%'

      const retryBtn = document.createElement('button')
      retryBtn.className = 'text-xs text-blue-500 hover:text-blue-700 dark:hover:text-blue-400 underline'
      retryBtn.textContent = 'Thử lại'
      retryBtn.addEventListener('click', () => this.retryUpload(index))
      fileItem.querySelector('.file-actions').appendChild(retryBtn)

      delete this.uploadXHRs[index]
      this.uploadsCompleted++
      this.checkAllUploadsComplete()
    })

    xhr.open('POST', '/manage/uploads')
    xhr.setRequestHeader('X-CSRF-Token', document.querySelector("meta[name='csrf-token']").content)
    xhr.setRequestHeader('Accept', 'application/json')
    xhr.send(formData)
  }

  cancelUpload(index) {
    if (this.uploadXHRs[index]) {
      this.uploadXHRs[index].abort()
    }
  }

  retryUpload(index) {
    const file = this.selectedFiles[index]
    if (!file) return

    const fileItem = this.fileListTarget.querySelector(`[data-file-index="${index}"]`)
    if (!fileItem) return

    const fileActions = fileItem.querySelector('.file-actions')
    while (fileActions.firstChild) {
      fileActions.removeChild(fileActions.firstChild)
    }

    const deleteButton = document.createElement('button')
    deleteButton.className = 'delete-file text-xs text-red-500 hover:text-red-700 dark:hover:text-red-400 underline'
    deleteButton.textContent = 'Xóa'
    deleteButton.addEventListener('click', () => this.removeFile(null, index))
    fileActions.appendChild(deleteButton)

    const progressBar = fileItem.querySelector('.progress-bar')
    const progressBarContainer = progressBar.parentElement
    const progressText = fileItem.querySelector('.progress-text')
    progressBar.style.width = '0%'
    progressText.textContent = '0%'
    progressBarContainer.classList.add('hidden')
    progressText.classList.add('hidden')

    const status = fileItem.querySelector('.file-status')
    status.textContent = 'Chờ xác nhận'
    status.className = 'file-status text-gray-500 dark:text-gray-400 text-xs'

    if (this.confirmButtonTarget.disabled) {
      this.confirmButtonTarget.disabled = false
    }
  }

  monitorProcessing(uploadId, index) {
    if (!uploadId) return

    const fileItem = this.fileListTarget.querySelector(`[data-file-index="${index}"]`)
    if (!fileItem) return

    const status = fileItem.querySelector('.file-status')

    const interval = setInterval(() => {
      fetch(`/manage/uploads/${uploadId}/progress`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.status === 'processing') {
          status.textContent = `Đang xử lý: ${data.progress}%`
        } else if (data.status === 'success') {
          clearInterval(interval)
          status.textContent = 'Hoàn thành'
          status.className = 'file-status text-green-500 dark:text-green-400 text-xs'

          if (this.uploadsCompleted >= this.processingFiles) {
            this.showSuccessUI()
          }
        } else if (data.status === 'failed') {
          clearInterval(interval)
          status.textContent = 'Xử lý thất bại'
          status.className = 'file-status text-red-500 dark:text-red-400 text-xs'
        }
      })
      .catch(error => {
        console.error('Lỗi khi kiểm tra tiến trình xử lý:', error)
      })
    }, 3000)

    fileItem.dataset.processingInterval = interval
  }

  showFileError(index, message) {
    const fileItem = this.fileListTarget.querySelector(`[data-file-index="${index}"]`)
    if (!fileItem) return

    const status = fileItem.querySelector('.file-status')
    status.textContent = 'Lỗi: ' + message
    status.className = 'file-status text-red-500 dark:text-red-400 text-xs'

    const cancelBtn = fileItem.querySelector('.cancel-button')
    if (cancelBtn) cancelBtn.remove()

    const retryBtn = document.createElement('button')
    retryBtn.className = 'text-xs text-blue-500 hover:text-blue-700 dark:hover:text-blue-400 underline'
    retryBtn.textContent = 'Thử lại'
    retryBtn.addEventListener('click', () => this.retryUpload(index))
    fileItem.querySelector('.file-actions').appendChild(retryBtn)
  }

  checkAllUploadsComplete() {
    if (this.uploadsCompleted >= this.processingFiles) {
      this.uploadMoreButtonTarget.disabled = false

      let allCompleted = true

      document.querySelectorAll('.file-status').forEach(status => {
        if (!status.textContent.includes('Hoàn thành') && !status.textContent.includes('Đang xử lý')) {
          allCompleted = false
        }
      })

      if (allCompleted) {
        this.showSuccessUI()
      }
    } else if (Object.keys(this.uploadXHRs).length === 0) {
      this.uploadMoreButtonTarget.disabled = false
    }
  }

  showSuccessUI() {
    this.uploadUITarget.classList.add("hidden")
    this.fileListTarget.classList.add("hidden")
    this.errorUITarget.classList.add("hidden")
    this.confirmButtonTarget.classList.add("hidden")
    this.uploadMoreButtonTarget.classList.add("hidden")
    this.cancelButtonTarget.classList.add("hidden")
    this.successUITarget.classList.remove("hidden")
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorUITarget.classList.remove("hidden")
    this.uploadUITarget.classList.add("hidden")
    this.fileListTarget.classList.add("hidden")
    this.confirmButtonTarget.classList.add("hidden")
    this.uploadMoreButtonTarget.classList.add("hidden")
    this.cancelButtonTarget.classList.add("hidden")
    this.successUITarget.classList.add("hidden")
  }

  resetUpload(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.uploadUITarget.classList.remove("hidden")
    this.fileListTarget.classList.add("hidden")
    this.errorUITarget.classList.add("hidden")
    this.confirmButtonTarget.classList.add("hidden")
    this.uploadMoreButtonTarget.classList.add("hidden")
    this.cancelButtonTarget.classList.add("hidden")
    this.successUITarget.classList.add("hidden")

    this.confirmButtonTarget.disabled = false
    this.uploadMoreButtonTarget.disabled = false

    this.abortAllUploads()

    document.querySelectorAll('[data-processing-interval]').forEach(item => {
      clearInterval(Number(item.dataset.processingInterval))
    })

    this.selectedFiles = []

    this.fileInputTarget.value = ''
  }

  uploadMore(event) {
    event.preventDefault()
    event.stopPropagation()

    this.fileInputTarget.click()
  }

  goToList(event) {
    event.preventDefault()
    event.stopPropagation()

    window.location.href = '/manage/uploads'
  }

  abortAllUploads() {
    Object.values(this.uploadXHRs).forEach(xhr => {
      if (xhr) xhr.abort()
    })
    this.uploadXHRs = {}
  }
}
