require "application_system_test_case"

class TableSortingTest < ApplicationSystemTestCase
  setup do
    @admin_user = User.create!(
      email: "admin@test.com",
      password: "password123",
      role: "admin"
    )

    # Create test quotes with different data types for comprehensive sorting testing
    @quotes = []

    # Create quotes with IDs that test numeric sorting: 1, 2, 10, 20, 100
    [ 1, 2, 10, 20, 100 ].each_with_index do |id, index|
      @quotes << Quote.create!(
        text: [ "All that is gold does not glitter",
               "Not all those who wander are lost",
               "Even the smallest person can change the course of the future",
               "One ring to rule them all",
               "Fly, you fools!" ][index],
        character: [ "Bilbo", "Aragorn", "Galadriel", "Sauron", "Gandalf" ][index],
        book: [ "The Fellowship of the Ring",
               "The Fellowship of the Ring",
               "The Fellowship of the Ring",
               "The Lord of the Rings",
               "The Fellowship of the Ring" ][index],
        chapter: [ "Chapter 1", "Chapter 2", "Chapter 10", "Chapter 20", "Chapter 100" ][index],
        id: id
      )
    end

    sign_in @admin_user
  end

  test "text column sorting works correctly with mixed alphanumeric" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Quotes Management"

    # Get initial order of chapter names
    initial_chapters = page.all("tbody tr td:nth-child(4)").map(&:text)
    puts "Initial chapter order: #{initial_chapters}"

    # Click Chapter header to sort ascending
    chapter_header = find('th[role="columnheader"]', text: "Chapter")
    chapter_header.click

    # Wait for JavaScript sorting to complete
    sleep(1)

    # Get sorted chapters
    sorted_chapters = page.all("tbody tr td:nth-child(4)").map(&:text)
    puts "Ascending chapter order: #{sorted_chapters}"

    # Should be in natural numeric order: Chapter 1, Chapter 2, Chapter 10, Chapter 20, Chapter 100
    # This tests that Chapter 10 comes after Chapter 2, not between Chapter 1 and Chapter 2
    expected_ascending = [ "Chapter 1", "Chapter 2", "Chapter 10", "Chapter 20", "Chapter 100" ]
    assert_equal expected_ascending, sorted_chapters, "Chapters should sort naturally: #{expected_ascending} but got #{sorted_chapters}"

    # Verify aria-sort attribute is set correctly
    assert_equal "ascending", chapter_header["aria-sort"], "Chapter header should have aria-sort='ascending'"

    # Click Chapter header again to sort descending
    chapter_header.click

    # Wait for JavaScript sorting to complete
    sleep(1)

    # Get reverse sorted chapters
    reverse_sorted_chapters = page.all("tbody tr td:nth-child(4)").map(&:text)
    puts "Descending chapter order: #{reverse_sorted_chapters}"

    # Should be in reverse natural numeric order
    expected_descending = [ "Chapter 100", "Chapter 20", "Chapter 10", "Chapter 2", "Chapter 1" ]
    assert_equal expected_descending, reverse_sorted_chapters, "Chapters should sort naturally descending: #{expected_descending} but got #{reverse_sorted_chapters}"

    # Verify aria-sort attribute is set correctly
    assert_equal "descending", chapter_header["aria-sort"], "Chapter header should have aria-sort='descending'"
  end

  test "quote text column sorting works correctly" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Quotes Management"

    # Click Quote header to sort ascending
    quote_header = find('th[role="columnheader"]', text: "Quote")
    quote_header.click

    # Wait for JavaScript sorting to complete
    sleep(1)

    # Get sorted quotes (first 20 characters to compare)
    sorted_quotes = page.all("tbody tr td:nth-child(2)").map { |cell| cell.text[0..19] }
    puts "Ascending quote order: #{sorted_quotes}"

    # Should be in alphabetical order
    # "All that is gold..." (starts with 'A')
    # "Even the smallest..." (starts with 'E')
    # "Fly, you fools!" (starts with 'F')
    # "Not all those who..." (starts with 'N')
    # "One ring to rule..." (starts with 'O')
    expected_quotes = sorted_quotes.sort
    assert_equal expected_quotes, sorted_quotes, "Quotes should be sorted alphabetically"

    # Verify aria-sort attribute
    assert_equal "ascending", quote_header["aria-sort"], "Quote header should have aria-sort='ascending'"
  end

  test "character column sorting works correctly" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Quotes Management"

    # Click Character header to sort ascending
    character_header = find('th[role="columnheader"]', text: "Character")
    character_header.click

    # Wait for JavaScript sorting to complete
    sleep(1)

    # Get sorted characters
    sorted_characters = page.all("tbody tr td:nth-child(5)").map(&:text)
    puts "Ascending character order: #{sorted_characters}"

    # Should be alphabetically sorted: Aragorn, Bilbo, Galadriel, Gandalf, Sauron
    expected_characters = sorted_characters.sort
    assert_equal expected_characters, sorted_characters, "Characters should be sorted alphabetically"

    # Verify aria-sort attribute
    assert_equal "ascending", character_header["aria-sort"], "Character header should have aria-sort='ascending'"
  end

  test "sorting resets other columns" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Quotes Management"

    # Sort by Chapter first
    chapter_header = find('th[role="columnheader"]', text: "Chapter")
    chapter_header.click
    sleep(0.5)

    # Verify Chapter header is sorted
    assert_equal "ascending", chapter_header["aria-sort"]

    # Sort by Quote
    quote_header = find('th[role="columnheader"]', text: "Quote")
    quote_header.click
    sleep(0.5)

    # Verify Quote header is sorted and Chapter header is reset
    assert_equal "ascending", quote_header["aria-sort"]
    assert_equal "none", chapter_header["aria-sort"], "Chapter header should be reset to 'none' when sorting by other column"
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "Sign In"

    # Wait for redirect and confirm we're in admin area
    assert_current_path admin_dashboard_path
  end
end
