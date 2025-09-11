require "test_helper"

class AdminUserDeleteDebugTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @test_user = User.create!(
      email: "debug-delete-test@example.com",
      password: "password123",
      first_name: "Debug",
      last_name: "DeleteTest",
      role: "commentor"
    )
  end

  test "debug delete request step by step" do
    # Step 1: Authenticate
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "password123"
      }
    }

    puts "\n🔍 DEBUGGING DELETE REQUEST"
    puts "=" * 40

    # Verify authentication worked
    puts "✅ Authentication successful" if response.status == 302

    # Step 2: Get the user show page to see the actual HTML
    get admin_user_path(@test_user)
    puts "✅ Show page loads: #{response.status == 200}"

    # Check if delete button exists in HTML
    if response.body.include?('data-turbo-method="delete"')
      puts "✅ Delete button found with correct Turbo syntax"
    elsif response.body.include?("Delete")
      puts "⚠️  Delete button found but syntax may be wrong"
      # Extract the delete link from HTML
      delete_link = response.body.match(/<a[^>]*>Delete<\/a>/m)
      puts "Delete link HTML: #{delete_link}" if delete_link
    else
      puts "❌ Delete button not found in HTML"
    end

    # Step 3: Make direct DELETE request
    puts "\n🚀 Making direct DELETE request..."
    initial_count = User.count
    puts "Initial user count: #{initial_count}"

    delete admin_user_path(@test_user), headers: {
      "Accept" => "text/html",
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    puts "Response status: #{response.status}"
    puts "Response location: #{response.headers['Location']}" if response.headers["Location"]

    final_count = User.count
    puts "Final user count: #{final_count}"

    if final_count < initial_count
      puts "✅ DELETE request worked! User was deleted."
    else
      puts "❌ DELETE request failed - user still exists"

      # Check if user still exists
      if User.exists?(@test_user.id)
        puts "❌ Test user still exists in database"
      else
        puts "🤔 Test user gone from database but count unchanged?"
      end
    end
  end
end
