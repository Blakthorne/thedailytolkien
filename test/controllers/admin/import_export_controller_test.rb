require "test_helper"

class Admin::ImportExportControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Clean up any existing data to avoid conflicts
    Quote.destroy_all
    Tag.destroy_all
    User.destroy_all

    @admin = User.create!(
      first_name: "Admin",
      last_name: "User",
      email: "admin_import_export@example.com",
      password: "password",
      password_confirmation: "password",
      role: "admin"
    )

    @user = User.create!(
      first_name: "Regular",
      last_name: "User",
      email: "user_import_export@example.com",
      password: "password",
      password_confirmation: "password",
      role: "commentor"
    )
  end

  test "should get index when logged in as admin" do
    sign_in @admin
    get admin_import_export_path
    assert_response :success
    assert_select "h1", text: "Import/Export Quotes"
  end

  test "should redirect when not logged in" do
    get admin_import_export_path
    assert_response :redirect
  end

  test "should redirect when logged in as non-admin" do
    sign_in @user
    get admin_import_export_path
    assert_response :redirect
  end

  test "should export CSV with enhanced format" do
    sign_in @admin

    # Create test quote with tags using unique names
    quote = Quote.create!(
      text: "Test quote text for export",
      book: "Test Book Export",
      chapter: "Test Chapter",
      context: "Test Context",
      character: "Test Character"
    )

    tag1 = Tag.create!(name: "wisdom_export")
    tag2 = Tag.create!(name: "courage_export")
    quote.tags << [ tag1, tag2 ]

    get admin_import_export_export_path
    assert_response :success
    assert_equal "text/csv", response.content_type

    csv_content = response.body
    assert_includes csv_content, "text,book,chapter,context,character,tags"
    assert_includes csv_content, "Test quote text for export"
    assert_includes csv_content, "wisdom_export,courage_export"
  end

  test "should import valid CSV file" do
    sign_in @admin

    csv_content = "text,book,chapter,context,character,tags\n" +
                  "\"All that is gold does not glitter\",\"The Fellowship of the Ring\",\"Chapter 1\",\"Aragorn's heritage\",\"Bilbo\",\"wisdom_import,poetry_import\"\n" +
                  "\"You shall not pass!\",\"The Fellowship of the Ring\",\"Chapter 5\",\"The Bridge\",\"Gandalf\",\"courage_import\""

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    uploaded_file = Rack::Test::UploadedFile.new(csv_file.path, "text/csv", original_filename: "test.csv")

    assert_difference "Quote.count", 2 do
      assert_difference "Tag.count", 3 do # wisdom_import, poetry_import, courage_import
        post admin_import_export_import_path, params: { csv_file: uploaded_file }
      end
    end

    assert_redirected_to admin_import_export_path
    assert_match(/Import completed!/, flash[:notice])
    assert_match(/Successfully imported: 2 quotes/, flash[:notice])

    # Verify quotes were created
    quote1 = Quote.find_by(text: "All that is gold does not glitter")
    assert_not_nil quote1
    assert_equal "The Fellowship of the Ring", quote1.book
    assert_equal "Chapter 1", quote1.chapter
    assert_equal "Aragorn's heritage", quote1.context
    assert_equal "Bilbo", quote1.character
    assert_equal 2, quote1.tags.count
    assert_includes quote1.tags.map(&:name), "wisdom_import"
    assert_includes quote1.tags.map(&:name), "poetry_import"

    csv_file.close
    csv_file.unlink
  end

  test "should handle duplicate quotes in CSV import" do
    sign_in @admin

    # Create existing quote (we just need to check it's created, don't need the variable)
    Quote.create!(
      text: "All that is gold does not glitter",
      book: "The Fellowship of the Ring"
    )

    csv_content = "text,book,chapter,context,character,tags\n" +
                  "\"All that is gold does not glitter\",\"The Fellowship of the Ring\",\"Chapter 1\",\"Aragorn's heritage\",\"Bilbo\",\"wisdom\"\n" +
                  "\"New quote\",\"New Book\",\"\",\"\",\"\",\"\""

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    uploaded_file = Rack::Test::UploadedFile.new(csv_file.path, "text/csv", original_filename: "test.csv")

    assert_difference "Quote.count", 1 do # Only new quote should be added
      post admin_import_export_import_path, params: { csv_file: uploaded_file }
    end

    assert_redirected_to admin_import_export_path
    assert_match(/Import completed!/, flash[:notice])
    assert_match(/Successfully imported: 1 quotes/, flash[:notice])
    assert_match(/Skipped \(duplicates\): 1 quotes/, flash[:notice])

    csv_file.close
    csv_file.unlink
  end

  test "should handle invalid CSV data" do
    sign_in @admin

    csv_content = "text,book,chapter,context,character,tags\n" +
                  "\"\",\"The Fellowship of the Ring\",\"Chapter 1\",\"Aragorn's heritage\",\"Bilbo\",\"wisdom\"\n" +  # Missing required text
                  "\"Valid quote\",\"\",\"\",\"\",\"\",\"\"\n" +  # Missing required book
                  "\"Another valid quote\",\"Valid Book\",\"\",\"\",\"\",\"\""  # This should succeed

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    uploaded_file = Rack::Test::UploadedFile.new(csv_file.path, "text/csv", original_filename: "test.csv")

    assert_difference "Quote.count", 1 do # Only valid quote should be added
      post admin_import_export_import_path, params: { csv_file: uploaded_file }
    end

    assert_redirected_to admin_import_export_path
    assert_match(/Import completed!/, flash[:alert])
    assert_match(/Successfully imported: 1 quotes/, flash[:alert])
    assert_match(/Failed: 2 quotes/, flash[:alert])

    csv_file.close
    csv_file.unlink
  end

  test "should require CSV file for import" do
    sign_in @admin

    post admin_import_export_import_path
    assert_redirected_to admin_import_export_path
    assert_equal "Please select a CSV file to upload.", flash[:alert]
  end

  test "should validate file type" do
    sign_in @admin

    text_file = Tempfile.new([ "test", ".txt" ])
    text_file.write("This is not a CSV file")
    text_file.rewind

    uploaded_file = Rack::Test::UploadedFile.new(text_file.path, "text/plain", original_filename: "test.txt")

    post admin_import_export_import_path, params: { csv_file: uploaded_file }
    assert_redirected_to admin_import_export_path
    assert_equal "Please upload a valid CSV file.", flash[:alert]

    text_file.close
    text_file.unlink
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password"
      }
    }
  end
end
