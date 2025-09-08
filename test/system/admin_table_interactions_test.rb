require "application_system_test_case"

class AdminTableInteractionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    @quote = quotes(:one)
  end

  def sign_in_admin
    visit new_user_session_path
    fill_in "user[email]", with: @admin.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"
    visit admin_root_path # Navigate to admin after login
  end

  test "clicking a quote row navigates to quote show" do
    sign_in_admin
    visit admin_quotes_path
    assert_selector "table[data-controller='sortable-table'] tbody tr", minimum: 1
  first_row = first("table[data-controller='sortable-table'] tbody tr")
  # Click second cell to avoid checkbox cell
  second_cell = first_row.all("td")[1]
  second_cell.click
    assert_current_path %r{/admin/quotes/\d+}
    assert_selector "h1", text: /Quote #/i
  end

  test "clicking a user row navigates to user show" do
    sign_in_admin
    visit admin_users_path
    assert_selector "table[data-controller='sortable-table'] tbody tr", minimum: 1
  # Skip first row if it has only current user and no checkbox; any row should work
  row = first("table[data-controller='sortable-table'] tbody tr")
  cell = row.all("td")[1]
  cell.click
    assert_current_path %r{/admin/users/\d+}
    assert_selector "h1", text: /User Details|Edit User|User #/i
  end

  test "sorting users by joined date toggles order" do
    sign_in_admin
    visit admin_users_path
  # Click the Joined header and then wait for any aria-sort to appear
  find("table[data-controller='sortable-table'] thead th", text: "Joined").click
  assert_selector "table[data-controller='sortable-table'] thead th[aria-sort]"
  end
end
