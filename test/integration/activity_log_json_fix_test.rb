require "test_helper"

class ActivityLogJSONFixTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in @admin
  end

  test "activity log page loads without JSON parsing errors after fix" do
    get admin_activity_logs_path
    assert_response :success

    # Check that the page contains expected content
    assert_select "table.app-table"

    # The page should contain activity data or show that there are activities
    # Since we have 205+ activities, we should see either the table rows or pagination
    page_content = response.body
    refute_includes page_content, "JSON::ParserError", "Page should not contain JSON parsing errors"
    refute_includes page_content, "unexpected token", "Page should not contain JSON parsing errors"

    puts "✅ Activity logs page loaded successfully without JSON errors after fixing malformed data!"
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
