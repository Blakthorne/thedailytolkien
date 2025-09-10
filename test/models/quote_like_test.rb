require "test_helper"

class QuoteLikeTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin)
    @quote = quotes(:fellowship_quote)
  end

  test "should create quote like" do
    like = QuoteLike.new(user: @user, quote: @quote, like_type: :like)
    assert like.valid?
    assert like.save
  end

  test "should create quote dislike" do
    dislike = QuoteLike.new(user: @user, quote: @quote, like_type: :dislike)
    assert dislike.valid?
    assert dislike.save
  end

  test "should not allow duplicate likes from same user" do
    QuoteLike.create!(user: @user, quote: @quote, like_type: :like)

    duplicate_like = QuoteLike.new(user: @user, quote: @quote, like_type: :like)
    assert_not duplicate_like.valid?
    assert_includes duplicate_like.errors[:user_id], "can only like or dislike a quote once"
  end

  test "should allow different users to like same quote" do
    QuoteLike.create!(user: @user, quote: @quote, like_type: :like)

    other_user = users(:commentor)
    other_like = QuoteLike.new(user: other_user, quote: @quote, like_type: :like)
    assert other_like.valid?
  end

  test "should require like_type" do
    like = QuoteLike.new(user: @user, quote: @quote)
    assert_not like.valid?
    assert_includes like.errors[:like_type], "can't be blank"
  end

  test "should belong to user and quote" do
    like = QuoteLike.create!(user: @user, quote: @quote, like_type: :like)

    assert_equal @user, like.user
    assert_equal @quote, like.quote
  end

  test "enum methods work correctly" do
    like = QuoteLike.create!(user: @user, quote: @quote, like_type: :like)
    dislike = QuoteLike.create!(user: users(:commentor), quote: @quote, like_type: :dislike)

    assert like.like?
    assert_not like.dislike?

    assert dislike.dislike?
    assert_not dislike.like?
  end

  test "scopes work correctly" do
    like = QuoteLike.create!(user: @user, quote: @quote, like_type: :like)
    dislike = QuoteLike.create!(user: users(:commentor), quote: @quote, like_type: :dislike)

    assert_includes QuoteLike.likes, like
    assert_not_includes QuoteLike.likes, dislike

    assert_includes QuoteLike.dislikes, dislike
    assert_not_includes QuoteLike.dislikes, like
  end
end
