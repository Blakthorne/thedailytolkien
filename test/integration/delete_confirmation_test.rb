require "test_helper"

class DeleteConfirmationTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
  end

  test "delete confirmation dialog HTML structure" do
    # Authenticate
    post user_session_path, params: {
      user: { email: @admin.email, password: "password123" }
    }

    # Create a test user to examine
    test_user = User.create!(
      email: "confirm-test@example.com",
      password: "password123",
      first_name: "Confirm",
      last_name: "Test",
      role: "commentor"
    )

    puts "\n🔍 TESTING DELETE CONFIRMATION DIALOG"
    puts "=" * 40

    # Get the user show page
    get admin_user_path(test_user)
    assert_response :success

    # Check for the delete form with confirmation
    puts "Checking HTML for delete confirmation attributes..."

    # Extract the form HTML
    form_html = response.body.match(/<form[^>]*method[^>]*delete[^>]*>.*?<\/form>/m)

    if form_html
      puts "✅ Found delete form in HTML"
      puts "Form HTML: #{form_html[0]}"

      # Check for turbo_confirm attribute
      if form_html[0].include?("data-turbo-confirm")
        puts "✅ Found data-turbo-confirm attribute"

        # Extract the confirmation message
        confirm_match = form_html[0].match(/data-turbo-confirm="([^"]*)"/)
        if confirm_match
          puts "✅ Confirmation message: #{confirm_match[1]}"
        else
          puts "❌ Could not extract confirmation message"
        end
      else
        puts "❌ Missing data-turbo-confirm attribute"
      end

      # Check for proper form structure
      if form_html[0].include?('method="post"') && form_html[0].include?("_method") && form_html[0].include?("delete")
        puts "✅ Proper delete method structure found"
      else
        puts "❌ Missing proper delete method structure"
      end

    else
      puts "❌ No delete form found in HTML"
    end

    # Also check for JavaScript/Turbo loading
    if response.body.include?("turbo")
      puts "✅ Turbo references found in page"
    else
      puts "❌ No Turbo references found"
    end

    # Cleanup
    test_user.destroy
  end
end
