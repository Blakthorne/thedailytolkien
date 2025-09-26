class ApplicationController < ActionController::Base
  # Allow all browsers - no restrictions for maximum compatibility
  # allow_browser versions: :modern  # Commented out - was too restrictive

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_current_ip
  after_action :update_user_streak, if: :user_signed_in?

  # Handle routing errors and show custom error pages
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_422
  rescue_from StandardError, with: :render_500 if Rails.env.production?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :name, :streak_timezone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :name, :streak_timezone ])
  end

  # Redirect admin users to admin dashboard, others to home page
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    else
      root_path
    end
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

  public

  # Error handling methods for custom error pages
  def render_404
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.any { head :not_found }
    end
  end

  def render_422
    # Prefer JSON when this is an XHR/JSON request to avoid returning HTML that breaks fetch handlers
    if request.xhr? || request.format.json? || request.headers["Accept"].to_s.include?("application/json")
      render json: { error: "Unprocessable entity" }, status: :unprocessable_entity
    else
      render file: Rails.public_path.join("422.html"), status: :unprocessable_entity, layout: false
    end
  end

  def render_500(exception = nil)
    logger.error "Internal Server Error: #{exception.message}" if exception
    logger.error exception.backtrace.join("\n") if exception

    respond_to do |format|
      format.html { render file: Rails.public_path.join("500.html"), status: :internal_server_error, layout: false }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.any { head :internal_server_error }
    end
  end
end
