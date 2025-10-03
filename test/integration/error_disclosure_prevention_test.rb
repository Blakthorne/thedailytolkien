require "test_helper"

class ErrorDisclosurePreventionTest < ActionDispatch::IntegrationTest
  test "404 error page should not disclose sensitive information" do
    # Request a non-existent page
    get "/non-existent-page"

    assert_response :not_found

    # Verify no sensitive information is disclosed
    assert_no_match(/stack trace/i, response.body, "404 page should not contain stack traces")
    assert_no_match(/activerecord/i, response.body, "404 page should not mention ActiveRecord")
    assert_no_match(/secret/i, response.body, "404 page should not contain secrets")
    assert_no_match(/password/i, response.body, "404 page should not contain password information")
    assert_no_match(/database/i, response.body, "404 page should not contain database information")
  end

  test "404 error page should have user-friendly message" do
    get "/non-existent-page"

    assert_response :not_found

    # Should have user-friendly content
    assert_match(/404|not found/i, response.body, "404 page should mention the error")
    assert_match(/tolkien|home|back/i, response.body, "404 page should have navigation options")
  end

  test "422 error page should not disclose sensitive information" do
    # The 422 page is shown for unprocessable entities
    # We can't easily trigger a real 422 in integration test without causing validation errors
    # So we'll verify the static HTML file content
    error_page = File.read(Rails.public_path.join("422.html"))

    assert_no_match(/stack trace/i, error_page, "422 page should not contain stack traces")
    assert_no_match(/activerecord/i, error_page, "422 page should not mention ActiveRecord")
    assert_no_match(/secret/i, error_page, "422 page should not contain secrets")
    assert_no_match(/password/i, error_page, "422 page should not contain password information")
  end

  test "500 error page should not disclose sensitive information" do
    # Verify the static 500 HTML file content
    error_page = File.read(Rails.public_path.join("500.html"))

    assert_no_match(/stack trace/i, error_page, "500 page should not contain stack traces")
    assert_no_match(/activerecord/i, error_page, "500 page should not mention ActiveRecord")
    assert_no_match(/secret/i, error_page, "500 page should not contain secrets")
    assert_no_match(/password/i, error_page, "500 page should not contain password information")
    assert_no_match(/exception/i, error_page, "500 page should not mention exceptions")
  end

  test "500 error page should have user-friendly message" do
    error_page = File.read(Rails.public_path.join("500.html"))

    # Should have user-friendly content
    assert_match(/500|server error|something went wrong/i, error_page,
      "500 page should mention the error in user-friendly terms")
    assert_match(/tolkien|home|back/i, error_page, "500 page should have navigation options")
  end

  test "production environment should be configured to hide errors" do
    # Verify production is configured to not show detailed errors
    # In production, consider_all_requests_local should be false
    # This is verified in the config file
    production_config = File.read(Rails.root.join("config/environments/production.rb"))
    assert_match(/consider_all_requests_local\s*=\s*false/, production_config,
      "Production should have consider_all_requests_local = false")
  end

  test "error responses should not include detailed exception messages" do
    # Try to trigger an error by accessing admin without authentication
    get admin_root_path

    # Should redirect to login, not show detailed error
    assert_redirected_to new_user_session_path

    # Response should not contain stack trace or exception details
    assert_no_match(/exception/i, response.body)
    assert_no_match(/backtrace/i, response.body)
  end

  test "flash messages should not expose sensitive system information" do
    # Try various invalid operations
    user = users(:commentor)
    sign_in user

    # Try to access admin area as non-admin
    get admin_root_path

    # Should redirect with appropriate message, not system details
    assert_redirected_to root_path

    follow_redirect!

    # Flash message should be user-friendly, not technical
    assert_no_match(/activerecord/i, response.body)
    assert_no_match(/rails/i, flash[:alert].to_s.downcase) if flash[:alert]
  end

  test "error pages should have proper security headers" do
    # Request 404 page
    get "/non-existent-page"

    # Should still have security headers
    assert response.headers["X-Frame-Options"].present?, "404 page should have X-Frame-Options header"
    assert response.headers["X-Content-Type-Options"].present?, "404 page should have X-Content-Type-Options header"
  end
end
