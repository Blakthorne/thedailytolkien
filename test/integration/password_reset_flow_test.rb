# frozen_string_literal: true

require "test_helper"

class PasswordResetFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:commentor)
    @user.update(email: "password_reset_test@example.com")
  end

  test "complete password reset flow works" do
    # Step 1: Visit sign-in page
    get new_user_session_path
    assert_response :success
    assert_select "a[href=?]", new_user_password_path, text: "Forgot your password?"

    # Step 2: Navigate to password reset request page
    get new_user_password_path
    assert_response :success
    assert_select "form[action=?][method=?]", user_password_path, "post"
    assert_select "input[type=?][name=?]", "email", "user[email]"
    assert_select "input[type=submit]"

    # Step 3: Submit password reset request
    assert_emails 1 do
      post user_password_path, params: {
        user: { email: @user.email }
      }
    end

    # Step 4: Verify redirect and flash message with actual Devise text
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select ".success-message", text: /If your email address exists in our database/i

    # Step 5: Get the reset token from the database (it's hashed)
    # Need to use send_reset_password_instructions which returns the raw token
    raw_token = @user.send_reset_password_instructions
    assert_not_nil raw_token, "Reset password token should be returned"

    # Step 6: Visit password reset edit page with token
    get edit_user_password_path(reset_password_token: raw_token)
    assert_response :success
    assert_select "form[action=?][method=?]", user_password_path, "post"
    assert_select "input[type=?][name=?]", "password", "user[password]"
    assert_select "input[type=?][name=?]", "password", "user[password_confirmation]"
    assert_select "input[type=submit]"

    # Step 7: Submit new password
    new_password = "NewSecurePassword123!"
    patch user_password_path, params: {
      user: {
        reset_password_token: raw_token,
        password: new_password,
        password_confirmation: new_password
      }
    }

    # Step 8: Verify user is signed in and redirected
    assert_redirected_to root_path
    follow_redirect!

    # Step 9: Verify user can sign in with new password
    delete destroy_user_session_path
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: new_password
      }
    }
    assert_redirected_to root_path
  end

  test "password reset request page renders correctly" do
    get new_user_password_path
    assert_response :success

    # Check for proper structure - h2 is in reset-container
    assert_select ".auth-wrapper"
    assert_select ".reset-container h2", text: "Forgot Your Password?"
    assert_select "input[type=email]#user_email"
    assert_select "input[type=submit]"
    assert_select "a[href=?]", new_user_session_path, text: "← Back to Sign In"
  end

  test "password reset edit page renders correctly" do
    # First generate a reset token
    @user.send_reset_password_instructions
    @user.reload

    get edit_user_password_path(reset_password_token: @user.reset_password_token)
    assert_response :success

    # Check for proper structure - h2 is in reset-container
    assert_select ".auth-wrapper"
    assert_select ".reset-container h2", text: "Reset Your Password"
    assert_select "input[type=password]#user_password"
    assert_select "input[type=password]#user_password_confirmation"
    assert_select ".password-requirements"
    assert_select "input[type=submit]"
  end

  test "password reset with invalid email shows appropriate message" do
    post user_password_path, params: {
      user: { email: "nonexistent@example.com" }
    }

    # Devise doesn't reveal whether email exists for security
    assert_redirected_to new_user_session_path
    follow_redirect!
    # Flash message will be displayed with standard Devise security message
    assert_select ".success-message", text: /If your email address exists in our database/i
  end

  test "password reset with expired token fails" do
    @user.send_reset_password_instructions
    @user.reload
    token = @user.reset_password_token

    # Simulate token expiration by backdating reset_password_sent_at
    @user.update_column(:reset_password_sent_at, 7.hours.ago)

    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!"
      }
    }

    # Should show error and re-render form
    assert_response :unprocessable_content
  end

  test "password reset with mismatched passwords fails" do
    @user.send_reset_password_instructions
    @user.reload

    patch user_password_path, params: {
      user: {
        reset_password_token: @user.reset_password_token,
        password: "NewPassword123!",
        password_confirmation: "DifferentPassword123!"
      }
    }

    assert_response :unprocessable_content
    # Error will be shown via client-side validation or server-side
    assert_select "form"
  end

  test "password reset with weak password fails" do
    @user.send_reset_password_instructions
    @user.reload

    patch user_password_path, params: {
      user: {
        reset_password_token: @user.reset_password_token,
        password: "weak",
        password_confirmation: "weak"
      }
    }

    assert_response :unprocessable_content
  end

  test "forgot password link is present on sign in page" do
    get new_user_session_path
    assert_response :success
    assert_select ".forgot-password-link a[href=?]", new_user_password_path
  end
end
