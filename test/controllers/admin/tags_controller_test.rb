require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin_user)
    @tag = tags(:friendship)
    sign_in @admin
  end

  test "should get index" do
    get admin_tags_url
    assert_response :success
    assert_select "h1", "Tag Management"
  end

  test "should get new" do
    get new_admin_tag_url
    assert_response :success
    assert_select "h1", "Create New Tag"
  end

  test "should create tag" do
    assert_difference("Tag.count") do
      post admin_tags_url, params: { tag: { name: "New Tag", description: "Test description" } }
    end

    assert_redirected_to admin_tag_url(Tag.last)
    assert_equal "Tag was successfully created.", flash[:notice]
  end

  test "should show tag" do
    get admin_tag_url(@tag)
    assert_response :success
    assert_select "h1", /Tag: #{@tag.name}/
  end

  test "should get edit" do
    get edit_admin_tag_url(@tag)
    assert_response :success
    assert_select "h1", /Edit Tag: #{@tag.name}/
  end

  test "should update tag" do
    patch admin_tag_url(@tag), params: { tag: { name: "Updated Tag Name", description: "Updated description" } }
    assert_redirected_to admin_tag_url(@tag)
    assert_equal "Tag was successfully updated.", flash[:notice]

    @tag.reload
    assert_equal "updated tag name", @tag.name  # normalized to lowercase
  end

  test "should not update tag with invalid data" do
    patch admin_tag_url(@tag), params: { tag: { name: "" } }
    assert_response :unprocessable_content
    assert_select ".error-messages"
  end

  test "should destroy tag" do
    assert_difference("Tag.count", -1) do
      delete admin_tag_url(@tag)
    end

    assert_redirected_to admin_tags_url
    assert_match(/Tag '#{@tag.name}' was successfully deleted./, flash[:notice])
  end

  test "should require admin authentication" do
    sign_out @admin

    get admin_tags_url
    assert_redirected_to new_user_session_path
  end

  test "should not allow non-admin users" do
    sign_out @admin
    commentor = users(:commentor_user)
    sign_in commentor

    get admin_tags_url
    assert_redirected_to root_path
    assert_equal "Access denied. Admin privileges required.", flash[:alert]
  end

  test "should handle search functionality" do
    get admin_tags_url, params: { search: "friend" }
    assert_response :success
    # Should include the friendship tag in search results
  end

  test "should add tag to quote via AJAX" do
    quote = quotes(:fellowship_quote)

    post add_to_quote_admin_tag_url(@tag), params: { quote_id: quote.id }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["success"]
  end

  test "should remove tag from quote via AJAX" do
    quote = quotes(:fellowship_quote)
    @tag.quotes << quote

    delete remove_from_quote_admin_tag_url(@tag), params: { quote_id: quote.id }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["success"]
  end

  test "should handle duplicate tag addition gracefully" do
    quote = quotes(:fellowship_quote)
    @tag.quotes << quote

    post add_to_quote_admin_tag_url(@tag), params: { quote_id: quote.id }
    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "Tag already exists on this quote", json_response["error"]
  end

  test "should log activity for tag operations" do
    assert_difference("ActivityLog.count", 1) do
      post admin_tags_url, params: { tag: { name: "Activity Test Tag" } }
    end

    activity = ActivityLog.last
    assert_equal "tag_created", activity.action
    assert_equal @admin, activity.user
  end
end
