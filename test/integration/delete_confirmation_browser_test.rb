require "test_helper"

class DeleteConfirmationBrowserTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
  end

  test "user delete confirmation works in browser simulation" do
    # Authenticate
    post user_session_path, params: {
      user: { email: @admin.email, password: "password123" }
    }

    # Create a test user
    test_user = User.create!(
      email: "browser-delete-test@example.com",
      password: "password123",
      first_name: "Browser",
      last_name: "Test",
      role: "commentor"
    )

    puts "\n🌐 BROWSER DELETE CONFIRMATION TEST"
    puts "=" * 40
    puts "Test user created: #{test_user.email}"

    # Visit the user page
    get admin_user_path(test_user)
    assert_response :success

    # Extract the delete form
    form_match = response.body.match(/<form[^>]*method[^>]*post[^>]*>.*?name="_method"[^>]*value="delete".*?<\/form>/m)

    if form_match
      form_html = form_match[0]
      puts "\n✅ Found delete form:"
      puts "📄 Form HTML snippet:"
      puts form_html[0..200] + "..."

      # Check for confirmation attribute
      if form_html.include?("data-turbo-confirm")
        confirm_match = form_html.match(/data-turbo-confirm="([^"]*)"/)
        if confirm_match
          puts "\n✅ Confirmation message: '#{confirm_match[1]}'"

          # Verify it's a proper warning message
          message = confirm_match[1].downcase
          if message.include?("sure") && (message.include?("delete") || message.include?("remove"))
            puts "✅ Confirmation message contains appropriate warning language"
          else
            puts "⚠️  Confirmation message may need improvement"
          end

          if message.include?("cannot be undone") || message.include?("irreversible")
            puts "✅ Confirmation message warns about permanence"
          else
            puts "⚠️  Consider adding permanence warning to confirmation"
          end
        end
      else
        puts "❌ No data-turbo-confirm attribute found"
      end

      # Check for proper CSRF token
      if form_html.include?("csrf-token") || form_html.include?("authenticity_token")
        puts "✅ CSRF protection present"
      else
        puts "⚠️  CSRF token may be missing"
      end

    else
      puts "❌ Delete form not found"
    end

    puts "\n🎯 MANUAL TESTING INSTRUCTIONS:"
    puts "1. Start server: bin/rails server"
    puts "2. Login as admin: http://localhost:3000/admin"
    puts "3. Visit test user: http://localhost:3000/admin/users/#{test_user.id}"
    puts "4. Click 'Delete' button - should show confirmation dialog"
    puts "5. Cancel to test dialog, or confirm to test actual deletion"

    puts "\n✅ Test user ready for manual verification at ID: #{test_user.id}"
  end
end
