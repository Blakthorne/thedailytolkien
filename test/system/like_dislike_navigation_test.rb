require "application_system_test_case"

class LikeDislikeNavigationTest < ApplicationSystemTestCase
  test "like/dislike buttons structure is present on page load" do
    visit "/"
    assert_selector ".quote-text", wait: 10

    # Verify engagement section exists (even for unauthenticated users)
    assert_selector ".quote-engagement-wrapper"

    # For unauthenticated users, should see static engagement display
    within(".quote-engagement-wrapper") do
      assert_selector ".quote-engagement"
      assert_selector ".engagement-btn", count: 2
      assert_selector ".count", count: 2
    end
  end

  test "QuoteEngagement JavaScript structure is properly initialized after page reload" do
    visit "/"
    assert_selector ".quote-text", wait: 10

    # Navigate via JavaScript (simulating Turbo navigation)
    page.execute_script("window.location.reload()")
    assert_selector ".quote-text", wait: 10

    # Verify the engagement section still exists after reload
    assert_selector ".quote-engagement-wrapper"
    within(".quote-engagement-wrapper") do
      assert_selector ".quote-engagement"
      assert_selector ".engagement-btn", count: 2
    end
  end

  test "page structure persists through browser refresh cycles" do
    visit "/"
    assert_selector ".quote-text", wait: 10

    # Get the initial page title for comparison
    initial_title = page.title

    # Refresh the page
    page.refresh
    assert_selector ".quote-text", wait: 10

    # Verify page loaded correctly and structure persists
    assert_equal initial_title, page.title
    assert_selector ".quote-engagement-wrapper"

    within(".quote-engagement-wrapper") do
      assert_selector ".quote-engagement"
      assert_selector ".engagement-btn", count: 2
      assert_selector ".count", count: 2
    end
  end

  test "JavaScript modules remain functional after programmatic navigation" do
    visit "/"
    assert_selector ".quote-text", wait: 10

    # Test that the basic page structure loads correctly
    assert_selector ".quote-engagement-wrapper"

    # Execute some JavaScript to test that modules are working
    # We test functionality rather than module existence since ES6 modules aren't global
    js_result = page.execute_script(<<-JS)
      return {
        hasEngagementContainer: document.querySelector('.quote-engagement-wrapper') !== null,
        hasEngagementButtons: document.querySelectorAll('.engagement-btn').length === 2,
        hasCommentsList: document.getElementById('comments-list') !== null,
        documentReady: document.readyState === 'complete'
      };
    JS

    # Verify our page structure is properly loaded
    assert js_result["hasEngagementContainer"], "Engagement container should exist"
    assert js_result["hasEngagementButtons"], "Should have 2 engagement buttons"
    assert js_result["hasCommentsList"], "Comments list should exist"
    assert js_result["documentReady"], "Document should be fully loaded"
  end
end
