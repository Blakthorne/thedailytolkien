require "test_helper"

class AdminComprehensiveTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @regular_user = users(:commentor_user)
    @quote = quotes(:one)

    # Sign in as admin for all tests
    sign_in @admin
  end

  # Test admin dashboard functionality
  test "admin dashboard loads successfully and shows all sections" do
    get admin_root_path
    assert_response :success

    # Check for key dashboard elements
    assert_select "h1", text: "Admin Dashboard"
    assert_select ".admin-stat-card"
    assert_select "h2", text: "Quick Actions"

    # Check for quick action links
    assert_select "a[href='#{new_admin_quote_path}']", text: "Add New Quote"
    assert_select "a[href='#{admin_users_path}']", text: "Manage Users"
    assert_select "a[href='#{admin_analytics_path}']", text: "View Analytics"
    assert_select "a[href='#{admin_quotes_path(format: :csv)}']", text: "Export Data"
  end

  # Test quotes management functionality
  test "quotes management - full CRUD operations" do
    # Test quotes index
    get admin_quotes_path
    assert_response :success
    assert_select "h1", text: "Manage Quotes"

    # Test quote creation
    get new_admin_quote_path
    assert_response :success
    assert_select "h1", text: "Add New Quote"

    post admin_quotes_path, params: {
      quote: {
        text: "Test quote for comprehensive testing",
        character: "Test Character",
        work: "Test Work",
        book: "Test Book",
        chapter: "1",
        days_displayed: 0
      }
    }
    assert_redirected_to admin_quote_path(Quote.last)
    follow_redirect!
    assert_select ".alert-success"

    # Test quote show page
    created_quote = Quote.last
  get admin_quote_path(created_quote)
  assert_response :success
  assert_select "h1", /Quote #/
  assert_select "h4", text: "Quick Actions"

  # Test quote editing
  get edit_admin_quote_path(created_quote)
  assert_response :success
  assert_select "h1", /Edit Quote #/

    patch admin_quote_path(created_quote), params: {
      quote: {
        text: "Updated test quote content",
        character: "Updated Character"
      }
    }
    assert_redirected_to admin_quote_path(created_quote)
    follow_redirect!
    assert_select ".alert-success"

    # Test quote deletion
    assert_difference("Quote.count", -1) do
      delete admin_quote_path(created_quote), headers: { "HTTP_ACCEPT" => "text/html" }
    end
    assert_redirected_to admin_quotes_path
  end

  # Test users management functionality
  test "users management - full CRUD operations and role management" do
    # Test users index
    get admin_users_path
    assert_response :success
    assert_select "h1", text: "Manage Users"

    # Test user show page
    get admin_user_path(@regular_user)
    assert_response :success
    assert_select "h1", text: "User Details"
    assert_select "h4", text: "Quick Actions"

    # Test user editing
    get edit_admin_user_path(@regular_user)
    assert_response :success
    assert_select "h1", text: "Edit User"

    patch admin_user_path(@regular_user), params: {
      user: {
        name: "Updated Name",
        email: @regular_user.email
      }
    }
    assert_redirected_to admin_user_path(@regular_user)
    follow_redirect!
    assert_select ".alert-success"

    # Test role promotion
    patch update_role_admin_user_path(@regular_user), params: { role: "admin" }
    assert_redirected_to admin_user_path(@regular_user)
    follow_redirect!
    assert_select ".alert-success"
    @regular_user.reload
    assert_equal "admin", @regular_user.role

    # Test role demotion
    patch update_role_admin_user_path(@regular_user), params: { role: "commentor" }
    assert_redirected_to admin_user_path(@regular_user)
    follow_redirect!
    assert_select ".alert-success"
    @regular_user.reload
    assert_equal "commentor", @regular_user.role

    # Test self role change prevention
    patch update_role_admin_user_path(@admin), params: { role: "commentor" }
    assert_redirected_to admin_user_path(@admin)
    follow_redirect!
    assert_select ".alert-alert", text: "You cannot change your own role."
    @admin.reload
    assert_equal "admin", @admin.role
  end

  # Test activity logs functionality
  test "activity logs management and viewing" do
    # Create some activity
    ActivityLog.create!(
      user: @admin,
      action: "create",
      target: @quote,
      details: { test: "comprehensive_test" },
      ip_address: "127.0.0.1"
    )

    # Test activity logs index
    get admin_activity_logs_path
    assert_response :success
    assert_select "h1", text: "Activity Log"

    # Test activity log show page
    activity = ActivityLog.last
    get admin_activity_log_path(activity)
    assert_response :success
    assert_select "h1", text: "Activity Details"
    assert_select "h4", text: "Quick Actions"

    # Test filtering by user
    get admin_activity_logs_path(user_id: @admin.id)
    assert_response :success

    # Test filtering by action
    get admin_activity_logs_path(action: "create")
    assert_response :success
  end

  # Test analytics functionality
  test "analytics page loads and displays data" do
    get admin_analytics_path
    assert_response :success
    assert_select "h1", text: "Analytics & Reports"

    # Check for stats sections
    assert_select ".admin-stat-card"

    # Check for any charts or data visualization elements
    assert_select "div[style*='background']" # Chart elements should have background styles
  end

  # Test bulk operations
  test "bulk delete operations work correctly" do
    # Create test quotes for bulk deletion
    quote1 = Quote.create!(text: "Bulk test 1", character: "Test", book: "Test", days_displayed: 0)
    quote2 = Quote.create!(text: "Bulk test 2", character: "Test", book: "Test", days_displayed: 0)

    # Test bulk delete of quotes
    assert_difference("Quote.count", -2) do
      post bulk_action_admin_quotes_path, params: {
        quote_ids: [ quote1.id, quote2.id ],
        bulk_action: "delete"
      }
    end
    assert_redirected_to admin_quotes_path
    follow_redirect!
    assert_select ".alert-success"
  end

  # Test export functionality
  test "data export functionality works" do
    # Test CSV export
    get admin_quotes_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  # Test navigation and accessibility
  test "admin navigation is accessible and functional" do
    get admin_root_path
    assert_response :success

    # Test main navigation links
    admin_paths = [
      admin_root_path,
      admin_quotes_path,
      admin_users_path,
      admin_activity_logs_path,
      admin_analytics_path
    ]

    admin_paths.each do |path|
      get path
      assert_response :success, "Failed to load #{path}"

      # Check for consistent admin styling elements
      assert_select ".admin-section", minimum: 1

      # Check for back navigation elements where appropriate
      unless path == admin_root_path
        assert_select "a[href*='admin']", minimum: 1
      end
    end
  end

  # Test error handling
  test "admin handles errors gracefully" do
    # Test accessing non-existent quote
    get admin_quote_path(999999)
    assert_response :not_found

    # Test accessing non-existent user
    get admin_user_path(999999)
    assert_response :not_found

    # Test invalid quote creation
    post admin_quotes_path, params: {
      quote: {
        text: "",  # Required field left empty
        character: "",
        book: ""
      }
    }
    assert_response :unprocessable_content
    assert_select ".alert-danger, .error, .field_with_errors"
  end

  # Test authorization
  test "admin access is properly restricted" do
    sign_out @admin
    sign_in @regular_user

    # Regular user should not be able to access admin sections
    get admin_root_path
    assert_redirected_to root_path

    get admin_quotes_path
    assert_redirected_to root_path

    get admin_users_path
    assert_redirected_to root_path
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

  def sign_out(user)
    delete destroy_user_session_path
  end
end
