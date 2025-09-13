require "test_helper"

class ActivityLogJSONErrorTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in @admin
  end

  test "activity log page loads without JSON parsing error" do
    # Create some test activities
    ActivityLog.create!(
      user: @admin,
      action: "dashboard_view",
      ip_address: "127.0.0.1",
      user_agent: "Debug Test"
    )

    get admin_activity_logs_path
    assert_response :success

    # Check that the page contains expected content
    assert_select "table.app-table"
    assert_select "td", text: /viewed dashboard/

    puts "✅ Activity logs page loaded successfully without JSON errors"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
