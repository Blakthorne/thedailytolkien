# Service for calculating user login streaks with timezone awareness
class StreakCalculatorService
  attr_reader :user, :login_time, :user_timezone

  def initialize(user, login_time = Time.current)
    @user = user
    @login_time = login_time
    @user_timezone = user.streak_timezone || "UTC"
  end

  def calculate_streak
    user_date = @login_time.in_time_zone(@user_timezone).to_date
    last_login_date = @user.last_login_date

    return initialize_new_user_streak(user_date) if last_login_date.nil?

    case date_difference(last_login_date, user_date)
    when 0
      # Same day - no change needed
      {
        current_streak: @user.current_streak,
        longest_streak: @user.longest_streak,
        last_login_date: user_date,
        streak_continued: false,
        streak_broken: false
      }
    when 1
      # Consecutive day - increment streak
      new_current = @user.current_streak + 1
      new_longest = [ new_current, @user.longest_streak ].max
      {
        current_streak: new_current,
        longest_streak: new_longest,
        last_login_date: user_date,
        streak_continued: true,
        streak_broken: false
      }
    else
      # Streak broken - reset to 1
      {
        current_streak: 1,
        longest_streak: @user.longest_streak,
        last_login_date: user_date,
        streak_continued: false,
        streak_broken: @user.current_streak > 0
      }
    end
  end

  def streak_status
    user_date = @login_time.in_time_zone(@user_timezone).to_date
    last_login_date = @user.last_login_date

    return :new_user if last_login_date.nil?

    case date_difference(last_login_date, user_date)
    when 0
      :same_day
    when 1
      :consecutive_day
    else
      :streak_broken
    end
  end

  private

  def initialize_new_user_streak(user_date)
    {
      current_streak: 1,
      longest_streak: 1,
      last_login_date: user_date,
      streak_continued: false,
      streak_broken: false
    }
  end

  def date_difference(last_date, current_date)
    return Float::INFINITY if last_date.nil?
    (current_date - last_date).to_i
  end
end
