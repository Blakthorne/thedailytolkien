/**
 * Quote Engagement System
 * Handles like/dislike interactions and comment functionality
 * Optimized for Turbo navigation with proper cleanup
 * 
 * This module provides a complete engagement system that:
 * - Works consistently across Turbo navigations
 * - Has proper cleanup to prevent memory leaks
 * - Provides real-time updates via ActionCable
 * - Includes comprehensive error handling
 * - Maintains accessibility standards
 */

/**
 * QuoteEngagement - Like/Dislike functionality
 */
export const QuoteEngagement = {
  initialized: false,
  boundHandleClick: null,

  /**
   * Initialize the engagement system
   */
  init() {
    if (this.initialized) return;
    
    // Bind the click handler once to preserve reference for cleanup
    this.boundHandleClick = this.handleClick.bind(this);
    document.addEventListener('click', this.boundHandleClick);
    
    this.initialized = true;
  },

  /**
   * Clean up event listeners (called before Turbo caches the page)
   */
  destroy() {
    if (!this.initialized) return;
    
    if (this.boundHandleClick) {
      document.removeEventListener('click', this.boundHandleClick);
    }
    
    this.initialized = false;
  },

  /**
   * Handle click events on engagement buttons
   */
  handleClick(event) {
    // Use event delegation to find engagement buttons
    const button = event.target.closest('[data-quote-engagement] .engagement-btn[data-type]');
    if (!button) return;

    event.preventDefault();
    
    const quoteId = button.closest('[data-quote-engagement]').dataset.quoteId;
    const type = button.dataset.type;
    
    if (!quoteId || !type) return;
    
    this.submitLike(button, quoteId, type);
  },

  /**
   * Submit like/dislike via AJAX
   */
  async submitLike(button, quoteId, type) {
    // Prevent double-clicks
    if (button.disabled) return;
    
    this.setButtonLoading(button, true);

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
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
        const errorMsg = data.error || 'An error occurred';
        alert(errorMsg);
      }

    } catch (error) {
      console.error('Engagement error:', error);
      alert('Network error. Please try again.');
    } finally {
      this.setButtonLoading(button, false);
    }
  },

  /**
   * Update the engagement UI with new data
   */
  updateEngagementUI(data) {
    const container = document.querySelector('[data-quote-engagement]');
    if (!container) return;

    const likeBtn = container.querySelector('.like-btn');
    const dislikeBtn = container.querySelector('.dislike-btn');
    
    if (!likeBtn || !dislikeBtn) return;

    // Reset active states
    likeBtn.classList.remove('like-active');
    dislikeBtn.classList.remove('dislike-active');

    // Update counts
    const likeCount = likeBtn.querySelector('.count');
    const dislikeCount = dislikeBtn.querySelector('.count');
    
    if (likeCount && typeof data.likes_count !== 'undefined') {
      likeCount.textContent = data.likes_count;
    }
    if (dislikeCount && typeof data.dislikes_count !== 'undefined') {
      dislikeCount.textContent = data.dislikes_count;
    }

    // Set active state and ARIA attributes
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

  /**
   * Update only counts (for ActionCable broadcasts)
   */
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

  /**
   * Set button loading state
   */
  setButtonLoading(button, loading) {
    button.disabled = loading;
    if (loading) {
      button.classList.add('loading');
    } else {
      button.classList.remove('loading');
    }
  }
};

/**
 * QuoteComments - Comment interaction functionality
 */
export const QuoteComments = {
  /**
   * Initialize comment functionality
   */
  init() {
    this.bindCommentFormSubmission();
    this.bindCommentInteractions();
    this.bindReplyForms();
    this.bindEditForms();
    this.bindDeleteButtons();
  },

  /**
   * Bind main comment form submission
   */
  bindCommentFormSubmission() {
    const commentForm = document.getElementById('comment-form');
    if (commentForm) {
      commentForm.addEventListener('submit', this.handleCommentSubmission.bind(this));
    }
  },

  /**
   * Bind comment interaction buttons (reply, edit, cancel)
   */
  bindCommentInteractions() {
    document.addEventListener('click', this.handleCommentClick.bind(this));
  },

  /**
   * Bind reply form submissions
   */
  bindReplyForms() {
    document.addEventListener('submit', this.handleReplySubmission.bind(this));
  },

  /**
   * Bind edit form submissions
   */
  bindEditForms() {
    document.addEventListener('submit', this.handleEditSubmission.bind(this));
  },

  /**
   * Bind delete button clicks
   */
  bindDeleteButtons() {
    document.addEventListener('click', this.handleDeleteClick.bind(this));
  },

  /**
   * Handle main comment form submission
   */
  handleCommentSubmission(e) {
    e.preventDefault();
    
    const form = e.target;
    const formData = new FormData(form);
    const submitBtn = form.querySelector('.btn-primary');
    
    submitBtn.disabled = true;
    submitBtn.textContent = 'Posting...';
    
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        document.getElementById('comment_content').value = '';
        
        if (data.html) {
          const commentsList = document.getElementById('comments-list');
          if (commentsList.innerHTML.includes('No comments yet')) {
            commentsList.innerHTML = data.html;
          } else {
            commentsList.insertAdjacentHTML('beforeend', data.html);
          }
        }
        
        const commentsTitle = document.querySelector('.comments-section .section-title');
        if (commentsTitle) {
          commentsTitle.innerHTML = `Comments (${data.comments_count})`;
        }
      } else {
        const errorMessage = data.errors ? data.errors.join(', ') : (data.error || 'Error posting comment. Please try again.');
        alert(errorMessage);
      }
    })
    .catch(error => {
      console.error('Error:', error);
      alert('Error posting comment. Please try again.');
    })
    .finally(() => {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Post Comment';
    });
  },

  /**
   * Handle comment button clicks (reply, edit, cancel)
   */
  handleCommentClick(e) {
    if (e.target.classList.contains('reply-btn')) {
      this.toggleReplyForm(e.target.dataset.commentId);
    } else if (e.target.classList.contains('cancel-reply-btn')) {
      this.hideReplyForm(e.target.dataset.commentId);
    } else if (e.target.classList.contains('edit-btn')) {
      this.showEditForm(e.target.dataset.commentId);
    } else if (e.target.classList.contains('cancel-edit-btn')) {
      this.hideEditForm(e.target.dataset.commentId);
    }
  },

  /**
   * Toggle reply form visibility
   */
  toggleReplyForm(commentId) {
    const replyForm = document.getElementById(`reply-form-${commentId}`);
    
    document.querySelectorAll('.reply-form').forEach(form => {
      if (form.id !== `reply-form-${commentId}`) {
        form.style.display = 'none';
      }
    });
    
    replyForm.style.display = replyForm.style.display === 'none' ? 'block' : 'none';
    
    if (replyForm.style.display === 'block') {
      const textarea = replyForm.querySelector('textarea');
      setTimeout(() => textarea.focus(), 100);
    }
  },

  /**
   * Hide reply form
   */
  hideReplyForm(commentId) {
    const replyForm = document.getElementById(`reply-form-${commentId}`);
    replyForm.style.display = 'none';
    replyForm.querySelector('textarea').value = '';
  },

  /**
   * Show edit form
   */
  showEditForm(commentId) {
    const editForm = document.getElementById(`edit-form-${commentId}`);
    const commentContent = document.querySelector(`[data-comment-id="${commentId}"] .comment-content`);
    
    document.querySelectorAll('.edit-form').forEach(form => {
      if (form.id !== `edit-form-${commentId}`) {
        form.style.display = 'none';
      }
    });
    
    if (commentContent && editForm) {
      commentContent.style.display = 'none';
      editForm.style.display = 'block';
      
      const textarea = editForm.querySelector('textarea');
      setTimeout(() => textarea.focus(), 100);
    }
  },

  /**
   * Hide edit form
   */
  hideEditForm(commentId) {
    const editForm = document.getElementById(`edit-form-${commentId}`);
    const commentContent = document.querySelector(`[data-comment-id="${commentId}"] .comment-content`);
    
    if (editForm && commentContent) {
      editForm.style.display = 'none';
      commentContent.style.display = 'block';
    }
  },

  /**
   * Handle reply form submission
   */
  handleReplySubmission(e) {
    if (!e.target.classList.contains('reply-form-inner')) return;
    
    e.preventDefault();
    
    const form = e.target;
    const formData = new FormData(form);
    const submitBtn = form.querySelector('.btn-primary');
    const commentId = form.dataset.commentId;
    
    submitBtn.disabled = true;
    submitBtn.textContent = 'Posting...';
    
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        const replyForm = document.getElementById(`reply-form-${commentId}`);
        replyForm.style.display = 'none';
        form.querySelector('textarea').value = '';
        location.reload();
      } else {
        const errorMessage = data.errors ? data.errors.join(', ') : (data.error || 'Error posting reply. Please try again.');
        alert(errorMessage);
      }
    })
    .catch(error => {
      console.error('Error:', error);
      alert('Error posting reply. Please try again.');
    })
    .finally(() => {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Post Reply';
    });
  },

  /**
   * Handle edit form submission
   */
  handleEditSubmission(e) {
    if (!e.target.classList.contains('edit-form-inner')) return;
    
    e.preventDefault();
    
    const form = e.target;
    const formData = new FormData(form);
    const submitBtn = form.querySelector('.btn-primary');
    const commentId = form.dataset.commentId;
    
    submitBtn.disabled = true;
    submitBtn.textContent = 'Saving...';
    
    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        const commentContent = document.querySelector(`[data-comment-id="${commentId}"] .comment-content`);
        const editForm = document.getElementById(`edit-form-${commentId}`);
        const textarea = form.querySelector('textarea');
        
        if (commentContent && editForm) {
          const simpleFormatted = textarea.value
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/\n\s*\n/g, '</p><p>')
            .replace(/\n/g, '<br>')
            .replace(/^/, '<p>')
            .replace(/$/, '</p>')
            .replace(/<p><\/p>/g, '');
          commentContent.innerHTML = simpleFormatted;
          
          let editIndicator = document.querySelector(`[data-comment-id="${commentId}"] .edit-indicator`);
          if (!editIndicator) {
            editIndicator = document.createElement('span');
            editIndicator.className = 'edit-indicator';
            document.querySelector(`[data-comment-id="${commentId}"] .comment-actions`).appendChild(editIndicator);
          }
          editIndicator.textContent = `(edited just now)`;
          
          editForm.style.display = 'none';
          commentContent.style.display = 'block';
        }
      } else {
        const errorMessage = data.errors ? data.errors.join(', ') : (data.error || 'Error saving changes. Please try again.');
        alert(errorMessage);
      }
    })
    .catch(error => {
      console.error('Error:', error);
      alert('Error saving changes. Please try again.');
    })
    .finally(() => {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Save Changes';
    });
  },

  /**
   * Handle delete button clicks
   */
  handleDeleteClick(e) {
    if (!e.target.classList.contains('delete-btn')) return;
    
    const commentId = e.target.dataset.commentId;
    const confirmMessage = e.target.dataset.turboConfirm;
    
    if (confirm(confirmMessage)) {
      e.target.disabled = true;
      e.target.textContent = 'Deleting...';
      
      fetch(`/comments/${commentId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`);
          if (commentElement) {
            commentElement.remove();
          }
          
          if (data.total_count !== undefined) {
            const commentsTitle = document.querySelector('.comments-section .section-title');
            if (commentsTitle) {
              commentsTitle.innerHTML = `Comments (${data.total_count})`;
            }
          }
        } else {
          const errorMessage = data.error || 'Error deleting comment. Please try again.';
          alert(errorMessage);
          e.target.disabled = false;
          e.target.textContent = e.target.textContent.includes('Admin') ? 'Delete (Admin)' : 'Delete';
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert('Error deleting comment. Please try again.');
        e.target.disabled = false;
        e.target.textContent = e.target.textContent.includes('Admin') ? 'Delete (Admin)' : 'Delete';
      });
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
