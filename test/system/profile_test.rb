require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test_profile@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commentor,
      current_streak: 5,
      longest_streak: 10
    )

    @oauth_user = User.create!(
      first_name: "OAuth",
      last_name: "User",
      email: "oauth_profile@example.com",
      password: Devise.friendly_token[0, 20],
      provider: "google_oauth2",
      uid: "12345",
      role: :commentor,
      current_streak: 3,
      longest_streak: 7
    )
  end

  teardown do
    @user&.destroy
    @oauth_user&.destroy
  end

  # Desktop Dropdown Tests
  test "user can open profile dropdown on desktop" do
    sign_in @user
    visit root_path

    # Find and click the profile trigger button
    find("[data-profile-trigger]", wait: 5).click

    # Dropdown should become visible
    assert_selector("[data-profile-dropdown].active", wait: 2)
    assert_selector(".dropdown-link", text: "Profile")
    assert_selector("input[value='Logout']")
  end

  test "dropdown closes when clicking outside" do
    sign_in @user
    visit root_path

    # Open dropdown
    find("[data-profile-trigger]").click
    assert_selector("[data-profile-dropdown].active")

    # Click outside (on the quote card)
    find(".quote-card").click

    # Dropdown should close
    assert_no_selector("[data-profile-dropdown].active", wait: 2)
  end

  test "dropdown closes when pressing Escape key" do
    sign_in @user
    visit root_path

    # Open dropdown
    find("[data-profile-trigger]").click
    assert_selector("[data-profile-dropdown].active")

    # Press Escape
    page.driver.browser.action.send_keys(:escape).perform

    # Dropdown should close
    assert_no_selector("[data-profile-dropdown].active", wait: 2)
  end

  # Profile Navigation Tests
  test "user can navigate to profile from dropdown" do
    sign_in @user
    visit root_path

    # Open dropdown and click Profile link
    find("[data-profile-trigger]").click
    click_link "Profile"

    # Should be on profile page
    assert_current_path profile_path
    assert_selector "h1", text: "My Profile"
  end

  test "mobile user can navigate to profile from mobile menu" do
    # Resize to mobile
    page.driver.browser.manage.window.resize_to(375, 667)

    sign_in @user
    visit root_path

    # Open mobile menu
    find(".mobile-menu-toggle").click
    assert_selector(".mobile-drawer-content", visible: true, wait: 2)

    # Click profile link in mobile menu
    within(".mobile-profile-dropdown") do
      click_link "Profile"
    end

    # Should be on profile page
    assert_current_path profile_path
  end

  # Profile Display Tests
  test "profile displays user information correctly" do
    sign_in @user
    visit profile_path

    assert_selector ".profile-title", text: "My Profile"
    assert_text @user.full_name
    assert_text @user.email
    assert_text "Member Since"
    assert_text @user.created_at.strftime("%B %Y")
  end

  test "profile displays streak statistics" do
    sign_in @user
    visit profile_path

    assert_text "Current Streak"
    assert_text "5 days"
    assert_text "Longest Streak"
    assert_text "10 days"
    assert_text "Total Comments"
  end

  test "profile displays email & password authentication for non-oauth users" do
    sign_in @user
    visit profile_path

    assert_text "Email & Password"
    assert_selector "a[href='#{new_user_password_path}']", text: "Reset Password"
  end

  test "profile displays oauth authentication for oauth users" do
    sign_in @oauth_user
    visit profile_path

    assert_text "Signed in with Google"
    assert_no_selector "a[href='#{new_user_password_path}']"
    assert_text "Password management is handled by Google"
  end

  # Edit Profile Tests
  test "user can navigate to edit profile" do
    sign_in @user
    visit profile_path

    click_link "Edit Profile"

    assert_current_path edit_profile_path
    assert_selector "h1", text: "Edit Profile"
    assert_field "First Name", with: @user.first_name
    assert_field "Last Name", with: @user.last_name
  end

  test "user can successfully edit and save profile" do
    sign_in @user
    visit edit_profile_path

    fill_in "First Name", with: "Updated"
    fill_in "Last Name", with: "Name"

    # Accept the confirmation dialog
    accept_confirm do
      click_button "Save Changes"
    end

    # Should redirect to profile page
    assert_current_path profile_path, wait: 5
    assert_text "Updated Name"

    # Verify in database
    @user.reload
    assert_equal "Updated", @user.first_name
    assert_equal "Name", @user.last_name
  end

  test "edit form displays character counters" do
    sign_in @user
    visit edit_profile_path

    # Check initial counts
    assert_text "#{@user.first_name.length}/50 characters"
    assert_text "#{@user.last_name.length}/50 characters"

    # Type and verify counter updates
    fill_in "First Name", with: "NewName"
    # Give the JavaScript time to update
    sleep 0.2
    assert_text "7/50 characters"
  end

  test "edit form displays validation errors" do
    sign_in @user
    visit edit_profile_path

    fill_in "First Name", with: ""

    accept_confirm do
      click_button "Save Changes"
    end

    # Should stay on edit page with errors
    assert_current_path profile_path # patch request
    assert_selector ".error-message"
  end

  test "user can cancel profile edit" do
    sign_in @user
    visit edit_profile_path

    fill_in "First Name", with: "Changed"
    click_link "Cancel"

    # Should return to profile page
    assert_current_path profile_path

    # Changes should not be saved
    @user.reload
    assert_not_equal "Changed", @user.first_name
  end

  # Back Button Tests
  test "back button on profile page returns to home" do
    sign_in @user
    visit profile_path

    find(".back-button").click

    assert_current_path root_path
  end

  test "back button on edit page returns to profile" do
    sign_in @user
    visit edit_profile_path

    find(".back-button").click

    assert_current_path profile_path
  end

  # Turbo Navigation Tests
  test "profile works correctly with Turbo navigation" do
    sign_in @user

    # Navigate via Turbo
    visit root_path
    find("[data-profile-trigger]").click
    click_link "Profile"
    assert_current_path profile_path

    # Edit profile
    click_link "Edit Profile"
    assert_current_path edit_profile_path

    # Navigate back
    find(".back-button").click
    assert_current_path profile_path

    # Navigate to home and back to profile via dropdown again
    find(".back-button").click
    assert_current_path root_path

    find("[data-profile-trigger]").click
    click_link "Profile"
    assert_current_path profile_path

    # Profile should still display correctly
    assert_text @user.full_name
    assert_text @user.email
  end

  # Edge Cases
  test "profile handles user with special characters in name" do
    special_user = User.create!(
      first_name: "Mary-Jane",
      last_name: "O'Brien",
      email: "special@example.com",
      password: "password123",
      role: :commentor
    )

    sign_in special_user
    visit profile_path

    assert_text "Mary-Jane O'Brien"

    special_user.destroy
  end

  test "profile displays zero streak correctly" do
    @user.update(current_streak: 0, longest_streak: 0)
    sign_in @user
    visit profile_path

    assert_text "0 days"
  end
end
