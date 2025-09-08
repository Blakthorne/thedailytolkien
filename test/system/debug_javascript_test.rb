require "application_system_test_case"

class DebugJavascriptTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
    login_as_admin(@admin)
  end

  test "debug html and javascript loading" do
    visit admin_quotes_path

    # Save the page source for inspection
    page_source = page.html
    File.write("/tmp/debug_page.html", page_source)

    # Check for script tags
    script_tags = page.all("script", visible: :all)
    puts "\n=== SCRIPT TAGS FOUND ==="
    script_tags.each_with_index do |script, i|
      src = script["src"]
      type = script["type"]
      puts "Script #{i+1}: src='#{src}' type='#{type}'"
      if src.nil? && script.text.present?
        puts "  Inline content: #{script.text[0..100]}..."
      end
    end

    # Check for importmap
    importmap_script = page.find('script[type="importmap"]', visible: :all) rescue nil
    if importmap_script
      puts "\n=== IMPORTMAP CONTENT ==="
      puts importmap_script.text
    else
      puts "\n=== NO IMPORTMAP FOUND ==="
    end

    # Check for application script
    app_scripts = page.all('script[src*="application"]', visible: :all)
    puts "\n=== APPLICATION SCRIPTS ==="
    app_scripts.each do |script|
      puts "Application script: #{script['src']}"
    end

    puts "\nPage source saved to /tmp/debug_page.html"

    # This should not fail - just gathering debug info
    assert true
  end

  private

  def login_as_admin(user)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: "password123"
    click_button "Sign In"
    visit admin_root_path
  end
end
