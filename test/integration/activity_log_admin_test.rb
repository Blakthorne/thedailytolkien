require "test_helper"

class ActivityLogAdminTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    sign_in @admin

    # Create some activity logs that will definitely show up
    @test_activity = ActivityLog.create!(
      user: @admin,
      action: "comment_created",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )
  end

  test "activity logs index page loads correctly" do
    get admin_activity_logs_path
    assert_response :success
    assert_select "h1", text: "Activity Log"
    assert_select "table.app-table"
  end

  test "activity logs shows data when activities exist" do
    get admin_activity_logs_path

    assert_response :success

    # Check that statistics show our activity
    assert_select ".admin-stat-card p", text: /\d+/

    # Should have table structure
    assert_select "table.app-table"
    assert_select "thead tr th", minimum: 6  # We have 6 columns
  end

  test "activity logs filtering by user works" do
    get admin_activity_logs_path, params: { user_id: @admin.id }
    assert_response :success

    # Check that the user filter is applied
    assert_select "select[name='user_id']"
  end

  test "activity logs filtering by action works" do
    get admin_activity_logs_path, params: { activity_action: "comment_created" }
    assert_response :success

    # Check that the action filter exists
    assert_select "select[name='activity_action']"
  end

  test "activity logs filtering by date range works" do
    start_date = 3.days.ago.strftime("%Y-%m-%d")
    end_date = Date.current.strftime("%Y-%m-%d")

    get admin_activity_logs_path, params: { start_date: start_date, end_date: end_date }

    assert_response :success

    # Check that date filters are set
    assert_select "input[name='start_date'][value='#{start_date}']"
    assert_select "input[name='end_date'][value='#{end_date}']"
  end

  test "activity logs shows appropriate empty state when no activities match filters" do
    get admin_activity_logs_path, params: { activity_action: "nonexistent_action" }

    assert_response :success
    assert_select ".empty-state h3", text: "No activity found"
    assert_select ".empty-state p", text: "No activity found matching your filters"
    assert_select "a", text: "Clear filters"
  end

  test "activity logs shows filter options correctly" do
    get admin_activity_logs_path

    assert_response :success

    # Check for filter form elements
    assert_select 'select[name="user_id"]'
    assert_select 'select[name="activity_action"]'
    assert_select 'input[name="start_date"][type="date"]'
    assert_select 'input[name="end_date"][type="date"]'
    assert_select 'input[type="submit"][value="Apply Filters"]'
  end

  test "activity log individual show page works" do
    get admin_activity_log_path(@test_activity)

    assert_response :success
    assert_select "h1", text: "Activity Details"

    # Check that activity details are shown
    assert_select "span", text: @test_activity.action_description
  end

  test "activity log action descriptions are human readable" do
    # Test that our action_description method returns human-readable text
    activity = ActivityLog.new(action: "comment_created")
    assert_equal "created a comment", activity.action_description

    activity = ActivityLog.new(action: "user_role_change")
    assert_equal "changed user role", activity.action_description

    activity = ActivityLog.new(action: "quotes_csv_import")
    assert_equal "imported quotes from CSV", activity.action_description
  end

  test "activity log target descriptions work correctly" do
    quote = quotes(:one)
    activity = ActivityLog.new(target: quote)
    assert_includes activity.target_description, "Quote:"
    assert_includes activity.target_description, quote.text.truncate(50)

    user = users(:admin_user)
    activity = ActivityLog.new(target: user)
    assert_includes activity.target_description, "User:"
    assert_includes activity.target_description, user.email
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
