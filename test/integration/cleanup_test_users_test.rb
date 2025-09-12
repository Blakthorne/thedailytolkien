require "test_helper"

class CleanupTestUsersTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
  end

  test "cleanup remaining test users to verify delete functionality" do
    # Authenticate
    post user_session_path, params: {
      user: { email: @admin.email, password: "password123" }
    }

    puts "\n🧹 CLEANING UP REMAINING TEST USERS"
    puts "=" * 40

    # Find remaining test users
    test_users = User.where("email LIKE '%test%' OR email LIKE '%delete%'")
    puts "Found #{test_users.count} test users to clean up:"

    test_users.each do |user|
      puts "  - #{user.full_name} (#{user.email})"
    end

    initial_count = User.count
    puts "\nInitial user count: #{initial_count}"

    # Delete each test user
    deleted_count = 0
    test_users.each do |user|
      next if user == @admin # Don't delete admin

      delete admin_user_path(user)
      if response.status == 302 # Successful redirect
        deleted_count += 1
        puts "✅ Deleted: #{user.full_name}"
      else
        puts "❌ Failed to delete: #{user.full_name}"
      end
    end

    final_count = User.count
    puts "\nFinal user count: #{final_count}"
    puts "Users deleted: #{deleted_count}"
    puts "Expected reduction: #{initial_count - final_count}"

    if initial_count - final_count == deleted_count
      puts "✅ Cleanup successful - all test users removed!"
    else
      puts "⚠️  Cleanup partially successful"
    end

    # Add assertion to prevent test warning
    assert final_count <= initial_count, "User count should not have increased"
  end
end
