require "test_helper"

class AccountEnumerationProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @existing_user = users(:admin)
    @nonexistent_email = "nonexistent@example.com"
  end

  test "should not reveal whether email exists on login failure" do
    # Try to login with existing user but wrong password
    post user_session_path, params: {
      user: {
        email: @existing_user.email,
        password: "wrongpassword"
      }
    }
    existing_user_status = response.status
    existing_user_flash = flash[:alert]

    # Try to login with non-existent user
    post user_session_path, params: {
      user: {
        email: @nonexistent_email,
        password: "wrongpassword"
      }
    }
    nonexistent_user_status = response.status
    nonexistent_user_flash = flash[:alert]

    # The responses should be identical (paranoid mode)
    # Both should return same status code
    assert_equal existing_user_status, nonexistent_user_status,
      "Paranoid mode should return same status for existing and non-existing users"

    # Both should return same error message (not revealing if email exists)
    assert_equal existing_user_flash, nonexistent_user_flash,
      "Paranoid mode should return identical error messages"
  end

  test "should not reveal whether email exists on password reset request" do
    # Request password reset for existing user
    post user_password_path, params: {
      user: {
        email: @existing_user.email
      }
    }
    existing_user_status = response.status

    # Request password reset for non-existent user
    post user_password_path, params: {
      user: {
        email: @nonexistent_email
      }
    }
    nonexistent_user_status = response.status

    # The responses should be identical (paranoid mode)
    assert_equal existing_user_status, nonexistent_user_status,
      "Paranoid mode should return same status for existing and non-existing users"
  end

  test "should lock account after maximum failed attempts" do
    user = users(:commentor)

    # Make 10 failed login attempts (maximum_attempts configured)
    10.times do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrongpassword"
        }
      }
    end

    # Reload user to get updated failed_attempts and locked_at
    user.reload

    # Account should be locked
    assert user.access_locked?, "User should be locked after #{Devise.maximum_attempts} failed attempts"
    assert_equal 10, user.failed_attempts, "Failed attempts should be 10"
    assert_not_nil user.locked_at, "Locked at timestamp should be set"
  end

  test "should not allow login when account is locked" do
    user = users(:commentor)

    # Lock the account manually
    user.lock_access!

    # Try to login with correct credentials
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    # Should not be signed in (422 status means login failed)
    assert_response :unprocessable_entity
    # With paranoid mode enabled, the error message should not reveal that the account is locked
    # It should show the generic "Invalid Email or password" message
    assert_equal "Invalid Email or password.", flash[:alert],
      "Paranoid mode should not reveal account is locked"
  end

  test "should reset failed attempts after successful login" do
    user = users(:commentor)

    # Make some failed attempts
    3.times do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrongpassword"
        }
      }
    end

    user.reload
    assert_equal 3, user.failed_attempts, "Failed attempts should be recorded"

    # Successful login
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    user.reload
    assert_equal 0, user.failed_attempts, "Failed attempts should be reset after successful login"
  end

  test "should automatically unlock account after unlock_in period" do
    user = users(:commentor)

    # Lock the account
    user.lock_access!

    # Simulate time passage (1 hour + 1 minute)
    travel_to(61.minutes.from_now) do
      # User should be unlocked now
      assert_not user.access_locked?, "User should be automatically unlocked after unlock_in period"
    end
  end

  test "locked account should increment failed attempts on additional login attempts" do
    user = users(:commentor)

    # Make 10 failed attempts to lock the account
    10.times do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "wrongpassword"
        }
      }
    end

    user.reload
    assert_equal 10, user.failed_attempts, "Should have 10 failed attempts"
    assert user.access_locked?, "Account should be locked"

    # Try another failed login
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "wrongpassword"
      }
    }

    user.reload
    assert_equal 11, user.failed_attempts, "Failed attempts should continue incrementing when locked"
  end
end
