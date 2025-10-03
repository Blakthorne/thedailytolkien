require "test_helper"

class PasswordPolicyTest < ActionDispatch::IntegrationTest
  test "should enforce minimum password length of 6 characters" do
    # Try to register with a password that's too short (5 characters)
    post user_registration_path, params: {
      user: {
        first_name: "Test",
        last_name: "User",
        email: "shortpass@example.com",
        password: "12345",
        password_confirmation: "12345"
      }
    }

    # Should fail validation
    assert_response :unprocessable_entity
  end

  test "should accept password with exactly 6 characters" do
    # Try to register with minimum valid password length
    post user_registration_path, params: {
      user: {
        first_name: "Test",
        last_name: "User",
        email: "minpass@example.com",
        password: "123456",
        password_confirmation: "123456"
      }
    }

    # Should succeed
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # Clean up
    User.find_by(email: "minpass@example.com")&.destroy
  end

  test "should accept password longer than minimum" do
    # Try to register with a longer password
    post user_registration_path, params: {
      user: {
        first_name: "Test",
        last_name: "User",
        email: "longpass@example.com",
        password: "thisismylongpassword123",
        password_confirmation: "thisismylongpassword123"
      }
    }

    # Should succeed
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # Clean up
    User.find_by(email: "longpass@example.com")&.destroy
  end

  test "should reject password exceeding maximum length" do
    # Try to register with a password that's too long (>128 characters)
    long_password = "a" * 129

    post user_registration_path, params: {
      user: {
        first_name: "Test",
        last_name: "User",
        email: "toolong@example.com",
        password: long_password,
        password_confirmation: long_password
      }
    }

    # Should fail validation
    assert_response :unprocessable_entity
  end

  test "should require password confirmation to match" do
    # Try to register with mismatched passwords
    post user_registration_path, params: {
      user: {
        first_name: "Test",
        last_name: "User",
        email: "mismatch@example.com",
        password: "password123",
        password_confirmation: "different123"
      }
    }

    # Should fail validation
    assert_response :unprocessable_entity
  end

  test "password configuration should be set to 6-128 characters" do
    # Verify the configuration
    assert_equal 6, Devise.password_length.min, "Minimum password length should be 6"
    assert_equal 128, Devise.password_length.max, "Maximum password length should be 128"
  end
end
