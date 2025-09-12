require "application_system_test_case"

class AdminSortingVerificationTest < ApplicationSystemTestCase
  def setup
    # Clear existing quotes to ensure clean test environment
    Quote.destroy_all
    User.where(email: "admin@test.com").destroy_all

    @user = User.create!(
      first_name: "Test",
      last_name: "Admin",
      email: "admin@test.com",
      password: "password123",
      role: "admin"
    )

    # Create test quotes with clear alphabetical ordering
    @quotes = [
      Quote.create!(
        text: "Apple quote text",
        book: "Book A",
        chapter: "Chapter 1",
        character: "Character X"
      ),
      Quote.create!(
        text: "Banana quote text",
        book: "Book B",
        chapter: "Chapter 2",
        character: "Character Y"
      ),
      Quote.create!(
        text: "Cherry quote text",
        book: "Book C",
        chapter: "Chapter 3",
        character: "Character Z"
      )
    ]

    login_as(@user)
  end

  test "quote column sorting works correctly" do
    visit admin_quotes_path

    # Wait for page to fully load
    assert_text "Quotes"

    # Verify initial order (should be creation order)
    rows = page.all("tbody tr")
    assert_equal 3, rows.count, "Should have 3 quote rows"

    # Get initial quote texts
    initial_quotes = rows.map do |row|
      quote_cell = row.all("td")[1] # Quote column is 2nd (index 1)
      quote_cell.text.strip.downcase
    end

    puts "Initial quote order: #{initial_quotes}"

    # Click the Quote header to sort
    quote_header = find("th", text: "Quote")
    quote_header.click

    # Wait for sorting to complete
    sleep 1

    # Get sorted quote texts
    sorted_rows = page.all("tbody tr")
    sorted_quotes = sorted_rows.map do |row|
      quote_cell = row.all("td")[1] # Quote column is 2nd (index 1)
      quote_cell.text.strip.downcase
    end

    puts "Sorted quote order: #{sorted_quotes}"

    # Verify alphabetical order (ascending)
    expected_order = sorted_quotes.sort
    assert_equal expected_order, sorted_quotes, "Quotes should be sorted alphabetically"

    # Verify specific order
    assert sorted_quotes[0].include?("apple"), "First quote should contain 'apple'"
    assert sorted_quotes[1].include?("banana"), "Second quote should contain 'banana'"
    assert sorted_quotes[2].include?("cherry"), "Third quote should contain 'cherry'"
  end

  test "book column sorting works correctly" do
    visit admin_quotes_path

    # Wait for page to fully load
    assert_text "Quotes"

    # Click the Book header to sort
    book_header = find("th", text: "Book")
    book_header.click

    # Wait for sorting to complete
    sleep 1

    # Get sorted book names
    rows = page.all("tbody tr")
    books = rows.map do |row|
      book_cell = row.all("td")[2] # Book column is 3rd (index 2)
      book_cell.text.strip.downcase
    end

    puts "Sorted book order: #{books}"

    # Verify alphabetical order
    expected_order = books.sort
    assert_equal expected_order, books, "Books should be sorted alphabetically"

    # Verify specific order
    assert_equal "book a", books[0], "First book should be 'Book A'"
    assert_equal "book b", books[1], "Second book should be 'Book B'"
    assert_equal "book c", books[2], "Third book should be 'Book C'"
  end

  test "sorting direction toggles correctly" do
    visit admin_quotes_path

    # Click Quote header once for ascending
    quote_header = find("th", text: "Quote")
    quote_header.click
    sleep 1

    # Verify ascending order
    rows = page.all("tbody tr")
    first_sort_quotes = rows.map do |row|
      quote_cell = row.all("td")[1]
      quote_cell.text.strip.downcase
    end

    # Click again for descending
    quote_header.click
    sleep 1

    # Get new order
    rows = page.all("tbody tr")
    second_sort_quotes = rows.map do |row|
      quote_cell = row.all("td")[1]
      quote_cell.text.strip.downcase
    end

    # Verify descending order (should be reverse of ascending)
    assert_equal first_sort_quotes.reverse, second_sort_quotes, "Second click should reverse the order"
  end

  private

  def login_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Welcome, #{user.display_name}"
  end

  def teardown
    # Clean up test data
    Quote.where(text: [ "Apple quote text", "Banana quote text", "Cherry quote text" ]).destroy_all
    User.where(email: "admin@test.com").destroy_all
  end
end
