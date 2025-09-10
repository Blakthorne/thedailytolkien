require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "should create tag" do
    tag = Tag.new(name: "new_tag")
    assert tag.valid?
    assert tag.save
  end

  test "should require name" do
    tag = Tag.new
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "should enforce unique names" do
    Tag.create!(name: "unique_tag")

    tag2 = Tag.new(name: "unique_tag")
    assert_not tag2.valid?
    assert_includes tag2.errors[:name], "has already been taken"
  end

  test "should normalize name to lowercase" do
    tag = Tag.create!(name: "  Mixed Case TAG  ")
    assert_equal "mixed case tag", tag.name
  end

  test "should enforce unique names case insensitive" do
    Tag.create!(name: "CaseTest")

    tag2 = Tag.new(name: "CASETEST")
    assert_not tag2.valid?
    assert_includes tag2.errors[:name], "has already been taken"
  end

  test "should have many quotes through quote_tags" do
    tag = Tag.create!(name: "relationship_test")
    quote1 = quotes(:fellowship_quote)
    quote2 = quotes(:two_towers_quote)

    tag.quotes << quote1
    tag.quotes << quote2

    assert_includes tag.quotes, quote1
    assert_includes tag.quotes, quote2
    assert_equal 2, tag.quotes.count
  end

  test "usage_count returns correct count" do
    tag = Tag.create!(name: "popular")
    quote1 = quotes(:fellowship_quote)
    quote2 = quotes(:two_towers_quote)

    assert_equal 0, tag.usage_count

    tag.quotes << quote1
    assert_equal 1, tag.usage_count

    tag.quotes << quote2
    assert_equal 2, tag.usage_count
  end

  test "popular scope orders by usage" do
    tag1 = Tag.create!(name: "less-popular")
    tag2 = Tag.create!(name: "more-popular")
    tag3 = Tag.create!(name: "unused")

    # Clear existing associations to start fresh
    QuoteTag.where(tag: [ tag1, tag2, tag3 ]).delete_all

    # Add quotes to make tag2 more popular than tag1
    tag1.quote_tags.create!(quote: quotes(:fellowship_quote))
    tag2.quote_tags.create!(quote: quotes(:fellowship_quote))
    tag2.quote_tags.create!(quote: quotes(:two_towers_quote))
    # tag3 has no quotes

    # Test only our created tags
    test_tags = [ tag1, tag2, tag3 ]
    popular_order = Tag.where(id: test_tags.map(&:id)).popular.to_a

    # Should be ordered by quote count descending
    assert_equal tag2, popular_order.first
    assert_equal tag1, popular_order.second
  end

  test "to_json_with_stats includes all required data" do
    tag = Tag.create!(name: "test-tag", description: "Test description")

    # Don't use fixture quote since it may have existing relationships
    # Create a fresh quote for this test
    quote = Quote.create!(
      text: "Test quote for tag stats",
      book: "Test Book",
      character: "Test Character",
      context: "Test Context"
    )
    tag.quotes << quote

    json_data = tag.to_json_with_stats

    assert_equal tag.id, json_data[:id]
    assert_equal "test-tag", json_data[:name]
    assert_equal "Test description", json_data[:description]
    assert_equal 1, json_data[:usage_count]
    assert json_data[:created_at].present?
    # Recent usage should be 1 since we just created the association
    assert_equal 1, json_data[:recent_usage]
  end

  test "should allow optional description" do
    tag = Tag.create!(name: "no-description")
    assert_nil tag.description
    assert tag.valid?
  end

  test "should destroy quote_tags when tag is destroyed" do
    tag = Tag.create!(name: "to-delete")
    quote = quotes(:fellowship_quote)
    tag.quotes << quote

    assert_equal 1, QuoteTag.where(tag: tag).count

    assert_difference("QuoteTag.count", -1) do
      tag.destroy
    end
  end
end
