require "test_helper"

module Users
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @oauth_user = User.create!(
        first_name: "OAuth",
        last_name: "User",
        email: "oauth@example.com",
        password: Devise.friendly_token[0, 20],
        provider: "google_oauth2",
        uid: "12345",
        role: "commentor"
      )
    end

    # Authentication Tests
    test "should redirect to login if not authenticated for show" do
      get profile_path
      assert_redirected_to new_user_session_path
    end

    test "should redirect to login if not authenticated for edit" do
      get edit_profile_path
      assert_redirected_to new_user_session_path
    end

    test "should redirect to login if not authenticated for update" do
      patch profile_path, params: { user: { first_name: "New", last_name: "Name" } }
      assert_redirected_to new_user_session_path
    end

    # Show Action Tests
    test "authenticated user can access show" do
      sign_in @user
      get profile_path
      assert_response :success
      assert_select "h1", "My Profile"
      assert_select ".info-value", @user.full_name
      assert_select ".info-value", @user.email
    end

    test "show displays current streak correctly" do
      # Sign in triggers update_login_streak which sets streak to 1 on first login
      sign_in @user
      get profile_path
      assert_response :success
      # After first login, user should have a 1-day streak
      assert_select ".stat-value", text: "1 days"
      assert_select ".stat-value", text: "1 days" # longest also becomes 1
    end

    test "show displays comments count" do
      sign_in @user
      # Create some comments for the user
      quote = Quote.create!(text: "Test quote", book: "Test book")
      3.times { Comment.create!(user: @user, quote: quote, content: "Test comment") }

      get profile_path
      assert_response :success
      assert_select ".stat-value", text: "3"
    end

    test "show displays oauth authentication badge for oauth users" do
      sign_in @oauth_user
      get profile_path
      assert_response :success
      assert_select ".oauth-badge", text: /Signed in with Google/
    end

    test "show displays email authentication badge for non-oauth users" do
      sign_in @user
      get profile_path
      assert_response :success
      assert_select ".auth-badge", text: /Email & Password/
    end

    test "show displays password reset button for non-oauth users" do
      sign_in @user
      get profile_path
      assert_response :success
      assert_select "form[action=?]", user_password_path
      assert_select "button.secondary-button", text: /Reset Password/
    end

    test "show does not display password reset button for oauth users" do
      sign_in @oauth_user
      get profile_path
      assert_response :success
      assert_select "form[action=?]", user_password_path, count: 0
      assert_select "button.secondary-button", text: /Reset Password/, count: 0
    end

    test "clicking reset password button sends reset instructions and shows flash message" do
      sign_in @user

      # Submit password reset request
      post user_password_path, params: { user: { email: @user.email } }

      # Should redirect to profile
      assert_redirected_to profile_path
      follow_redirect!

      # Check for the flash message
      assert flash[:notice].present?, "Should have a notice flash message"
      flash_message = flash[:notice]
      assert_match(/email/, flash_message.downcase, "Flash should mention email being sent")
    end

    test "reset password redirects oauth users appropriately" do
      sign_in @oauth_user

      # OAuth users can still access the endpoint, but shouldn't have encrypted_password
      post user_password_path, params: { user: { email: @oauth_user.email } }

      # Verify some response (could be redirect or error)
      assert_response :redirect
    end

    # Edit Action Tests
    test "authenticated user can access edit" do
      sign_in @user
      get edit_profile_path
      assert_response :success
      assert_select "h1", "Edit Profile"
      assert_select "input[name='user[first_name]']"
      assert_select "input[name='user[last_name]']"
    end

    test "edit form displays current user data" do
      sign_in @user
      get edit_profile_path
      assert_response :success
      assert_select "input[name='user[first_name]'][value=?]", @user.first_name
      assert_select "input[name='user[last_name]'][value=?]", @user.last_name
    end

    # Update Action Tests
    test "authenticated user can update first_name and last_name" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "Updated",
          last_name: "Name"
        }
      }

      assert_redirected_to profile_path
      follow_redirect!
      assert_select ".info-value", "Updated Name"

      @user.reload
      assert_equal "Updated", @user.first_name
      assert_equal "Name", @user.last_name
    end

    test "update rejects empty first_name" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "",
          last_name: "Name"
        }
      }

      assert_response :unprocessable_entity
      assert_select ".error-message"

      @user.reload
      assert_not_equal "", @user.first_name
    end

    test "update rejects empty last_name" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "Test",
          last_name: ""
        }
      }

      assert_response :unprocessable_entity
      assert_select ".error-message"

      @user.reload
      assert_not_equal "", @user.last_name
    end

    test "update rejects first_name longer than 50 characters" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "a" * 51,
          last_name: "Name"
        }
      }

      assert_response :unprocessable_entity

      @user.reload
      assert @user.first_name.length <= 50
    end

    test "update rejects last_name longer than 50 characters" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "Test",
          last_name: "b" * 51
        }
      }

      assert_response :unprocessable_entity

      @user.reload
      assert @user.last_name.length <= 50
    end

    test "update rejects names with invalid characters" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "Test123",
          last_name: "Name"
        }
      }

      assert_response :unprocessable_entity

      @user.reload
      assert_not_equal "Test123", @user.first_name
    end

    test "update accepts names with valid special characters" do
      sign_in @user
      patch profile_path, params: {
        user: {
          first_name: "Mary-Jane",
          last_name: "O'Brien-Smith"
        }
      }

      assert_redirected_to profile_path

      @user.reload
      assert_equal "Mary-Jane", @user.first_name
      assert_equal "O'Brien-Smith", @user.last_name
    end

    # Strong Parameters Tests
    test "update only permits first_name and last_name" do
      sign_in @user
      original_email = @user.email
      original_role = @user.role

      patch profile_path, params: {
        user: {
          first_name: "Updated",
          last_name: "Name",
          email: "hacker@example.com",
          role: "admin",
          current_streak: 999
        }
      }

      @user.reload
      assert_equal "Updated", @user.first_name
      assert_equal "Name", @user.last_name
      assert_equal original_email, @user.email
      assert_equal original_role, @user.role
      assert_not_equal 999, @user.current_streak
    end

    test "user cannot update another user's profile" do
      other_user = users(:two)
      sign_in @user

      # Even if we try to pass a different user ID, it should update current_user
      patch profile_path, params: {
        id: other_user.id,
        user: {
          first_name: "Hacked",
          last_name: "Name"
        }
      }

      @user.reload
      other_user.reload

      assert_equal "Hacked", @user.first_name
      assert_not_equal "Hacked", other_user.first_name
    end
  end
end
