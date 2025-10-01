require "test_helper"

class ContextFieldIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      first_name: "Context",
      last_name: "TestAdmin",
      email: "context_test_admin@example.com",
      password: "password123",
      role: "admin"
    )

    @quote = Quote.create!(
      text: "This is a test quote with context",
      book: "Test Book",
      chapter: "Test Chapter",
      context: "This is test context information",
      character: "Test Character"
    )
  end

  def teardown
    User.where(email: "context_test_admin@example.com").destroy_all
    Quote.where(text: "This is a test quote with context").destroy_all
  end

  def sign_in_admin
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "password123"
      }
    }
  end

  test "context field displays on main quote page" do
    # Completely clear out all existing quotes to avoid conflicts
    Quote.destroy_all

    # Create only our test quote
    test_quote = Quote.create!(
      text: "This is a test quote with context",
      book: "Test Book",
      chapter: "Test Chapter",
      context: "This is test context information",
      character: "Test Character"
    )

    # Set our test quote as the current quote for today using exact same logic as controller
    today_start = Time.now.beginning_of_day.to_i
    test_quote.update!(
      days_displayed: 1,
      last_date_displayed: today_start,
      first_date_displayed: today_start
    )

    get root_path
    assert_response :success

    assert_match "This is test context information", response.body
  end

  test "context field displays on discover page" do
    # Set up quote with a specific date for discover display
    @quote.update!(
      days_displayed: 1,
      last_date_displayed: 1.day.ago.to_time.to_i,
      first_date_displayed: 1.day.ago.to_time.to_i
    )

    get discover_path(@quote.id)
    assert_response :success
    assert_match "This is test context information", response.body
  end

  test "context field displays on admin quote show page" do
    sign_in_admin
    get admin_quote_path(@quote)
    assert_response :success
    assert_match "This is test context information", response.body
  end

  test "context field appears in admin quote edit form" do
    sign_in_admin
    get edit_admin_quote_path(@quote)
    assert_response :success
    assert_match 'name="quote[context]"', response.body
    assert_match "This is test context information", response.body
  end

  test "context field appears in admin new quote form" do
    sign_in_admin
    get new_admin_quote_path
    assert_response :success
    assert_match 'name="quote[context]"', response.body
  end

  test "context can be updated via admin form" do
    sign_in_admin

    patch admin_quote_path(@quote), params: {
      quote: {
        text: @quote.text,
        book: @quote.book,
        chapter: @quote.chapter,
        character: @quote.character,
        context: "Updated context information"
      }
    }

    assert_redirected_to admin_quote_path(@quote)
    @quote.reload
    assert_equal "Updated context information", @quote.context
  end

  test "context field is included in CSV export" do
    sign_in_admin

    get admin_quotes_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match "Context", response.body  # Column header
    assert_match "This is test context information", response.body  # Data
  end
end
