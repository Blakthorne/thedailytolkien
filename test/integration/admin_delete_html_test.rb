require "test_helper"

class AdminDeleteHtmlInspectionTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @test_user = User.create!(
      first_name: "HTML",
      last_name: "InspectTest",
      email: "html-inspect-test@example.com",
      password: "password123",
      role: "commentor"
    )
  end

  test "inspect actual HTML generated for delete button" do
    # Authenticate
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "password123"
      }
    }

    # Get the show page
    get admin_user_path(@test_user)

    puts "\n🔍 HTML INSPECTION FOR DELETE BUTTON"
    puts "=" * 50

    html = response.body

    # Find all links containing "Delete"
    delete_links = html.scan(/<a[^>]*>.*?Delete.*?<\/a>/mi)

    puts "Delete links found: #{delete_links.length}"
    delete_links.each_with_index do |link, i|
      puts "\nDelete link #{i + 1}:"
      puts link

      # Check for required attributes
      has_turbo_method = link.include?("data-turbo-method")
      has_turbo_confirm = link.include?("data-turbo-confirm")
      has_href = link.match(/href="([^"]*)"/)

      puts "  ✅ Has data-turbo-method: #{has_turbo_method}"
      puts "  ✅ Has data-turbo-confirm: #{has_turbo_confirm}"
      puts "  ✅ Has href: #{has_href ? has_href[1] : 'NO'}"
    end

    # Check for CSRF token in the page
    csrf_token = html.match(/<meta name="csrf-token" content="([^"]*)"/)
    csrf_param = html.match(/<meta name="csrf-param" content="([^"]*)"/)
    puts "\n🛡️  CSRF token present: #{csrf_token ? 'YES' : 'NO'}"
    puts "🛡️  CSRF param present: #{csrf_param ? 'YES' : 'NO'}"
    if csrf_token
      puts "🔑 CSRF token: #{csrf_token[1][0..20]}..."
    end

    # Check for Turbo imports
    turbo_import = html.include?("@hotwired/turbo-rails") || html.include?("turbo")
    puts "🔧 Turbo imports found: #{turbo_import}"

    # Look for any JavaScript errors in console (we can't actually see them in tests, but check for error divs)
    error_divs = html.scan(/<div[^>]*error[^>]*>/i)
    puts "⚠️  Error divs found: #{error_divs.length}"

    # Add minimal assertion to verify we got a valid response
    assert_response :success
  end
end
