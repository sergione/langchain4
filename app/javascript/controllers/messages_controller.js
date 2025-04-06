import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // When a message connects to the DOM, scroll to bottom
    this.scrollToBottom()
  }
  
  scrollToBottom() {
    const messagesContainer = document.getElementById('messages')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
} 