require "test_helper"

class CssLoadingTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update(role: "admin")
    sign_in @admin
  end

  test "admin dashboard loads without CSP blocking inline styles" do
    get admin_root_path
    assert_response :success

    # Verify CSP header allows inline styles
    csp_header = response.headers["Content-Security-Policy"]
    assert csp_header.include?("style-src"), "CSP header should include style-src"
    assert csp_header.include?("unsafe-inline"), "CSP should allow unsafe-inline for styles"
  end

  test "admin users page loads with inline styles" do
    get admin_users_path
    assert_response :success

    # Check that inline styles are present in the response
    assert_match(/style=/, response.body, "Page should contain inline styles")
  end

  test "sign in page loads with inline styles" do
    sign_out @admin

    get new_user_session_path
    assert_response :success

    # Verify inline styles can load
    assert_match(/style=/, response.body, "Sign in page should contain inline styles")
  end

  test "quotes index page loads with inline styles" do
    get root_path
    assert_response :success

    # Check for inline styles
    assert_match(/style=/, response.body, "Quotes page should contain inline styles")
  end

  test "CSP allows inline styles in all environments" do
    # Test that style-src includes unsafe-inline
    get root_path
    assert_response :success

    csp_header = response.headers["Content-Security-Policy"]
    if csp_header.present?
      assert csp_header.include?("unsafe-inline"),
        "CSP must allow unsafe-inline for styles due to 377+ inline style attributes"
    end
  end
end
