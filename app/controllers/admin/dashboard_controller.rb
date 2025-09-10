class Admin::DashboardController < AdminController
  def index
    @stats = calculate_dashboard_stats
    @recent_quotes = Quote.order(created_at: :desc).limit(5)
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_activities = ActivityLog.includes(:user, :target)
                                  .order(created_at: :desc)
                                  .limit(10)

    # No logging for dashboard views
  end

  private

  def calculate_dashboard_stats
    today_start = Date.current.beginning_of_day

    {
      total_users: User.count,
      admin_users: User.admin.count,
      recent_users: User.where("created_at > ?", 7.days.ago).count,
      comments_today: Comment.where("created_at >= ?", today_start).count,
      likes_dislikes_today: QuoteLike.where("created_at >= ?", today_start).count
    }
  end
end
