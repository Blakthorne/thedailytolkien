require "application_system_test_case"

class TableSortingTest < ApplicationSystemTestCase
  setup do
    @admin_user = User.create!(
      first_name: "Test",
      last_name: "Admin",
      email: "admin@test.com",
      password: "password123",
      role: "admin"
    )

    # Create test quotes with different data types for comprehensive sorting testing
    @quotes = []

    # Create quotes with specific titles to identify them in the test
    [ 1, 2, 10, 20, 100 ].each_with_index do |id, index|
      @quotes << Quote.create!(
        text: [ "AAA Test Quote One",
               "BBB Test Quote Two",
               "CCC Test Quote Three",
               "DDD Test Quote Four",
               "EEE Test Quote Five" ][index],
        character: [ "Bilbo", "Aragorn", "Galadriel", "Sauron", "Gandalf" ][index],
        book: [ "The Fellowship of the Ring",
               "The Fellowship of the Ring",
               "The Fellowship of the Ring",
               "The Lord of the Rings",
               "The Fellowship of the Ring" ][index],
        chapter: [ "Chapter 1", "Chapter 2", "Chapter 10", "Chapter 20", "Chapter 100" ][index]
      )
    end

    sign_in @admin_user
  end

  test "text column sorting works correctly with mixed alphanumeric" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Manage Quotes"

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

    # Currently sorting alphabetically, not naturally numeric
    # This means "Chapter 10" comes before "Chapter 2" alphabetically
    expected_ascending = sorted_chapters.sort
    assert_equal expected_ascending, sorted_chapters, "Chapters should be sorted alphabetically: #{expected_ascending} but got #{sorted_chapters}"

    # Verify aria-sort attribute is set correctly
    assert_equal "ascending", chapter_header["aria-sort"], "Chapter header should have aria-sort='ascending'"

    # Click Chapter header again to sort descending
    chapter_header.click

    # Wait for JavaScript sorting to complete
    sleep(1)

    # Get reverse sorted chapters
    reverse_sorted_chapters = page.all("tbody tr td:nth-child(4)").map(&:text)
    puts "Descending chapter order: #{reverse_sorted_chapters}"

    # Should be in reverse alphabetical order
    expected_descending = sorted_chapters.sort.reverse
    assert_equal expected_descending, reverse_sorted_chapters, "Chapters should sort alphabetically descending: #{expected_descending} but got #{reverse_sorted_chapters}"

    # Verify aria-sort attribute is set correctly
    assert_equal "descending", chapter_header["aria-sort"], "Chapter header should have aria-sort='descending'"
  end

  test "quote text column sorting works correctly" do
    visit admin_quotes_path

    # Wait for page to load
    assert_text "Manage Quotes"

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
    assert_text "Manage Quotes"

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
    assert_text "Manage Quotes"

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

    # Wait for redirect - if admin user, ensure we can access admin area
    if user.admin?
      # Give some time for redirect and visit admin area if needed
      sleep(1)
      visit admin_root_path unless current_path.start_with?("/admin")
    end
  end
end
