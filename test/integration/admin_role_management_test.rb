require "test_helper"

class AdminRoleManagementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin_user = users(:admin_user)
    @commentor_user = users(:commentor_user)
    sign_in @admin_user
  end

  test "admin can promote commentor to admin" do
    assert @commentor_user.commentor?

    patch update_role_admin_user_path(@commentor_user, role: "admin")

    assert_response :redirect
    @commentor_user.reload
    assert @commentor_user.admin?
  end

  test "admin can demote admin to commentor" do
    # Create another admin user to demote
    another_admin = User.create!(
      email: "another@admin.com",
      password: "password123",
      role: "admin"
    )

    assert another_admin.admin?

    patch update_role_admin_user_path(another_admin, role: "commentor")

    assert_response :redirect
    another_admin.reload
    assert another_admin.commentor?
  end

  test "admin cannot change their own role" do
    assert @admin_user.admin?

    patch update_role_admin_user_path(@admin_user, role: "commentor")

    assert_response :redirect
    assert_redirected_to admin_user_path(@admin_user)

    # Check that the alert flash message was set
    follow_redirect!
    assert_match(/cannot change your own role/i, flash[:alert])

    @admin_user.reload
    assert @admin_user.admin? # Should remain admin
  end

  test "commentor cannot access role management" do
    sign_out @admin_user
    sign_in @commentor_user

    patch update_role_admin_user_path(@admin_user, role: "commentor")

    assert_response :redirect
    assert_redirected_to root_path
  end

  test "role update requires valid role parameter" do
    patch update_role_admin_user_path(@commentor_user, role: "invalid_role")

    assert_response :redirect
    assert_redirected_to admin_user_path(@commentor_user)

    @commentor_user.reload
    assert @commentor_user.commentor? # Should remain unchanged
  end
end
