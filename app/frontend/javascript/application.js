import "@hotwired/turbo-rails"
import "./controllers"
import "toastr/build/toastr.min.css";
// Configure toastr options (optional)
toastr.options = {
  closeButton: true,
  progressBar: true,
  positionClass: "toast-top-right",
  timeOut: "5000",
};
