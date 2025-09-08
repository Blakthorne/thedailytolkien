require "application_system_test_case"

class DebugConsoleTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    login_as_admin(@admin)
  end

  test "check debug console messages" do
    visit admin_quotes_path

    # Wait for JavaScript to load
    sleep 3

    # The debug messages should have printed to console
    # Let's check if Stimulus is available after the imports
    stimulus_available = page.evaluate_script("typeof window.Stimulus !== 'undefined'")
    puts "Stimulus available after debug imports: #{stimulus_available}"

    # If Stimulus is available, check what controllers are registered
    if stimulus_available
      controllers = page.evaluate_script("Object.keys(window.Stimulus.router.modulesByIdentifier)")
      puts "Registered controllers: #{controllers.join(', ')}"

      # Test the sorting functionality directly
      sort_test_result = page.evaluate_script("""
        const table = document.querySelector('[data-controller*=\"sortable-table\"]');
        const header = document.querySelector('th[role=\"columnheader\"]');
        if (table && header) {
          const originalSort = header.getAttribute('aria-sort');
          header.click();
          const newSort = header.getAttribute('aria-sort');
          return 'Original: ' + originalSort + ', After click: ' + newSort;
        } else {
          return 'Table or header not found';
        }
      """)
      puts "Sort test result: #{sort_test_result}"

      # Test the row clicking functionality
      row_test_result = page.evaluate_script("""
        const row = document.querySelector('[data-controller*=\"row-link\"]');
        if (row) {
          return 'Row found with URL: ' + row.getAttribute('data-row-link-url-value');
        } else {
          return 'Row not found';
        }
      """)
      puts "Row test result: #{row_test_result}"

    else
      puts "Stimulus is not available - checking importmap loading..."

      # Check if the importmap script exists
      importmap_exists = page.evaluate_script("!!document.querySelector('script[type=\"importmap\"]')")
      puts "Importmap script exists: #{importmap_exists}"

      # Check if the module script exists
      module_script_exists = page.evaluate_script("!!document.querySelector('script[type=\"module\"]')")
      puts "Module script exists: #{module_script_exists}"
    end

    assert true
  end

  private

  def login_as_admin(user)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"
    visit admin_root_path
  end
end
