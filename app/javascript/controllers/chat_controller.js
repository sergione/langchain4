import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "messageInput"]
  
  connect() {
    this.scrollToBottom()
    // Create a MutationObserver to watch for Turbo Stream updates
    this.setupMutationObserver()
  }

  setupMutationObserver() {
    // Observe DOM changes to detect Turbo Stream updates
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          // When new content is added, reset the form
          this.clearInput()
          this.scrollToBottom()
        }
      });
    });
    
    // Watch for changes to the messages container
    const messagesContainer = document.getElementById('messages')
    if (messagesContainer) {
      observer.observe(messagesContainer, { childList: true })
    }
  }
  
  resetForm(event) {
    // Reset the form
    event.target.reset()
    this.clearInput()
    this.scrollToBottom()
  }
  
  clearInput() {
    // Clear the input field
    const input = document.getElementById('chat_message')
    if (input) {
      input.value = ''
      input.focus()
    }
  }
  
  submitOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.submitButtonTarget.click()
      
      // Immediately clear the input
      this.clearInput()
    }
  }
  
  scrollToBottom() {
    const messagesContainer = document.getElementById('messages')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
} 