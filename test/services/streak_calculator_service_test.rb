require "test_helper"

class StreakCalculatorServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password",
      role: "commentor",
      streak_timezone: "Eastern Time (US & Canada)"
    )
  end

  test "should initialize new user streak correctly" do
    login_time = Time.zone.parse("2024-01-15 10:00:00 EST")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    assert_equal 1, result[:current_streak]
    assert_equal 1, result[:longest_streak]
    assert_equal Date.new(2024, 1, 15), result[:last_login_date]
    assert_equal false, result[:streak_continued]
    assert_equal false, result[:streak_broken]
  end

  test "should not change streak for same day login" do
    @user.update(
      current_streak: 5,
      longest_streak: 10,
      last_login_date: Date.new(2024, 1, 15)
    )

    # Same day, different time
    login_time = Time.zone.parse("2024-01-15 18:00:00 EST")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    assert_equal 5, result[:current_streak]
    assert_equal 10, result[:longest_streak]
    assert_equal Date.new(2024, 1, 15), result[:last_login_date]
    assert_equal false, result[:streak_continued]
    assert_equal false, result[:streak_broken]
  end

  test "should increment streak for consecutive day login" do
    @user.update(
      current_streak: 5,
      longest_streak: 8,
      last_login_date: Date.new(2024, 1, 15)
    )

    # Next day login
    login_time = Time.zone.parse("2024-01-16 10:00:00 EST")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    assert_equal 6, result[:current_streak]
    assert_equal 8, result[:longest_streak] # Not exceeded yet
    assert_equal Date.new(2024, 1, 16), result[:last_login_date]
    assert_equal true, result[:streak_continued]
    assert_equal false, result[:streak_broken]
  end

  test "should update longest streak when current exceeds it" do
    @user.update(
      current_streak: 7,
      longest_streak: 7,
      last_login_date: Date.new(2024, 1, 15)
    )

    # Next day login - should create new record
    login_time = Time.zone.parse("2024-01-16 10:00:00 EST")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    assert_equal 8, result[:current_streak]
    assert_equal 8, result[:longest_streak] # New record!
    assert_equal true, result[:streak_continued]
  end

  test "should reset streak for gap in login" do
    @user.update(
      current_streak: 5,
      longest_streak: 10,
      last_login_date: Date.new(2024, 1, 15)
    )

    # Login after 3 days gap
    login_time = Time.zone.parse("2024-01-19 10:00:00 EST")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    assert_equal 1, result[:current_streak] # Reset to 1
    assert_equal 10, result[:longest_streak] # Preserved
    assert_equal Date.new(2024, 1, 19), result[:last_login_date]
    assert_equal false, result[:streak_continued]
    assert_equal true, result[:streak_broken]
  end

  test "should handle timezone correctly" do
    @user.update(streak_timezone: "Auckland") # UTC+13

    # 11 PM Auckland time on Jan 15
    # This would be earlier in UTC (about 10 AM UTC on Jan 15)
    login_time = Time.zone.parse("2024-01-15 23:00:00 +1300") # Auckland time with offset
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    # Should use Auckland date (Jan 15), regardless of UTC date
    assert_equal Date.new(2024, 1, 15), result[:last_login_date]
  end

  test "streak_status should return correct status" do
    current_time = Time.current.in_time_zone(@user.streak_timezone)
    user_date = current_time.to_date

    service = StreakCalculatorService.new(@user, current_time)
    assert_equal :new_user, service.streak_status

    @user.update(last_login_date: user_date)
    service = StreakCalculatorService.new(@user, current_time)
    assert_equal :same_day, service.streak_status

    @user.update(last_login_date: user_date - 1.day)
    service = StreakCalculatorService.new(@user, current_time)
    assert_equal :consecutive_day, service.streak_status

    @user.update(last_login_date: user_date - 3.days)
    service = StreakCalculatorService.new(@user, current_time)
    assert_equal :streak_broken, service.streak_status
  end

  test "should handle daylight saving time transitions" do
    # Set up user in timezone that observes DST
    @user.update(streak_timezone: "Eastern Time (US & Canada)") # EST/EDT

    # Login on March 10, 2024 (day before DST starts)
    @user.update(last_login_date: Date.new(2024, 3, 10))

    # Login on March 11, 2024 (DST starts - clocks spring forward)
    login_time = Time.zone.parse("2024-03-11 10:00:00").in_time_zone("Eastern Time (US & Canada)")
    service = StreakCalculatorService.new(@user, login_time)

    result = service.calculate_streak

    # Should still be consecutive despite DST change
    assert_equal :consecutive_day, service.streak_status
    assert_equal true, result[:streak_continued]
  end

  test "should handle leap year correctly" do
    # Feb 28, 2024 (leap year)
    @user.update(last_login_date: Date.new(2024, 2, 28))

    # Feb 29, 2024 (leap day)
    login_time = Time.zone.parse("2024-02-29 10:00:00").in_time_zone(@user.streak_timezone)
    service = StreakCalculatorService.new(@user, login_time)

    assert_equal :consecutive_day, service.streak_status
  end
end
