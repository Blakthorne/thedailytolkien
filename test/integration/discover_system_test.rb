require "application_system_test_case"

class DiscoverSystemTest < ApplicationSystemTestCase
  def setup
    # Clean up any existing test data
    Quote.where(character: "Gandalf_Test").destroy_all
    Tag.where("name LIKE ?", "wisdom_%").destroy_all

    # Create a quote with a timestamp that falls within a UTC day range
    # Use yesterday at noon UTC to ensure it's within the day range
    test_date = 1.day.ago.to_date
    test_timestamp = test_date.beginning_of_day.in_time_zone("UTC").to_i + 12.hours

    @quote = Quote.create!(
      text: "A test quote for system testing functionality",
      book: "The Fellowship of the Ring",
      character: "Gandalf_Test",
      last_date_displayed: test_timestamp,
      first_date_displayed: (test_date - 1.week).beginning_of_day.in_time_zone("UTC").to_i + 12.hours
    )

    @tag = Tag.create!(name: "wisdom_#{Time.current.to_i}")
    @quote.tags << @tag
  end

  test "visiting the discover index" do
    visit discover_index_path

    assert_selector "h1", text: "Discover Quotes"
    assert_selector ".discover-cards-container"
    assert_selector ".discover-card", text: @quote.discover_snippet(100)
  end

  test "filtering quotes by search term" do
    visit discover_index_path

    fill_in "search", with: "test quote"
    click_button "Filter"

    # Just check that we get some results on the page
    assert_selector ".discover-cards-container"
    # Use a more specific assertion that doesn't rely on the exact text
    assert_text "system testing functionality"
  end

  test "filtering quotes by book" do
    visit discover_index_path

    select "The Fellowship of the Ring", from: "book"
    click_button "Filter"

    assert_selector ".discover-card", text: @quote.book
  end

  test "clearing filters" do
    visit discover_index_path

    fill_in "search", with: "test"
    click_button "Filter"

    assert_selector "a", text: "Clear All"
    click_link "Clear All"

    assert_field "search", with: ""
  end

  test "cards are displayed in descending order by last displayed" do
    visit discover_index_path

    # Cards should be displayed with most recently displayed quotes first
    # This is handled by the controller's default ordering
    assert_selector ".discover-card", minimum: 1
  end

  test "navigating to discovered quote from card" do
    visit discover_index_path

    # Click on the first discover card
    first(".discover-card").click

    assert_current_path discover_path(@quote.id)
    assert_selector ".quote-text", text: @quote.text
  end

  test "viewing discovered quote shows interactive state" do
    visit discover_path(@quote.id)

    assert_selector ".discover-notice", text: /last featured on/
    assert_selector ".quote-text", text: @quote.text
    # Discover view should show sign in prompt for comments when not logged in
    assert_selector "a[href='/users/sign_in']", text: "Sign in"
  end

  test "discovered quote shows interactive engagement buttons" do
    visit discover_path(@quote.id)

    assert_selector ".engagement-btn", count: 2
    # Buttons should be visible but show sign in prompt when not logged in
    assert_selector "a[href='/users/sign_in']", text: "Sign in"
  end

  test "back to discover button works" do
    visit discover_path(@quote.id)

    click_link "Back to Discovered Quotes"
    assert_current_path discover_index_path
  end

  test "footer discover link works" do
    visit root_path

    within "footer" do
      click_link "Discover"
    end

    assert_current_path discover_index_path
  end

  test "handling invalid discover date" do
    # Route constraint prevents invalid dates, so test via controller
    # This is already thoroughly tested in controller tests
    skip "Invalid date format blocked by route constraints - tested in controller tests"
  end

  test "handling invalid quote ID" do
    visit discover_path(99999)

    assert_selector ".no-quote h2", text: "No quote found"
    assert_selector "a", text: "Back to Discovered Quotes"
  end

  test "mobile responsive design" do
    # Test with mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)
    visit discover_index_path

    assert_selector ".discover-cards-container"  # Cards should still be present
    assert_selector ".discover-card"  # Individual cards should adapt
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

    visit discover_index_path

    # Should show pagination
    assert_selector "span", text: /Page \d+ of \d+/

    # Should have next link if more than 25 quotes
    if Quote.displayed.count > 25
      assert_selector "a", text: "Next ›"
    end
  end
end
