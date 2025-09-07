require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "action_description returns human friendly labels for known actions" do
    a = activity_logs(:one)
    a.action = "create"
    assert_equal "created", a.action_description

    a.action = "destroy"
    assert_equal "deleted", a.action_description

    a.action = "promote_user"
    assert_equal "promoted a user", a.action_description
  end

  test "action_description falls back to humanized for unknown actions" do
    a = activity_logs(:one)
    a.action = "something_weird"
    assert_equal "Something weird", a.action_description
  end

  test "target_description handles nil and known target types" do
    a = activity_logs(:one)
    # when target is present and points to quote fixture one
    quote = quotes(:one)
    a.target = quote
    a.target_type = "Quote"
  assert_match %r{Quote:}, a.target_description

    # when no target
    a.target = nil
    a.target_type = nil
    assert_equal "N/A", a.target_description
  end
end
