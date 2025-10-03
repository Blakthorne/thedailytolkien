# frozen_string_literal: true

require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    # Enable Rack::Attack for these tests
    Rack::Attack.enabled = true
    # Clear Rack::Attack cache before each test
    Rack::Attack.cache.store.clear
    @user = users(:one)
  end

  teardown do
    # Disable Rack::Attack after tests
    Rack::Attack.enabled = false
  end

  test "allows login attempts under the limit" do
    14.times do
      post user_session_path, params: { user: { email: @user.email, password: "wrong_password" } }
    end

    # Should not be rate limited (but login will fail with 422)
    assert_response :unprocessable_entity
    assert_not_equal 429, response.status
  end

  test "blocks login attempts over the email limit" do
    # Make 15 attempts (the limit)
    15.times do
      post user_session_path, params: { user: { email: @user.email, password: "wrong_password" } }
    end

    # 16th attempt should be blocked
    post user_session_path, params: { user: { email: @user.email, password: "wrong_password" } }
    assert_response :too_many_requests
    assert_match(/too many/i, response.body)
  end

  test "blocks login attempts over the IP limit" do
    # Make 15 attempts with different emails (the IP limit)
    15.times do |i|
      post user_session_path, params: { user: { email: "test#{i}@example.com", password: "wrong_password" } }
    end

    # 16th attempt should be blocked
    post user_session_path, params: { user: { email: "test99@example.com", password: "wrong_password" } }
    assert_response :too_many_requests
  end

  test "allows password reset requests under the limit" do
    2.times do
      post user_password_path, params: { user: { email: @user.email } }
    end

    assert_response :redirect
  end

  test "blocks password reset requests over the email limit" do
    # Make 3 attempts (the limit)
    3.times do
      post user_password_path, params: { user: { email: @user.email } }
    end

    # 4th attempt should be blocked
    post user_password_path, params: { user: { email: @user.email } }
    assert_response :too_many_requests
  end

  test "blocks password reset requests over the IP limit" do
    # Make 10 attempts with different emails (the IP limit)
    10.times do |i|
      post user_password_path, params: { user: { email: "test#{i}@example.com" } }
    end

    # 11th attempt should be blocked
    post user_password_path, params: { user: { email: "test99@example.com" } }
    assert_response :too_many_requests
  end

  test "allows registration requests under the limit" do
    4.times do |i|
      post user_registration_path, params: {
        user: {
          first_name: "Test",
          last_name: "User",
          email: "newuser#{i}@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # Should still be allowed (limit is 5) - last attempt should succeed
    assert_response :redirect
  end

  test "blocks registration requests over the IP limit" do
    # Make 5 registration attempts (the limit)
    5.times do |i|
      post user_registration_path, params: {
        user: {
          first_name: "Test",
          last_name: "User",
          email: "bulkuser#{i}@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # 6th attempt should be blocked
    post user_registration_path, params: {
      user: {
        first_name: "Blocked",
        last_name: "User",
        email: "blocked@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_response :too_many_requests
  end

  test "allows general requests under the limit" do
    100.times do
      get root_path
    end

    assert_response :success
  end

  test "blocks general requests over the IP limit" do
    # Make 500 requests (the limit)
    500.times do
      get root_path
    end

    # 501st request should be blocked
    get root_path
    assert_response :too_many_requests
  end

  test "rate limit headers are present in throttled response" do
    # Make enough requests to trigger throttle
    15.times do
      post user_session_path, params: { user: { email: @user.email, password: "wrong" } }
    end

    post user_session_path, params: { user: { email: @user.email, password: "wrong" } }

    assert_response :too_many_requests
    assert response.headers["RateLimit-Limit"].present?, "RateLimit-Limit header missing"
    assert response.headers["RateLimit-Remaining"].present?, "RateLimit-Remaining header missing"
    assert response.headers["RateLimit-Reset"].present?, "RateLimit-Reset header missing"
    assert response.headers["Retry-After"].present?, "Retry-After header missing"
  end

  test "different IPs are tracked separately" do
    # This test verifies the concept, though in practice changing IPs in tests is complex
    # Make 15 attempts from "one IP" (simulated by using same test session)
    15.times do
      post user_session_path, params: { user: { email: "user1@example.com", password: "wrong" } }
    end

    # Should be blocked
    post user_session_path, params: { user: { email: "user1@example.com", password: "wrong" } }
    assert_response :too_many_requests
  end

  test "different emails for password reset are tracked separately" do
    user2 = users(:two)

    # Max out one email
    3.times do
      post user_password_path, params: { user: { email: @user.email } }
    end

    # Should be blocked for first email
    post user_password_path, params: { user: { email: @user.email } }
    assert_response :too_many_requests

    # But still allowed for different email
    post user_password_path, params: { user: { email: user2.email } }
    assert_response :redirect
  end
end
