/**
 * Quote Engagement System
 * Handles like/dislike interactions and comment functionality
 * Optimized for Turbo navigation with proper cleanup
 */

/**
 * QuoteEngagement - Like/Dislike functionality
 */
export const QuoteEngagement = {
  initialized: false,
  boundHandleClick: null,

  init() {
    if (this.initialized) return;
    
    this.boundHandleClick = this.handleClick.bind(this);
    document.addEventListener('click', this.boundHandleClick);
    this.initialized = true;
  },

  destroy() {
    if (!this.initialized) return;
    
    if (this.boundHandleClick) {
      document.removeEventListener('click', this.boundHandleClick);
    }
    this.initialized = false;
  },

  handleClick(event) {
    const button = event.target.closest('[data-quote-engagement] .engagement-btn[data-type]');
    if (!button) return;

    event.preventDefault();
    
    const quoteId = button.closest('[data-quote-engagement]').dataset.quoteId;
    const type = button.dataset.type;
    
    if (!quoteId || !type) return;
    
    this.submitLike(button, quoteId, type);
  },

  async submitLike(button, quoteId, type) {
    if (button.disabled) return;
    
    this.setButtonLoading(button, true);

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      if (!csrfToken) throw new Error('CSRF token not found');

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

      if (!response.ok) {
        if (response.status === 401) {
          alert('Please sign in to like or dislike quotes.');
          return;
        } else if (response.status === 422) {
          alert('Session expired. Refreshing page...');
          window.location.reload();
          return;
        }
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success) {
        this.updateEngagementUI(data);
      } else {
        alert(data.error || 'An error occurred');
      }

    } catch (error) {
      console.error('Engagement error:', error);
      alert('Network error. Please try again.');
    } finally {
      this.setButtonLoading(button, false);
    }
  },

  updateEngagementUI(data) {
    const container = document.querySelector('[data-quote-engagement]');
    if (!container) return;

    const likeBtn = container.querySelector('.like-btn');
    const dislikeBtn = container.querySelector('.dislike-btn');
    
    if (!likeBtn || !dislikeBtn) return;

    likeBtn.classList.remove('like-active');
    dislikeBtn.classList.remove('dislike-active');

    const likeCount = likeBtn.querySelector('.count');
    const dislikeCount = dislikeBtn.querySelector('.count');
    
    if (likeCount && typeof data.likes_count !== 'undefined') {
      likeCount.textContent = data.likes_count;
    }
    if (dislikeCount && typeof data.dislikes_count !== 'undefined') {
      dislikeCount.textContent = data.dislikes_count;
    }

    const isLiked = data.user_like_status === 'like';
    const isDisliked = data.user_like_status === 'dislike';

    if (isLiked) {
      likeBtn.classList.add('like-active');
    } else if (isDisliked) {
      dislikeBtn.classList.add('dislike-active');
    }

    likeBtn.setAttribute('aria-pressed', isLiked.toString());
    dislikeBtn.setAttribute('aria-pressed', isDisliked.toString());
  },

  updateEngagementCounts(data) {
    const container = document.querySelector('[data-quote-engagement]');
    if (!container) return;

    const likeCount = container.querySelector('.like-btn .count');
    const dislikeCount = container.querySelector('.dislike-btn .count');

    if (likeCount && typeof data.likes_count !== 'undefined') {
      likeCount.textContent = data.likes_count;
    }
    if (dislikeCount && typeof data.dislikes_count !== 'undefined') {
      dislikeCount.textContent = data.dislikes_count;
    }
  },

  setButtonLoading(button, loading) {
    button.disabled = loading;
    button.classList.toggle('loading', loading);
  }
};

/**
 * QuoteComments - Comment interaction functionality
 */
export const QuoteComments = {
  initialized: false,
  boundClickHandler: null,

  init() {
    if (this.initialized) return;
    
    this.boundClickHandler = this.handleClick.bind(this);
    document.addEventListener('click', this.boundClickHandler);
    this.initialized = true;
  },

  destroy() {
    if (!this.initialized) return;
    
    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler);
    }
    this.initialized = false;
  },

  handleClick(event) {
    const target = event.target;

    // Reply button - show reply form
    if (target.classList.contains('reply-btn')) {
      event.preventDefault();
      const commentId = target.dataset.commentId;
      this.toggleForm(`reply-form-${commentId}`);
      return;
    }

    // Cancel reply button - hide reply form
    if (target.classList.contains('cancel-reply-btn')) {
      event.preventDefault();
      const commentId = target.dataset.commentId;
      this.hideForm(`reply-form-${commentId}`, true);
      return;
    }

    // Edit button - show edit form
    if (target.classList.contains('edit-btn')) {
      event.preventDefault();
      const commentId = target.dataset.commentId;
      const commentContent = document.querySelector(`[data-comment-id="${commentId}"] > .comment-content`);
      const editForm = document.getElementById(`edit-form-${commentId}`);
      
      if (commentContent && editForm) {
        const isVisible = editForm.style.display !== 'none';
        editForm.style.display = isVisible ? 'none' : 'block';
        commentContent.style.display = isVisible ? 'block' : 'none';
      }
      return;
    }

    // Cancel edit button - hide edit form
    if (target.classList.contains('cancel-edit-btn')) {
      event.preventDefault();
      const commentId = target.dataset.commentId;
      const commentContent = document.querySelector(`[data-comment-id="${commentId}"] > .comment-content`);
      const editForm = document.getElementById(`edit-form-${commentId}`);
      
      if (commentContent && editForm) {
        editForm.style.display = 'none';
        commentContent.style.display = 'block';
      }
      return;
    }

    // Delete button - submit DELETE request
    if (target.classList.contains('delete-btn')) {
      event.preventDefault();
      const commentId = target.dataset.commentId;
      const confirmMessage = target.dataset.turboConfirm || 'Are you sure you want to delete this comment?';
      
      if (confirm(confirmMessage)) {
        this.deleteComment(commentId);
      }
      return;
    }
  },

  toggleForm(formId) {
    const form = document.getElementById(formId);
    if (form) {
      const isHidden = form.style.display === 'none' || !form.style.display;
      form.style.display = isHidden ? 'block' : 'none';
    }
  },

  hideForm(formId, clearInput = false) {
    const form = document.getElementById(formId);
    if (form) {
      form.style.display = 'none';
      if (clearInput) {
        const textarea = form.querySelector('textarea');
        if (textarea) textarea.value = '';
      }
    }
  },

  async deleteComment(commentId) {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      if (!csrfToken) throw new Error('CSRF token not found');

      const response = await fetch(`/comments/${commentId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin'
      });

      if (!response.ok) {
        if (response.status === 403) {
          alert('You are not authorized to delete this comment.');
          return;
        }
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      
      if (data.success) {
        // Remove comment from DOM
        const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`);
        if (commentElement) {
          commentElement.remove();
        }
        
        // Update comment count
        const commentsTitle = document.querySelector('.comments-section .section-title');
        if (commentsTitle && typeof data.total_count !== 'undefined') {
          commentsTitle.textContent = `Comments (${data.total_count})`;
        }
      } else {
        alert(data.error || 'Failed to delete comment');
      }

    } catch (error) {
      console.error('Delete error:', error);
      alert('Network error. Please try again.');
    }
  }
};

/**
 * Global function for ActionCable backward compatibility
 * This allows ActionCable broadcasts to update engagement counts
 */
window.updateEngagementCounts = function(data) {
  QuoteEngagement.updateEngagementCounts(data);
};

/**
 * Make modules available globally for backward compatibility
 * This ensures existing inline code can still reference these objects
 */
window.QuoteEngagement = QuoteEngagement;
window.QuoteComments = QuoteComments;
