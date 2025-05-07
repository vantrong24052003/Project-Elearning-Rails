import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropzone", "fileInput", "form", "uploadUI", "progressUI", "successUI", "errorUI",
    "progressBar", "progressText", "fileName", "errorMessage", "submitButton",
    "cdnUrlInput", "thumbnailInput", "fileTypeInput", "durationInput", "resolutionInput"
  ]

  connect() {
    this.dragCounter = 0
    console.log("Upload form controller connected")
  }

  openFileDialog(event) {
    event.preventDefault()
    event.stopPropagation()
    this.fileInputTarget.click()
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add('bg-blue-50', 'dark:bg-blue-900/20', 'border-blue-300', 'dark:border-blue-700')
  }

  handleDragEnter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter++
  }

  handleDragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter--
    if (this.dragCounter === 0) {
      this.dropzoneTarget.classList.remove('bg-blue-50', 'dark:bg-blue-900/20', 'border-blue-300', 'dark:border-blue-700')
    }
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dragCounter = 0
    this.dropzoneTarget.classList.remove('bg-blue-50', 'dark:bg-blue-900/20', 'border-blue-300', 'dark:border-blue-700')

    const files = event.dataTransfer ? event.dataTransfer.files : null
    if (files && files.length > 0) {
      this.uploadFile(files[0])
    }
  }

  handleFileChange(event) {
    const files = event.target.files
    if (files && files.length > 0) {
      this.uploadFile(files[0])
    }
  }

  uploadFile(file) {
    if (!file.type.startsWith('video/')) {
      this.showError('Chỉ hỗ trợ tải lên video.')
      return
    }

    if (file.size > 2 * 1024 * 1024 * 1024) {
      this.showError('Kích thước file không được vượt quá 2GB.')
      return
    }

    this.showUI('progress')
    this.fileNameTarget.textContent = file.name

    this.uploadToServer(file)
  }

  uploadToServer(file) {
    const formData = new FormData()
    formData.append('upload[video]', file)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    formData.append('authenticity_token', csrfToken)

    const xhr = new XMLHttpRequest()
    xhr.open('POST', '/manage/uploads', true)

    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    xhr.setRequestHeader('Accept', 'application/json')

    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percentComplete = Math.round((e.loaded / e.total) * 100)
        this.progressBarTarget.style.width = percentComplete + '%'
        this.progressTextTarget.textContent = percentComplete + '%'
      }
    })

    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          const response = JSON.parse(xhr.responseText)
          if (response.success && response.upload_id) {
            this.handleUploadSuccess(response)
            setTimeout(() => {
              window.location.href = `/manage/uploads/${response.upload_id}`
            }, 1500)
          } else {
            let errorMessage = 'Có lỗi xảy ra khi tải lên'
            if (response.errors && response.errors.length > 0) {
              errorMessage += ': ' + response.errors.join(', ')
            }
            this.showError(errorMessage)
          }
        } catch (e) {
          console.error('Error parsing JSON response:', e)
          this.showUI('success')
          setTimeout(() => {
            window.location.href = '/manage/uploads'
          }, 1500)
        }
      } else {
        let errorMessage = 'Có lỗi xảy ra khi tải lên: ' + xhr.statusText

        try {
          const response = JSON.parse(xhr.responseText)
          if (response.errors && response.errors.length > 0) {
            errorMessage += ' - ' + response.errors.join(', ')
          }
        } catch (e) {
        }

        this.showError(errorMessage)
      }
    })

    xhr.addEventListener('error', () => {
      console.error('XHR error event triggered')
      this.showError('Lỗi kết nối. Vui lòng thử lại sau.')
    })

    xhr.addEventListener('abort', () => {
      this.showError('Tải lên đã bị hủy.')
    })

    xhr.send(formData)
  }

  handleUploadSuccess(response) {
    let cdnUrl = response.cdn_url || '';
    if (response.formats && response.formats.includes('hls') && !cdnUrl.includes('.m3u8')) {
      cdnUrl = cdnUrl.replace('/videos/', '/hls/').replace('.mp4', '.m3u8');
    }

    this.cdnUrlInputTarget.value = cdnUrl;
    this.thumbnailInputTarget.value = response.thumbnail_path || '';
    this.fileTypeInputTarget.value = response.file_type || '';
    this.durationInputTarget.value = response.duration || '';
    this.resolutionInputTarget.value = response.resolution || '';

    this.uploadUITarget.classList.add('hidden');
    this.progressUITarget.classList.add('hidden');
    this.successUITarget.classList.remove('hidden');

    this.submitButtonTarget.disabled = false;
  }

  showUI(type) {
    this.uploadUITarget.classList.add('hidden')
    this.progressUITarget.classList.add('hidden')
    this.successUITarget.classList.add('hidden')
    this.errorUITarget.classList.add('hidden')

    switch (type) {
      case 'upload':
        this.uploadUITarget.classList.remove('hidden')
        break
      case 'progress':
        this.progressUITarget.classList.remove('hidden')
        break
      case 'success':
        this.successUITarget.classList.remove('hidden')
        break
      case 'error':
        this.errorUITarget.classList.remove('hidden')
        break
    }
  }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.showUI('error')
  }

  resetUpload() {
    this.showUI('upload')
    this.fileInputTarget.value = ''
    this.progressBarTarget.style.width = '0%'
    this.progressTextTarget.textContent = '0%'
  }
}
