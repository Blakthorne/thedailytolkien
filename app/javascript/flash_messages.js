// Flash Messages Module
// Handles auto-dismiss and manual close of flash messages

export default class FlashMessages {
  constructor() {
    this.AUTO_DISMISS_DELAY = 5000; // 5 seconds
    this.init();
  }

  init() {
    this.setupFlashMessages();
    this.setupCloseButtons();
  }

  setupFlashMessages() {
    const flashMessages = document.querySelectorAll('.flash-message');
    
    flashMessages.forEach(message => {
      // Auto-dismiss after delay
      setTimeout(() => {
        this.dismissMessage(message);
      }, this.AUTO_DISMISS_DELAY);
    });
  }

  setupCloseButtons() {
    document.addEventListener('click', (event) => {
      const closeButton = event.target.closest('[data-flash-close]');
      if (closeButton) {
        const message = closeButton.closest('.flash-message');
        if (message) {
          this.dismissMessage(message);
        }
      }
    });
  }

  dismissMessage(message) {
    // Add hiding class for animation
    message.classList.add('flash-hiding');
    
    // Remove from DOM after animation completes
    setTimeout(() => {
      message.remove();
      
      // If no more messages, remove container
      const container = document.querySelector('.flash-container');
      if (container && !container.querySelector('.flash-message')) {
        container.remove();
      }
    }, 300); // Match animation duration
  }

  // Cleanup for Turbo navigation
  cleanup() {
    // Flash messages are server-rendered, so they'll be replaced on navigation
    // No specific cleanup needed
  }
}

// Initialize on page load and Turbo navigation
document.addEventListener('DOMContentLoaded', () => {
  window.flashMessages = new FlashMessages();
});

document.addEventListener('turbo:load', () => {
  window.flashMessages = new FlashMessages();
});

// Cleanup on Turbo before-cache
document.addEventListener('turbo:before-cache', () => {
  if (window.flashMessages) {
    window.flashMessages.cleanup();
  }
});
