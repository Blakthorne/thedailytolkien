require "application_system_test_case"

class QuoteSortingTest < ApplicationSystemTestCase
  setup do
    # Create test user with known password for each test
    @admin_user = User.create!(
      first_name: "Test",
      last_name: "Admin",
      email: "admin@sorttest.com",
      password: "password123",
      role: "admin"
    )

    # Create quotes with specific text to test sorting
    @quote_a = Quote.create!(
      text: "All that is gold does not glitter",
      book: "The Fellowship of the Ring",
      chapter: "Chapter 1",
      character: "Bilbo"
    )

    @quote_b = Quote.create!(
      text: "Even the smallest person can change the course of the future",
      book: "The Fellowship of the Ring",
      chapter: "Chapter 2",
      character: "Galadriel"
    )

    @quote_z = Quote.create!(
      text: "You shall not pass!",
      book: "The Two Towers",
      chapter: "Chapter 3",
      character: "Gandalf"
    )
  end

  teardown do
    # Clean up test data
    User.where(email: "admin@sorttest.com").destroy_all
    Quote.where(character: [ "Bilbo", "Galadriel", "Gandalf" ]).destroy_all
  end

  test "quote column sorts alphabetically" do
    # Create and sign in admin user using Devise helpers
    user = User.create!(
      first_name: "Quote",
      last_name: "Test",
      email: "quote_test@example.com",
      password: "password123",
      role: "admin"
    )

    sign_in user
    visit admin_quotes_path

    # Wait for page load
    assert_text "Manage Quotes"

    # Check initial sort state and click to sort
    quote_header = find('th[role="columnheader"]', text: "Quote")
    initial_sort = quote_header["aria-sort"]
    quote_header.click

    # Wait for JavaScript to execute
    sleep(1)

    # Check if sort state changed (indicates JavaScript is working)
    updated_sort = quote_header["aria-sort"]

    # Get the quote texts in order they appear
    quote_cells = page.all("tbody tr td:nth-child(2)")
    quote_texts = quote_cells.map { |cell| cell.text.gsub(/^["']|["']$/, "").strip }

    # Verify JavaScript sorting is working by checking aria-sort change
    assert_not_equal initial_sort, updated_sort, "JavaScript sorting should change aria-sort attribute"

    # Verify quotes are in sorted order
    sorted_quotes = quote_texts.sort
    assert_equal sorted_quotes, quote_texts, "Quotes should be sorted alphabetically after clicking header"

    # Cleanup
    user.destroy
  end

  test "book column sorts alphabetically" do
    # Create and sign in admin user using Devise helpers
    user = User.create!(
      first_name: "Book",
      last_name: "Test",
      email: "book_test@example.com",
      password: "password123",
      role: "admin"
    )

    sign_in user
    visit admin_quotes_path

    # Wait for page load
    assert_text "Manage Quotes"

    # Click Book header to sort
    book_header = find('th[role="columnheader"]', text: "Book")
    initial_sort = book_header["aria-sort"]
    book_header.click

    # Wait for JavaScript to execute
    sleep(1)

    # Check if sort state changed (indicates JavaScript is working)
    updated_sort = book_header["aria-sort"]
    assert_not_equal initial_sort, updated_sort, "JavaScript sorting should change aria-sort attribute"

    # Get the book names in order they appear
    book_cells = page.all("tbody tr td:nth-child(3)")
    book_names = book_cells.map { |cell| cell.text.strip }

    # Verify books are in sorted order
    sorted_books = book_names.sort
    assert_equal sorted_books, book_names, "Books should be sorted alphabetically after clicking header"

    # Cleanup
    user.destroy
  end

  private

  # Remove custom sign_in method since we're using Devise helpers
end
