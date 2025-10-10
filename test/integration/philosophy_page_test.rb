# Temporarily disabled - Philosophy page hidden
=begin
require "test_helper"

class PhilosophyPageTest < ActionDispatch::IntegrationTest
  parallelize workers: 1  # Disable parallelization for this test class
  setup do
    @md_path = Rails.root.join("app", "content", "philosophy.md")
    @backup_path = Rails.root.join("app", "content", "philosophy.backup.md")
    # Always backup the original file if it exists
    if File.exist?(@md_path)
      FileUtils.cp(@md_path, @backup_path)
    end
  end

  teardown do
    # Always clean up and restore original state
    FileUtils.rm(@md_path) if File.exist?(@md_path)
    if File.exist?(@backup_path)
      FileUtils.mv(@backup_path, @md_path)
    end
  end

  test "philosophy page renders fallback when file missing" do
    # Ensure the file is removed for this test
    FileUtils.rm(@md_path) if File.exist?(@md_path)

    get philosophy_path
    assert_response :success
    assert_select ".markdown-content", text: /Philosophy Content Missing/
  end

  test "philosophy page renders markdown when file exists" do
    # Ensure we have a fresh file for this test
    File.write(@md_path, "# Hello\n\nThis is content.")

    get philosophy_path
    assert_response :success
    assert_select ".markdown-content", text: /Hello/
    assert_select ".markdown-content", text: /This is content./
  end
end
=end
