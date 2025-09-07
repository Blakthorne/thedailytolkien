class Admin::ActivityLogsController < AdminController
  def index
    @activities = ActivityLog.includes(:user, :target)

    # Filter by user if specified
    @activities = @activities.where(user_id: params[:user_id]) if params[:user_id].present?

    # Filter by action if specified
    @activities = @activities.where(action: params[:action]) if params[:action].present?

    # Filter by date range if specified
    if params[:start_date].present?
      @activities = @activities.where("created_at >= ?", Date.parse(params[:start_date]))
    end
    if params[:end_date].present?
      @activities = @activities.where("created_at <= ?", Date.parse(params[:end_date]).end_of_day)
    end

    @activities = @activities.order(created_at: :desc).limit(200)

    # Get filter options
    @users = User.admin.order(:email)
    @actions = ActivityLog.distinct.pluck(:action).compact.sort

    log_action("activity_logs_view", nil, {
      filters: {
        user_id: params[:user_id],
        action: params[:action],
        start_date: params[:start_date],
        end_date: params[:end_date]
      }
    })
  end

  def show
    @activity = ActivityLog.includes(:user, :target).find(params[:id])
    log_action("activity_log_view", @activity)
  end
end
