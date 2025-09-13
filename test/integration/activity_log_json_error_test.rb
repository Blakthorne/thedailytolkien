require "test_helper"

class ActivityLogJSONErrorTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in @admin
  end

  test "activity log page should not have JSON parsing error" do
    # Create some test activities
    ActivityLog.create!(
      user: @admin,
      action: "dashboard_view",
      ip_address: "127.0.0.1",
      user_agent: "Debug Test"
    )

    begin
      get admin_activity_logs_path
      assert_response :success
      puts "✅ Page loaded successfully"
    rescue JSON::ParserError => e
      puts "❌ JSON Error: #{e.message}"
      puts "Error location: #{e.backtrace.first(5)}"
      raise e
    rescue => e
      puts "❌ Other error: #{e.class.name}: #{e.message}"
      puts "Error location: #{e.backtrace.first(5)}"
      raise e
    end
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
