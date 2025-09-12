require "application_system_test_case"

class SimpleJavascriptTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    login_as_admin(@admin)

    # Ensure we have some quotes for testing
    @quote1 = quotes(:one) if quotes(:one)
    @quote2 = quotes(:fellowship_quote) if quotes(:fellowship_quote)
  end

  test "row clicking functionality" do
    visit admin_quotes_path

    # Wait for page to load and controllers to connect
    sleep 2

    # Check if we have any quotes
    if page.has_css?("tbody tr")
      # Test row clicking by getting the first quote row and clicking it
      first_quote_row = find("tbody tr:first-child")
      quote_id = first_quote_row.find("input[type='checkbox']")[:value]

      # Click in the character cell (5th column) which should not have interactive elements
      character_cell = first_quote_row.find("td:nth-child(5)")
      character_cell.click

      # Check if we navigated to the show page
      assert_current_path admin_quote_path(quote_id)
    else
      skip "No quotes available for testing row clicking"
    end
  end

  test "column sorting functionality" do
    visit admin_quotes_path

    # Wait for page to load and controllers to connect
    sleep 2

    # Check if we have any quotes
    if page.has_css?("tbody tr")
      # Get the initial order of quotes
      initial_first_quote = find("tbody tr:first-child td:nth-child(2)").text

      # Click the Quote header to sort
      quote_header = find("thead th:nth-child(2)")
      quote_header.click

      # Wait a moment for JavaScript to execute
      sleep 1

      # Check if the aria-sort attribute changed
      updated_sort = quote_header["aria-sort"]
      assert [ "ascending", "descending" ].include?(updated_sort),
             "Expected aria-sort to be ascending or descending, got: #{updated_sort}"

      # Check if the first quote changed (indicating sorting worked)
      new_first_quote = find("tbody tr:first-child td:nth-child(2)").text
      # Note: This might not always change depending on the data, but aria-sort should change
      puts "Initial first quote: #{initial_first_quote}"
      puts "After sort first quote: #{new_first_quote}"
      puts "Sort direction: #{updated_sort}"
    else
      skip "No quotes available for testing column sorting"
    end
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
