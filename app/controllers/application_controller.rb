class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_current_ip
  after_action :update_user_streak, if: :user_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :name, :streak_timezone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :name, :streak_timezone ])
  end

  # Always redirect to home page after successful sign in
  def after_sign_in_path_for(resource)
    root_path
  end

  # Always redirect to home page after successful sign up
  def after_sign_up_path_for(resource)
    root_path
  end

  private

  def store_current_ip
    RequestStore.store[:current_ip] = request.remote_ip
  end

  def update_user_streak
    # Only update streak on actual sign-in, not on every page load
    return unless should_update_streak_for_request?

    current_user.update_login_streak
  rescue StandardError => e
    Rails.logger.error "Failed to update streak for user #{current_user.id}: #{e.message}"
    # Don't let streak update failure break the user experience
  end

  def should_update_streak_for_request?
    # Update streak only on sign-in or if user hasn't been updated recently
    session[:just_signed_in] ||
      current_user.updated_at < 1.hour.ago
  ensure
    # Clear the flag after checking
    session.delete(:just_signed_in)
  end
end
