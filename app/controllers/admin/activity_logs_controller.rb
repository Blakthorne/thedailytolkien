class Admin::ActivityLogsController < AdminController
  def index
    @activities = ActivityLog.includes(:user, :target)

    # Filter by user if specified
    @activities = @activities.where(user_id: params[:user_id]) if params[:user_id].present?

    # Filter by action if specified
    @activities = @activities.where(action: params[:activity_action]) if params[:activity_action].present?

    # Filter by date range if specified
    if params[:start_date].present?
      @activities = @activities.where("created_at >= ?", Date.parse(params[:start_date]))
    end
    if params[:end_date].present?
      @activities = @activities.where("created_at <= ?", Date.parse(params[:end_date]).end_of_day)
    end

    # Get filter options first
    @users = User.joins(:activity_logs).distinct.order(:email)
    # Only show actions that exist in database AND are defined in the model
    existing_actions = ActivityLog.distinct.pluck(:action).compact
    @actions = (ActivityLog::ACTIONS & existing_actions).sort

    # CRITICAL: Filter activities to only show those with valid actions
    @activities = @activities.where(action: @actions)
    @activities = @activities.order(created_at: :desc).limit(200)

    # Activity logging removed for activity logs view per user request
  end

  def show
    @activity = ActivityLog.includes(:user, :target).find(params[:id])
    # Activity logging removed for individual activity log views per user request
  end
end
