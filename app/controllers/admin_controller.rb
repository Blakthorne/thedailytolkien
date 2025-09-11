class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :log_admin_activity

  layout "admin"

  # Handle missing records gracefully
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found

  protected

  def handle_record_not_found(exception)
    # Log the 404 attempt for security monitoring
    log_action("record_not_found", nil, {
      attempted_model: exception.model,
      attempted_id: exception.id,
      attempted_path: request.path,
      referer: request.referer
    })

    # Determine appropriate redirect based on the model
    redirect_path = case exception.model
    when "User"
                      admin_users_path
    when "Quote"
                      admin_quotes_path
    when "Tag"
                      admin_tags_path
    when "Comment"
                      admin_comments_path
    when "ActivityLog"
                      admin_activity_logs_path
    else
                      admin_root_path
    end

    redirect_to redirect_path, alert: "#{exception.model} not found. It may have been deleted or the ID is incorrect."
  end

  def ensure_admin!
    unless current_user.admin?
      ActivityLog.create!(
        user: current_user,
        action: "unauthorized_access_attempt",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        details: {
          attempted_path: request.path,
          user_role: current_user.role
        }
      )

      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def log_admin_activity
  # Intentionally disabled noisy page/access logging.
  # We retain explicit logging only for meaningful admin actions
  # (creates, updates, deletes, role changes, exports, bulk ops) via log_action.
  nil
  end

  def log_action(action, target = nil, details = {})
    ActivityLog.create!(
      user: current_user,
      action: action,
      target: target,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      details: details
    )
  end
end
