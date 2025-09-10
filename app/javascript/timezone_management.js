// Timezone Detection and Management
document.addEventListener('DOMContentLoaded', function() {
  // Detect user's timezone on page load
  detectAndStoreTimezone();
  
  // Update timezone when user changes it
  const timezoneSelect = document.getElementById('user_streak_timezone');
  if (timezoneSelect) {
    timezoneSelect.addEventListener('change', handleTimezoneChange);
  }
});

function detectAndStoreTimezone() {
  try {
    // Get timezone from browser
    const browserTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    
    // Get timezone offset in minutes
    const timezoneOffset = new Date().getTimezoneOffset();
    
    // Store in session storage for form default
    sessionStorage.setItem('detectedTimezone', browserTimezone);
    sessionStorage.setItem('timezoneOffset', timezoneOffset.toString());
    
    // Set form field if present and not already set
    const timezoneField = document.getElementById('user_streak_timezone');
    if (timezoneField && !timezoneField.value) {
      timezoneField.value = browserTimezone;
    }
    
    // Send timezone info to server for new users
    sendTimezoneToServer(browserTimezone, timezoneOffset);
    
  } catch (error) {
    console.warn('Timezone detection failed:', error);
    // Fallback to UTC
    sessionStorage.setItem('detectedTimezone', 'UTC');
    sessionStorage.setItem('timezoneOffset', '0');
  }
}

function sendTimezoneToServer(timezone, offset) {
  // Only send if user is logged in and timezone hasn't been set
  const userTimezoneElement = document.querySelector('[data-user-timezone]');
  if (userTimezoneElement && userTimezoneElement.dataset.userTimezone === 'UTC') {
    
    fetch('/users/update_timezone', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        timezone: timezone,
        offset: offset
      })
    }).catch(error => {
      console.warn('Failed to update timezone on server:', error);
    });
  }
}

function handleTimezoneChange(event) {
  const newTimezone = event.target.value;
  
  // Show loading indicator
  showTimezoneUpdateFeedback('Updating timezone...');
  
  // Send timezone update to server
  fetch('/users/update_timezone', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({
      timezone: newTimezone
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      showTimezoneUpdateFeedback('Timezone updated successfully!', 'success');
      // Optionally refresh streak display
      refreshStreakDisplay();
    } else {
      showTimezoneUpdateFeedback('Failed to update timezone', 'error');
    }
  })
  .catch(error => {
    console.error('Timezone update failed:', error);
    showTimezoneUpdateFeedback('Failed to update timezone', 'error');
  });
}

function showTimezoneUpdateFeedback(message, type = 'info') {
  // Remove existing feedback
  const existingFeedback = document.querySelector('.timezone-feedback');
  if (existingFeedback) {
    existingFeedback.remove();
  }
  
  // Create feedback element
  const feedback = document.createElement('div');
  feedback.className = `timezone-feedback timezone-feedback--${type}`;
  feedback.textContent = message;
  
  // Style the feedback
  feedback.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 0.75rem 1rem;
    border-radius: 6px;
    color: white;
    font-size: 0.875rem;
    font-weight: 500;
    z-index: 1000;
    transform: translateX(100%);
    transition: transform 0.3s ease;
    ${type === 'success' ? 'background-color: #10b981;' : ''}
    ${type === 'error' ? 'background-color: #ef4444;' : ''}
    ${type === 'info' ? 'background-color: #3b82f6;' : ''}
  `;
  
  document.body.appendChild(feedback);
  
  // Animate in
  setTimeout(() => {
    feedback.style.transform = 'translateX(0)';
  }, 10);
  
  // Remove after delay
  setTimeout(() => {
    feedback.style.transform = 'translateX(100%)';
    setTimeout(() => feedback.remove(), 300);
  }, 3000);
}

function refreshStreakDisplay() {
  // Optionally refresh the page to show updated streak
  // or make an AJAX call to get updated streak data
  window.location.reload();
}
