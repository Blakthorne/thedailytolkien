# Service for updating user login streaks with proper error handling and logging
class StreakUpdateService
  attr_reader :user, :login_time

  def initialize(user, login_time = Time.current)
    @user = user
    @login_time = login_time
  end

  def call
    return unless should_update_streak?

    ActiveRecord::Base.transaction do
      calculator = StreakCalculatorService.new(user, login_time)
      streak_data = calculator.calculate_streak

      update_user_streak(streak_data)
      log_streak_update(streak_data)

      streak_data
    rescue StandardError => e
      Rails.logger.error "Failed to update streak for user #{user.id}: #{e.message}"
      # Return current state on error to avoid breaking login
      {
        current_streak: user.current_streak,
        longest_streak: user.longest_streak,
        last_login_date: user.last_login_date,
        streak_continued: false,
        streak_broken: false,
        error: e.message
      }
    end
  end

  private

  def should_update_streak?
    # Always allow streak calculation - removed rate limiting
    # Exception: Always allow updates for users who have never logged in (new users)
    return true if user.last_login_date.nil?

    true
  end

  def update_user_streak(streak_data)
    user.update!(
      current_streak: streak_data[:current_streak],
      longest_streak: streak_data[:longest_streak],
      last_login_date: streak_data[:last_login_date]
    )
  end

  def log_streak_update(streak_data)
    # Only log streak breaks, not streak continues per user request
    return unless streak_data[:streak_broken]

    ActivityLog.create!(
      user: user,
      action: streak_action_type(streak_data),
      details: streak_log_details(streak_data),
      ip_address: current_ip_address
    )
  end

  def streak_action_type(streak_data)
    "streak_broken"
  end

  def streak_log_details(streak_data)
    {
      current_streak: streak_data[:current_streak],
      longest_streak: streak_data[:longest_streak],
      login_time: login_time.iso8601,
      user_timezone: user.streak_timezone,
      streak_continued: streak_data[:streak_continued],
      streak_broken: streak_data[:streak_broken]
    }
  end

  def current_ip_address
    # This will be set by the controller during login
    RequestStore[:current_ip] || "127.0.0.1"
  end
end
