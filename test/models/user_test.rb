require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password",
      role: "commentor"
    )
  end

  test "should be valid with required attributes" do
    assert @user.valid?
  end

  test "should have default streak values after creation" do
    assert_equal 0, @user.current_streak
    assert_equal 0, @user.longest_streak
    assert_equal "UTC", @user.streak_timezone
  end

  test "should validate timezone is valid" do
    @user.streak_timezone = "Invalid/Timezone"
    assert_not @user.valid?
    assert_includes @user.errors[:streak_timezone], "must be a valid timezone"
  end

  test "should validate streak values are non-negative" do
    @user.current_streak = -1
    assert_not @user.valid?
    assert_includes @user.errors[:current_streak], "must be greater than or equal to 0"

    @user.current_streak = 0
    @user.longest_streak = -1
    assert_not @user.valid?
    assert_includes @user.errors[:longest_streak], "must be greater than or equal to 0"
  end

  test "streak_display should return correct format" do
    assert_equal "No streak yet", @user.streak_display

    @user.update(current_streak: 1)
    assert_equal "1 day streak!", @user.streak_display

    @user.update(current_streak: 5)
    assert_equal "5 day streak!", @user.streak_display
  end

  test "streak_emoji should return appropriate emoji based on streak" do
    assert_equal "📅", @user.streak_emoji # 0 days

    @user.update(current_streak: 1)
    assert_equal "🔥", @user.streak_emoji # 1-7 days

    @user.update(current_streak: 15)
    assert_equal "⚡", @user.streak_emoji # 8-30 days

    @user.update(current_streak: 50)
    assert_equal "🏆", @user.streak_emoji # 31-99 days

    @user.update(current_streak: 150)
    assert_equal "👑", @user.streak_emoji # 100+ days
  end

  test "has_longest_streak_record? should work correctly" do
    assert_not @user.has_longest_streak_record?

    @user.update(current_streak: 5, longest_streak: 5)
    assert_not @user.has_longest_streak_record?

    @user.update(current_streak: 3, longest_streak: 10)
    assert @user.has_longest_streak_record?
  end

  test "reset_streak! should reset to defaults" do
    @user.update(current_streak: 10, longest_streak: 15, last_login_date: Date.current)

    @user.reset_streak!

    assert_equal 0, @user.current_streak
    assert_equal 15, @user.longest_streak # Longest streak should not be reset
    assert_nil @user.last_login_date
  end

  test "should set default role and timezone on creation" do
    new_user = User.new(email: "new@example.com", password: "password")
    new_user.valid? # Trigger validations

    assert_equal "commentor", new_user.role
    assert_equal "UTC", new_user.streak_timezone
  end

  test "admin? and commentor? methods should work correctly" do
    assert @user.commentor?
    assert_not @user.admin?

    @user.update(role: "admin")
    assert @user.admin?
    assert_not @user.commentor?
  end

  test "should require valid role" do
    assert_raises(ArgumentError) do
      @user.role = "invalid_role"
    end
  end
end
