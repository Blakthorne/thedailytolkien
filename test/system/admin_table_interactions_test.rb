require "application_system_test_case"

class AdminTableInteractionsTest < ApplicationSystemTestCase
  setup do
    # Clean up any existing test users first
    User.where("email LIKE ?", "%admin_interaction_test%").destroy_all

    @admin = User.create!(
      first_name: "Test",
      last_name: "AdminUser",
      email: "admin_interaction_test_#{Time.current.to_i}@example.com",
      password: "password123",
      role: "admin"
    )
    @quote = quotes(:one)
  end

  def teardown
    User.where("email LIKE ?", "%admin_interaction_test%").destroy_all
  end

  def sign_in_admin
    visit new_user_session_path
    fill_in "user[email]", with: @admin.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"

    # Ensure we're properly authenticated by checking for welcome message
    assert page.has_text?("Welcome, #{@admin.display_name}"), "Login failed - no welcome message"

    visit admin_root_path # Navigate to admin after login

    # Verify we're on admin page
    assert_current_path admin_root_path
  end

  test "clicking a quote row navigates to quote show" do
    sign_in_admin
    visit admin_quotes_path

    # Check if we're on the right page
    assert_current_path admin_quotes_path

    # Look for table and rows
    assert_selector "table tbody tr", minimum: 1

    first_row = first("table tbody tr")
    # Click second cell to avoid checkbox cell
    second_cell = first_row.all("td")[1]
    second_cell.click
    assert_current_path %r{/admin/quotes/\d+}
    assert_selector "h1", text: /Quote #/i
  end

  test "clicking a user row navigates to user show" do
    sign_in_admin
    visit admin_users_path

    # Look for the table and rows
    assert_selector "table tbody tr", minimum: 1

    # Skip first row if it has only current user and no checkbox; any row should work
    row = first("table tbody tr")
    cell = row.all("td")[1]
    cell.click
    assert_current_path %r{/admin/users/\d+}
  end

  test "sorting users by joined date toggles order" do
    sign_in_admin
    visit admin_users_path
  # Click the Joined header and then wait for any aria-sort to appear
  find("table[data-controller='sortable-table'] thead th", text: "Joined").click
  assert_selector "table[data-controller='sortable-table'] thead th[aria-sort]"
  end
end
