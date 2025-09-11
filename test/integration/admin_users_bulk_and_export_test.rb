require "test_helper"

class AdminUsersBulkAndExportTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @u1 = User.create!(first_name: "Test", last_name: "User1", email: "a1@example.com", password: "password123", role: "commentor")
    @u2 = User.create!(first_name: "Test", last_name: "User2", email: "a2@example.com", password: "password123", role: "commentor")
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "bulk delete users excluding current user" do
    assert_difference("User.count", -2) do
      post bulk_action_admin_users_path, params: { user_ids: [ @u1.id, @u2.id, @admin.id ], bulk_action: "delete" }
    end
    assert_redirected_to admin_users_path
  end

  test "bulk role changes work" do
    post bulk_action_admin_users_path, params: { user_ids: [ @u1.id, @u2.id ], bulk_action: "make_admin" }
    assert_redirected_to admin_users_path
    assert_equal [ "admin", "admin" ], [ @u1.reload.role, @u2.reload.role ]

    post bulk_action_admin_users_path, params: { user_ids: [ @u1.id, @u2.id ], bulk_action: "make_commentor" }
    assert_redirected_to admin_users_path
    assert_equal [ "commentor", "commentor" ], [ @u1.reload.role, @u2.reload.role ]
  end

  test "users export csv" do
    get admin_users_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
  end
end
