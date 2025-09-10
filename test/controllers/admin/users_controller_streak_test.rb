require "test_helper"

class Admin::UsersControllerStreakTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      email: "admin_streak_#{SecureRandom.hex(8)}@example.com",
      password: "password",
      role: "admin"
    )

    @user = User.create!(
      email: "user_streak_#{SecureRandom.hex(8)}@example.com",
      password: "password",
      role: "commentor",
      current_streak: 5,
      longest_streak: 10,
      last_login_date: Date.current - 1.day
    )

    sign_in @admin
  end

  test "should reset user streak" do
    assert_difference "ActivityLog.count", 1 do
      patch reset_streak_admin_user_path(@user)
    end

    @user.reload
    assert_equal 0, @user.current_streak
    assert_nil @user.last_login_date
    assert_equal 10, @user.longest_streak # Should not change

    assert_redirected_to admin_user_path(@user)
    assert_match "Streak reset", flash[:notice]

    # Check activity log
    activity = ActivityLog.last
    assert_equal "user_streak_reset", activity.action
    assert_equal @admin, activity.user  # Admin who performed the action
    assert_equal @user, activity.target  # Target user
  end

  test "should recalculate user streak" do
    assert_difference "ActivityLog.count", 1 do
      patch recalculate_streak_admin_user_path(@user)
    end

    assert_redirected_to admin_user_path(@user)
    assert_match "Streak recalculated", flash[:notice]

    activity = ActivityLog.last
    assert_equal "user_streak_recalculated", activity.action
  end

  test "should update streak manually with valid values" do
    assert_difference "ActivityLog.count", 1 do
      patch update_streak_admin_user_path(@user), params: {
        current_streak: 8,
        longest_streak: 15
      }
    end

    @user.reload
    assert_equal 8, @user.current_streak
    assert_equal 15, @user.longest_streak

    assert_redirected_to admin_user_path(@user)
    assert_match "Streak updated", flash[:notice]
  end

  test "should reject negative streak values" do
    patch update_streak_admin_user_path(@user), params: {
      current_streak: -1,
      longest_streak: 5
    }

    @user.reload
    assert_equal 5, @user.current_streak # Unchanged

    assert_redirected_to admin_user_path(@user)
    assert_match "cannot be negative", flash[:alert]
  end

  test "should handle bulk streak reset" do
    user2 = User.create!(
      email: "user2@example.com",
      password: "password",
      role: "commentor",
      current_streak: 3,
      longest_streak: 8
    )

    assert_difference "ActivityLog.count", 1 do
      post bulk_action_admin_users_path, params: {
        bulk_action: "reset_streaks",
        user_ids: [ @user.id, user2.id ]
      }
    end

    @user.reload
    user2.reload

    assert_equal 0, @user.current_streak
    assert_equal 0, user2.current_streak

    assert_redirected_to admin_users_path
    assert_match "Reset streaks for 2 users", flash[:notice]
  end

  test "should handle bulk streak recalculation" do
    user2 = User.create!(
      email: "user2@example.com",
      password: "password",
      role: "commentor"
    )

    assert_difference "ActivityLog.count", 1 do
      post bulk_action_admin_users_path, params: {
        bulk_action: "recalculate_streaks",
        user_ids: [ @user.id, user2.id ]
      }
    end

    assert_redirected_to admin_users_path
    assert_match "Recalculated streaks for 2 users", flash[:notice]
  end

  test "should not include admin in bulk actions" do
    post bulk_action_admin_users_path, params: {
      bulk_action: "reset_streaks",
      user_ids: [ @admin.id, @user.id ] # Include admin ID
    }

    # Only user streak should be reset, not admin
    @admin.reload
    @user.reload

    # Admin streak should be unchanged (assuming it had values)
    assert_equal 0, @user.current_streak # Changed
  end

  test "index should show streak statistics" do
    get admin_users_path

    assert_response :success
    assert_match "Active Streaks", response.body
    assert_match "Max Streak", response.body
    assert_match "Avg Streak", response.body
  end

  test "show page should display streak information" do
    get admin_user_path(@user)

    assert_response :success
    assert_match "Login Streak Management", response.body
    assert_match @user.streak_display, response.body
    assert_match "Reset Streak", response.body
    assert_match "Recalculate Streak", response.body
  end

  test "CSV export should include streak data" do
    get admin_users_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.content_type

    csv_content = response.body
    assert_match "Current Streak", csv_content
    assert_match "Longest Streak", csv_content
    assert_match "Timezone", csv_content
    assert_match @user.current_streak.to_s, csv_content
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password"
      }
    }
  end
end
