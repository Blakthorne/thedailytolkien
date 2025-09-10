#!/usr/bin/env ruby
# Test tag functionality by making HTTP requests to the admin interface

require 'net/http'
require 'uri'
require 'json'

# Test if we can access the admin tags page
def test_admin_tags_access
  uri = URI('http://localhost:3000/admin/tags')

  begin
    response = Net::HTTP.get_response(uri)
    puts "Admin tags index status: #{response.code}"

    if response.code == '302'
      puts "Redirected to: #{response['Location']}"
      puts "This is expected - admin authentication required"
    elsif response.code == '200'
      puts "Successfully accessed admin tags (already authenticated?)"
    else
      puts "Unexpected response code"
    end
  rescue => e
    puts "Error accessing admin tags: #{e.message}"
  end
end

# Test basic Rails app health
def test_app_health
  uri = URI('http://localhost:3000')

  begin
    response = Net::HTTP.get_response(uri)
    puts "App root status: #{response.code}"
  rescue => e
    puts "Error accessing app root: #{e.message}"
  end
end

puts "Testing The Daily Tolkien admin interface..."
puts "=" * 50

test_app_health
test_admin_tags_access

puts "=" * 50
puts "Manual testing required:"
puts "1. Navigate to http://localhost:3000"
puts "2. Login as admin (admin@thedailytolkien.com or dlpolar38@gmail.com)"
puts "3. Go to admin section"
puts "4. Try to create, update, or delete a tag"
puts "5. Check for any error messages"
