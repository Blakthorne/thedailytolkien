require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "should include X-Frame-Options header" do
    get root_path
    assert_response :success
    assert_equal "DENY", response.headers["X-Frame-Options"],
      "X-Frame-Options header should be set to DENY"
  end

  test "should include X-Content-Type-Options header" do
    get root_path
    assert_response :success
    assert_equal "nosniff", response.headers["X-Content-Type-Options"],
      "X-Content-Type-Options header should be set to nosniff"
  end

  test "should include X-XSS-Protection header" do
    get root_path
    assert_response :success
    assert_equal "1; mode=block", response.headers["X-XSS-Protection"],
      "X-XSS-Protection header should be set to 1; mode=block"
  end

  test "should include Referrer-Policy header" do
    get root_path
    assert_response :success
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"],
      "Referrer-Policy header should be set to strict-origin-when-cross-origin"
  end

  test "should include Permissions-Policy header" do
    get root_path
    assert_response :success
    assert response.headers["Permissions-Policy"].present?,
      "Permissions-Policy header should be present"
    assert_includes response.headers["Permissions-Policy"], "geolocation=()",
      "Permissions-Policy should restrict geolocation"
  end

  test "should include Content-Security-Policy header" do
    get root_path
    assert_response :success
    assert response.headers["Content-Security-Policy"].present?,
      "Content-Security-Policy header should be present"
  end

  test "CSP should restrict default-src" do
    get root_path
    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert_includes csp, "default-src", "CSP should include default-src directive"
  end

  test "CSP should restrict object-src to none" do
    get root_path
    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert_includes csp, "object-src 'none'", "CSP should set object-src to none"
  end

  test "CSP should allow self for script-src" do
    get root_path
    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert_includes csp, "script-src", "CSP should include script-src directive"
    assert_includes csp, "'self'", "CSP should allow 'self' for scripts"
  end

  test "CSP should allow self for style-src" do
    get root_path
    assert_response :success
    csp = response.headers["Content-Security-Policy"]
    assert_includes csp, "style-src", "CSP should include style-src directive"
  end

  test "all security headers should be present on protected pages" do
    # Test on a different page to ensure headers are applied globally
    user = users(:commentor)
    sign_in user

    get philosophy_path

    assert_response :success
    assert response.headers["X-Frame-Options"].present?, "X-Frame-Options should be present"
    assert response.headers["X-Content-Type-Options"].present?, "X-Content-Type-Options should be present"
    assert response.headers["X-XSS-Protection"].present?, "X-XSS-Protection should be present"
    assert response.headers["Referrer-Policy"].present?, "Referrer-Policy should be present"
    assert response.headers["Content-Security-Policy"].present?, "Content-Security-Policy should be present"
  end

  test "security headers should be present on admin pages" do
    # Test on admin page
    user = users(:admin)
    sign_in user

    get admin_root_path

    # Should have security headers on admin pages
    assert_response :success
    assert response.headers["X-Frame-Options"].present?, "X-Frame-Options should be present on admin pages"
    assert response.headers["X-Content-Type-Options"].present?, "X-Content-Type-Options should be present on admin pages"
    assert response.headers["Referrer-Policy"].present?, "Referrer-Policy should be present on admin pages"
  end
end
