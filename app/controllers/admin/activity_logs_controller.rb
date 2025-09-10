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
    @users = User.joins(:activity_logs).distinct.order(:email)
    @actions = ActivityLog.distinct.pluck(:action).compact.sort

    # Activity logging removed for activity logs view per user request
  end

  def show
    @activity = ActivityLog.includes(:user, :target).find(params[:id])
    # Activity logging removed for individual activity log views per user request
  end
end
