require "test_helper"

class QuoteInteractionSystemTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin_user)
    @quote = quotes(:fellowship_quote)
    sign_in @user
  end

  test "user can like a quote via AJAX" do
    assert_difference("QuoteLike.count", 1) do
      post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 1, response_data["likes_count"]
    assert_equal 0, response_data["dislikes_count"]

    like = QuoteLike.last
    assert_equal @user, like.user
    assert_equal @quote, like.quote
    assert like.like?
  end

  test "user can dislike a quote via AJAX" do
    assert_difference("QuoteLike.count", 1) do
      post quote_quote_likes_path(@quote), params: { like_type: "dislike" }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 0, response_data["likes_count"]
    assert_equal 1, response_data["dislikes_count"]

    like = QuoteLike.last
    assert_equal @user, like.user
    assert_equal @quote, like.quote
    assert like.dislike?
  end

  test "user can toggle from like to dislike" do
    # First like
    post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    assert_response :success

    # Then dislike (should update existing record)
    assert_no_difference("QuoteLike.count") do
      post quote_quote_likes_path(@quote), params: { like_type: "dislike" }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 0, response_data["likes_count"]
    assert_equal 1, response_data["dislikes_count"]

    like = QuoteLike.last
    assert like.dislike?
  end

  test "user can remove like by clicking same button" do
    # First like
    post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    assert_response :success

    # Click like again (should remove)
    assert_difference("QuoteLike.count", -1) do
      post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 0, response_data["likes_count"]
    assert_equal 0, response_data["dislikes_count"]
  end

  test "unauthenticated user cannot like quotes" do
    sign_out @user

    assert_no_difference("QuoteLike.count") do
      post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    end

    assert_response :unauthorized
  end

  test "user can create comment on quote" do
    assert_difference("Comment.count", 1) do
      post quote_comments_path(@quote), params: { comment: { content: "Great quote!" } }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]
    assert_equal 1, response_data["total_count"]

    comment = Comment.last
    assert_equal @user, comment.user
    assert_equal @quote, comment.quote
    assert_equal "Great quote!", comment.content
    assert_equal 0, comment.depth
  end

  test "user can reply to a comment" do
    parent_comment = Comment.create!(
      user: @user,
      quote: @quote,
      content: "Original comment",
      depth: 0
    )

    assert_difference("Comment.count", 1) do
      post quote_comments_path(@quote), params: {
        comment: { content: "Reply to comment" },
        parent_id: parent_comment.id
      }, as: :json
    end

    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data["success"]

    reply = Comment.last
    assert_equal parent_comment, reply.parent
    assert_equal 1, reply.depth
  end

  test "comment depth is limited to 4 levels" do
    # Create nested comments up to depth 4
    comment = @quote.comments.create!(user: @user, content: "Level 0", depth: 0)
    (1..4).each do |level|
      comment = comment.replies.create!(user: @user, quote: @quote, content: "Level #{level}", depth: level)
    end

    # Try to create depth 5 comment
    assert_no_difference("Comment.count") do
      post quote_comments_path(@quote), params: {
        comment: { content: "Level 5 - should fail" },
        parent_id: comment.id
      }, as: :json
    end

    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_not response_data["success"]
    assert_includes response_data["error"], "Maximum comment nesting depth exceeded"
  end

  test "profanity in comments is filtered" do
    assert_difference("Comment.count", 1) do
      post quote_comments_path(@quote), params: {
        comment: { content: "This is damn good!" }
      }, as: :json
    end

    assert_response :success
    comment = Comment.last
    assert_equal "This is damn good!", comment.content
    assert_equal "This is **** good!", comment.filtered_content
  end

  test "unauthenticated user cannot create comments" do
    sign_out @user

    assert_no_difference("Comment.count") do
      post quote_comments_path(@quote), params: { comment: { content: "Test comment" } }, as: :json
    end

    assert_response :unauthorized
  end

  test "user can delete their own comment" do
    comment = Comment.create!(
      user: @user,
      quote: @quote,
      content: "My comment"
    )

    assert_difference("Comment.count", -1) do
      delete comment_path(comment), as: :json
    end

    assert_response :success
  end

  test "user cannot delete others' comments" do
    # Sign in as a regular commentor (not admin)
    regular_user = users(:commentor_user)
    sign_in regular_user

    # Create comment by another user
    other_user = users(:admin_user)
    comment = Comment.create!(
      user: other_user,
      quote: @quote,
      content: "Other user's comment"
    )

    assert_no_difference("Comment.count") do
      delete comment_path(comment), as: :json
    end

    assert_response :forbidden

    # Sign back in as admin for other tests
    sign_in @user
  end

  test "admin can delete any comment" do
    other_user = users(:commentor_user)
    comment = Comment.create!(
      user: other_user,
      quote: @quote,
      content: "Other user's comment"
    )

    # Admin can delete
    assert_difference("Comment.count", -1) do
      delete comment_path(comment), as: :json
    end

    assert_response :success
  end

  test "get comments for quote returns properly formatted data" do
    # Create some test comments
    parent = Comment.create!(user: @user, quote: @quote, content: "Parent comment")
    Comment.create!(user: @user, quote: @quote, content: "Reply", parent: parent, depth: 1)

    get quote_comments_path(@quote), as: :json

    assert_response :success
    response_data = JSON.parse(response.body)

    assert_equal 2, response_data["total_count"]
    assert_equal 1, response_data["comments"].length  # Only top-level comments

    comment_data = response_data["comments"].first
    assert_equal "Parent comment", comment_data["content"]
    assert_equal 1, comment_data["replies"].length
    assert_equal "Reply", comment_data["replies"].first["content"]
  end
end
