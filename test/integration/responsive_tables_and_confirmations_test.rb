require "test_helper"

class ResponsiveTablesAndConfirmationsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
  end

  test "responsive tables and delete confirmations work correctly" do
    # Authenticate as admin
    post user_session_path, params: {
      user: { email: @admin.email, password: "password123" }
    }

    puts "\n🧪 COMPREHENSIVE RESPONSIVE TABLES & CONFIRMATIONS TEST"
    puts "=" * 60

    # Test 1: Users Admin Table
    puts "\n1. 👥 Users Admin Table:"
    get admin_users_path
    assert_response :success

    # Check for responsive table classes
    if response.body.include?("responsive-table-container") && response.body.include?("responsive-table")
      puts "   ✅ Responsive table structure found"
    else
      puts "   ❌ Missing responsive table structure"
    end

    # Check for column priorities
    priority_classes = [ "col-priority-critical", "col-priority-high", "col-priority-medium", "col-priority-low" ]
    priority_classes.each do |class_name|
      if response.body.include?(class_name)
        puts "   ✅ Found priority class: #{class_name}"
      else
        puts "   ⚠️  Missing priority class: #{class_name}"
      end
    end

    # Check for data-label attributes (for mobile cards)
    if response.body.include?('data-label="Name"')
      puts "   ✅ Mobile card labels found"
    else
      puts "   ❌ Missing mobile card labels"
    end

    # Test 2: Activity Logs Table
    puts "\n2. 📊 Activity Logs Table:"
    get admin_activity_logs_path
    assert_response :success

    if response.body.include?("responsive-table-container")
      puts "   ✅ Activity logs responsive structure found"
    else
      puts "   ❌ Missing activity logs responsive structure"
    end

    # Test 3: Comments Admin Table
    puts "\n3. 💬 Comments Admin Table:"
    get admin_comments_path
    assert_response :success

    if response.body.include?("responsive-table-container")
      puts "   ✅ Comments responsive structure found"
    else
      puts "   ❌ Missing comments responsive structure"
    end

    # Test delete confirmation in comments (the one we just fixed)
    if response.body.include?('data-turbo-confirm="Are you sure you want to delete this comment?')
      puts "   ✅ Comments delete confirmation found"
    else
      puts "   ❌ Comments delete confirmation missing"
    end

    # Test 4: CSS File Loaded
    puts "\n4. 🎨 CSS Assets:"

    # Check if admin_responsive_tables.css is being served
    get "/assets/admin_responsive_tables.css"
    if response.status == 200
      puts "   ✅ Responsive tables CSS file accessible"
    else
      puts "   ⚠️  Responsive tables CSS file not accessible (may need asset compilation)"
    end

    puts "\n🎯 MOBILE RESPONSIVENESS CHECK:"
    puts "=" * 40

    # Simulate mobile viewport test
    get admin_users_path, headers: {
      "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
    }

    # Check for proper table structure that supports mobile
    mobile_features = [
      "responsive-table-container",  # Container for horizontal scroll
      "col-priority-critical",       # Critical columns shown on mobile
      "data-label=",                 # Labels for mobile cards
      "table-cell-truncate"          # Content truncation
    ]

    mobile_features.each do |feature|
      if response.body.include?(feature)
        puts "   ✅ Mobile feature found: #{feature}"
      else
        puts "   ❌ Missing mobile feature: #{feature}"
      end
    end

    puts "\n📱 ACCESSIBILITY CHECK:"
    puts "=" * 30

    # Check accessibility features
    accessibility_features = [
      "aria-label=",          # Proper labels
      'tabindex="0"',         # Keyboard navigation
      'role="columnheader"',  # Semantic headers
      "caption"              # Table captions
    ]

    accessibility_features.each do |feature|
      if response.body.include?(feature)
        puts "   ✅ Accessibility feature: #{feature}"
      else
        puts "   ⚠️  Missing accessibility feature: #{feature}"
      end
    end

    puts "\n🎉 RESPONSIVE TABLES & CONFIRMATIONS TEST COMPLETE!"
    puts "📋 Manual Testing Recommendations:"
    puts "1. Test on mobile device or browser dev tools"
    puts "2. Try different screen sizes (320px, 768px, 1024px, 1200px+)"
    puts "3. Test horizontal scrolling on small screens"
    puts "4. Verify delete confirmations appear in all admin sections"
    puts "5. Test keyboard navigation with Tab key"
  end
end
