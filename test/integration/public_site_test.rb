require "test_helper"

class PublicSiteTest < ActionDispatch::IntegrationTest
  test "home loads with quote when present" do
    Quote.create!(text: "A single quote for today", book: "LOTR", days_displayed: 0)

    get root_path
    assert_response :success
    assert_select "h1", text: "The Daily Tolkien", count: 1, minimum: 0
    assert_select "blockquote, q, p", /A single quote for today/
  end

  test "home loads gracefully when no quotes present" do
    # Clean up related data first to avoid foreign key constraints
    QuoteTag.delete_all
    QuoteLike.delete_all
    Comment.delete_all
    Quote.delete_all

    get root_path
    assert_response :success
    # Page should render without exceptions; may show placeholder text
    assert_select "body", minimum: 1
  end
end
