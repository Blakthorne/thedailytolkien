require "test_helper"

class PhilosophyControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get philosophy_show_url
    assert_response :success
  end
end
