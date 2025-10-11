require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
  end

  test "selects quote based on user-local day boundaries" do
  # Create two quotes without last_date_displayed so rotation can pick one
  Quote.create!(text: "Q1", book: "B1")
  Quote.create!(text: "Q2", book: "B2")

    # User in Auckland (far ahead of UTC)
    user = User.create!(
      first_name: "A",
      last_name: "U",
      email: "au@example.com",
      password: "password",
      role: "commentor",
      streak_timezone: "Auckland"
    )

    # Simulate time just after midnight in Auckland using travel_to
    akl_zone = ActiveSupport::TimeZone["Auckland"]
    travel_to akl_zone.parse("2024-06-01 00:05:00").utc do
      sign_in user
      get root_path
      assert_response :success
      # One of the quotes should now be marked as displayed today in Auckland
      today_start_akl = akl_zone.parse("2024-06-01 00:00:00").to_i
      assert Quote.where(last_date_displayed: today_start_akl..today_start_akl + 86_399).exists?
    end
  end

  test "guest cookie timezone controls day boundary" do
    # Ensure rotation has quotes available
    Quote.create!(text: "GQ1", book: "GB1")
    Quote.create!(text: "GQ2", book: "GB2")

    # Guest in Tokyo
    tokyo = ActiveSupport::TimeZone["Tokyo"]
    travel_to tokyo.parse("2024-06-15 00:03:00").utc do
      # Set guest timezone cookie to IANA identifier
      cookies["guest_tz"] = "Asia/Tokyo"

      get root_path
      assert_response :success

      today_start_tokyo = tokyo.parse("2024-06-15 00:00:00").to_i
      assert Quote.where(last_date_displayed: today_start_tokyo..today_start_tokyo + 86_399).exists?,
             "Expected a quote to be marked for the guest's local day window"
    end
  end

  test "DST spring forward boundary uses local day" do
    # US Eastern DST started on 2024-03-10 at 02:00 local time (skips to 03:00)
    # Verify that just after local midnight we still mark the correct day window
    Quote.create!(text: "DST1", book: "B1")
    Quote.create!(text: "DST2", book: "B2")

    eastern = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    travel_to eastern.parse("2024-03-10 00:05:00").utc do
      cookies["guest_tz"] = "America/New_York"

      get root_path
      assert_response :success

      day_start = eastern.parse("2024-03-10 00:00:00").to_i
      assert Quote.where(last_date_displayed: day_start..day_start + 86_399).exists?,
             "Expected quote marked for local DST spring-forward day boundary"
    end
  end

  test "DST fall back boundary uses local day" do
    # US Eastern DST ends on 2024-11-03 at 02:00 local time (repeats 01:00 hour)
    Quote.create!(text: "DSTF1", book: "B1")
    Quote.create!(text: "DSTF2", book: "B2")

    eastern = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    travel_to eastern.parse("2024-11-03 00:05:00").utc do
      cookies["guest_tz"] = "America/New_York"

      get root_path
      assert_response :success

      day_start = eastern.parse("2024-11-03 00:00:00").to_i
      assert Quote.where(last_date_displayed: day_start..day_start + 86_399).exists?,
             "Expected quote marked for local DST fall-back day boundary"
    end
  end

  test "admin edit button appears for admin users on home page" do
    admin_user = users(:admin)
    sign_in admin_user
    get root_path
    assert_response :success
    assert_select "a.admin-quick-edit-btn", text: /Edit Quote/
  end

  test "admin edit button does not appear for non-admin users on home page" do
    regular_user = users(:commentor)
    sign_in regular_user
    get root_path
    assert_response :success
    assert_select "a.admin-quick-edit-btn", count: 0
  end

  test "admin edit button does not appear for guests on home page" do
    get root_path
    assert_response :success
    assert_select "a.admin-quick-edit-btn", count: 0
  end
end
