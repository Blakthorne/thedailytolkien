require "application_system_test_case"

class AdminRoleChangeUITest < ApplicationSystemTestCase
  setup do
    @admin = User.create!(first_name: "Test", last_name: "Admin", email: "ui-admin@example.com", password: "password123", role: "admin")
    @commentor = User.create!(first_name: "Test", last_name: "User", email: "ui-user@example.com", password: "password123", role: "commentor")
  end

  def login(email:, password:)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
  click_on "Sign In"
  # Wait for login to complete and the header to show the signed-in user
  assert_text "Welcome, #{email}"
  end

  test "admin can promote and demote a user via UI buttons using PATCH" do
  login(email: @admin.email, password: "password123")
  # Ensure we can access the admin area after login
  visit admin_root_path
  assert_text "Admin Dashboard"

  visit admin_user_path(@commentor)
    assert_text "User Details"

    # Promote to admin (accept confirm if shown)
    begin
      accept_confirm(wait: 1) { click_on "Make Admin" }
    rescue Capybara::ModalNotFound
      # No modal shown; action already submitted
    end
  assert_text "User role updated to Admin."

    # Demote back to commentor
    begin
      accept_confirm(wait: 1) { click_on "Make Commentor" }
    rescue Capybara::ModalNotFound
      # No modal shown; action already submitted
    end
  assert_text "User role updated to Commentor."
  end
end
