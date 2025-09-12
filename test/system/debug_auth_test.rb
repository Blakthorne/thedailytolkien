require "application_system_test_case"

class DebugAuthTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      first_name: "Debug",
      last_name: "Admin",
      email: "debug_admin@test.com",
      password: "password123",
      role: "admin"
    )
  end

  def teardown
    User.where(email: "debug_admin@test.com").destroy_all
  end

  test "admin can login and access admin pages" do
    # Test login process step by step
    visit new_user_session_path
    puts "On login page: #{current_path}"

    fill_in "user[email]", with: @admin.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"

    puts "After login attempt: #{current_path}"
    puts "Page source snippet: #{page.text[0..200]}"

    # Check if login was successful
    if page.has_text?("Welcome, #{@admin.display_name}")
      puts "Login successful!"
    else
      puts "Login failed - no welcome message found"
    end

    # Check if we can access admin root
    visit admin_root_path
    puts "After admin root visit: #{current_path}"
    puts "Page title: #{page.title}"

    # Check if we can access admin quotes
    visit admin_quotes_path
    puts "After admin quotes visit: #{current_path}"
    puts "Looking for table element..."

    if page.has_css?("table")
      puts "Found table element!"
      if page.has_css?("table[data-controller='sortable-table']")
        puts "Found sortable table!"
      else
        puts "Table found but no sortable-table controller"
      end
    else
      puts "No table element found"
    end

    # Add assertion to prevent test warning
    assert_equal admin_quotes_path, current_path, "Should be on admin quotes page"
  end
end
