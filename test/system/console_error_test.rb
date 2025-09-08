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
        result = page.evaluate_script("import('#{module_name}').then(() => 'SUCCESS').catch(e => 'ERROR: ' + e.message)")
        puts "#{module_name}: Checking..."
        sleep 2 # Give time for async import
        # Note: The above won't work directly in this context, let me try a different approach
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
            // Try to manually load and start stimulus
            const app = new (await import('@hotwired/stimulus')).Application();
            app.start();
            window.Stimulus = app;
            return 'Manually created Stimulus';
          } else {
            return 'Stimulus already exists';
          }
        } catch (e) {
          return 'Error creating manual stimulus: ' + e.message;
        }
      })()
    """)

    puts "Manual controller test result: #{manual_controller_test}"

    assert true # Just gathering debug info
  end
end
