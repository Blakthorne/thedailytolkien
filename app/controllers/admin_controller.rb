class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :log_admin_activity

  layout "admin"

  protected

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
