require "test_helper"

class QuoteArchiveTest < ActiveSupport::TestCase
  def setup
    # Create a quote with a timestamp that falls within a UTC day range
    # Use yesterday at noon UTC to ensure it's within the day range
    test_date = 1.day.ago.to_date
    test_timestamp = test_date.beginning_of_day.in_time_zone("UTC").to_i + 12.hours

    @quote = Quote.create!(
      text: "Test quote text",
      book: "Test Book",
      character: "Test Character",
      last_date_displayed: test_timestamp,
      first_date_displayed: (test_date - 1.week).beginning_of_day.in_time_zone("UTC").to_i + 12.hours
    )
  end

  test "displayed_on_date should find quotes by date" do
    date = Time.at(@quote.last_date_displayed).to_date
    quotes = Quote.displayed_on_date(date)
    assert_includes quotes, @quote
  end

  test "archive_date should return formatted date" do
    expected_date = Time.at(@quote.last_date_displayed).to_date
    assert_equal expected_date, @quote.archive_date
  end

  test "archive_date should return nil for quotes without display date" do
    quote = Quote.create!(text: "Undisplayed quote", book: "Test Book")
    assert_nil quote.archive_date
  end

  test "archive_snippet should truncate long quotes" do
    long_text = "A" * 200
    quote = Quote.create!(text: long_text, book: "Test Book")

    snippet = quote.archive_snippet(100)
    assert snippet.length <= 103  # 100 + "..."
    assert snippet.end_with?("...")
  end

  test "archive_snippet should preserve short quotes" do
    short_text = "Short quote"
    quote = Quote.create!(text: short_text, book: "Test Book")

    assert_equal short_text, quote.archive_snippet(100)
  end

  test "archive_snippet should break at word boundaries" do
    text = "This is a test quote that should be truncated properly at word boundaries"
    quote = Quote.create!(text: text, book: "Test Book")

    snippet = quote.archive_snippet(30)
    refute snippet.include?(" boundaries")  # Should not include partial word
    assert snippet.end_with?("...")
  end

  test "has_been_displayed? should return true for displayed quotes" do
    assert @quote.has_been_displayed?
  end

  test "has_been_displayed? should return false for undisplayed quotes" do
    quote = Quote.create!(text: "Undisplayed quote", book: "Test Book")
    refute quote.has_been_displayed?
  end

  test "displayed scope should only return displayed quotes" do
    undisplayed_quote = Quote.create!(text: "Undisplayed", book: "Test Book")

    displayed_quotes = Quote.displayed
    assert_includes displayed_quotes, @quote
    refute_includes displayed_quotes, undisplayed_quote
  end

  test "by_display_date scope should order by last_date_displayed desc" do
    older_quote = Quote.create!(
      text: "Older quote",
      book: "Test Book",
      last_date_displayed: 2.days.ago.to_i
    )

    newer_quote = Quote.create!(
      text: "Newer quote",
      book: "Test Book",
      last_date_displayed: Time.current.to_i
    )

    ordered_quotes = Quote.by_display_date
    first_index = ordered_quotes.index(newer_quote)
    second_index = ordered_quotes.index(older_quote)

    assert first_index < second_index
  end

  test "date_range scope should filter by date range" do
    start_date = 2.days.ago.to_date
    end_date = Date.current

    in_range_quote = Quote.create!(
      text: "In range",
      book: "Test Book",
      last_date_displayed: 1.day.ago.to_i
    )

    out_of_range_quote = Quote.create!(
      text: "Out of range",
      book: "Test Book",
      last_date_displayed: 1.week.ago.to_i
    )

    filtered_quotes = Quote.date_range(start_date, end_date)
    assert_includes filtered_quotes, in_range_quote
    refute_includes filtered_quotes, out_of_range_quote
  end
end
