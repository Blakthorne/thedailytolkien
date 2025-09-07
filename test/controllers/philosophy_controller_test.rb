require "test_helper"

class PhilosophyControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get philosophy_path
    assert_response :success
  end
end
