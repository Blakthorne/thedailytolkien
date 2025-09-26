/**
 * LikeDislike - Clean, Turbo-compatible like/dislike functionality
 * 
 * This module provides a complete like/dislike system that:
 * - Works consistently across Turbo navigations
 * - Has proper cleanup to prevent memory leaks
 * - Provides real-time updates via ActionCable
 * - Includes comprehensive error handling
 * - Maintains accessibility standards
 */

class LikeDislike {
  constructor() {
    this.isInitialized = false;
    this.quoteChannel = null;
    this.boundClickHandler = this.handleButtonClick.bind(this);
  }

  /**
   * Initialize the like/dislike functionality
   * Sets up event listeners and ActionCable subscription
   */
  init() {
    if (this.isInitialized) {
      this.cleanup(); // Clean up existing setup before reinitializing
    }

    this.setupEventListeners();
    this.setupActionCable();
    this.isInitialized = true;
  }

  /**
   * Clean up event listeners and subscriptions
   * Called before page navigation to prevent memory leaks
   */
  cleanup() {
    if (!this.isInitialized) return;

    // Remove event listeners
    const container = document.querySelector('.quote-engagement-section');
    if (container) {
      container.removeEventListener('click', this.boundClickHandler);
    }

    // Unsubscribe from ActionCable
    if (this.quoteChannel && typeof this.quoteChannel.unsubscribe === 'function') {
      try {
        this.quoteChannel.unsubscribe();
        this.quoteChannel = null;
      } catch (error) {
        console.warn('Error unsubscribing from quote channel:', error);
      }
    }

    this.isInitialized = false;
  }

  /**
   * Set up click event listeners using event delegation
   */
  setupEventListeners() {
    const container = document.querySelector('.quote-engagement-section');
    if (!container) return;

    container.addEventListener('click', this.boundClickHandler);
  }

  /**
   * Handle click events on like/dislike buttons
   * @param {Event} event - The click event
   */
  handleButtonClick(event) {
    const button = event.target.closest('.engagement-btn[data-type]');
    if (!button) return;

    event.preventDefault();
    
    const quoteId = button.dataset.quoteId;
    const type = button.dataset.type;
    
    if (!quoteId || !type) {
      console.error('Missing quote ID or type data');
      return;
    }

    this.submitLikeDislike(quoteId, type, button);
  }

  /**
   * Submit like/dislike request to the server
   * @param {string} quoteId - The quote ID
   * @param {string} type - 'like' or 'dislike'
   * @param {HTMLElement} button - The clicked button
   */
  async submitLikeDislike(quoteId, type, button) {
    // Prevent double-clicks
    if (button.disabled) return;

    // Set loading state
    this.setButtonLoading(button, true);

    try {
      const csrfToken = this.getCSRFToken();
      if (!csrfToken) {
        throw new Error('CSRF token not found');
      }

      const response = await fetch(`/quotes/${quoteId}/likes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin',
        body: JSON.stringify({ like_type: type })
      });

      await this.handleResponse(response);

    } catch (error) {
      this.handleError(error);
    } finally {
      this.setButtonLoading(button, false);
    }
  }

  /**
   * Handle the server response
   * @param {Response} response - The fetch response
   */
  async handleResponse(response) {
    if (!response.ok) {
      if (response.status === 401) {
        alert('Your session has expired. Please sign in again to like or dislike.');
        return;
      } else if (response.status === 422) {
        alert('Your request could not be processed. Reloading the page...');
        window.location.reload();
        return;
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    
    if (data.success) {
      this.updateUI(data);
    } else {
      const errorMsg = data.error || (data.errors && data.errors.join(', ')) || 'Unknown error occurred';
      alert(`Error: ${errorMsg}`);
    }
  }

  /**
   * Handle errors during the request
   * @param {Error} error - The error object
   */
  handleError(error) {
    console.error('Like/Dislike Error:', error);
    alert('Network error. Please check your connection and try again.');
  }

  /**
   * Update the UI with new like/dislike data
   * @param {Object} data - The response data containing likes/dislikes counts and user status
   */
  updateUI(data) {
    const likeBtn = document.querySelector('.like-btn');
    const dislikeBtn = document.querySelector('.dislike-btn');
    
    if (!likeBtn || !dislikeBtn) return;

    // Reset active states
    likeBtn.classList.remove('like-active');
    dislikeBtn.classList.remove('dislike-active');

    // Update counts
    this.updateCount(likeBtn, data.likes_count);
    this.updateCount(dislikeBtn, data.dislikes_count);

    // Set active state based on user preference
    const isLiked = data.user_like_status === 'like';
    const isDisliked = data.user_like_status === 'dislike';

    if (isLiked) {
      likeBtn.classList.add('like-active');
    } else if (isDisliked) {
      dislikeBtn.classList.add('dislike-active');
    }

    // Update ARIA attributes for accessibility
    likeBtn.setAttribute('aria-pressed', isLiked.toString());
    dislikeBtn.setAttribute('aria-pressed', isDisliked.toString());
  }

  /**
   * Update only the engagement counts (used for ActionCable broadcasts)
   * @param {Object} data - The broadcast data containing updated counts
   */
  updateCounts(data) {
    const likeBtn = document.querySelector('.like-btn');
    const dislikeBtn = document.querySelector('.dislike-btn');
    
    if (!likeBtn || !dislikeBtn) return;

    this.updateCount(likeBtn, data.likes_count);
    this.updateCount(dislikeBtn, data.dislikes_count);
  }

  /**
   * Update a single count element
   * @param {HTMLElement} button - The button containing the count
   * @param {number} count - The new count value
   */
  updateCount(button, count) {
    if (typeof count === 'undefined') return;
    
    const countElement = button.querySelector('.count');
    if (countElement) {
      countElement.textContent = count;
    }
  }

  /**
   * Set loading state on a button
   * @param {HTMLElement} button - The button to modify
   * @param {boolean} loading - Whether to set loading state
   */
  setButtonLoading(button, loading) {
    if (loading) {
      button.classList.add('loading');
      button.disabled = true;
    } else {
      button.classList.remove('loading');
      button.disabled = false;
    }
  }

  /**
   * Get the CSRF token from the page
   * @returns {string|null} The CSRF token or null if not found
   */
  getCSRFToken() {
    const csrfMeta = document.querySelector('meta[name="csrf-token"]');
    return csrfMeta ? csrfMeta.getAttribute('content') : null;
  }

  /**
   * Set up ActionCable subscription for real-time updates
   */
  setupActionCable() {
    // Check if we have a quote ID and ActionCable is available
    const quoteElement = document.querySelector('[data-quote-id]');
    if (!quoteElement || typeof ActionCable === 'undefined') return;

    const quoteId = quoteElement.dataset.quoteId;
    if (!quoteId) return;

    // Initialize ActionCable consumer if needed
    if (typeof window.App === 'undefined') {
      window.App = {};
    }
    if (typeof window.App.cable === 'undefined') {
      window.App.cable = ActionCable.createConsumer();
    }

    if (!window.App.cable) return;

    // Subscribe to quote interaction updates
    this.quoteChannel = window.App.cable.subscriptions.create({
      channel: "QuoteInteractionChannel",
      quote_id: parseInt(quoteId)
    }, {
      received: (data) => {
        if (data.type === 'like_update') {
          // Update like/dislike counts from other users without changing local active state
          this.updateCounts(data);
        }
        // Note: comment updates are handled separately in the main script
      }
    });
  }
}

// Create singleton instance
const likeDislike = new LikeDislike();

// Turbo lifecycle management
document.addEventListener('turbo:load', () => {
  likeDislike.init();
});

document.addEventListener('turbo:before-cache', () => {
  likeDislike.cleanup();
});

document.addEventListener('turbo:before-visit', () => {
  likeDislike.cleanup();
});

// Export for testing or manual access
window.LikeDislike = LikeDislike;
window.likeDislike = likeDislike;