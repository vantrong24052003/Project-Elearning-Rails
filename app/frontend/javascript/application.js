import "@hotwired/turbo-rails"
import "./controllers"
import "toastr/build/toastr.min.css";
import { createIcons, icons } from "lucide"

toastr.options = {
  closeButton: true,
  progressBar: true,
  positionClass: "toast-top-right",
  timeOut: "5000",
};

// Initialize Lucide icons when DOM is loaded and on Turbo navigation
document.addEventListener("DOMContentLoaded", () => {
  createIcons({ icons })
})

document.addEventListener("turbo:load", () => {
  createIcons({ icons })
})
