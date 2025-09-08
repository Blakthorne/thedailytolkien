require "test_helper"

class AdminQuotesNegativeCasesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @quote = Quote.create!(text: "OK", book: "LOTR", days_displayed: 0)
  end

  test "update fails with invalid params and renders edit" do
    patch admin_quote_path(@quote), params: { quote: { text: "", book: "" } }
    assert_response :unprocessable_content
    assert_select "h1", /Edit Quote #/
  end
end
