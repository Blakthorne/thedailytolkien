require "test_helper"

class PhilosophyPageTest < ActionDispatch::IntegrationTest
  setup do
    @md_path = Rails.root.join("app", "content", "philosophy.md")
    @backup_path = Rails.root.join("app", "content", "philosophy.backup.md")
    if File.exist?(@md_path)
      FileUtils.cp(@md_path, @backup_path)
      FileUtils.rm(@md_path)
    end
  end

  teardown do
    if File.exist?(@backup_path)
      FileUtils.mv(@backup_path, @md_path)
    end
  end

  test "philosophy page renders fallback when file missing" do
    get philosophy_path
    assert_response :success
    assert_select "h1, h2, h3, p", /Philosophy Content Missing|
                                      could not be found|
                                      Please create this file/i
  end

  test "philosophy page renders markdown when file exists" do
    File.write(@md_path, "# Hello\n\nThis is content.")
    get philosophy_path
    assert_response :success
    assert_select "h1, h2", /Hello/
    assert_select "p", /This is content./
  end
end
