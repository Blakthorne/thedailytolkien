require "test_helper"

class QuoteTagTest < ActiveSupport::TestCase
  def setup
    @quote = quotes(:fellowship_quote)
    @tag = tags(:wisdom)
    # Clean up any existing associations for test isolation
    QuoteTag.where(quote: @quote, tag: @tag).delete_all
  end

  test "should create quote_tag association" do
    quote_tag = QuoteTag.new(quote: @quote, tag: @tag)
    assert quote_tag.valid?
    assert quote_tag.save
  end

  test "should belong to quote and tag" do
    quote_tag = QuoteTag.create!(quote: @quote, tag: @tag)

    assert_equal @quote, quote_tag.quote
    assert_equal @tag, quote_tag.tag
  end

  test "should enforce unique quote-tag pairs" do
    QuoteTag.create!(quote: @quote, tag: @tag)

    duplicate = QuoteTag.new(quote: @quote, tag: @tag)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:quote_id], "Tag already assigned to this quote"
  end

  test "should allow same tag on different quotes" do
    other_quote = quotes(:two_towers_quote)

    # Clean up any existing associations to ensure test isolation
    QuoteTag.where(quote: [ @quote, other_quote ], tag: @tag).delete_all

    first_qt = QuoteTag.create!(quote: @quote, tag: @tag)
    assert first_qt.persisted?

    other_quote_tag = QuoteTag.new(quote: other_quote, tag: @tag)

    assert other_quote_tag.valid?, "Should be valid: #{other_quote_tag.errors.full_messages}"
    assert other_quote_tag.save
  end

  test "should allow different tags on same quote" do
    other_tag = Tag.create!(name: "courage")

    QuoteTag.create!(quote: @quote, tag: @tag)
    other_tag_association = QuoteTag.new(quote: @quote, tag: other_tag)

    assert other_tag_association.valid?
  end
end
