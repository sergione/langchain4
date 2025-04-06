// Add additional event listener for Turbo Stream form submissions
document.addEventListener("turbo:submit-start", function(event) {
  const form = event.target;
  // If this is a chat form, immediately clear the input
  if (form && form.id === "chat-form") {
    const input = document.getElementById("chat_message");
    if (input) {
      // Store the value temporarily (in case we need it)
      form.dataset.lastValue = input.value;
      
      // Clear the input right away for better UX
      setTimeout(() => {
        input.value = "";
        input.focus();
      }, 50);
    }
  }
});
