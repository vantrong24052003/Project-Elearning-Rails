export function updateURL(formElement, submitFn) {
  const formData = new FormData(formElement)
  const url = new URL(window.location.href)
  const params = url.searchParams
  for (const [key, value] of formData.entries()) {
    if (value && value.trim() !== '') {
      params.set(key, value)
    }
  }
  window.history.pushState({}, '', url.toString())
  submitFn()
}

export function clearURLAndSubmit(submitFn) {
  const url = new URL(window.location.href)
  const params = url.searchParams
  Array.from(params.keys()).forEach(key => {
    params.delete(key)
  })
  window.history.pushState({}, '', url.toString())
  submitFn()
}

export function closeModal(name) {
  const modal = document.getElementById(name)
  if (modal) {
    modal.close()
  }
}

export function openModal(name) {
  const modal = document.getElementById(name)
  if (modal) {
    modal.showModal ? modal.showModal() : modal.close()
  }
}

export function formatPrice(value) {
  return new Intl.NumberFormat('vi-VN').format(value)
}
