require "test_helper"

class QuoteAuthenticationMessageTest < ActionDispatch::IntegrationTest
  test "unauthenticated user sees sign in message for like/dislike buttons" do
    # Get the quotes page without authentication
    get root_path

    # Check that the page loads successfully
    assert_response :success

    # Check for the sign in message for like/dislike
    assert_select "p.empty-message", text: /Sign in.*to like\/dislike/

    # Check that the like/dislike buttons are still visible but not interactive
    assert_select ".quote-engagement-wrapper", count: 1
    assert_select ".quote-engagement .engagement-btn", count: 2

    # Check that interactive buttons with data attributes are NOT present for unauthenticated users
    assert_select 'button[data-type="like"]', count: 0
    assert_select 'button[data-type="dislike"]', count: 0
  end

  test "unauthenticated user sees sign in message for comments" do
    # Get the quotes page without authentication
    get root_path

    # Check that the page loads successfully
    assert_response :success

    # Check for the sign in message for comments
    assert_select "p.empty-message", text: /Sign in.*to join the conversation/
  end
end
