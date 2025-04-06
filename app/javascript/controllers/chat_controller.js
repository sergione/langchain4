import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]
  
  connect() {
    this.scrollToBottom()
  }
  
  // This is still needed for the Turbo form submission callback
  resetForm(event) {
    // The form is now reset by both the controller response
    // and the turbo:submit-start event handler, so we just need
    // to scroll to the bottom here
    this.scrollToBottom()
  }
  
  // Still needed for keyboard shortcut support
  submitOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.submitButtonTarget.click()
    }
  }
  
  // Still needed for scrolling to the newest messages
  scrollToBottom() {
    const messagesContainer = document.getElementById('messages')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
} 