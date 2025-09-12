#!/usr/bin/env ruby

# Set the Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Load the Rails application
require_relative 'config/environment'

# Simulate the test setup
quote = Quote.create!(
  text: "Test quote for archive controller testing",
  book: "Test Book",
  character: "Test Character",
  last_date_displayed: 1.day.ago.to_i,
  first_date_displayed: 1.day.ago.to_i
)

puts "=== Created quote ==="
puts "ID: #{quote.id}"
puts "Text: #{quote.text}"
puts "last_date_displayed: #{quote.last_date_displayed}"
puts "Time: #{Time.at(quote.last_date_displayed)}"

# Try to get the date string like the test does
date_string = Time.at(quote.last_date_displayed).strftime("%Y-%m-%d")
puts "\n=== Date string: #{date_string} ==="

# Test what the controller method does
require_relative 'app/controllers/archive_controller'

controller = ArchiveController.new
controller.params = ActionController::Parameters.new(date: date_string)

# Simulate the show method logic
begin
  date = Date.parse(date_string)
  puts "Parsed date: #{date}"
  
  quotes_found = Quote.displayed_on_date(date)
  puts "Quotes found: #{quotes_found.count}"
  
  if quotes_found.any?
    puts "Quote text: #{quotes_found.first.text}"
  else
    puts "No quotes found for date"
  end
rescue => e
  puts "Error: #{e.message}"
end
