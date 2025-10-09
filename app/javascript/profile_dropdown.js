/**
 * Profile Dropdown System
 * Handles profile menu dropdown with proper Turbo cleanup
 */

export const ProfileDropdown = {
  initialized: false,
  boundHandleClick: null,
  boundHandleKeydown: null,
  boundHandleOutsideClick: null,
  isOpen: false,

  init() {
    if (this.initialized) return;
    
    this.boundHandleClick = this.handleClick.bind(this);
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    
    document.addEventListener('click', this.boundHandleClick);
    document.addEventListener('keydown', this.boundHandleKeydown);
    
    this.initialized = true;
  },

  destroy() {
    if (!this.initialized) return;
    
    if (this.boundHandleClick) {
      document.removeEventListener('click', this.boundHandleClick);
    }
    if (this.boundHandleKeydown) {
      document.removeEventListener('keydown', this.boundHandleKeydown);
    }
    if (this.boundHandleOutsideClick) {
      document.removeEventListener('click', this.boundHandleOutsideClick);
    }
    
    this.initialized = false;
    this.isOpen = false;
  },

  handleClick(event) {
    // Check if profile trigger button was clicked
    const trigger = event.target.closest('[data-profile-trigger]');
    if (trigger) {
      event.preventDefault();
      this.toggleDropdown(trigger);
      return;
    }
  },

  handleKeydown(event) {
    if (event.key === 'Escape' && this.isOpen) {
      this.closeDropdown();
    }
  },

  handleOutsideClick(event) {
    const dropdown = document.querySelector('[data-profile-dropdown]');
    const trigger = document.querySelector('[data-profile-trigger]');
    
    if (dropdown && trigger && 
        !dropdown.contains(event.target) && 
        !trigger.contains(event.target)) {
      this.closeDropdown();
    }
  },

  toggleDropdown(trigger) {
    if (this.isOpen) {
      this.closeDropdown();
    } else {
      this.openDropdown(trigger);
    }
  },

  openDropdown(trigger) {
    const dropdown = document.querySelector('[data-profile-dropdown]');
    if (!dropdown) return;

    dropdown.classList.add('active');
    trigger.setAttribute('aria-expanded', 'true');
    this.isOpen = true;

    // Add outside click listener after a brief delay
    setTimeout(() => {
      document.addEventListener('click', this.boundHandleOutsideClick);
    }, 10);
  },

  closeDropdown() {
    const dropdown = document.querySelector('[data-profile-dropdown]');
    const trigger = document.querySelector('[data-profile-trigger]');
    
    if (dropdown) {
      dropdown.classList.remove('active');
    }
    if (trigger) {
      trigger.setAttribute('aria-expanded', 'false');
    }
    
    this.isOpen = false;
    document.removeEventListener('click', this.boundHandleOutsideClick);
  }
};
