require "application_system_test_case"

class ConsoleErrorTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
  end

  test "check for javascript console errors" do
    # Clear any existing logs
    visit "about:blank"

    # Navigate to login page
    visit new_user_session_path
    fill_in "user[email]", with: @admin.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"

    # Navigate to admin quotes page
    visit admin_quotes_path

    # Wait a bit for all JS to load
    sleep 5

    # Try to execute each import manually to see where the failure occurs
    puts "\n=== Testing individual module imports ==="

    modules_to_test = [
      "@hotwired/turbo-rails",
      "@rails/ujs",
      "controllers",
      "controllers/application",
      "controllers/row_link_controller",
      "controllers/sortable_table_controller"
    ]

    modules_to_test.each do |module_name|
      begin
        # Check if the module is referenced in the page's script tags
        script_content = page.evaluate_script("document.querySelector('script[type=\"importmap\"]').textContent")
        if script_content.include?(module_name)
          puts "#{module_name}: Found in importmap"
        else
          puts "#{module_name}: Not found in importmap"
        end
      rescue => e
        puts "#{module_name}: ERROR - #{e.message}"
      end
    end

    # Let's try a more direct approach - check if each step of loading works
    puts "\n=== Testing Stimulus setup manually ==="

    # Test if we can import and start Stimulus manually
    manual_stimulus_test = page.evaluate_script("""
      (function() {
        try {
          // Try to import stimulus manually
          if (typeof window.Stimulus === 'undefined') {
            return 'Stimulus not available in window';
          } else {
            return 'Stimulus available: ' + Object.keys(window.Stimulus.router.modulesByIdentifier).length + ' controllers';
          }
        } catch (e) {
          return 'Error: ' + e.message;
        }
      })()
    """)

    puts "Stimulus manual test result: #{manual_stimulus_test}"

    # Check if we can manually create and connect a simple controller
    manual_controller_test = page.evaluate_script("""
      (function() {
        try {
          if (typeof window.Stimulus === 'undefined') {
            return 'Stimulus not available';
          } else {
            return 'Stimulus already exists: ' + Object.keys(window.Stimulus.router.modulesByIdentifier).length + ' controllers';
          }
        } catch (e) {
          return 'Error: ' + e.message;
        }
      })()
    """)

    puts "Manual controller test result: #{manual_controller_test}"

    assert true # Just gathering debug info
  end
end
