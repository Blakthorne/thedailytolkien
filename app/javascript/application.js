// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "timezone_management"
import { ProfileDropdown } from "profile_dropdown"

// Initialize profile dropdown on page load and Turbo navigation
document.addEventListener('DOMContentLoaded', () => {
  ProfileDropdown.init();
});

document.addEventListener('turbo:load', () => {
  ProfileDropdown.init();
});

document.addEventListener('turbo:before-cache', () => {
  ProfileDropdown.destroy();
});
