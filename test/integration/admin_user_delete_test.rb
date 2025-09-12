require "test_helper"

class AdminUserDeleteTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)

    @test_user = User.create!(
      email: "delete_test@example.com",
      password: "password",
      first_name: "Delete",
      last_name: "TestUser",
      role: "commentor"
    )
  end

  test "admin can delete user via DELETE request" do
    sign_in @admin

    initial_count = User.count

    # Make DELETE request to user path
    delete admin_user_path(@test_user)

    # Should redirect to users index
    assert_redirected_to admin_users_path

    # User should be deleted
    assert_equal initial_count - 1, User.count
    assert_not User.exists?(@test_user.id)

    # Should show success message
    follow_redirect!
    assert_match(/successfully deleted/, response.body)
  end

  test "admin cannot delete themselves" do
    sign_in @admin

    initial_count = User.count

    # Try to delete self
    delete admin_user_path(@admin)

    # Should redirect but user should not be deleted
    assert_redirected_to admin_users_path
    assert_equal initial_count, User.count
    assert User.exists?(@admin.id)
  end

  test "delete button shows correct attributes in view" do
    sign_in @admin

    get admin_user_path(@test_user)
    assert_response :success

    # Check for correct form-based delete
    assert_select 'form[method="post"]' do
      assert_select 'input[name="_method"][value="delete"]'
      assert_select 'input[type="submit"][value="Delete"]'
    end
    assert_select "form[data-turbo-confirm]"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
