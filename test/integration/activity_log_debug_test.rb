require "test_helper"

class ActivityLogDebugTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in @admin
  end

  test "debug activity log content" do
    # Create some test activities
    ActivityLog.create!(
      user: @admin,
      action: "dashboard_view",
      ip_address: "127.0.0.1",
      user_agent: "Debug Test"
    )

    get admin_activity_logs_path
    assert_response :success

    # Print the response body to see what's actually being returned
    puts "\n" + "="*80
    puts "ACTIVITY LOG PAGE CONTENT DEBUG"
    puts "="*80
    puts "Response status: #{response.status}"

    # Check what parameters are being passed
    puts "Request parameters: #{request.params.inspect}"
    puts "Filtered params: #{request.params.slice(:user_id, :activity_action, :start_date, :end_date).inspect}"
    puts "Any filters present?: #{request.params.slice(:user_id, :activity_action, :start_date, :end_date).values.any?(&:present?)}"

    # Check if table is there
    if response.body.include?("<table")
      puts "✅ Table element found"
    else
      puts "❌ Table element NOT found"
    end

    # Check if tbody has content
    tbody_match = response.body.match(/<tbody>(.*?)<\/tbody>/m)
    if tbody_match
      tbody_content = tbody_match[1]
      puts "✅ tbody element found"
      puts "tbody content length: #{tbody_content.length}"

      if tbody_content.include?("empty-state")
        puts "❌ Shows empty state"
        puts "Empty state content:"
        empty_match = tbody_content.match(/<td[^>]*class="empty-state"[^>]*>(.*?)<\/td>/m)
        puts empty_match[1] if empty_match
      else
        puts "✅ No empty state detected"
        # Count table rows
        row_count = tbody_content.scan(/<tr[^>]*>/).length
        puts "Number of rows found: #{row_count}"
      end
    else
      puts "❌ tbody element NOT found"
    end

    # Check activities count in controller
    activities = ActivityLog.includes(:user, :target)
    # Simulate the exact controller logic
    existing_actions = ActivityLog.distinct.pluck(:action).compact
    valid_actions = (ActivityLog::ACTIONS & existing_actions).sort
    activities = activities.where(action: valid_actions)
    activities = activities.order(created_at: :desc).limit(200)

    puts "Valid actions: #{valid_actions.first(5)}"
    puts "Activities count from controller query: #{activities.count}"
    puts "Activities any?: #{activities.any?}"

    puts "="*80
    puts "\n"
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
