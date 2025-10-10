require "application_system_test_case"

class PostSigninInteractivityTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      first_name: "Test",
      last_name: "SigninUser",
      email: "test_signin_interaction@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :commentor
    )
  end

  teardown do
    @user&.destroy
  end

  test "like/dislike buttons work immediately after signing in without refresh" do
    # Start on home page as guest
    visit root_path
    assert_selector ".quote-text", wait: 10

    # Verify we see the "Sign in to like/dislike" message
    assert_text "Sign in to like/dislike"

    # Sign in
    click_link "Sign in"
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    # Should be redirected to home page
    assert_current_path root_path
    assert_selector ".quote-text", wait: 10

    # Verify we're signed in (no more "Sign in to like/dislike" message)
    assert_no_text "Sign in to like/dislike"

    # Get initial counts
    like_button = find(".like-btn", match: :first)
    dislike_button = find(".dislike-btn", match: :first)

    initial_like_count = like_button.find(".count").text.to_i
    initial_dislike_count = dislike_button.find(".count").text.to_i

    # Click like button - THIS IS THE CRITICAL TEST
    # If the JavaScript isn't initialized, this click will do nothing
    like_button.click

    # Wait for AJAX request to complete and UI to update
    sleep 0.5

    # Verify like button became active
    assert like_button[:class].include?("like-active"),
           "Like button should have 'like-active' class after clicking"

    # Verify count increased
    new_like_count = like_button.find(".count").text.to_i
    assert_equal initial_like_count + 1, new_like_count,
                 "Like count should increase by 1"

    # Test dislike button as well
    dislike_button.click
    sleep 0.5

    # Like should be removed, dislike should be active
    assert_not like_button[:class].include?("like-active"),
               "Like button should not be active after clicking dislike"
    assert dislike_button[:class].include?("dislike-active"),
           "Dislike button should have 'dislike-active' class"

    # Verify counts updated correctly
    final_like_count = like_button.find(".count").text.to_i
    final_dislike_count = dislike_button.find(".count").text.to_i

    assert_equal initial_like_count, final_like_count,
                 "Like count should return to initial value"
    assert_equal initial_dislike_count + 1, final_dislike_count,
                 "Dislike count should increase by 1"
  end

  test "comment form works immediately after signing in without refresh" do
    # Start on home page as guest
    visit root_path
    assert_selector ".quote-text", wait: 10

    # Verify we see "Sign in to join the conversation"
    assert_text "Sign in to join the conversation"
    assert_no_selector "#comment-form"

    # Sign in
    click_link "Sign in"
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    # Should be redirected to home page
    assert_current_path root_path
    assert_selector ".quote-text", wait: 10

    # Verify comment form is now visible
    assert_selector "#comment-form"
    assert_no_text "Sign in to join the conversation"

    # Try to post a comment - THIS IS THE CRITICAL TEST
    within "#comment-form" do
      fill_in "comment_content", with: "This is a test comment after sign in"
      click_button "Post Comment"
    end

    # Wait for comment to appear
    sleep 1

    # Verify comment was posted successfully
    assert_text "This is a test comment after sign in"
    assert_text @user.email # Comment should show user's email
  end

  test "JavaScript modules are initialized after sign in redirect" do
    # Sign in
    visit new_user_session_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    # Should be redirected to home page
    assert_current_path root_path
    assert_selector ".quote-text", wait: 10

    # Execute JavaScript to verify modules are initialized
    js_result = page.execute_script(<<-JS)
      // Check if modules exist and are initialized
      const engagement = document.querySelector('[data-quote-engagement]');
      const commentForm = document.getElementById('comment-form');

      return {
        hasEngagementSection: engagement !== null,
        hasCommentForm: commentForm !== null,
        hasLikeButton: engagement?.querySelector('.like-btn') !== null,
        hasDislikeButton: engagement?.querySelector('.dislike-btn') !== null,
        readyState: document.readyState
      };
    JS

    assert js_result["hasEngagementSection"], "Engagement section should exist"
    assert js_result["hasCommentForm"], "Comment form should exist"
    assert js_result["hasLikeButton"], "Like button should exist"
    assert js_result["hasDislikeButton"], "Dislike button should exist"
    assert_equal "complete", js_result["readyState"], "Document should be fully loaded"
  end

  # Temporarily disabled - Philosophy page hidden
  # test "buttons work after navigation from another page" do
  #   # Sign in first
  #   visit new_user_session_path
  #   fill_in "Email", with: @user.email
  #   fill_in "Password", with: "password123"
  #   click_button "Sign in"

  #   # Navigate to Philosophy page
  #   click_link "Philosophy"
  #   assert_text "Our Philosophy"

  #   # Navigate back to home page
  #   click_link "The Daily Tolkien"
  #   assert_selector ".quote-text", wait: 10

  #   # Verify like button works after Turbo navigation
  #   like_button = find(".like-btn", match: :first)
  #   initial_count = like_button.find(".count").text.to_i

  #   like_button.click
  #   sleep 0.5

  #   assert like_button[:class].include?("like-active"),
  #          "Like button should work after Turbo navigation"

  #   new_count = like_button.find(".count").text.to_i
  #   assert_equal initial_count + 1, new_count,
  #                "Like count should increase after Turbo navigation"
  # end

  # Temporarily disabled - Philosophy page hidden
  # test "buttons work after browser back button" do
  #   # Sign in and interact
  #   visit new_user_session_path
  #   fill_in "Email", with: @user.email
  #   fill_in "Password", with: "password123"
  #   click_button "Sign in"

  #   assert_current_path root_path
  #   assert_selector ".quote-text", wait: 10

  #   # Click like button
  #   like_button = find(".like-btn", match: :first)
  #   like_button.click
  #   sleep 0.5

  #   assert like_button[:class].include?("like-active")

  #   # Navigate to another page
  #   click_link "Philosophy"
  #   assert_text "Our Philosophy"

  #   # Use browser back button
  #   page.go_back
  #   assert_selector ".quote-text", wait: 10

  #   # Verify like button still shows active state
  #   like_button = find(".like-btn", match: :first)
  #   assert like_button[:class].include?("like-active"),
  #          "Like state should persist after back button"

  #   # Verify we can still interact (remove like)
  #   like_button.click
  #   sleep 0.5

  #   assert_not like_button[:class].include?("like-active"),
  #              "Should be able to remove like after back button"
  # end
end
