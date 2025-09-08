require "application_system_test_case"

class JavascriptExecutionTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    login_as_admin(@admin)
  end

  test "basic javascript execution and controller detection" do
    visit admin_quotes_path

    # Wait for page to load
    sleep 3

    # Test basic JavaScript execution
    result = page.evaluate_script("2 + 2")
    assert_equal 4, result, "Basic JavaScript should execute"

    # Test if Stimulus is available
    stimulus_available = page.evaluate_script("typeof window.Stimulus !== 'undefined'")
    puts "Stimulus available: #{stimulus_available}"

    # Test if application is loaded
    app_available = page.evaluate_script("typeof window.Application !== 'undefined'")
    puts "Application available: #{app_available}"

    # Check for controllers in DOM
    sortable_elements = page.evaluate_script("document.querySelectorAll('[data-controller*=\"sortable-table\"]').length")
    puts "Sortable table elements: #{sortable_elements}"

    row_link_elements = page.evaluate_script("document.querySelectorAll('[data-controller*=\"row-link\"]').length")
    puts "Row link elements: #{row_link_elements}"

    # Manually test click handler
    if sortable_elements > 0
      # Get the first header
      header_count = page.evaluate_script("document.querySelectorAll('th[role=\"columnheader\"]').length")
      puts "Headers with columnheader role: #{header_count}"

      if header_count > 0
        # Try to manually add a click listener to see if it works
        page.execute_script("""
          const header = document.querySelector('th[role=\"columnheader\"]');
          header.addEventListener('click', function() {
            console.log('Manual click listener worked!');
            this.setAttribute('data-clicked', 'true');
          });
          header.click();
        """)

        clicked = page.evaluate_script("document.querySelector('th[role=\"columnheader\"]').getAttribute('data-clicked')")
        puts "Manual click listener result: #{clicked}"
      end
    end

    assert true # Just gathering debug info
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
