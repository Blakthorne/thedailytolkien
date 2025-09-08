require "test_helper"

class DeviseAuthFlowsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:commentor_user)
  end

  test "sign in with valid credentials" do
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "sign in fails with invalid credentials" do
    post user_session_path, params: { user: { email: @user.email, password: "wrong" } }
    assert_response :unprocessable_content
  end

  test "sign out works" do
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    delete destroy_user_session_path
    assert_response :redirect
  end
end
