require "test_helper"

class AdminDeleteComprehensiveTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
  end

  test "comprehensive delete functionality tests" do
    puts "\n🎯 COMPREHENSIVE DELETE FUNCTIONALITY TEST"
    puts "=" * 50

    # Test 1: Create and delete user successfully
    test_user1 = User.create!(
      first_name: "Delete", last_name: "Test1",
      email: "delete-test1@example.com", password: "password123", role: "commentor"
    )

    # Authenticate
    post user_session_path, params: {
      user: { email: @admin.email, password: "password123" }
    }

    initial_count = User.count
    delete admin_user_path(test_user1)

    assert_redirected_to admin_users_path
    assert_equal initial_count - 1, User.count
    assert_not User.exists?(test_user1.id)
    puts "✅ Test 1: Regular user deletion - PASSED"

    # Test 2: Prevent self-deletion
    delete admin_user_path(@admin)
    assert_redirected_to admin_users_path
    assert User.exists?(@admin.id)
    puts "✅ Test 2: Self-deletion prevention - PASSED"

    # Test 3: Test multiple users
    test_users = []
    3.times do |i|
      test_users << User.create!(
        first_name: "Batch", last_name: "Test#{i}",
        email: "batch-test#{i}@example.com", password: "password123", role: "commentor"
      )
    end

    # Delete each one
    test_users.each do |user|
      count_before = User.count
      delete admin_user_path(user)
      assert_equal count_before - 1, User.count
      assert_not User.exists?(user.id)
    end
    puts "✅ Test 3: Multiple user deletions - PASSED"

    # Test 4: Verify success messages
    final_test_user = User.create!(
      first_name: "Final", last_name: "Test",
      email: "final-test@example.com", password: "password123", role: "commentor"
    )

    delete admin_user_path(final_test_user)
    follow_redirect!
    assert_match(/successfully deleted/, response.body)
    puts "✅ Test 4: Success message display - PASSED"

    puts "\n🎉 ALL DELETE FUNCTIONALITY TESTS PASSED!"
    puts "The form-based delete solution is working correctly."
  end
end
