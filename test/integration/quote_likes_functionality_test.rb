require "test_helper"

class QuoteLikesFunctionalityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:commentor)
    @quote = quotes(:one)
  end

  test "authenticated user can create a like" do
    sign_in @user

    assert_difference "@quote.quote_likes.count", 1 do
      post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "like", json_response["user_like_status"]
    assert_equal 1, json_response["likes_count"]
    assert_equal 0, json_response["dislikes_count"]
  end

  test "authenticated user can create a dislike" do
    sign_in @user

    assert_difference "@quote.quote_likes.count", 1 do
      post quote_quote_likes_path(@quote), params: { like_type: "dislike" }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "dislike", json_response["user_like_status"]
    assert_equal 0, json_response["likes_count"]
    assert_equal 1, json_response["dislikes_count"]
  end

  test "authenticated user can toggle from like to dislike" do
    sign_in @user

    # First create a like
    post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    assert_response :success

    # Then change to dislike - should not create new record, just update existing
    assert_no_difference "@quote.quote_likes.count" do
      post quote_quote_likes_path(@quote), params: { like_type: "dislike" }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "dislike", json_response["user_like_status"]
    assert_equal 0, json_response["likes_count"]
    assert_equal 1, json_response["dislikes_count"]
  end

  test "authenticated user can remove like by clicking same button" do
    sign_in @user

    # First create a like
    post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    assert_response :success

    # Click like again to remove it
    assert_difference "@quote.quote_likes.count", -1 do
      post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_nil json_response["user_like_status"]
    assert_equal 0, json_response["likes_count"]
    assert_equal 0, json_response["dislikes_count"]
  end

  test "unauthenticated user cannot create likes" do
    post quote_quote_likes_path(@quote), params: { like_type: "like" }, as: :json
    assert_response :unauthorized
  end

  test "invalid like_type returns error" do
    sign_in @user

    post quote_quote_likes_path(@quote), params: { like_type: "invalid" }, as: :json
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
  end
end
