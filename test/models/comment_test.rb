require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @quote = quotes(:fellowship_quote)
  end

  test "should create comment" do
    comment = Comment.new(user: @user, quote: @quote, content: "Great quote!")
    assert comment.valid?
    assert comment.save
    assert_equal 0, comment.depth
  end

  test "should require content" do
    comment = Comment.new(user: @user, quote: @quote)
    assert_not comment.valid?
    assert_includes comment.errors[:content], "can't be blank"
  end

  test "should validate content length" do
    comment = Comment.new(user: @user, quote: @quote, content: "a" * 2001)
    assert_not comment.valid?
    assert_includes comment.errors[:content], "is too long (maximum is 2000 characters)"

    comment.content = ""
    assert_not comment.valid?
    assert_includes comment.errors[:content], "is too short (minimum is 1 character)"
  end

  test "should set depth for nested comments" do
    parent = Comment.create!(user: @user, quote: @quote, content: "Parent")

    child = Comment.new(user: @user, quote: @quote, content: "Child", parent: parent)
    child.save!

    assert_equal 1, child.depth
  end

  test "should validate maximum depth" do
    comment = @quote.comments.create!(user: @user, content: "Level 0", depth: 0)

    (1..4).each do |level|
      comment = comment.replies.create!(user: @user, quote: @quote, content: "Level #{level}", depth: level)
    end

    # Try to create a depth 5 comment
    deep_comment = Comment.new(user: @user, quote: @quote, content: "Too deep", parent: comment)
    deep_comment.valid?  # This triggers set_depth callback

    assert_not deep_comment.valid?
    assert_includes deep_comment.errors[:parent], "Comment nesting too deep (max 4 levels)"
  end

  test "should filter profanity" do
    comment = Comment.create!(user: @user, quote: @quote, content: "This is damn good!")

    assert_equal "This is damn good!", comment.content
    assert_equal "This is **** good!", comment.filtered_content
  end

  test "should not filter clean content" do
    comment = Comment.create!(user: @user, quote: @quote, content: "This is really good!")

    assert_equal "This is really good!", comment.content
    assert_equal "This is really good!", comment.filtered_content
  end

  test "should have proper associations" do
    parent = Comment.create!(user: @user, quote: @quote, content: "Parent")
    child = Comment.create!(user: @user, quote: @quote, content: "Child", parent: parent)

    assert_equal @user, parent.user
    assert_equal @quote, parent.quote
    assert_nil parent.parent
    assert_includes parent.replies, child

    assert_equal parent, child.parent
  end

  test "scopes work correctly" do
    parent = Comment.create!(user: @user, quote: @quote, content: "Parent")
    child = Comment.create!(user: @user, quote: @quote, content: "Child", parent: parent)

    top_level_comments = @quote.comments.top_level
    assert_includes top_level_comments, parent
    assert_not_includes top_level_comments, child

    ordered_comments = @quote.comments.ordered
    # Should be ordered by created_at
    assert_equal parent, ordered_comments.first
  end

  test "should cascade delete replies when parent deleted" do
    parent = Comment.create!(user: @user, quote: @quote, content: "Parent")
    child = Comment.create!(user: @user, quote: @quote, content: "Child", parent: parent)
    Comment.create!(user: @user, quote: @quote, content: "Grandchild", parent: child)

    assert_difference("Comment.count", -3) do
      parent.destroy
    end
  end

  test "to_admin_json returns proper format" do
    comment = Comment.create!(user: @user, quote: @quote, content: "Test with damn profanity")

    json_data = comment.to_admin_json

    assert_equal comment.id, json_data[:id]
    assert_equal "Test with damn profanity", json_data[:content]
    assert_equal "Test with **** profanity", json_data[:filtered_content]
    assert_equal @user.email, json_data[:user_email]
    assert json_data[:quote_text].present?
    assert_equal @quote.id, json_data[:quote_id]
    assert_equal 0, json_data[:depth]
    assert json_data[:has_profanity]
    assert json_data[:created_at].present?
    assert_equal 0, json_data[:replies_count]
  end

  test "creates activity log after creation" do
    assert_difference("ActivityLog.count", 1) do
      Comment.create!(user: @user, quote: @quote, content: "Test comment")
    end

    log = ActivityLog.last
    assert_equal @user, log.user
    assert_equal "comment_created", log.action
    assert_equal @quote, log.target
  end
end
