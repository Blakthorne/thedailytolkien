require "application_system_test_case"

class QuoteSortingTest < ApplicationSystemTestCase
  setup do
    @admin_user = User.create!(
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

  test "quote column sorts alphabetically" do
    sign_in @admin_user
    visit admin_quotes_path

    # Wait for page load
    assert_text "Quotes Management"

    # Click Quote header to sort ascending
    find('th[role="columnheader"]', text: "Quote").click

    # Wait for JavaScript to execute
    sleep(2)

    # Get the quote texts in order they appear
    quote_cells = page.all("tbody tr td:nth-child(2)")
    quote_texts = quote_cells.map { |cell| cell.text.gsub(/^["']|["']$/, "").strip }

    puts "Quote order after sorting: #{quote_texts.inspect}"

    # Should be alphabetical: "All that is gold..." comes before "Even the..." comes before "You shall..."
    assert quote_texts[0].start_with?("All"), "First quote should start with 'All', got: #{quote_texts[0]}"
    assert quote_texts[1].start_with?("Even"), "Second quote should start with 'Even', got: #{quote_texts[1]}"
    assert quote_texts[2].start_with?("You"), "Third quote should start with 'You', got: #{quote_texts[2]}"
  end

  test "book column sorts alphabetically" do
    sign_in @admin_user
    visit admin_quotes_path

    # Wait for page load
    assert_text "Quotes Management"

    # Click Book header to sort ascending
    find('th[role="columnheader"]', text: "Book").click

    # Wait for JavaScript to execute
    sleep(2)

    # Get the book names in order they appear
    book_cells = page.all("tbody tr td:nth-child(3)")
    book_names = book_cells.map { |cell| cell.text.strip }

    puts "Book order after sorting: #{book_names.inspect}"

    # Should be alphabetical: "The Fellowship..." comes before "The Two Towers"
    fellowship_indices = book_names.each_with_index.select { |book, i| book.include?("Fellowship") }.map(&:last)
    towers_indices = book_names.each_with_index.select { |book, i| book.include?("Two Towers") }.map(&:last)

    if fellowship_indices.any? && towers_indices.any?
      assert fellowship_indices.max < towers_indices.min, "Fellowship books should come before Two Towers books"
    end
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "Sign In"

    # Wait for redirect
    assert_current_path admin_dashboard_path
  end
end
