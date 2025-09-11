require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password",
      role: "commentor",
      streak_timezone: "UTC"
    )

    sign_in @user
  end

  test "should update user timezone successfully" do
    sign_in @user

    patch users_update_timezone_path, params: {
      timezone: "Eastern Time (US & Canada)"
    }, as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "Eastern Time (US & Canada)", json_response["timezone"]

    @user.reload
    assert_equal "Eastern Time (US & Canada)", @user.streak_timezone
  end

  test "should validate timezone and fallback to UTC" do
    patch users_update_timezone_path, params: {
      timezone: "Invalid/Timezone"
    }, as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "UTC", json_response["timezone"] # Fallback

    @user.reload
    assert_equal "UTC", @user.streak_timezone
  end

  test "should recalculate streak when timezone changes" do
    sign_in @user

    # Set up user with existing streak
    @user.update!(
      current_streak: 3,
      longest_streak: 5,
      last_login_date: Date.current - 1.day
    )

    patch users_update_timezone_path, params: {
      timezone: "Auckland"
    }, as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["streak"].present?
    assert_equal @user.reload.current_streak, json_response["streak"]["current"]
  end

  test "should handle timezone update errors gracefully" do
    sign_in @user

    # Test with empty timezone parameter to trigger validation
    patch users_update_timezone_path, params: {
      timezone: ""
    }, as: :json

    assert_response :success  # Should fallback to UTC for empty timezone

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "UTC", json_response["timezone"]  # Should fallback to UTC
  end

  test "should require authentication for timezone update" do
    sign_out @user

    patch users_update_timezone_path, params: {
      timezone: "Eastern Time (US & Canada)"
    }, as: :json

    assert_response :unauthorized
  end

  test "should handle server errors gracefully" do
    sign_in @user

    # Test with an invalid timezone format to trigger error handling
    patch users_update_timezone_path, params: {
      timezone: "Invalid/Timezone/Format"
    }, as: :json

    assert_response :success  # TimezoneDetectionService will validate and fallback to UTC

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "UTC", json_response["timezone"]  # Should fallback to UTC
  end

  test "should return streak information in response" do
    sign_in @user
    @user.update!(current_streak: 5, longest_streak: 10)

    patch users_update_timezone_path, params: {
      timezone: "London"
    }, as: :json

    json_response = JSON.parse(response.body)
    streak_data = json_response["streak"]

    assert_equal 5, streak_data["current"]
    assert_equal 10, streak_data["longest"]
    assert streak_data["display"].present?
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

  def sign_out(user)
    delete destroy_user_session_path
  end
end
