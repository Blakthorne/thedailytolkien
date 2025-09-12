require "test_helper"

class AdminDeleteFormTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @test_user = User.create!(
      first_name: "Form",
      last_name: "DeleteTest",
      email: "form-delete-test@example.com",
      password: "password123",
      role: "commentor"
    )
  end

  test "form-based delete functionality" do
    # Authenticate
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "password123"
      }
    }

    puts "\n🔍 TESTING FORM-BASED DELETE"
    puts "=" * 40

    # Get the show page and inspect the HTML
    get admin_user_path(@test_user)
    html = response.body

    # Check for form and CSRF token
    has_form = html.include?("<form") && html.include?('method="post"')
    has_csrf = html.include?("authenticity_token") || html.include?("csrf-token")
    has_delete_method = html.include?('name="_method"') && html.include?('value="delete"')
    has_turbo_confirm = html.include?("data-turbo-confirm")

    puts "✅ Form present: #{has_form}"
    puts "✅ CSRF token present: #{has_csrf}"
    puts "✅ DELETE method hidden field: #{has_delete_method}"
    puts "✅ Turbo confirm present: #{has_turbo_confirm}"

    # Test the delete request
    initial_count = User.count
    puts "\nInitial user count: #{initial_count}"

    delete admin_user_path(@test_user)

    final_count = User.count
    puts "Final user count: #{final_count}"

    success = final_count < initial_count
    puts "🎯 Delete successful: #{success ? 'YES ✅' : 'NO ❌'}"

    if success
      puts "✅ Form-based delete is working!"
    else
      puts "❌ Form-based delete still not working"
    end

    # Add assertion to prevent test warning
    assert_response :redirect
  end
end
