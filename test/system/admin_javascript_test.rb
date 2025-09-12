require "application_system_test_case"

class AdminJavascriptTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    login_as_admin(@admin)
  end

  test "row clicking works on quotes table" do
    visit admin_quotes_path

    # Wait for the page to load completely
    assert_selector "table", wait: 5

    # Find the first quote row (skip the header)
    first_row = find("tbody tr:first-child")
    quote_id = first_row.find("input[type='checkbox']")[:value]

    # Debug: Check if the row-link controller is attached
    assert first_row["data-controller"].include?("row-link")

    # Click somewhere in the middle of the row (not the checkbox or link)
    character_cell = first_row.find("td:nth-child(5)") # Character column
    character_cell.click

    # Should navigate to the quote show page
    assert_current_path admin_quote_path(quote_id)
  end

  test "column sorting works on quotes table" do
    visit admin_quotes_path

    # Wait for the page to load completely
    assert_selector "table", wait: 5

    # Get initial order of quotes
    initial_quotes = page.all("tbody tr").map { |row| row.find("td:nth-child(2)").text.strip }

    # Click on the "Quote" column header to sort
    quote_header = find("th[data-type='text']:nth-child(2)")
    assert quote_header["aria-sort"] == "none", "Initial sort should be none"

    quote_header.click

    # Check if aria-sort changed
    sleep 0.5 # Give time for JavaScript to execute
    updated_sort = quote_header["aria-sort"]
    assert [ "ascending", "descending" ].include?(updated_sort), "Sort should be ascending or descending after click, got: #{updated_sort}"

    # Check if the rows actually reordered
    new_quotes = page.all("tbody tr").map { |row| row.find("td:nth-child(2)").text.strip }
    refute_equal initial_quotes, new_quotes, "Quotes should be reordered after sorting"
  end

  test "stimulus controllers are loaded and active" do
    visit admin_quotes_path

    # Debug: Check what JavaScript is being loaded
    scripts = page.all("script[src]").map { |s| s["src"] }
    puts "Scripts loaded: #{scripts.join(', ')}"

    # Debug: Check for console errors
    logs = page.driver.browser.manage.logs.get(:browser)
    errors = logs.select { |log| log.level == "SEVERE" }
    puts "Console errors: #{errors.map(&:message).join(', ')}" if errors.any?

    # Check if Stimulus is available
    stimulus_available = page.evaluate_script("typeof window.Stimulus !== 'undefined'")
    puts "Stimulus available: #{stimulus_available}"

    unless stimulus_available
      # Try to load application.js manually and see what happens
      app_js_result = page.evaluate_script("typeof window.Application !== 'undefined'")
      puts "Application object available: #{app_js_result}"
    end

    assert stimulus_available, "Stimulus should be available globally"

    # Check if our controllers are registered
    controllers = page.evaluate_script("Object.keys(window.Stimulus.router.modulesByIdentifier)")
    assert controllers.include?("row-link"), "row-link controller should be registered"
    assert controllers.include?("sortable-table"), "sortable-table controller should be registered"

    # Check if controllers are connected to elements
    row_controllers = page.evaluate_script("document.querySelectorAll('[data-controller*=\"row-link\"]').length")
    assert row_controllers > 0, "Should have row-link controllers connected to elements"

    table_controllers = page.evaluate_script("document.querySelectorAll('[data-controller*=\"sortable-table\"]').length")
    assert table_controllers > 0, "Should have sortable-table controllers connected to elements"
  end

  private

  def login_as_admin(user)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"

    # Verify login was successful
    assert page.has_text?("Welcome, #{user.display_name}")

    # App redirects to home page, so navigate to admin after login
    visit admin_root_path

    # Verify we're on admin page
    assert_current_path admin_root_path
  end
end
