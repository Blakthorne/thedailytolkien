require "test_helper"

class StreakUpdateServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password",
      role: "commentor"
    )
  end

  test "should update user streak on first login" do
    login_time = Time.zone.parse("2024-01-15 10:00:00 UTC")
    
    # Clear the last_login_date to simulate a truly new user
    @user.update_column(:last_login_date, nil)

    result = StreakUpdateService.new(@user, login_time).call

    @user.reload
    assert_equal 1, @user.current_streak
    assert_equal 1, @user.longest_streak
    assert_equal Date.new(2024, 1, 15), @user.last_login_date

    assert result[:streak_continued] == false
    assert result[:streak_broken] == false
  end

  test "should continue streak on consecutive login" do
    @user.update(
      current_streak: 3,
      longest_streak: 5,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago # Ensure enough time has passed
    )

    login_time = Time.zone.parse("2024-01-16 10:00:00 UTC")

    result = StreakUpdateService.new(@user, login_time).call

    @user.reload
    assert_equal 4, @user.current_streak
    assert_equal 5, @user.longest_streak
    assert_equal Date.new(2024, 1, 16), @user.last_login_date

    assert result[:streak_continued] == true
  end

  test "should break streak after gap" do
    @user.update(
      current_streak: 5,
      longest_streak: 8,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago
    )

    # Login after 3 day gap
    login_time = Time.zone.parse("2024-01-19 10:00:00 UTC")

    result = StreakUpdateService.new(@user, login_time).call

    @user.reload
    assert_equal 1, @user.current_streak
    assert_equal 8, @user.longest_streak # Preserved
    assert_equal Date.new(2024, 1, 19), @user.last_login_date

    assert result[:streak_broken] == true
  end

  test "should not update if not enough time has passed" do
    @user.update(
      current_streak: 3,
      longest_streak: 5,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 30.minutes.ago # Recent update
    )

    login_time = Time.zone.parse("2024-01-16 10:00:00 UTC")

    # Should not update due to rate limiting
    result = StreakUpdateService.new(@user, login_time).call

    assert_nil result # No update performed
  end

  test "should handle validation errors gracefully" do
    @user.update(
      current_streak: 3,
      longest_streak: 5,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago
    )

    # Make user invalid by setting invalid timezone (bypassing validation for setup)
    @user.update_column(:streak_timezone, "Invalid/Timezone")

    result = StreakUpdateService.new(@user, Time.current).call

    # Should return current state on error
    assert_equal 3, result[:current_streak]
    assert_equal 5, result[:longest_streak]
    assert result[:error].present?
  end

  test "should create activity log for streak events" do
    @user.update(
      current_streak: 3,
      longest_streak: 5,
      last_login_date: Date.new(2024, 1, 13),  # 3 days ago to force streak break
      updated_at: 2.hours.ago
    )

    initial_activity_count = ActivityLog.count

    login_time = Time.zone.parse("2024-01-16 10:00:00 UTC")
    StreakUpdateService.new(@user, login_time).call

    # Should create an activity log entry for streak break only (per user request)
    assert_equal initial_activity_count + 1, ActivityLog.count

    activity = ActivityLog.last
    assert_equal @user, activity.user
    assert_equal "streak_broken", activity.action
  end

  test "should log streak broken event" do
    @user.update(
      current_streak: 5,
      longest_streak: 8,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago
    )

    initial_activity_count = ActivityLog.count

    # Login after gap to break streak
    login_time = Time.zone.parse("2024-01-19 10:00:00 UTC")
    StreakUpdateService.new(@user, login_time).call

    # Should create an activity log entry
    assert_equal initial_activity_count + 1, ActivityLog.count

    activity = ActivityLog.last
    assert_equal "streak_broken", activity.action
    assert_equal true, activity.details["streak_broken"]
  end

  test "should handle timezone in update" do
    @user.update(
      streak_timezone: "Eastern Time (US & Canada)",
      current_streak: 1,
      longest_streak: 1,
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago
    )

    # Create a time that is clearly the next day in Eastern timezone
    login_time = Time.zone.parse("2024-01-16 12:00:00 EST") # Noon Eastern Time

    StreakUpdateService.new(@user, login_time).call

    @user.reload
    # Should have incremented the streak for consecutive day
    assert_equal 2, @user.current_streak
    assert @user.last_login_date.present?
  end

  test "should preserve longest streak when current streak is reset" do
    @user.update(
      current_streak: 3,
      longest_streak: 10, # Higher than current
      last_login_date: Date.new(2024, 1, 15),
      updated_at: 2.hours.ago
    )

    # Break streak
    login_time = Time.zone.parse("2024-01-20 10:00:00 UTC")
    StreakUpdateService.new(@user, login_time).call

    @user.reload
    assert_equal 1, @user.current_streak # Reset
    assert_equal 10, @user.longest_streak # Preserved
  end
end
