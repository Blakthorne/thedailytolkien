import { Controller } from "@hotwired/stimulus"

// Mobile menu controller for responsive header navigation
export default class extends Controller {
  static targets = ["drawer"]

  connect() {
    // Bind escape key handler
    this.handleKeydown = this.handleKeydown.bind(this)
    
    // Set initial state
    this.isOpen = false
    
    // Get the menu button - it's within the element this controller is attached to
    this.menuButton = this.element.querySelector('.mobile-menu-toggle')
    
    if (!this.menuButton) {
      return
    }
    
    this.drawer = this.drawerTarget
    
    // Ensure proper initial ARIA state
    this.updateAriaStates()
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleKeydown)
    this.enableBodyScroll()
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.isOpen = true
    
    // Update visual state
    this.drawer.classList.add('active')
    this.updateAriaStates()
    
    // Prevent body scroll
    this.disableBodyScroll()
    
    // Add escape key listener
    document.addEventListener('keydown', this.handleKeydown)
    
    // Focus management - focus the close button for accessibility
    setTimeout(() => {
      const closeButton = this.drawer.querySelector('.mobile-drawer-close')
      if (closeButton) {
        closeButton.focus()
      }
    }, 150) // Allow animation to start
  }

  close() {
    this.isOpen = false
    
    // Update visual state
    this.drawer.classList.remove('active')
    this.updateAriaStates()
    
    // Re-enable body scroll
    this.enableBodyScroll()
    
    // Remove escape key listener
    document.removeEventListener('keydown', this.handleKeydown)
    
    // Return focus to menu button
    if (this.menuButton) {
      this.menuButton.focus()
    }
  }

  // Handle escape key to close drawer
  handleKeydown(event) {
    if (event.key === 'Escape' && this.isOpen) {
      event.preventDefault()
      this.close()
    }
  }

  // Update ARIA attributes for accessibility
  updateAriaStates() {
    if (!this.menuButton) return
    
    // Update menu button
    this.menuButton.setAttribute('aria-expanded', this.isOpen.toString())
    this.menuButton.setAttribute('aria-label', this.isOpen ? 'Close mobile menu' : 'Open mobile menu')
    
    // Update drawer
    this.drawer.setAttribute('aria-hidden', (!this.isOpen).toString())
  }

  // Prevent body scrolling when drawer is open
  disableBodyScroll() {
    document.body.style.overflow = 'hidden'
    document.body.style.position = 'fixed'
    document.body.style.width = '100%'
    document.body.style.top = `-${window.scrollY}px`
  }

  // Re-enable body scrolling
  enableBodyScroll() {
    const scrollY = document.body.style.top
    document.body.style.overflow = ''
    document.body.style.position = ''
    document.body.style.width = ''
    document.body.style.top = ''
    
    // Restore scroll position
    if (scrollY) {
      const scrollTop = parseInt(scrollY || '0') * -1
      window.scrollTo(0, scrollTop)
    }
  }

  // Handle clicks outside drawer (on overlay)
  clickOutside(event) {
    if (event.target === this.drawer.querySelector('.mobile-drawer-overlay')) {
      this.close()
    }
  }
}
