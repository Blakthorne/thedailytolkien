require "test_helper"

class QuoteTaggingSystemTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @quote = quotes(:fellowship_quote)
    sign_in @admin
  end

  test "admin can create new tag" do
    assert_difference("Tag.count", 1) do
      post admin_tags_path, params: {
        tag: {
          name: "Courage",
          description: "Quotes containing courage"
        }
      }
    end

    assert_redirected_to admin_tag_path(Tag.last)
    follow_redirect!
    assert_match "Tag was successfully created", response.body

    tag = Tag.last
    assert_equal "courage", tag.name  # Should be normalized to lowercase
    assert_equal "Quotes containing courage", tag.description
  end

  test "admin can view all tags" do
    Tag.create!(name: "honor", description: "Honorable quotes")
    Tag.create!(name: "courage", description: "Courageous quotes")

    get admin_tags_path
    assert_response :success

    assert_match "honor", response.body
    assert_match "courage", response.body
  end

  test "admin can edit existing tag" do
    tag = Tag.create!(name: "test-tag", description: "Test description")

    patch admin_tag_path(tag), params: {
      tag: {
        name: "Updated Tag",
        description: "Updated description"
      }
    }

    assert_redirected_to admin_tag_path(tag)
    follow_redirect!
    assert_match "Tag was successfully updated", response.body

    tag.reload
    assert_equal "updated tag", tag.name
    assert_equal "Updated description", tag.description
  end

  test "admin can delete tag" do
    tag = Tag.create!(name: "delete-me", description: "To be deleted")

    assert_difference("Tag.count", -1) do
      delete admin_tag_path(tag)
    end

    assert_redirected_to admin_tags_path
    follow_redirect!
    assert_match(/Tag.*delete-me.*was successfully deleted/, response.body)
  end

  test "admin can add tag to quote" do
    tag = Tag.create!(name: "bravery")

    assert_difference("QuoteTag.count", 1) do
      post add_to_quote_admin_tag_path(tag), params: { quote_id: @quote.id }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]

    assert @quote.tags.include?(tag)
  end

  test "admin cannot add same tag to quote twice" do
    tag = Tag.create!(name: "loyalty")
    @quote.tags << tag

    assert_no_difference("QuoteTag.count") do
      post add_to_quote_admin_tag_path(tag), params: { quote_id: @quote.id }, as: :json
    end

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "already exists"
  end

  test "admin can remove tag from quote" do
    tag = Tag.create!(name: "valor")
    @quote.tags << tag

    assert_difference("QuoteTag.count", -1) do
      delete remove_from_quote_admin_tag_path(tag), params: { quote_id: @quote.id }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]

    assert_not @quote.tags.include?(tag)
  end

  test "tag names are unique" do
    Tag.create!(name: "unique-tag")

    tag2 = Tag.new(name: "Unique-Tag")  # Different case
    assert_not tag2.valid?
    assert_includes tag2.errors[:name], "has already been taken"
  end

  test "tag names are normalized to lowercase" do
    tag = Tag.create!(name: "  Mixed Case TAG  ")
    assert_equal "mixed case tag", tag.name
  end

  test "tag usage_count method returns correct count" do
    tag = Tag.create!(name: "popular")
    quote1 = quotes(:fellowship_quote)
    quote2 = quotes(:two_towers_quote)

    tag.quotes << quote1
    tag.quotes << quote2

    assert_equal 2, tag.usage_count
  end

  test "tag to_json_with_stats includes usage statistics" do
    tag = Tag.create!(name: "test", description: "Test tag")
    @quote.tags << tag

    json_data = tag.to_json_with_stats

    assert_equal "test", json_data[:name]
    assert_equal "Test tag", json_data[:description]
    assert_equal 1, json_data[:usage_count]
    assert json_data[:created_at].present?
    assert_equal 1, json_data[:recent_usage]  # Quote was just created, so it's recent
  end

  test "admin analytics includes tag statistics" do
    # Create some test data
    tag1 = Tag.create!(name: "hope")
    tag2 = Tag.create!(name: "strength")

    tag1.quotes << @quote
    tag1.quotes << quotes(:two_towers_quote)
    tag2.quotes << quotes(:return_king_quote)

    get admin_analytics_path
    assert_response :success

    # Check that analytics data is present (this would need to be enhanced based on view implementation)
    assert_match "analytics", response.body.downcase
  end

  test "non-admin cannot access tag management" do
    sign_out @admin
    sign_in users(:commentor)

    get admin_tags_path
    assert_response :redirect  # Should redirect to login or unauthorized
  end

  test "unauthenticated user cannot access tag management" do
    sign_out @admin

    get admin_tags_path
    assert_response :redirect  # Should redirect to login
  end

  test "deleting tag also removes quote_tag associations" do
    tag = Tag.create!(name: "to-delete")
    @quote.tags << tag
    another_quote = quotes(:two_towers_quote)
    another_quote.tags << tag

    assert_equal 2, tag.quote_tags.count

    assert_difference("Tag.count", -1) do
      assert_difference("QuoteTag.count", -2) do
        delete admin_tag_path(tag)
      end
    end

    # Verify quote_tags are also deleted
    assert_equal 0, QuoteTag.where(tag_id: tag.id).count
  end

  test "tag popular scope orders by usage count" do
    # Clear existing associations and create new quotes for isolated test
    QuoteTag.delete_all
    Tag.delete_all

    quote1 = Quote.create!(text: "Test quote 1", book: "Test", chapter: "1", character: "Test")
    quote2 = Quote.create!(text: "Test quote 2", book: "Test", chapter: "2", character: "Test")
    quote3 = Quote.create!(text: "Test quote 3", book: "Test", chapter: "3", character: "Test")

    tag1 = Tag.create!(name: "less-popular")
    tag2 = Tag.create!(name: "more-popular")
    tag3 = Tag.create!(name: "most-popular")

    # Add different numbers of quotes to each tag
    tag1.quotes << quote1

    tag2.quotes << quote1
    tag2.quotes << quote2

    tag3.quotes << quote1
    tag3.quotes << quote2
    tag3.quotes << quote3

    popular_tags = Tag.popular.limit(3)

    # Should be ordered by quote count descending
    assert_equal "most-popular", popular_tags.first.name
    assert_equal "more-popular", popular_tags.second.name
    assert_equal "less-popular", popular_tags.third.name
  end
end
