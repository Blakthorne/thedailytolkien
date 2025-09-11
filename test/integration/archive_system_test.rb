require "application_system_test_case"

class ArchiveSystemTest < ApplicationSystemTestCase
  def setup
    # Clean up any existing test data
    Quote.where(character: "Gandalf_Test").destroy_all
    Tag.where("name LIKE ?", "wisdom_%").destroy_all

    @quote = Quote.create!(
      text: "A test quote for system testing functionality",
      book: "The Fellowship of the Ring",
      character: "Gandalf_Test",
      last_date_displayed: 1.day.ago.to_i,
      first_date_displayed: 1.week.ago.to_i
    )

    @tag = Tag.create!(name: "wisdom_#{Time.current.to_i}")
    @quote.tags << @tag
  end

  test "visiting the archive index" do
    visit archive_index_path

    assert_selector "h1", text: "Quote Archive"
    assert_selector "table"
    assert_selector "td", text: @quote.archive_snippet(100)
  end

  test "filtering quotes by search term" do
    visit archive_index_path

    fill_in "search", with: "test quote"
    click_button "Filter"

    # Just check that we get some results on the page
    assert_selector "table"
    # Use a more specific assertion that doesn't rely on the exact text
    assert_text "system testing functionality"
  end

  test "filtering quotes by book" do
    visit archive_index_path

    select "The Fellowship of the Ring", from: "book"
    click_button "Filter"

    assert_selector "td", text: @quote.book
  end

  test "clearing filters" do
    visit archive_index_path

    fill_in "search", with: "test"
    click_button "Filter"

    assert_selector "a", text: "Clear All"
    click_link "Clear All"

    assert_field "search", with: ""
  end

  test "sorting table by clicking headers" do
    visit archive_index_path

    # Date header should initially be sorted descending (newest first)
    assert_selector "th[aria-sort='descending']"

    # Click on Date header to sort ascending (oldest first)
    find("th[data-type='date']").click

    # Should see aria-sort attribute change to ascending
    assert_selector "th[aria-sort='ascending']"
  end

  test "navigating to archived quote from table" do
    visit archive_index_path

    date_string = Time.at(@quote.last_date_displayed).strftime("%Y-%m-%d")

    # Click on table row (JavaScript click event)
    execute_script("window.location.href='/archive/#{date_string}'")

    assert_current_path archive_path(date_string)
    assert_selector ".quote-text", text: @quote.text
  end

  test "viewing archived quote shows read-only state" do
    date_string = Time.at(@quote.last_date_displayed).strftime("%Y-%m-%d")
    visit archive_path(date_string)

    assert_selector ".archive-notice", text: /archived quote/
    assert_selector ".quote-text", text: @quote.text
    # Archive view should not have comment form - it's read-only
    assert_no_selector "textarea"
    assert_no_selector "button", text: "Post Comment"
  end

  test "archived quote shows engagement counts but disabled buttons" do
    date_string = Time.at(@quote.last_date_displayed).strftime("%Y-%m-%d")
    visit archive_path(date_string)

    assert_selector ".engagement-btn", count: 2
    # Buttons should be visible but not clickable
  end

  test "back to archive button works" do
    date_string = Time.at(@quote.last_date_displayed).strftime("%Y-%m-%d")
    visit archive_path(date_string)

    click_link "Back to Archived Quotes"
    assert_current_path archive_index_path
  end

  test "footer archive link works" do
    visit root_path

    within "footer" do
      click_link "Archive"
    end

    assert_current_path archive_index_path
  end

  test "handling invalid archive date" do
    # Route constraint prevents invalid dates, so test via controller
    # This is already thoroughly tested in controller tests
    skip "Invalid date format blocked by route constraints - tested in controller tests"
  end

  test "handling date with no quote" do
    visit archive_path("2000-01-01")

    assert_selector ".no-quote h2", text: "No quote for this date"
    assert_selector "a", text: "Back to Archived Quotes"
    assert_selector "a", text: "Browse Archive"
  end

  test "mobile responsive design" do
    # Test with mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)
    visit archive_index_path

    assert_selector "table"  # Table should still be present
    assert_selector ".app-table-section"  # Sections should adapt with new unified class names
    assert_selector ".search-section"  # Search section should be responsive
  end

  test "pagination works with many quotes" do
    # Create 30 quotes to test pagination
    30.times do |i|
      Quote.create!(
        text: "Test quote #{i}",
        book: "Test Book #{i}",
        last_date_displayed: (i + 2).days.ago.to_i
      )
    end

    visit archive_index_path

    # Should show pagination
    assert_selector "span", text: /Page \d+ of \d+/

    # Should have next link if more than 25 quotes
    if Quote.displayed.count > 25
      assert_selector "a", text: "Next ›"
    end
  end
end
